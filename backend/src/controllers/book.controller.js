const Book = require('../models/Book');
const s3Service = require('../services/s3.service');
const { sendSuccess, sendError } = require('../utils/response.utils');
const pdfParse = require('pdf-parse');

// Create a new book
const createBook = async (req, res) => {
  try {
    const { title, author, description, language, subject, academicCategory, pdfUrl, pdfS3Key, coverUrl, coverS3Key, fileSize, pages, relatedCourses, textContent, isPublished } = req.body;

    // Validate required fields
    if (!title || !author || !pdfUrl || !pdfS3Key) {
      return sendError(res, 'Missing required fields: title, author, pdfUrl, pdfS3Key', 400);
    }

    const book = await Book.create({
      title,
      author,
      description,
      pdfUrl,
      pdfS3Key,
      coverUrl,
      coverS3Key,
      language: language || 'en',
      subject: subject || 'Other',
      academicCategory,
      relatedCourses: relatedCourses || [],
      uploadedBy: req.user.id,
      fileSize,
      pages,
      textContent,
      isPublished: isPublished === undefined ? true : !!isPublished
    });

    sendSuccess(res, book, 'Book created successfully');
  } catch (error) {
    console.error('Create book error:', error);
    sendError(res, 'Failed to create book', 500, error.message);
  }
};

// Get all books (for library)
const getAllBooks = async (req, res) => {
  try {
    const { subject, language, search, page = 1, limit = 20 } = req.query;

    const query = { isPublished: true };

    if (subject && subject !== 'All') {
      query.subject = subject;
    }

    if (language && language !== 'All') {
      query.language = language;
    }

    if (search) {
      query.$text = { $search: search };
    }

    const skip = (page - 1) * limit;

    const books = await Book.find(query)
      .populate('uploadedBy', 'fullName email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Book.countDocuments(query);

    sendSuccess(res, {
      books,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    }, 'Books retrieved successfully');
  } catch (error) {
    console.error('Get all books error:', error);
    sendError(res, 'Failed to retrieve books', 500, error.message);
  }
};

// Escape user text for use inside a RegExp
const escapeRegex = (str) => String(str).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const ADMIN_SORTS = {
  newest: { createdAt: -1 },
  oldest: { createdAt: 1 },
  updated: { updatedAt: -1 },
  title: { title: 1 },
  author: { author: 1 },
  downloads: { downloadCount: -1 },
};

const safeDeleteS3 = async (key) => {
  if (!key) return;
  try {
    await s3Service.deleteFile(key);
  } catch (e) {
    console.error('Failed to delete S3 object', key, e.message);
  }
};

// Get all books for admin (including unpublished), with search, filters,
// sorting, pagination and summary stats.
const getAllBooksForAdmin = async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 20));
    const { search, subject, language, status, courseId, academicCategory, sort } = req.query;

    const query = {};
    if (search && search.trim()) {
      const rx = new RegExp(escapeRegex(search.trim()), 'i');
      query.$or = [{ title: rx }, { author: rx }, { subject: rx }, { description: rx }, { academicCategory: rx }];
    }
    if (subject && subject !== 'All') query.subject = subject;
    if (language && language !== 'All') query.language = language;
    if (academicCategory && academicCategory !== 'All') query.academicCategory = academicCategory;
    if (status === 'published') query.isPublished = true;
    if (status === 'draft') query.isPublished = false;
    if (status === 'nocover') query.$and = [{ $or: [{ coverUrl: null }, { coverUrl: '' }] }];
    if (courseId === 'none') {
      query.relatedCourses = { $size: 0 };
    } else if (courseId && courseId !== 'All') {
      query.relatedCourses = courseId;
    }

    const skip = (page - 1) * limit;

    const [books, total, statsAgg, subjects, categories] = await Promise.all([
      Book.find(query)
        .select('-textContent')
        .populate('uploadedBy', 'fullName email')
        .populate('relatedCourses', 'title thumbnail level')
        .sort(ADMIN_SORTS[sort] || ADMIN_SORTS.newest)
        .skip(skip)
        .limit(limit)
        .lean(),
      Book.countDocuments(query),
      Book.aggregate([
        {
          $group: {
            _id: null,
            total: { $sum: 1 },
            published: { $sum: { $cond: ['$isPublished', 1, 0] } },
            downloads: { $sum: { $ifNull: ['$downloadCount', 0] } },
            totalSize: { $sum: { $ifNull: ['$fileSize', 0] } },
            withoutCover: { $sum: { $cond: [{ $gt: [{ $strLenCP: { $ifNull: ['$coverUrl', ''] } }, 0] }, 0, 1] } },
          },
        },
      ]),
      Book.distinct('subject'),
      Book.distinct('academicCategory'),
    ]);

    const st = statsAgg[0] || { total: 0, published: 0, downloads: 0, totalSize: 0, withoutCover: 0 };

    sendSuccess(res, {
      books,
      pagination: {
        page,
        limit,
        total,
        pages: Math.max(1, Math.ceil(total / limit)),
      },
      stats: {
        total: st.total,
        published: st.published,
        drafts: st.total - st.published,
        downloads: st.downloads,
        totalSize: st.totalSize,
        withoutCover: st.withoutCover,
      },
      subjects: subjects.filter(Boolean).sort((a, b) => a.localeCompare(b)),
      academicCategories: categories.filter(Boolean).sort((a, b) => a.localeCompare(b)),
    }, 'Books retrieved successfully');
  } catch (error) {
    console.error('Get all books for admin error:', error);
    sendError(res, 'Failed to retrieve books', 500, error.message);
  }
};

