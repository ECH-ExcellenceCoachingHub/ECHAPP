const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User ID is required']
  },
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: [true, 'Course ID is required']
  },
  amount: {
    type: Number,
    required: [true, 'Amount is required'],
    min: [0, 'Amount cannot be negative']
  },
  currency: {
    type: String,
    default: 'RWF' // Rwanda Francs
  },
  paymentMethod: {
    type: String,
    required: [true, 'Payment method is required'],
    enum: ['mtn_momo', 'airtel_money', 'free']
  },
  transactionId: {
    type: String,
    required: [true, 'Transaction ID is required'],
    unique: true
  },
  status: {
    type: String,
    enum: ['pending', 'admin_review', 'approved', 'completed', 'failed', 'cancelled'],
    default: 'pending'
  },
  adminApproval: {
    approvedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    approvedAt: {
      type: Date
    },
    adminNotes: {
      type: String
    }
  },
  // 'course' = student enrollment; 'teacher_guide' = teacher access to a course's guide
  purpose: {
    type: String,
    enum: ['course', 'teacher_guide'],
    default: 'course'
  },
  contactInfo: {
    type: String,
    required: [true, 'Contact information is required for payment']
  },
  paymentDate: {
    type: Date
  }
}, {
  timestamps: true
});

// Index for better performance
paymentSchema.index({ userId: 1 });
paymentSchema.index({ courseId: 1 });
// transactionId already has unique index from schema definition
paymentSchema.index({ status: 1 });

module.exports = mongoose.model('Payment', paymentSchema);