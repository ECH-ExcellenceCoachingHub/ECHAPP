const express = require('express');
const router = express.Router();
const {
  createBook,
  getAllBooks,
  getAllBooksForAdmin,
  getBookForAdmin,
  bulkBookAction,
  getBookById,
  getBooksByCourse,
  updateBook,
  deleteBook,
  uploadBookFiles
} = require('../controllers/book.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');

// Admin routes (declared before /:id so they are not swallowed by it)
router.get('/admin/all', protect, authorize('admin'), getAllBooksForAdmin);
router.get('/admin/:id', protect, authorize('admin'), getBookForAdmin);
router.post('/admin/bulk', protect, authorize('admin'), bulkBookAction);

// Public route to get all published books (for library)
router.get('/', getAllBooks);

// Public route to get books by course ID (must come before /:id)
router.get('/course/:courseId', protect, getBooksByCourse);

// Public route to get a single book by ID
router.get('/:id', getBookById);

// Admin routes
router.post('/upload-files', protect, authorize('admin'), uploadBookFiles);
router.post('/', protect, authorize('admin'), createBook);
router.put('/:id', protect, authorize('admin'), updateBook);
router.delete('/:id', protect, authorize('admin'), deleteBook);

module.exports = router;