// Get one book for admin (full record, does not count as a download)
const getBookForAdmin = async (req, res) => {
  try {
    const book = await Book.findById(req.params.id)
      .populate('uploadedBy', 'fullName email')
      .populate('relatedCourses', 'title thumbnail level');
    if (!book) return sendError(res, 'Book not found', 404);
    sendSuccess(res, book, 'Book retrieved successfully');
  } catch (error) {
    console.error('Get book for admin error:', error);
    sendError(res, 'Failed to retrieve book', 500, error.message);
  }
};

// Bulk publish / unpublish / delete
const bulkBookAction = async (req, res) => {
  try {
    const { ids, action } = req.body || {};
    if (!Array.isArray(ids) || ids.length === 0) {
      return sendError(res, 'No books selected', 400);
    }
    if (ids.length > 200) {
      return sendError(res, 'Too many books selected (max 200)', 400);
    }

    if (action === 'publish' || action === 'unpublish') {
      const result = await Book.updateMany(
        { _id: { $in: ids } },
        { $set: { isPublished: action === 'publish' } }
      );
      return sendSuccess(res, { modified: result.modifiedCount }, `Books ${action === 'publish' ? 'published' : 'unpublished'}`);
    }

    if (action === 'delete') {
      const books = await Book.find({ _id: { $in: ids } }).select('pdfS3Key coverS3Key');
      for (const b of books) {
        await safeDeleteS3(b.pdfS3Key);
        await safeDeleteS3(b.coverS3Key);
      }
      const result = await Book.deleteMany({ _id: { $in: ids } });
      return sendSuccess(res, { deleted: result.deletedCount }, 'Books deleted');
    }

    sendError(res, 'Unknown action', 400);
  } catch (error) {
    console.error('Bulk book action error:', error);
    sendError(res, 'Failed to apply bulk action', 500, error.message);
  }
};

// Get a single book by ID
const getBookById = async (req, res) => {
  try {
    const book = await Book.findById(req.params.id).populate('uploadedBy', 'fullName email');

    if (!book) {
      return sendError(res, 'Book not found', 404);
    }

    // Increment download count
    book.downloadCount += 1;
    await book.save();

    sendSuccess(res, book, 'Book retrieved successfully');
  } catch (error) {
    console.error('Get book by ID error:', error);
    sendError(res, 'Failed to retrieve book', 500, error.message);
  }
};

// Update a book: every editable field, including replacing the PDF / cover,
// removing the cover and changing related courses.
const updateBook = async (req, res) => {
  try {
    const {
      title, author, description, language, subject, academicCategory,
      coverUrl, coverS3Key, isPublished, pages, relatedCourses,
      pdfUrl, pdfS3Key, fileSize, textContent,
    } = req.body;

    const book = await Book.findById(req.params.id);

    if (!book) {
      return sendError(res, 'Book not found', 404);
    }

    if (title !== undefined) {
      if (!String(title).trim()) return sendError(res, 'Title cannot be empty', 400);
      book.title = title;
    }
    if (author !== undefined) {
      if (!String(author).trim()) return sendError(res, 'Author cannot be empty', 400);
      book.author = author;
    }
    if (subject !== undefined) {
      if (!String(subject).trim()) return sendError(res, 'Subject cannot be empty', 400);
      book.subject = subject;
    }
    if (description !== undefined) book.description = description;
    if (language) book.language = language;
    if (academicCategory !== undefined) book.academicCategory = academicCategory || undefined;
    if (isPublished !== undefined) book.isPublished = !!isPublished;
    if (pages !== undefined) {
      const n = pages === null || pages === '' ? null : parseInt(pages, 10);
      book.pages = Number.isFinite(n) && n > 0 ? n : null;
    }
    if (Array.isArray(relatedCourses)) {
      book.relatedCourses = [...new Set(relatedCourses.map(String))];
    }

    // Cover replaced or removed: clean up the old file
    const oldCoverKey = book.coverS3Key;
    if (coverUrl !== undefined) {
      book.coverUrl = coverUrl || null;
      book.coverS3Key = coverUrl ? (coverS3Key || null) : null;
      if (oldCoverKey && oldCoverKey !== book.coverS3Key) await safeDeleteS3(oldCoverKey);
    }

    // PDF replaced: swap file metadata and clean up the old file
    if (pdfUrl && pdfS3Key && pdfS3Key !== book.pdfS3Key) {
      const oldPdfKey = book.pdfS3Key;
      book.pdfUrl = pdfUrl;
      book.pdfS3Key = pdfS3Key;
      if (fileSize !== undefined) book.fileSize = fileSize || 0;
      if (textContent !== undefined) book.textContent = textContent || null;
      await safeDeleteS3(oldPdfKey);
    }

    await book.save();
    await book.populate('relatedCourses', 'title thumbnail level');

    const out = book.toObject();
    delete out.textContent;
    sendSuccess(res, out, 'Book updated successfully');
  } catch (error) {
    console.error('Update book error:', error);
    sendError(res, 'Failed to update book', 500, error.message);
  }
};

