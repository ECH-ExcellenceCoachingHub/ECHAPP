const mongoose = require('mongoose');

/**
 * A class (stream) of a school for one academic year, e.g. "S3 A" or "S5 MPC B".
 * Students belong to exactly one current classroom; teachers are linked to it
 * as class teacher and/or through ClassSubject (subject teachers).
 */
const classroomSchema = new mongoose.Schema({
  schoolId: { type: mongoose.Schema.Types.ObjectId, ref: 'School', required: true, index: true },
  academicYear: { type: String, required: true, trim: true, maxlength: 20 },
  level: { type: String, required: true, trim: true, uppercase: true, maxlength: 20 }, // S3, P5, L4…
  combination: { type: String, trim: true, uppercase: true, maxlength: 20, default: '' }, // MPC, PCB… (A-level / TVET trade)
  stream: { type: String, trim: true, uppercase: true, maxlength: 10, default: '' }, // A, B, C…
  name: { type: String, trim: true, maxlength: 60 },
  classTeacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null, index: true },
  room: { type: String, trim: true, maxlength: 60 },
  capacity: { type: Number, min: 0 },
  isActive: { type: Boolean, default: true },
}, { timestamps: true });

classroomSchema.index(
  { schoolId: 1, academicYear: 1, level: 1, combination: 1, stream: 1 },
  { unique: true }
);

classroomSchema.statics.buildName = function ({ level, combination, stream }) {
  return [level, combination, stream].map((p) => (p || '').trim().toUpperCase()).filter(Boolean).join(' ');
};

classroomSchema.pre('validate', function () {
  this.name = this.constructor.buildName(this);
});

module.exports = mongoose.model('Classroom', classroomSchema);
