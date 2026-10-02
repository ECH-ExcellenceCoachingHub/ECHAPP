const Enrollment = require('../models/Enrollment');
const Course = require('../models/Course');
const Section = require('../models/Section');
const Lesson = require('../models/Lesson');
const Payment = require('../models/Payment');
const User = require('../models/User');
const Certificate = require('../models/Certificate');
const mongoose = require('mongoose');
const emailService = require('../services/email.service');
const notificationController = require('./notification.controller');
const CertificatePDFService = require('../services/certificate_pdf_service');
const { sendSuccess, sendError, sendNotFound } = require('../utils/response.utils');
const { transformUrls } = require('../utils/url.utils');

// Helper function to check if enrollment access has expired
const isEnrollmentExpired = (enrollment) => {
  if (!enrollment.accessExpirationDate) {
    return false; // No expiration set, access is unlimited
  }
  
  const currentDate = new Date();
  return currentDate > enrollment.accessExpirationDate;
};

// Enroll in a course
const enrollInCourse = async (req, res) => {
  try {
    const { courseId } = req.body;
    const userId = req.user.id;

    // Check if course exists
    const course = await Course.findById(courseId);
    if (!course) {
      return sendNotFound(res, 'Course not found');
    }

    // Check if already enrolled
    const existingEnrollment = await Enrollment.findOne({ userId, courseId });
    if (existingEnrollment) {
      return sendError(res, 'Already enrolled in this course', 400);
    }

    // Check if course is free or payment exists for paid courses
    if (course.price > 0) {
      const payment = await Payment.findOne({ 
        userId, 
        courseId, 
        status: 'completed' 
      });
      
      if (!payment) {
        return sendError(res, 'Payment required for this course', 400);
      }
    }

    // Calculate access expiration date based on course duration
    let accessExpirationDate = null;
    if (course.accessDuration) {
      accessExpirationDate = new Date();
      const unit = course.accessDurationUnit || 'days';
      const value = course.accessDuration;
      
      switch (unit) {
        case 'hours':
          accessExpirationDate.setHours(accessExpirationDate.getHours() + value);
          break;
        case 'days':
          accessExpirationDate.setDate(accessExpirationDate.getDate() + value);
          break;
        case 'weeks':
          accessExpirationDate.setDate(accessExpirationDate.getDate() + (value * 7));
          break;
        case 'months':
          accessExpirationDate.setMonth(accessExpirationDate.getMonth() + value);
          break;
        case 'years':
          accessExpirationDate.setFullYear(accessExpirationDate.getFullYear() + value);
          break;
        default:
          accessExpirationDate.setDate(accessExpirationDate.getDate() + value);
      }
    } else if (course.accessDurationDays) {
      accessExpirationDate = new Date();
      accessExpirationDate.setDate(accessExpirationDate.getDate() + course.accessDurationDays);
    }

    // Create enrollment
    const enrollment = await Enrollment.create({
      userId,
      courseId,
      enrollmentDate: new Date(),
      completionStatus: 'enrolled',
      accessExpirationDate
    });

    // Update course enrollment count
    await Course.findByIdAndUpdate(courseId, { $inc: { enrollmentCount: 1 } });

    // Get user and course details for email notification
    const user = await User.findById(userId).select('fullName email');
    
    // Send enrollment confirmation email
    try {
      await emailService.sendEnrollmentConfirmation(user.email, user, course);
      console.log(`Enrollment confirmation email sent to user: ${user.email}`);
    } catch (emailError) {
      console.error('Error sending enrollment confirmation email:', emailError);
      // Don't fail the enrollment if email sending fails
    }

    // Send in-app and push notification (Professional way)
    try {
      const NotificationController = require('./notification.controller').NotificationController;
      await NotificationController.createCourseEnrollmentNotification(userId, course.title, courseId);
    } catch (notificationError) {
      console.error('Error creating enrollment notification:', notificationError);
    }

    sendSuccess(res, transformUrls(enrollment), 'Successfully enrolled in course', 201);
  } catch (error) {
    sendError(res, 'Failed to enroll in course', 500, error.message);
  }
};

