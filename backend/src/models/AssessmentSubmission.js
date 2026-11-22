const mongoose = require('mongoose');

const submissionSchema = new mongoose.Schema({
  assessmentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Assessment', required: true, index: true },
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  schoolId: { type: mongoose.Schema.Types.ObjectId, ref: 'School', required: true },
  classroomId: { type: mongoose.Schema.Types.ObjectId, ref: 'Classroom', required: true },
  text: { type: String, trim: true, maxlength: 10000 },
  attachments: [{ _id: false, url: String, name: String, type: { type: String } }],
  submittedAt: { type: Date, default: Date.now },
  isLate: { type: Boolean, default: false },
  status: { type: String, enum: ['submitted', 'graded'], default: 'submitted' },
  score: { type: Number, min: 0, default: null },
  feedback: { type: String, trim: true, maxlength: 2000 },
  gradedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  gradedAt: Date,
}, { timestamps: true });

submissionSchema.index({ assessmentId: 1, studentId: 1 }, { unique: true });

module.exports = mongoose.model('AssessmentSubmission', submissionSchema);
