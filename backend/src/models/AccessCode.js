const mongoose = require('mongoose');

/**
 * Short-lived sign-in code a teacher shows in class (or the school admin in
 * the lab). Students of the class (or of the school, when classroomId is null)
 * need it to sign in while the school is in "School only (code)" mode.
 */
const accessCodeSchema = new mongoose.Schema({
  schoolId: { type: mongoose.Schema.Types.ObjectId, ref: 'School', required: true, index: true },
  classroomId: { type: mongoose.Schema.Types.ObjectId, ref: 'Classroom', default: null },
  code: { type: String, required: true },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  expiresAt: { type: Date, required: true },
}, { timestamps: true });

accessCodeSchema.index({ code: 1 }, { unique: true });
accessCodeSchema.index({ schoolId: 1, classroomId: 1, expiresAt: -1 });
// Expired codes are removed a day later (keeps sign-in history readable meanwhile).
accessCodeSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 24 * 3600 });

module.exports = mongoose.model('AccessCode', accessCodeSchema);