// Get user's enrolled courses
const getMyCourses = async (req, res) => {
  try {
    const userId = req.user.id;
    
    const enrollments = await Enrollment.find({ userId })
      .populate({
        path: 'courseId',
        select: 'title description price duration level thumbnail isPublished',
        populate: {
          path: 'createdBy',
          select: 'fullName'
        }
      })
      .sort({ enrollmentDate: -1 })
      .lean();

    // Filter out expired enrollments, but keep completed courses even if access has expired
    const activeEnrollments = enrollments.filter(enrollment => {
      // If it's not expired, it's active
      if (!isEnrollmentExpired(enrollment)) return true;
      
      // If it IS expired, only keep it if it was completed
      return enrollment.completionStatus === 'completed';
    });

    sendSuccess(res, transformUrls(activeEnrollments), 'Enrolled courses retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve enrolled courses', 500, error.message);
  }
};

// Get course feedback
const getCourseFeedback = async (req, res) => {
  try {
    const { courseId } = req.params;
    const userId = req.user.id;

    const enrollment = await Enrollment.findOne({ userId, courseId });
    if (!enrollment) {
      return sendNotFound(res, 'Enrollment not found for this course');
    }

    const feedbackData = {
      rating: enrollment.rating,
      feedback: enrollment.feedback,
      hasSubmittedFeedback: enrollment.rating !== null && enrollment.rating !== undefined
    };

    sendSuccess(res, feedbackData, 'Course feedback retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve course feedback', 500, error.message);
  }
};

// Submit course feedback
const submitCourseFeedback = async (req, res) => {
  try {
    const { courseId } = req.params;
    const { rating, feedback } = req.body;
    const userId = req.user.id;

    if (!rating || rating < 1 || rating > 5) {
      return sendError(res, 'Invalid rating. Must be between 1 and 5', 400);
    }

    const enrollment = await Enrollment.findOne({ userId, courseId });
    if (!enrollment) {
      return sendNotFound(res, 'Enrollment not found for this course');
    }

    enrollment.rating = rating;
    enrollment.feedback = feedback;
    await enrollment.save();

    // Update course average rating
    const mongoose = require('mongoose');
    const stats = await Enrollment.aggregate([
      { $match: { courseId: new mongoose.Types.ObjectId(courseId), rating: { $ne: null } } },
      { $group: { _id: '$courseId', averageRating: { $avg: '$rating' } } }
    ]);

    if (stats.length > 0) {
      await Course.findByIdAndUpdate(courseId, { averageRating: stats[0].averageRating });
    }

    sendSuccess(res, transformUrls(enrollment), 'Feedback submitted successfully');
  } catch (error) {
    sendError(res, 'Failed to submit feedback', 500, error.message);
  }
};

// Get enrollment progress
const getEnrollmentProgress = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const enrollment = await Enrollment.findOne({ 
      _id: id, 
      userId 
    }).populate('courseId', 'title');

    if (!enrollment) {
      return sendNotFound(res, 'Enrollment not found');
    }
    
    if (isEnrollmentExpired(enrollment)) {
      return sendError(res, 'Access to this course has expired', 403);
    }

    sendSuccess(res, transformUrls(enrollment), 'Enrollment progress retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve enrollment progress', 500, error.message);
  }
};

