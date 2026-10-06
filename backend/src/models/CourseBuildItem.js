const mongoose = require('mongoose');

/**
 * A single reviewable unit of an AI course draft: a lesson, a chapter test,
 * chapter revision notes, or the mock exam. Teachers edit / regenerate /
 * approve these before they are published into the live course.
 */

const draftQuestionSchema = new mongoose.Schema({
  // mcq | true_false | short_answer | calculation | scenario
  type: { type: String, default: 'mcq' },
  question: { type: String, required: true, trim: true },
  options: [String],
  correctIndex: { type: Number, default: null },
  answer: { type: String, default: '' },
  explanation: { type: String, default: '' },
  difficulty: { type: String, enum: ['easy', 'medium', 'hard'], default: 'medium' },
  source: {
    chapter: String,
    section: String,
    page: Number,
    quote: String,
  },
  verified: { type: Boolean, default: false },
  confidence: { type: Number, default: 0 },
}, { _id: true });

const courseBuildItemSchema = new mongoose.Schema({
  jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'CourseBuildJob', required: true },
  courseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', required: true },
  kind: { type: String, enum: ['lesson', 'chapter_test', 'revision', 'mock_exam'], required: true },
  chapterIndex: { type: Number, default: null }, // null for the mock exam
  order: { type: Number, default: 0 },
  title: { type: String, trim: true },
  pageStart: Number,
  pageEnd: Number,

  status: {
    type: String,
    enum: ['pending', 'generating', 'draft', 'needs_review', 'approved', 'rejected', 'error', 'published'],
    default: 'pending',
  },

  // Structured lesson content (summary, notes, keyTerms, visuals, …) — same
  // shape that ends up in Lesson.aiContent.
  content: { type: mongoose.Schema.Types.Mixed, default: null },
  questions: [draftQuestionSchema],

  confidence: { type: Number, default: null },
  warnings: [String],
  error: { type: String, default: null },
  attempts: { type: Number, default: 0 },
  generationMs: { type: Number, default: null },

  // Set once the teacher edits the item after publishing, so we know to re-sync.
  dirtyAfterPublish: { type: Boolean, default: false },
  published: {
    sectionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Section', default: null },
    lessonId: { type: mongoose.Schema.Types.ObjectId, ref: 'Lesson', default: null },
    quizId: { type: mongoose.Schema.Types.ObjectId, ref: 'Quiz', default: null },
    at: Date,
  },
  reviewedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  reviewedAt: Date,
}, { timestamps: true });

courseBuildItemSchema.index({ jobId: 1, chapterIndex: 1, order: 1 });
courseBuildItemSchema.index({ jobId: 1, status: 1 });

module.exports = mongoose.model('CourseBuildItem', courseBuildItemSchema);
