const mongoose = require('mongoose');

const groupMessageSchema = new mongoose.Schema({
  groupId: { type: mongoose.Schema.Types.ObjectId, ref: 'SchoolGroup', required: true },
  authorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  text: { type: String, trim: true, maxlength: 4000 },
  attachments: [{ _id: false, url: String, name: String, type: { type: String } }],
  replyTo: { type: mongoose.Schema.Types.ObjectId, ref: 'GroupMessage', default: null },
  pinned: { type: Boolean, default: false },
  deletedAt: { type: Date, default: null },
  deletedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
}, { timestamps: true });

groupMessageSchema.index({ groupId: 1, createdAt: -1 });

module.exports = mongoose.model('GroupMessage', groupMessageSchema);