// Update enrollment progress
const updateEnrollmentProgress = async (req, res) => {
  try {
    const { id } = req.params;
    const { lessonId, completed } = req.body;
    const userId = req.user.id;

    const enrollment = await Enrollment.findOne({ 
      _id: id, 
      userId 
    });

    if (!enrollment) {
      return sendNotFound(res, 'Enrollment not found');
    }
    
    if (isEnrollmentExpired(enrollment)) {
      return sendError(res, 'Access to this course has expired', 403);
    }

    const alreadyCompleted = enrollment.completedLessons.some(id => id.toString() === lessonId);
    
    if (completed && !alreadyCompleted) {
      enrollment.completedLessons.push(lessonId);
      
      // Calculate real progress percentage
      const totalLessons = await Lesson.countDocuments({ courseId: enrollment.courseId });
      enrollment.progress = totalLessons > 0 
        ? Math.round((enrollment.completedLessons.length / totalLessons) * 100) 
        : 0;
      
      if (enrollment.progress === 100) {
        enrollment.completionStatus = 'completed';
        enrollment.certificateEligible = true;

        // Send Achievement Notification
        try {
          const NotificationController = require('./notification.controller').NotificationController;
          await NotificationController.createAchievementNotification(
            userId, 
            `Completed Course: ${enrollment.courseId.title}`
          );
        } catch (notificationError) {
          console.error('Error sending achievement notification:', notificationError);
        }
      } else if (enrollment.progress > 0) {
        enrollment.completionStatus = 'in-progress';
      }
    }

    await enrollment.save();

    // Update last active status for user
    await User.findByIdAndUpdate(userId, { lastActive: new Date() });
    
    sendSuccess(res, transformUrls(enrollment), 'Enrollment progress updated successfully');
  } catch (error) {
    sendError(res, 'Failed to update enrollment progress', 500, error.message);
  }
};

// Mark section as completed (marks all lessons in section as complete)
const completeSection = async (req, res) => {
  try {
    const { id } = req.params; // enrollment id
    const { sectionId } = req.body;
    const userId = req.user.id;

    const enrollment = await Enrollment.findOne({ _id: id, userId });
    if (!enrollment) {
      return sendNotFound(res, 'Enrollment not found');
    }
    
    if (isEnrollmentExpired(enrollment)) {
      return sendError(res, 'Access to this course has expired', 403);
    }

    // Find all lessons in this section
    const sectionLessons = await Lesson.find({ sectionId: new mongoose.Types.ObjectId(sectionId) });
    if (!sectionLessons || sectionLessons.length === 0) {
      return sendNotFound(res, 'No lessons found in this section');
    }
    
    const sectionLessonIds = sectionLessons.map(l => l._id.toString());
    
    // Check if user has completed at least one lesson in this section
    const completedInThisSection = sectionLessonIds.filter(lessonId => 
      enrollment.completedLessons.some(id => id.toString() === lessonId)
    );
    
    if (completedInThisSection.length === 0) {
      return sendError(res, 'Please complete at least one lesson in this section before marking it as complete', 400);
    }
    
    // Mark all lessons in this section as complete
    let addedCount = 0;
    sectionLessonIds.forEach(lessonId => {
      const alreadyCompleted = enrollment.completedLessons.some(id => id.toString() === lessonId);
      if (!alreadyCompleted) {
        enrollment.completedLessons.push(lessonId);
        addedCount++;
      }
    });

    // Record the section itself so the next chapter stays unlocked across sessions
    if (!enrollment.completedSections.some(id => id.toString() === sectionId)) {
      enrollment.completedSections.push(sectionId);
    }

    // Calculate real progress percentage based on actual completed lessons
    const totalLessons = await Lesson.countDocuments({ courseId: new mongoose.Types.ObjectId(enrollment.courseId) });
    enrollment.progress = totalLessons > 0 
      ? Math.round((enrollment.completedLessons.length / totalLessons) * 100) 
      : 0;
    
    if (enrollment.progress === 100) {
      enrollment.completionStatus = 'completed';
      enrollment.certificateEligible = true;
    } else {
      enrollment.completionStatus = 'in-progress';
    }
    
    await enrollment.save();
    
    sendSuccess(res, transformUrls(enrollment), 'Section marked as completed');
  } catch (error) {
    sendError(res, 'Failed to complete section', 500, error.message);
  }
};

