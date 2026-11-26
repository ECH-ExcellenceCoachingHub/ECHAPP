const mongoose = require('mongoose');

/**
 * Work a teacher gives to a class: homework lives fully in ECH (students
 * submit text / photos / files); quizzes and exams can point to an eexams exam.
 */
const assessmentSchema = new mongoose.Schema({
  schoolId: { type: mongoose.Schema.Types.ObjectId, ref: 'School', required: true, index: true },
  classroomId: { type: mongoose.Schema.Types.ObjectId, ref: 'Classroom', required: true, index: true },
  classSubjectId: { type: mongoose.Schema.Types.ObjectId, ref: 'ClassSubject', required: true, index: true },
  subject: { type: String, trim: true, maxlength: 80 },
  teacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  termId: { type: mongoose.Schema.Types.ObjectId, ref: 'SchoolTerm', default: null },

  type: { type: String, enum: ['homework', 'quiz', 'exam'], default: 'homework' },
  title: { type: String, required: true, trim: true, maxlength: 200 },
  instructions: { type: String, trim: true, maxlength: 5000 },
  attachments: [{ _id: false, url: String, name: String, type: { type: String } }],
  // What the student hands in.
  submissionMode: { type: String, enum: ['photo', 'file', 'text', 'none', 'eexams'], default: 'photo' },
  maxScore: { type: Number, min: 0, default: 10 },
  dueAt: { type: Date, required: true },
  allowLate: { type: Boolean, default: true },

  // Optional link to the lesson coverage it follows (e.g. "read chapter 3").
  coverageId: { type: mongoose.Schema.Types.ObjectId, ref: 'LessonCoverage', default: null },

  // Exams / quizzes on eexams.net
  eexamsExamId: { type: String, default: null },
  eexamsPath: { type: String, default: null },

  // Who it is for: empty = the whole class; otherwise only these students
  // (e.g. an eexams exam the teacher sent to chosen students).
  studentIds: { type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }], default: [] },

  status: { type: String, enum: ['published', 'closed'], default: 'published', index: true },
}, { timestamps: true });

assessmentSchema.index({ classroomId: 1, dueAt: -1 });

/** Mongo filter: assessments a given student can see (whole-class ones and the ones aimed at them). */
assessmentSchema.statics.visibleTo = function (studentId) {
  return { $or: [{ studentIds: { $exists: false } }, { studentIds: { $size: 0 } }, { studentIds: studentId }] };
};

assessmentSchema.methods.isFor = function (studentId) {
  return !this.studentIds?.length || this.studentIds.some((id) => String(id) === String(studentId));
};

module.exports = mongoose.model('Assessment', assessmentSchema);
