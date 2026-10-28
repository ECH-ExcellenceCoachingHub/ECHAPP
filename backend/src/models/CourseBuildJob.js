const mongoose = require('mongoose');

/**
 * One AI course-build run: a book uploaded by an admin/teacher that is turned
 * into a reviewable course draft. Nothing here is visible to students — drafts
 * live in CourseBuildItem until a reviewer publishes them into real
 * Sections / Lessons / Quizzes.
 */

const outlineLessonSchema = new mongoose.Schema({
  title: { type: String, trim: true },
  pageStart: Number,
  pageEnd: Number,
}, { _id: false });

const outlineChapterSchema = new mongoose.Schema({
  index: Number,
  title: { type: String, trim: true },
  summary: String,
  pageStart: Number,
  pageEnd: Number,
  selected: { type: Boolean, default: true },
  lessons: [outlineLessonSchema],
  publishedSectionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Section', default: null },
}, { _id: false });

const courseBuildJobSchema = new mongoose.Schema({
  courseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', required: true },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },

  status: {
    type: String,
    enum: ['uploaded', 'extracting', 'analyzing', 'outline_ready', 'generating', 'ready', 'failed', 'cancelled'],
    default: 'uploaded',
  },

  source: {
    fileName: String,
    mimeType: String,
    size: Number,
    s3Key: String,
    s3Url: String,
    pageCount: { type: Number, default: 0 },
    charCount: { type: Number, default: 0 },
    pageUnit: { type: String, enum: ['page', 'segment'], default: 'page' },
    isScanned: { type: Boolean, default: false },
    ocrUsed: { type: Boolean, default: false },
    hasBookmarks: { type: Boolean, default: false },
  },

  options: {
    // full | selected | lessons_only | quizzes_only | exam_prep | revision | mock_exam
    mode: { type: String, default: 'full' },
    questionsPerLesson: { type: Number, default: 5, min: 0, max: 30 },
    chapterTestQuestions: { type: Number, default: 15, min: 0, max: 60 },
    mockExamQuestions: { type: Number, default: 0, min: 0, max: 200 },
    difficultyMix: {
      easy: { type: Number, default: 30 },
      medium: { type: Number, default: 50 },
      hard: { type: Number, default: 20 },
    },
    questionTypes: { type: [String], default: ['mcq', 'true_false', 'short_answer', 'calculation', 'scenario'] },
    examStyle: { type: String, default: '' }, // e.g. "CPA", "ACCA", "University final"
    includeVisuals: { type: Boolean, default: true },
    includeFlashcards: { type: Boolean, default: true },
    autoGenerate: { type: Boolean, default: false },
    instructions: { type: String, default: '' },
    language: { type: String, default: 'English' },
    // Automatic lesson videos (explainer + experiment demos for science).
    generateVideos: { type: Boolean, default: true },
    videoLanguage: { type: String, default: '' },
    // Per-course spending limit override (USD). 0 = use server default.
    videoBudgetUsd: { type: Number, default: 0, min: 0 },
  },

  // Textbook figure extraction (PDF only), shared by every build of the same book.
  figureExtraction: {
    status: { type: String, enum: ['not_applicable', 'queued', 'running', 'completed', 'failed', 'skipped'], default: 'not_applicable' },
    bookHash: { type: String, default: null },
    extractionId: { type: mongoose.Schema.Types.ObjectId, ref: 'FigureExtraction', default: null },
    summary: { type: mongoose.Schema.Types.Mixed, default: null },
    error: { type: String, default: null },
  },

  outline: {
    bookTitle: String,
    subject: String,
    level: String,
    description: String,
    chapters: [outlineChapterSchema],
  },

  progress: {
    stage: { type: String, default: 'uploaded' },
    percent: { type: Number, default: 0 },
    message: { type: String, default: '' },
    done: { type: Number, default: 0 },
    total: { type: Number, default: 0 },
    etaSeconds: { type: Number, default: null },
    startedAt: Date,
    updatedAt: Date,
  },

  stats: {
    lessons: { type: Number, default: 0 },
    questions: { type: Number, default: 0 },
    visuals: { type: Number, default: 0 },
    unverifiedQuestions: { type: Number, default: 0 },
  },

  logs: [{
    at: { type: Date, default: Date.now },
    level: { type: String, default: 'info' },
    message: String,
    _id: false,
  }],

  mockSectionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Section', default: null },
  cancelRequested: { type: Boolean, default: false },
  error: { type: String, default: null },
}, { timestamps: true });

courseBuildJobSchema.index({ courseId: 1, createdAt: -1 });
courseBuildJobSchema.index({ status: 1 });

module.exports = mongoose.model('CourseBuildJob', courseBuildJobSchema);
