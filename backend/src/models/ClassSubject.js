const mongoose = require('mongoose');

/**
 * "Teacher X teaches subject Y to class Z" — the link that decides what a
 * teacher sees (students, coverage, homework, results).
 * courseId optionally links the ECH course used as the syllabus for coverage.
 */
const classSubjectSchema = new mongoose.Schema({
  schoolId: { type: mongoose.Schema.Types.ObjectId, ref: 'School', required: true, index: true },
  classroomId: { type: mongoose.Schema.Types.ObjectId, ref: 'Classroom', required: true, index: true },
  subject: { type: String, required: true, trim: true, maxlength: 80 },
  teacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null, index: true },
  courseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', default: null },
  periodsPerWeek: { type: Number, min: 0, max: 40 },
  isActive: { type: Boolean, default: true },
}, { timestamps: true });

classSubjectSchema.index({ classroomId: 1, subject: 1 }, { unique: true });

module.exports = mongoose.model('ClassSubject', classSubjectSchema);
