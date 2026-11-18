const express = require('express');
const router = express.Router();
const { 
  getSectionsByCourse,
  createSection,
  updateSection,
  deleteSection,
  reorderSections
} = require('../controllers/section.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');
const { denySelfRegisteredTeacher } = require('../services/teacherAccess.service');

// Get sections for a course (public)
router.get('/course/:courseId', getSectionsByCourse);

// Admin and Instructor routes
router.post('/course/:courseId', protect, authorize('admin', 'instructor'), denySelfRegisteredTeacher, createSection);
router.put('/:sectionId', protect, authorize('admin', 'instructor'), denySelfRegisteredTeacher, updateSection);
router.delete('/:sectionId', protect, authorize('admin'), deleteSection);
router.post('/course/:courseId/reorder', protect, authorize('admin', 'instructor'), denySelfRegisteredTeacher, reorderSections);

module.exports = router;