// Delete a book
const deleteBook = async (req, res) => {
  try {
    const book = await Book.findById(req.params.id);

    if (!book) {
      return sendError(res, 'Book not found', 404);
    }

    // Delete PDF from S3
    if (book.pdfS3Key) {
      try {
        await s3Service.deleteFile(book.pdfS3Key);
      } catch (s3Error) {
        console.error('Failed to delete PDF from S3:', s3Error);
      }
    }

    // Delete cover from S3 if exists
    if (book.coverS3Key) {
      try {
        await s3Service.deleteFile(book.coverS3Key);
      } catch (s3Error) {
        console.error('Failed to delete cover from S3:', s3Error);
      }
    }

    await Book.findByIdAndDelete(req.params.id);

    sendSuccess(res, null, 'Book deleted successfully');
  } catch (error) {
    console.error('Delete book error:', error);
    sendError(res, 'Failed to delete book', 500, error.message);
  }
};

// Get books by course ID
const getBooksByCourse = async (req, res) => {
  try {
    const { courseId } = req.params;
    const { page = 1, limit = 20 } = req.query;

    const skip = (page - 1) * limit;

    const query = {
      isPublished: true,
      relatedCourses: courseId
    };

    const books = await Book.find(query)
      .populate('uploadedBy', 'fullName email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Book.countDocuments(query);

    sendSuccess(res, {
      books,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    }, 'Books retrieved successfully');
  } catch (error) {
    console.error('Get books by course error:', error);
    sendError(res, 'Failed to retrieve books', 500, error.message);
  }
};

// Upload book PDF and cover
const uploadBookFiles = async (req, res) => {
  try {
    const multer = require('multer');
    const storage = multer.memoryStorage();
    const upload = multer({
      storage,
      limits: {
        fileSize: 50 * 1024 * 1024 // 50MB limit for PDF
      }
    });

    upload.fields([
      { name: 'pdf', maxCount: 1 },
      { name: 'cover', maxCount: 1 }
    ])(req, res, async function (err) {
      if (err) {
        console.error('Multer error:', err);
        return sendError(res, err.message, 400);
      }

      const pdfFile = req.files['pdf'] ? req.files['pdf'][0] : null;
      const coverFile = req.files['cover'] ? req.files['cover'][0] : null;

      if (!pdfFile && !coverFile) {
        return sendError(res, 'A PDF or a cover image is required', 400);
      }

      try {
        // Extract text from PDF
        let extractedText = null;
        let pageCount = null;
        let pdfResult = null;
        if (pdfFile) {
          try {
            const pdfData = await pdfParse(pdfFile.buffer);
            extractedText = pdfData.text;
            pageCount = pdfData.numpages || null;
          } catch (pdfError) {
            console.error('PDF text extraction failed:', pdfError);
            // Continue without text extraction
          }

          pdfResult = await s3Service.uploadDocument(
            pdfFile.buffer,
            pdfFile.originalname,
            'application/pdf'
          );
        }

        let coverResult = null;
        if (coverFile) {
          coverResult = await s3Service.uploadImage(
            coverFile.buffer,
            coverFile.originalname,
            coverFile.mimetype
          );
        }

        sendSuccess(res, {
          pdfUrl: pdfResult ? pdfResult.url : null,
          pdfS3Key: pdfResult ? pdfResult.key : null,
          coverUrl: coverResult ? coverResult.url : null,
          coverS3Key: coverResult ? coverResult.key : null,
          fileSize: pdfFile ? pdfFile.size : null,
          pages: pageCount,
          textContent: extractedText
        }, 'Book files uploaded successfully');
      } catch (s3Error) {
        console.error('S3 upload error:', s3Error);
        sendError(res, 'Failed to upload files to storage', 500, s3Error.message);
      }
    });
  } catch (error) {
    console.error('Upload book files error:', error);
    sendError(res, 'Failed to upload book files', 500, error.message);
  }
};

module.exports = {
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
};
