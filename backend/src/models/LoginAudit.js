const mongoose = require('mongoose');

/** Sign-in history of school members (helps spot shared student accounts). */
const loginAuditSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
  schoolId: { type: mongoose.Schema.Types.ObjectId, ref: 'School', index: true },
  identifier: { type: String, trim: true, maxlength: 120 },
  method: { type: String, enum: ['code_pin', 'phone_pin', 'class_code', 'firebase', 'password'], default: 'code_pin' },
  // Class/school code used to sign in (School only mode).
  accessCodeId: { type: mongoose.Schema.Types.ObjectId, ref: 'AccessCode', default: null, index: true },
  viaSchoolNetwork: { type: Boolean, default: false },
  success: { type: Boolean, default: true },
  reason: { type: String, maxlength: 120 },
  ip: String,
  userAgent: { type: String, maxlength: 300 },
  deviceId: { type: String, maxlength: 200 },
  suspicious: { type: Boolean, default: false, index: true },
  suspiciousReason: { type: String, maxlength: 200 },
  at: { type: Date, default: Date.now, index: true },
}, { timestamps: false });

loginAuditSchema.index({ userId: 1, at: -1 });
// Keep one year of history.
loginAuditSchema.index({ at: 1 }, { expireAfterSeconds: 365 * 24 * 3600 });

module.exports = mongoose.model('LoginAudit', loginAuditSchema);
