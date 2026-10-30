const Lesson = require('../models/Lesson');
const Section = require('../models/Section');
const Course = require('../models/Course');
const s3Service = require('../services/s3.service');
const { sendSuccess, sendError, sendNotFound } = require('../utils/response.utils');
const { transformUrls } = require('../utils/url.utils');

// Get all lessons for a section
const getLessonsBySection = async (req, res) => {
  try {
    const { sectionId } = req.params;
    
    // Verify section exists
    const section = await Section.findById(sectionId);
    if (!section) {
      return sendNotFound(res, 'Section not found');
    }

    // Check if user is enrolled in course (skip for admins)
    if (req.user && req.user.role !== 'admin') {
      const Enrollment = require('../models/Enrollment');
      const enrollment = await Enrollment.findOne({
        userId: req.user.id,
        courseId: section.courseId
      });

      if (!enrollment) {
        return sendError(res, 'Access denied. You must be enrolled in this course to access lessons.', 403);
      }

      // Check if enrollment has expired
      const isEnrollmentExpired = (enrollment) => {
        if (!enrollment.accessExpirationDate) {
          return false; // No expiration set, access is unlimited
        }
        const currentDate = new Date();
        return currentDate > enrollment.accessExpirationDate;
      };

      if (isEnrollmentExpired(enrollment)) {
        return sendError(res, 'Access denied. Your enrollment has expired.', 403);
      }
    }
    
    const lessons = await Lesson.find({ sectionId })
      .sort({ order: 1 });
    
    const lessonsWithUrls = lessons.map(lesson => formatLessonUrls(lesson, s3Service));
    
    sendSuccess(res, transformUrls(lessonsWithUrls, ['thumbnail', 'videoUrl', 'url', 'notesPdfUrl']), 'Lessons retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve lessons', 500, error.message);
  }
};

// Get lesson by ID
const getLessonById = async (req, res) => {
  try {
    const { lessonId } = req.params;
    
    const lesson = await Lesson.findById(lessonId);
    
    if (!lesson) {
      return sendNotFound(res, 'Lesson not found');
    }

    // Check if user is enrolled in the course (skip for admins)
    if (req.user && req.user.role !== 'admin') {
      const Enrollment = require('../models/Enrollment');
      const enrollment = await Enrollment.findOne({
        userId: req.user.id,
        courseId: lesson.courseId
      });

      if (!enrollment) {
        return sendError(res, 'Access denied. You must be enrolled in this course to access lessons.', 403);
      }

      // Check if enrollment has expired
      const isEnrollmentExpired = (enrollment) => {
        if (!enrollment.accessExpirationDate) {
          return false; // No expiration set, access is unlimited
        }
        const currentDate = new Date();
        return currentDate > enrollment.accessExpirationDate;
      };

      if (isEnrollmentExpired(enrollment)) {
        return sendError(res, 'Access denied. Your enrollment has expired.', 403);
      }
    }
    
    const lessonObj = formatLessonUrls(lesson, s3Service);
    
    sendSuccess(res, transformUrls(lessonObj, ['thumbnail', 'videoUrl', 'url', 'notesPdfUrl']), 'Lesson retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve lesson', 500, error.message);
  }
};

// Create lesson (admin only)
const createLesson = async (req, res) => {
  try {
    const { sectionId } = req.params;
    const { title, description, videoId, notes, notesPdfUrl, order, duration, quizId, materials, lessonType, isPublished } = req.body;

    console.log('Creating lesson with data:', { sectionId, title, videoId, notesPdfUrl, quizId, lessonType, order, duration });
    
    // Verify section exists
    const section = await Section.findById(sectionId);
    if (!section) {
      return sendNotFound(res, 'Section not found');
    }
    
    // If notes field looks like a document path, process it with AI to organize notes
    let processedNotes = notes;
    const documentPath = notesPdfUrl || notes; // Prioritize notesPdfUrl for processing
    const shouldProcessNotes = req.body.processNotes === 'true' || req.body.processNotes === true;
    
    if (shouldProcessNotes && documentPath && (documentPath.includes('documents/') || documentPath.includes('.pdf') || documentPath.includes('.doc') || documentPath.includes('.docx'))) {
      try {
        const S3Service = require('../services/s3.service');
        const DocumentProcessingService = require('../services/document_processing_service');
        const GrokService = require('../services/grok_service');
        
        if (GrokService.isConfigured()) {
          // Fetch the document from S3
          const documentBuffer = await S3Service.getFileBuffer(documentPath);
          
          if (documentBuffer) {
            // Determine MIME type based on file extension
            let mimeType = 'application/pdf'; // default
            if (documentPath.toLowerCase().includes('.docx')) {
              mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
            } else if (documentPath.toLowerCase().includes('.doc')) {
              mimeType = 'application/msword';
            } else if (documentPath.toLowerCase().includes('.txt')) {
              mimeType = 'text/plain';
            }
            
            // Organize the notes using Groq AI
            processedNotes = await GrokService.organizeNotes({
              buffer: documentBuffer,
              mimetype: mimeType,
              originalname: documentPath.split('/').pop()
            }, mimeType);
            
            console.log('Successfully organized notes using Groq AI for lesson');
          }
        }
      } catch (aiError) {
        console.error('Error processing document for notes organization:', aiError);
        // Fall back to using the original notes
        processedNotes = notes;
      }
    }
    
    const lessonData = {
      sectionId,
      courseId: section.courseId,
      title,
      description,
      videoId,
      notes: processedNotes, // Use processed notes instead of original
      notesPdfUrl,
      order,
      duration,
      quizId, // New field for quiz association
      materials: materials || [], // New field for additional materials
      lessonType: lessonType || 'Content', // New field for lesson type
      isPublished: isPublished !== undefined ? isPublished : true // New field for publish status
    };

    console.log('Lesson data to create:', lessonData);
    
    const lesson = await Lesson.create(lessonData);
    
    const lessonObj = formatLessonUrls(lesson, s3Service);
    
    sendSuccess(res, transformUrls(lessonObj, ['thumbnail', 'videoUrl', 'url', 'notesPdfUrl']), 'Lesson created successfully', 201);
  } catch (error) {
    console.error('Error creating lesson:', error);
    sendError(res, 'Failed to create lesson', 500, error.message);
  }
};