// Get user's certificates
const getCertificates = async (req, res) => {
  try {
    const userId = req.user.id;
    
    const certificates = await Certificate.find({ 
      userId,
      isValid: true 
    })
      .populate({
        path: 'courseId',
        select: 'title description duration level thumbnail createdBy'
      })
      .populate({
        path: 'examId',
        select: 'title type'
      })
      .sort({ issuedDate: -1 });

    sendSuccess(res, certificates, 'Certificates retrieved successfully');
  } catch (error) {
    sendError(res, 'Failed to retrieve certificates', 500, error.message);
  }
};

// Check if user is eligible for certificate for a specific course
const checkCertificateEligibility = async (req, res) => {
  try {
    const { courseId } = req.params;
    const userId = req.user.id;
    
    const enrollment = await Enrollment.findOne({ 
      userId, 
      courseId 
    });
    
    if (!enrollment) {
      return sendNotFound(res, 'Enrollment not found');
    }
    
    const isEligible = enrollment.certificateEligible && enrollment.completionStatus === 'completed';
    
    sendSuccess(res, { 
      eligible: isEligible,
      completionStatus: enrollment.completionStatus,
      progress: enrollment.progress,
      certificateEligible: enrollment.certificateEligible
    }, 'Certificate eligibility checked successfully');
  } catch (error) {
    sendError(res, 'Failed to check certificate eligibility', 500, error.message);
  }
};

// Download certificate for a course (placeholder)
const downloadCertificate = async (req, res) => {
  try {
    const { courseId } = req.params;
    const userId = req.user.id;
    
    const enrollment = await Enrollment.findOne({ 
      userId, 
      courseId,
      certificateEligible: true
    }).populate('courseId', 'title');
    
    if (!enrollment) {
      return sendNotFound(res, 'Certificate not found or not eligible');
    }
    
    // In a real implementation, this would generate and return a PDF certificate
    // For now, we'll return a placeholder download URL
    const downloadUrl = `${req.protocol}://${req.get('host')}/api/enrollments/${courseId}/certificate/download/file`;
    
    sendSuccess(res, { 
      downloadUrl,
      courseTitle: enrollment.courseId.title,
      completionDate: enrollment.updatedAt,
      studentName: req.user.fullName || req.user.email
    }, 'Certificate download URL generated');
  } catch (error) {
    sendError(res, 'Failed to generate certificate download', 500, error.message);
  }
};

// Check if user has access to a course (handles expiration)
const checkCourseAccess = async (req, res) => {
  try {
    const { courseId } = req.params;
    const userId = req.user.id;
    
    // Find enrollment
    const enrollment = await Enrollment.findOne({ 
      userId, 
      courseId 
    }).populate('courseId', 'title accessDurationDays');
    
    if (!enrollment) {
      return sendNotFound(res, 'Enrollment not found');
    }
    
    // Check if access has expired
    const isExpired = isEnrollmentExpired(enrollment);

    // Sections explicitly completed, plus any whose lessons are all done
    // (covers enrollments that completed chapters before completedSections existed)
    const completedSectionIds = new Set(
      (enrollment.completedSections || []).map(id => id.toString())
    );
    const completedLessonIds = new Set(
      (enrollment.completedLessons || []).map(id => id.toString())
    );
    const courseLessons = await Lesson.find(
      { courseId: enrollment.courseId._id },
      'sectionId'
    ).lean();
    const lessonsBySection = new Map();
    for (const lesson of courseLessons) {
      if (!lesson.sectionId) continue;
      const key = lesson.sectionId.toString();
      if (!lessonsBySection.has(key)) lessonsBySection.set(key, []);
      lessonsBySection.get(key).push(lesson._id.toString());
    }
    for (const [sectionId, lessonIds] of lessonsBySection) {
      if (lessonIds.every(id => completedLessonIds.has(id))) {
        completedSectionIds.add(sectionId);
      }
    }

    const responseData = {
      hasAccess: !isExpired,
      enrollmentId: enrollment._id,
      courseId: enrollment.courseId,
      enrollmentDate: enrollment.enrollmentDate,
      accessExpirationDate: enrollment.accessExpirationDate,
      courseTitle: enrollment.courseId.title,
      accessDurationDays: enrollment.courseId.accessDurationDays,
      completedLessons: enrollment.completedLessons,
      completedSections: [...completedSectionIds],
      progress: enrollment.progress,
      completionStatus: enrollment.completionStatus,
      rating: enrollment.rating,
      feedback: enrollment.feedback,
    };
    
    if (isExpired) {
      responseData.expiredAt = enrollment.accessExpirationDate;
      responseData.message = 'Access to this course has expired';
    }
    
    const statusCode = isExpired ? 403 : 200;
    const message = isExpired ? 'Access expired' : 'Access granted';
    
    res.status(statusCode).send({
      success: !isExpired,
      data: responseData,
      message: message
    });
    
  } catch (error) {
    sendError(res, 'Failed to check course access', 500, error.message);
  }
}

