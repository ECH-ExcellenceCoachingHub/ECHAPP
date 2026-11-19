const express = require('express');
const router = express.Router();
const {
  createSchool,
  getSchools,
  getSchool,
  getMySchool,
  updateSchoolPlan,
  updateSchoolDetails,
  changeSchoolAdmin,
  deleteSchool,
  addTeacher,
  getTeachers,
  addStudent,
  getStudents,
  getSchoolMembers,
} = require('../controllers/school.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// ── Super admin: platform-wide school management ────────────────────────
router.post('/schools', protect, authorize('admin'), createSchool);
router.get('/schools', protect, authorize('admin'), getSchools);
router.get('/schools/me', protect, authorize('admin', 'school_admin', 'instructor'), getMySchool);
router.get('/schools/:id', protect, authorize('admin', 'school_admin', 'instructor'), getSchool);
router.patch('/schools/:id/plan', protect, authorize('admin'), updateSchoolPlan);
router.patch('/schools/:id/details', protect, authorize('admin'), updateSchoolDetails);
router.patch('/schools/:id/admin', protect, authorize('admin'), changeSchoolAdmin);
router.delete('/schools/:id', protect, authorize('admin'), deleteSchool);

// ── School admin / teacher: manage members of their own school ─────────
router.post('/schools/:id/teachers', protect, authorize('admin', 'school_admin'), addTeacher);
router.get('/schools/:id/teachers', protect, authorize('admin', 'school_admin', 'instructor'), getTeachers);
router.post('/schools/:id/students', protect, authorize('admin', 'school_admin', 'instructor'), addStudent);
router.get('/schools/:id/students', protect, authorize('admin', 'school_admin', 'instructor'), getStudents);
router.get('/schools/:id/members', protect, authorize('admin', 'school_admin', 'instructor'), getSchoolMembers);

module.exports = router;
