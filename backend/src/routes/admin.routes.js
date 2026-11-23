const express = require('express');
const router = express.Router();
const { 
  getStudents,
  getAdmins,
  getTeachers,
  createTeacher,
  updateTeacher,
  deleteTeacher,
  assignTeacherToCourse,
  unassignTeacherFromCourse,
  getTeacherAssignments,
  getCourseTeachers,
  getTeacherActivity,
  updateUserRole,
  getStudentDetail,
  deleteStudent,
  getCourseStats,
  getPaymentStats,
  getExamStats,
  getStudentAnalytics,
  getCourseAnalytics,
  getStudentCoursePerformance,
  createAdmin,
  syncFirebaseUser,
  deleteUserSync,
  manualSyncAllUsers,
  getUserDeviceInfo,
  resetUserDevice,
  toggleStudentStatus,
  unenrollStudent,
  resetStudentPassword,
  updateStudent,
  updateEnrollmentPermissions
} = require('../controllers/admin.controller');
const { manualExpirationCheck } = require('../controllers/admin-expiration.controller');
const notificationController = require('../controllers/notification.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');
const User = require('../models/User');
const admins = require('../controllers/admin/admins.controller');
const { deleteStudent: deleteUserAccount } = require('../controllers/admin.controller');

const adminOnly = [protect, authorize('admin')];
// Changing an admin account (or making someone admin) needs full 'admins' access.
const userWrite = [...adminOnly, admins.guardAdminTarget];

// First-run setup only: once any admin exists, creating one needs a signed-in
// admin with full access to admins (otherwise anyone could make themselves admin).
const firstAdminOrAdmin = async (req, res, next) => {
  try {
    if (!(await User.exists({ role: 'admin' }))) return next();
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Could not check admins' });
  }
  return protect(req, res, () => authorize('admin')(req, res, next));
};
router.post('/create-admin', firstAdminOrAdmin, createAdmin);

// User synchronization routes (can be called by Firebase functions)
router.post('/sync-firebase-user', syncFirebaseUser);
router.delete('/sync-firebase-user/:firebaseUid', deleteUserSync);
router.post('/manual-sync-users', protect, authorize('admin'), manualSyncAllUsers);

// Protected admin routes
router.get('/students', protect, authorize('admin'), getStudents);
router.get('/admins', protect, authorize('admin'), getAdmins);
router.put('/users/:id/role', ...userWrite, updateUserRole);
router.get('/students/:id/detail', protect, authorize('admin'), getStudentDetail);
router.delete('/students/:id', ...userWrite, deleteStudent);

// Super admins managing other super admins (details, password, limits, status)
router.get('/my-access', ...adminOnly, admins.getMyAccess);
router.get('/admins/:id', ...adminOnly, admins.getAdmin);
router.put('/admins/:id', ...adminOnly, admins.updateAdminDetails);
router.put('/admins/:id/password', ...adminOnly, admins.setAdminPassword);
router.put('/admins/:id/limits', ...adminOnly, admins.setAdminLimits);
router.put('/admins/:id/status', ...adminOnly, admins.setAdminStatus);
router.delete('/admins/:id', ...adminOnly, admins.deleteAdmin(deleteUserAccount));
router.get('/course-stats', protect, authorize('admin'), getCourseStats);
router.get('/payment-stats', protect, authorize('admin'), getPaymentStats);
router.get('/exam-stats', protect, authorize('admin'), getExamStats);
router.get('/analytics/overview', protect, authorize('admin'), require('../controllers/analyticsOverview.controller').getAnalyticsOverview);
router.get('/analytics/students', protect, authorize('admin'), getStudentAnalytics);
router.get('/analytics/course/:courseId', protect, authorize('admin'), getCourseAnalytics);
router.get('/courses/:courseId/students/:studentId/performance', protect, authorize('admin'), getStudentCoursePerformance);

// Notifications
router.get('/notifications', protect, authorize('admin'), (req, res) => notificationController.getAdminNotifications(req, res));

// Push delivery report — which pushes reached devices and which did not.
// Push sends swallow their own errors by design, so this is the only place a
// failed delivery is visible.
const adminPushReportController = require('../controllers/admin/push-report.controller');
router.get('/push-report', protect, authorize('admin'), (req, res) => adminPushReportController.report(req, res));

// Device management routes
router.get('/students/:id/device-info', protect, authorize('admin'), getUserDeviceInfo);
router.put('/students/:id/device-reset', ...userWrite, resetUserDevice);
router.put('/students/:id/toggle-status', ...userWrite, toggleStudentStatus);
router.put('/students/:id/reset-password', ...userWrite, resetStudentPassword);
router.put('/students/:id', ...userWrite, updateStudent);
router.delete('/courses/:courseId/enrollments/:studentId', protect, authorize('admin'), unenrollStudent);
router.put('/enrollments/:id/permissions', protect, authorize('admin'), updateEnrollmentPermissions);

// Manual expiration check
router.post('/trigger-expiration-check', protect, authorize('admin'), manualExpirationCheck);

// Teacher management routes
router.get('/teachers', protect, authorize('admin'), getTeachers);
router.post('/teachers', protect, authorize('admin'), createTeacher);
router.put('/teachers/:id', protect, authorize('admin'), updateTeacher);
router.delete('/teachers/:id', protect, authorize('admin'), deleteTeacher);
router.post('/teachers/assign', protect, authorize('admin'), assignTeacherToCourse);
router.post('/teachers/unassign', protect, authorize('admin'), unassignTeacherFromCourse);
router.get('/teachers/:teacherId/assignments', protect, authorize('admin'), getTeacherAssignments);
router.get('/teachers/:teacherId/activity', protect, authorize('admin'), getTeacherActivity);
router.get('/courses/:courseId/teachers', protect, authorize('admin'), getCourseTeachers);

// ── Recordings library ──────────────────────────────────────────
// Admins are the only role that can take a course recording off the platform,
// so they get one place listing every recording rather than hunting course by
// course. `kind` is 'live' (teacher class) or 'study' (peer session).
const adminRecordingsController = require('../controllers/admin/recordings.controller');
router.get('/recordings', protect, authorize('admin'), adminRecordingsController.list);
router.post('/recordings/:kind/:sessionId/refresh', protect, authorize('admin'), adminRecordingsController.refresh);
router.patch('/recordings/:kind/:sessionId/published', protect, authorize('admin'), adminRecordingsController.setPublished);

module.exports = router;