// Generated-video metadata safe for the client: files that are pending review
// (or rejected) are hidden, internal fields are dropped. Older lessons have
// no such field and simply return null.
const { isVideoWatchable } = require('../models/schemas/aiVideo.schema');
const publicVideoMeta = (v) => {
  if (!v) return null;
  const { previous, jobId, provider, pendingContentVersion, ...meta } = v;
  if (!isVideoWatchable(v)) {
    meta.s3Key = null;
    meta.url = null;
    meta.captionsKey = null;
    meta.captionsUrl = null;
    meta.transcript = null;
    meta.interactions = [];
    meta.credits = [];
  }
  return meta;
};

// Helper function to format lesson URLs
const formatLessonUrls = (lesson, s3Service) => {
  const lessonObj = lesson.toObject();
  lessonObj.aiVideo = publicVideoMeta(lessonObj.aiVideo);
  lessonObj.aiExperimentVideo = publicVideoMeta(lessonObj.aiExperimentVideo);
  lessonObj.demo = require('../services/demo/demo.service').publicDemo(lessonObj.demo);
  
  if (lessonObj.videoId && !lessonObj.videoId.startsWith('http')) {
    lessonObj.videoUrl = s3Service.getPublicUrl(lessonObj.videoId);
  } else if (lessonObj.videoId) {
    lessonObj.videoUrl = lessonObj.videoId;
  }
  
  if (lessonObj.notesPdfUrl && !lessonObj.notesPdfUrl.startsWith('http')) {
    lessonObj.notesPdfUrl = s3Service.getPublicUrl(lessonObj.notesPdfUrl);
  }
  
  return lessonObj;
};

// Update lesson (admin only)
const updateLesson = async (req, res) => {
  try {
    const { lessonId } = req.params;
    const updateData = { ...req.body };
    
    // Remove null/undefined values to avoid overwriting existing data with null
    Object.keys(updateData).forEach(key => {
      if (updateData[key] === null || updateData[key] === undefined) {
        delete updateData[key];
      }
    });
    
    // If notesPdfUrl is provided but notes is not, try to organize notes
    if (updateData.notesPdfUrl && !updateData.notes) {
      try {
        const S3Service = require('../services/s3.service');
        const GrokService = require('../services/grok_service');
        
        if (GrokService.isConfigured()) {
          const documentBuffer = await S3Service.getFileBuffer(updateData.notesPdfUrl);
          if (documentBuffer) {
            let mimeType = 'application/pdf';
            if (updateData.notesPdfUrl.toLowerCase().includes('.docx')) {
              mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
            }
            
            updateData.notes = await GrokService.organizeNotes({
              buffer: documentBuffer,
              mimetype: mimeType,
              originalname: updateData.notesPdfUrl.split('/').pop()
            }, mimeType);
          }
        }
      } catch (aiError) {
        console.error('Error auto-organizing notes during update:', aiError);
      }
    }

    // Generated-video bookkeeping is managed by the video pipeline only.
    delete updateData.aiVideo;
    delete updateData.aiExperimentVideo;
    delete updateData.demo; // set from the course builder's Demo tab only
    delete updateData.contentVersion;
    if (updateData.aiContent !== undefined) {
      // Edited AI content → new content version; existing generated videos are outdated.
      const existing = await Lesson.findById(lessonId).select('aiVideo aiExperimentVideo').lean();
      updateData.$inc = { contentVersion: 1 };
      if (existing?.aiVideo?.s3Key) updateData['aiVideo.stale'] = true;
      if (existing?.aiExperimentVideo?.s3Key) updateData['aiExperimentVideo.stale'] = true;
    }

    const lesson = await Lesson.findByIdAndUpdate(
      lessonId,
      updateData,
      { new: true, runValidators: true }
    );
    
    if (!lesson) {
      return sendNotFound(res, 'Lesson not found');
    }
    
    const lessonObj = formatLessonUrls(lesson, s3Service);
    
    sendSuccess(res, transformUrls(lessonObj, ['thumbnail', 'videoUrl', 'url', 'notesPdfUrl']), 'Lesson updated successfully');
  } catch (error) {
    sendError(res, 'Failed to update lesson', 500, error.message);
  }
};

