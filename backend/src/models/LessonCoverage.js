const mongoose = require('mongoose');

/**
 * A lesson/topic a teacher marked as taught to a class.
 * ECH checks each mark and raises flags when it looks like it was not taught
 * (no evidence, bulk marking, future/weekend date, students disagree…).
 */
const coverageSchema = new mongoose.Schema({
  schoolId: { type: mongoose.Schema.Types.ObjectId, ref: 'School', required: true, index: true },
  classroomId: { type: mongoose.Schema.Types.ObjectId, ref: 'Classroom', required: true, index: true },
  classSubjectId: { type: mongoose.Schema.Types.ObjectId, ref: 'ClassSubject', required: true, index: true },
  subject: { type: String, trim: true, maxlength: 80 },
  teacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  termId: { type: mongoose.Schema.Types.ObjectId, ref: 'SchoolTerm', default: null },

  // Either an ECH syllabus lesson (course → section/chapter → lesson) or a free topic.
  courseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', default: null },
  sectionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Section', default: null },
  lessonId: { type: mongoose.Schema.Types.ObjectId, ref: 'Lesson', default: null },
  chapterTitle: { type: String, trim: true, maxlength: 200 },
  topic: { type: String, required: true, trim: true, maxlength: 200 },

  taughtOn: { type: Date, required: true },
  notes: { type: String, trim: true, maxlength: 1000 },
  attachments: [{ _id: false, url: String, name: String, type: { type: String } }],

  flags: [{ _id: false, code: String, severity: { type: String, enum: ['low', 'medium', 'high'] }, message: String }],
  // ok → nothing suspicious; flagged → needs review; confirmed → admin agrees it was NOT taught;
  // dismissed → admin checked and it was taught.
  status: { type: String, enum: ['ok', 'flagged', 'confirmed', 'dismissed'], default: 'ok', index: true },
  review: {
    by: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    at: Date,
    note: { type: String, trim: true, maxlength: 500 },
  },
  // Students of the class answer "Was this lesson taught?"
  studentChecks: [{
    _id: false,
    studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    taught: Boolean,
    at: { type: Date, default: Date.now },
  }],
}, { timestamps: true });

coverageSchema.index({ classSubjectId: 1, lessonId: 1 });
coverageSchema.index({ teacherId: 1, createdAt: -1 });

module.exports = mongoose.model('LessonCoverage', coverageSchema);
