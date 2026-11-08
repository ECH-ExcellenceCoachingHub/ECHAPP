const express = require('express');
const router = express.Router();
const { 
  enrollInCourse,
  unenrollFromCourse,
  getEnrollmentStatus,
  updateEnrollmentStatus,
  getEnrollmentHistory,
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
} = require('../controllers/enrollment.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Public routes
router.get('/verify/:serialNumber', verifyCertificate);

// Protected routes
router.post('/', protect, enrollInCourse);
router.get('/my-courses', protect, getMyCourses);
router.get('/course/:courseId/status', protect, getEnrollmentStatus);
router.post('/course/:courseId/unenroll', protect, unenrollFromCourse);

// Admin: enrollment history and suspension
router.get('/history', protect, authorize('admin'), getEnrollmentHistory);
router.put('/:id/status', protect, authorize('admin'), updateEnrollmentStatus);
router.post('/course/:courseId/feedback', protect, submitCourseFeedback);
router.get('/course/:courseId/feedback', protect, getCourseFeedback);
router.get('/:id/progress', protect, getEnrollmentProgress);
router.put('/:id/progress', protect, updateEnrollmentProgress);
router.put('/:id/complete-section', protect, completeSection);

// Certificate routes
router.get('/certificates', protect, getCertificates);
router.get('/:courseId/certificate-eligibility', protect, checkCertificateEligibility);
router.get('/:courseId/certificate/download', protect, downloadCertificate);
router.post('/generate-certificate', protect, generateCertificateManually);

// New route for downloading certificate files
router.get('/certificates/:certificateId/download-file', protect, downloadCertificateFile);

// Course access check route
router.get('/:courseId/access-check', protect, checkCourseAccess);

module.exports = router;