// Download certificate file
const downloadCertificateFile = async (req, res) => {
  try {
    const { certificateId } = req.params;
    const userId = req.user.id;
    
    // Find the certificate
    const certificate = await Certificate.findOne({ 
      _id: certificateId,
      userId,
      isValid: true
    }).populate('courseId', 'title description');
    
    if (!certificate) {
      return sendNotFound(res, 'Certificate not found or not authorized');
    }
    
    // Check if the file exists
    const fs = require('fs');
    const path = require('path');
    const Result = require('../models/Result');
    const CertificatePDFService = require('../services/certificate_pdf_service');
    
    if (!fs.existsSync(certificate.certificatePdfPath)) {
      console.log(`Certificate file missing locally: ${certificate.certificatePdfPath}. Attempting to re-generate...`);
      
      try {
        // Find the result to get totalPoints
        const result = await Result.findOne({ userId, examId: certificate.examId });
        
        if (!result) {
          console.error(`Original exam result not found for certificate ${certificateId}, user ${userId}`);
          return sendNotFound(res, 'Certificate file not found and cannot be re-generated (result missing)');
        }
        
        const user = await User.findById(userId).select('fullName email');
        if (!user) {
          return sendNotFound(res, 'User not found, cannot re-generate certificate');
        }
        
        // Re-generate PDF certificate
        const newPdfPath = await CertificatePDFService.generateCertificatePDF({
          studentName: user.fullName,
          userFullName: user.fullName,
          courseTitle: certificate.courseId.title,
          courseDescription: certificate.courseId.description,
          score: certificate.score,
          totalPoints: result.totalPoints,
          percentage: certificate.percentage,
          issuedDate: certificate.issuedDate,
          serialNumber: certificate.serialNumber,
          userId,
          examId: certificate.examId
        });
        
        // Update certificate record with the new path
        certificate.certificatePdfPath = newPdfPath;
        await certificate.save();
        
        console.log(`Certificate re-generated and updated: ${newPdfPath}`);
      } catch (genError) {
        console.error('Error re-generating certificate:', genError);
        return sendError(res, 'Certificate file not found and re-generation failed', 500, genError.message);
      }
    }
    
    // Set headers for PDF download
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="certificate_${certificate.courseId.title.replace(/[^a-zA-Z0-9]/g, '_')}.pdf"`);
    
    // Stream the file
    const fileStream = fs.createReadStream(certificate.certificatePdfPath);
    fileStream.pipe(res);
    
  } catch (error) {
    console.error('Error downloading certificate file:', error);
    sendError(res, 'Failed to download certificate', 500, error.message);
  }
};

// Verify certificate by serial number (Public endpoint)
const verifyCertificate = async (req, res) => {
  try {
    const { serialNumber } = req.params;
    
    if (!serialNumber) {
      return sendError(res, 'Serial number is required', 400);
    }
    
    // Find the certificate and populate relevant data
    const certificate = await Certificate.findOne({ 
      serialNumber,
      isValid: true
    })
    .populate({
      path: 'userId',
      select: 'fullName email profileImage'
    })
    .populate({
      path: 'courseId',
      select: 'title description thumbnail duration level'
    });
    
    if (!certificate) {
      return sendNotFound(res, 'Certificate not found or invalid');
    }
    
    // Structure the verification data
    const verificationData = {
      serialNumber: certificate.serialNumber,
      studentName: certificate.userId ? certificate.userId.fullName : 'Valued Student',
      studentProfileImage: certificate.userId ? certificate.userId.profileImage : null,
      courseTitle: certificate.courseId ? certificate.courseId.title : 'Course',
      courseDescription: certificate.courseId ? certificate.courseId.description : '',
      courseThumbnail: certificate.courseId ? certificate.courseId.thumbnail : null,
      issuedDate: certificate.issuedDate,
      percentage: certificate.percentage,
      isValid: certificate.isValid,
      verificationStatus: 'VERIFIED',
      institution: 'Excellence Coaching Hub'
    };
    
    sendSuccess(res, verificationData, 'Certificate verified successfully');
  } catch (error) {
    console.error('Error verifying certificate:', error);
    sendError(res, 'Failed to verify certificate', 500, error.message);
  }
};

// Note: getCertificates function is already declared above at line 361

// Manual certificate generation for passed final exams
const generateCertificateManually = async (req, res) => {
  try {
    const { courseId, examId } = req.body;
    const userId = req.user.id;
    
    console.log('Manual certificate generation request:', { userId, courseId, examId });
    
    // Verify user passed the exam
    const Submission = require('../../models/Submission');
    const submission = await Submission.findOne({ 
      userId, 
      examId,
      passed: true 
    }).sort({ submittedAt: -1 });
    
    if (!submission) {
      return sendError(res, 'No passed exam found for this user', 400);
    }
    
    // Check if certificate already exists
    const existingCertificate = await Certificate.findOne({
      userId,
      courseId
    });
    
    if (existingCertificate) {
      return sendError(res, 'Certificate already exists for this course', 400);
    }
    
    // Get course and user details
    const course = await Course.findById(courseId);
    const user = await User.findById(userId).select('fullName email');
    
    if (!course || !user) {
      return sendError(res, 'Course or user not found', 404);
    }
    
    // Generate serial number first
    const serialNumber = `CERT-${Date.now()}-${Math.random().toString(36).substr(2, 9).toUpperCase()}`;
    
    // Generate PDF certificate first
    const pdfPath = await CertificatePDFService.generateCertificatePDF({
      studentName: user.fullName,
      userFullName: user.fullName,
      courseTitle: course.title,
      completionDate: new Date(),
      score: submission.percentage,
      percentage: submission.percentage,
      serialNumber: serialNumber,
      issuedDate: new Date()
    });
    
    // Generate certificate with PDF path included
    const certificateData = {
      userId,
      courseId,
      examId,
      score: submission.percentage,
      percentage: submission.percentage,
      issuedDate: new Date(),
      isValid: true,
      serialNumber: serialNumber,
      certificatePdfPath: pdfPath
    };
    
    const certificate = await Certificate.create(certificateData);
    
    console.log(`Certificate generated manually: ${certificate._id}`);
    
    sendSuccess(res, certificate, 'Certificate generated successfully');
  } catch (error) {
    console.error('MANUAL CERTIFICATE GENERATION ERROR:', error);
    sendError(res, 'Failed to generate certificate', 500, error.message);
  }
};

module.exports = {
  enrollInCourse,
  getMyCourses,
  getCourseFeedback,
  submitCourseFeedback,
  getEnrollmentProgress,
  updateEnrollmentProgress,
  completeSection,
  getCertificates,
  checkCertificateEligibility,
  downloadCertificate,
  checkCourseAccess,
  downloadCertificateFile,
  verifyCertificate,
  generateCertificateManually
};