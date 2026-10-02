const express = require('express');
const router = express.Router();
const Question = require('../models/Question');
const { 
  createQuiz,
  addQuestion,
  getQuiz,
  updateQuiz,
  updateQuestion,
  deleteQuestion,
  submitQuiz,
  getStudentQuizAttempts,
  getAllMyQuizAttempts,
  getQuizTemplates,
  duplicateQuiz
} = require('../controllers/quiz.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Public routes
router.get('/templates', protect, getQuizTemplates);

// Student routes
// Must stay above '/:examId', otherwise "my-attempts" is captured as an examId
router.get('/my-attempts', protect, getAllMyQuizAttempts);
router.post('/:examId/submit', protect, submitQuiz);
router.get('/:examId', protect, getQuiz);
router.get('/:examId/my-attempts', protect, getStudentQuizAttempts);

// Admin routes
router.post('/', protect, authorize('admin'), createQuiz);
router.put('/:examId', protect, authorize('admin'), updateQuiz);
router.post('/:examId/questions', protect, authorize('admin'), addQuestion);
router.put('/questions/:questionId', protect, authorize('admin'), updateQuestion);
router.delete('/questions/:questionId', protect, authorize('admin'), deleteQuestion);
router.post('/:examId/duplicate', protect, authorize('admin'), duplicateQuiz);

module.exports = router;