// Delete lesson (admin only)
const deleteLesson = async (req, res) => {
  try {
    const { lessonId } = req.params;
    
    const lesson = await Lesson.findByIdAndDelete(lessonId);
    
    if (!lesson) {
      return sendNotFound(res, 'Lesson not found');
    }
    
    sendSuccess(res, null, 'Lesson deleted successfully');
  } catch (error) {
    sendError(res, 'Failed to delete lesson', 500, error.message);
  }
};

// Reorder lessons (admin only)
const reorderLessons = async (req, res) => {
  try {
    const { sectionId } = req.params;
    const { lessonIds } = req.body; // Array of lesson IDs in new order
    
    // Verify section exists
    const section = await Section.findById(sectionId);
    if (!section) {
      return sendNotFound(res, 'Section not found');
    }
    
    // Update order for each lesson
    const updatePromises = lessonIds.map((lessonId, index) =>
      Lesson.findByIdAndUpdate(lessonId, { order: index + 1 }, { new: true })
    );
    
    await Promise.all(updatePromises);
    
    const updatedLessons = await Lesson.find({ sectionId }).sort({ order: 1 });
    
    const lessonsWithUrls = updatedLessons.map(lesson => formatLessonUrls(lesson, s3Service));
    
    sendSuccess(res, transformUrls(lessonsWithUrls, ['thumbnail', 'videoUrl', 'url', 'notesPdfUrl']), 'Lessons reordered successfully');
  } catch (error) {
    sendError(res, 'Failed to reorder lessons', 500, error.message);
  }
};

// Get course content with sections and lessons
const getCourseContent = async (req, res) => {
  try {
    const { courseId } = req.params;
    
    // Verify course exists
    const course = await Course.findById(courseId);
    if (!course) {
      return sendNotFound(res, 'Course not found');
    }

    // Check if user is enrolled in course (skip for admins and instructors)
    const isStudent = req.user && req.user.role !== 'admin' && req.user.role !== 'instructor';
    
    if (isStudent) {
      const Enrollment = require('../models/Enrollment');
      const enrollment = await Enrollment.findOne({
        userId: req.user.id,
        courseId: courseId
      });

      if (!enrollment) {
        return sendError(res, 'Access denied. You must be enrolled in this course to access content.', 403);
      }

      // Check if enrollment has expired
      const isEnrollmentExpired = (enrollment) => {
        if (!enrollment.accessExpirationDate) {
          return false; // No expiration set, access is unlimited
        }
        const currentDate = new Date();
        return currentDate > enrollment.accessExpirationDate;
      };

      if (isEnrollmentExpired(enrollment)) {
        return sendError(res, 'Access denied. Your enrollment has expired.', 403);
      }
    }
    
    // Get all sections for the course
    const sections = await Section.find({ courseId })
      .sort({ order: 1 });
    
    // Get all lessons for each section
    const sectionsWithLessons = await Promise.all(
      sections.map(async (section) => {
        const lessons = await Lesson.find({ sectionId: section._id })
          .sort({ order: 1 });
        
        const lessonsWithUrls = lessons.map(lesson => formatLessonUrls(lesson, s3Service));
        
        return {
          ...section.toObject(),
          lessons: transformUrls(lessonsWithUrls, ['thumbnail', 'videoUrl', 'url', 'notesPdfUrl'])
        };
      })
    );
    
    // Filter out empty sections for students (but not for admins/instructors)
    const filteredSections = isStudent 
      ? sectionsWithLessons.filter(section => section.lessons && section.lessons.length > 0)
      : sectionsWithLessons;
    
    sendSuccess(res, transformUrls({
      course,
      sections: filteredSections
    }), 'Course content retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve course content', 500, error.message);
  }
};

module.exports = {
  getLessonsBySection,
  getLessonById,
  createLesson,
  updateLesson,
  deleteLesson,
  reorderLessons,
  getCourseContent
};