const express = require('express');
const router = express.Router();
const { 
  getCourses, 
  getCourseById, 
  createCourse, 
  updateCourse, 
  deleteCourse,
  getRecommendedCourses,
  suggestCourses
} = require('../controllers/course.controller');
const { protect, optionalProtect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Public routes
router.get('/', optionalProtect, getCourses);
router.get('/recommendations', optionalProtect, getRecommendedCourses);
router.get('/suggest', optionalProtect, suggestCourses); // search-as-you-type (before /:id)
router.get('/:id', optionalProtect, getCourseById); // Make basic course info public

// Admin routes
router.post('/', protect, authorize('admin'), createCourse);
router.put('/:id', protect, authorize('admin'), updateCourse);
router.delete('/:id', protect, authorize('admin'), deleteCourse);

module.exports = router;