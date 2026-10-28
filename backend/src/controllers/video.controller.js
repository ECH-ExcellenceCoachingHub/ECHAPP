const s3Service = require('../services/s3.service');
const Lesson = require('../models/Lesson');
const Enrollment = require('../models/Enrollment');
const { sendSuccess, sendError, sendNotFound, sendForbidden } = require('../utils/response.utils');
const { transformUrls } = require('../utils/url.utils');

// Get signed URL for video playback
const getVideoStreamUrl = async (req, res) => {
  try {
    const { lessonId } = req.params;
    const userId = req.user.id;

    // Find the lesson
    const lesson = await Lesson.findById(lessonId);
    if (!lesson) {
      return sendNotFound(res, 'Lesson not found');
    }

    // ?variant=experiment → the generated experiment-demonstration video
    let videoKey = lesson.videoId;
    if (req.query.variant === 'experiment') {
      const { isVideoWatchable } = require('../models/schemas/aiVideo.schema');
      videoKey = isVideoWatchable(lesson.aiExperimentVideo) ? lesson.aiExperimentVideo.s3Key : null;
    }

    // Check if lesson has a video
    if (!videoKey) {
      return sendNotFound(res, 'No video available for this lesson');
    }

    // Check if user is enrolled in the course or is an admin
    if (req.user.role !== 'admin') {
      const enrollment = await Enrollment.findOne({ 
        userId, 
        courseId: lesson.courseId 
      });
      
      if (!enrollment) {
        return sendForbidden(res, 'You must be enrolled in this course to access the video');
      }
    }

    // Generate signed streaming URL from S3 with 24-hour expiration
    // This handles long downloads on slow connections (24h = 86400 seconds)
    const streamingUrl = await s3Service.generateStreamingUrl(videoKey, 86400);

    sendSuccess(res, transformUrls({
      streamingUrl,
      lessonId: lesson._id,
      courseId: lesson.courseId,
      expiration: new Date(Date.now() + 86400 * 1000) // 24 hours from now
    }), 'Video stream URL generated successfully');
  } catch (error) {
    sendError(res, 'Failed to generate video stream URL', 500, error.message);
  }
};

// Get video details from S3
const getVideoDetails = async (req, res) => {
  try {
    const { videoId } = req.params;
    
    // Get file metadata from S3
    const metadata = await s3Service.getFileMetadata(videoId);
    
    sendSuccess(res, {
      id: videoId,
      status: 'ready',
      size: metadata.size,
      contentType: metadata.contentType,
      lastModified: metadata.lastModified,
      url: s3Service.getPublicUrl(videoId)
    }, 'Video details retrieved successfully');
  } catch (error) {
    if (error.message.includes('NoSuchKey')) {
      return sendNotFound(res, 'Video not found');
    }
    sendError(res, 'Failed to get video details', 500, error.message);
  }
};

// Delete video from S3
const deleteVideo = async (req, res) => {
  try {
    const { videoId } = req.params;
    
    const result = await s3Service.deleteFile(videoId);
    
    sendSuccess(res, result, 'Video deleted successfully');
  } catch (error) {
    sendError(res, 'Failed to delete video', 500, error.message);
  }
};

// Get all videos (admin only)
const getAllVideos = async (req, res) => {
  try {
    const { courseId } = req.query;
    
    // Get all lessons that have videos
    const filter = courseId ? { courseId, videoId: { $exists: true, $ne: null } } : { videoId: { $exists: true, $ne: null } };
    
    const lessons = await Lesson.find(filter)
      .populate('courseId', 'title')
      .sort({ createdAt: -1 });
    
    const videos = lessons.map(lesson => ({
      id: lesson._id,
      title: lesson.title,
      description: lesson.description,
      courseId: lesson.courseId._id,
      courseTitle: lesson.courseId.title,
      videoId: lesson.videoId,
      duration: lesson.duration || 0,
      createdAt: lesson.createdAt,
      updatedAt: lesson.updatedAt
    }));
    
    sendSuccess(res, videos, 'Videos retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve videos', 500, error.message);
  }
};

// Get videos by course ID
const getVideosByCourse = async (req, res) => {
  try {
    const { courseId } = req.params;
    
    const lessons = await Lesson.find({ courseId, videoId: { $exists: true, $ne: null } })
      .sort({ createdAt: -1 });
    
    const videos = lessons.map(lesson => ({
      id: lesson._id,
      title: lesson.title,
      description: lesson.description,
      courseId: lesson.courseId,
      videoId: lesson.videoId,
      duration: lesson.duration || 0,
      createdAt: lesson.createdAt,
      updatedAt: lesson.updatedAt
    }));
    
    sendSuccess(res, videos, 'Course videos retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve course videos', 500, error.message);
  }
};

module.exports = {
  getVideoStreamUrl,
  getVideoDetails,
  deleteVideo,
  getAllVideos,
  getVideosByCourse
};