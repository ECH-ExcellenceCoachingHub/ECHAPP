const mongoose = require('mongoose');

/**
 * Discussion group a teacher creates for students of a class they teach
 * (whole class or chosen students). Teachers moderate; "announcements only"
 * lets only teachers post.
 */
const schoolGroupSchema = new mongoose.Schema({
  schoolId: { type: mongoose.Schema.Types.ObjectId, ref: 'School', required: true, index: true },
  classroomId: { type: mongoose.Schema.Types.ObjectId, ref: 'Classroom', required: true, index: true },
  subject: { type: String, trim: true, maxlength: 80 },
  name: { type: String, required: true, trim: true, maxlength: 80 },
  description: { type: String, trim: true, maxlength: 500 },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  // Teachers who moderate (creator + invited colleagues).
  teacherIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  // true → every active student of the class is a member (new students too).
  wholeClass: { type: Boolean, default: true },
  studentIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  announcementsOnly: { type: Boolean, default: false },
  // userId → last time they opened the group (unread counts).
  lastRead: { type: Map, of: Date, default: {} },
  lastMessageAt: { type: Date, default: null },
  isActive: { type: Boolean, default: true },
}, { timestamps: true });

schoolGroupSchema.index({ teacherIds: 1, isActive: 1 });
schoolGroupSchema.index({ studentIds: 1 });

module.exports = mongoose.model('SchoolGroup', schoolGroupSchema);
