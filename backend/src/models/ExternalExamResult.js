const mongoose = require('mongoose');

/**
 * Exam results that happened on a partner platform (currently eexams.net),
 * pushed to ECH through signed webhook events so they show up in the
 * student's ECH progress. One document per external result; a re-grade on
 * eexams updates the same document.
 */
const externalExamResultSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  source: { type: String, enum: ['eexams'], default: 'eexams' },
  externalResultId: { type: String, required: true },
  externalExamId: { type: String },
  examTitle: { type: String, default: 'Exam' },
  level: { type: String, default: null },
  score: { type: Number, default: 0 },
  maxScore: { type: Number, default: 0 },
  percentage: { type: Number, default: 0 },
  passingScore: { type: Number, default: null },
  passed: { type: Boolean, default: null },
  startedAt: { type: Date },
  completedAt: { type: Date },
  reviewPath: { type: String, default: null }, // path on eexams, opened through SSO
}, { timestamps: true });

externalExamResultSchema.index({ source: 1, externalResultId: 1 }, { unique: true });
externalExamResultSchema.index({ user: 1, completedAt: -1 });

module.exports = mongoose.model('ExternalExamResult', externalExamResultSchema);
