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
    // School-term payments are for a school, not a course.
    required: [function () { return this.purpose !== 'school_term'; }, 'Course ID is required']
  },
  // purpose 'school_term': the school, the term and how many student seats are bought.
  schoolId: { type: mongoose.Schema.Types.ObjectId, ref: 'School' },
  termId: { type: mongoose.Schema.Types.ObjectId, ref: 'SchoolTerm' },
  seats: { type: Number, min: 0 },
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
    enum: ['mtn_momo', 'airtel_money', 'card', 'free']
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
  // 'course' = student enrollment; 'teacher_guide' = teacher access to a course's guide;
  // 'school_term' = a school paying for student seats in a term
  purpose: {
    type: String,
    enum: ['course', 'teacher_guide', 'school_term'],
    default: 'course'
  },
  contactInfo: {
    type: String,
    required: [true, 'Contact information is required for payment']
  },
  paymentDate: {
    type: Date
  },
  // Set when the payment goes through iTechPay (automatic). Manual payments
  // (admin approval) leave it empty. gateway.reference is the req_ref we
  // generated: the only id we trust when iTechPay or the app reports back.
  gateway: {
    provider: { type: String, enum: ['itecpay'] },
    reference: { type: String },
    gatewayId: String,
    paymentUrl: String,
    phone: String,
    lastStatus: String,
    lastCheckedAt: Date,
    checks: { type: Number, default: 0 },
    gatewayTransactionId: String,
    amountReported: Number,
    // Why a payment ended without being fulfilled ('timeout', 'declined', ...) or why fulfilment failed.
    failureReason: String,
    confirmedBy: { type: String, enum: ['callback', 'poll', 'sweeper', 'admin'] },
  }
}, {
  timestamps: true
});

// Index for better performance
paymentSchema.index({ userId: 1 });
paymentSchema.index({ courseId: 1 });
// transactionId already has unique index from schema definition
paymentSchema.index({ status: 1 });
paymentSchema.index({ 'gateway.reference': 1 }, { unique: true, sparse: true });
paymentSchema.index({ 'gateway.provider': 1, status: 1, createdAt: -1 });

module.exports = mongoose.model('Payment', paymentSchema);