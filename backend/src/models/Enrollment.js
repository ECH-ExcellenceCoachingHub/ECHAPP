const mongoose = require('mongoose');

// Enrollment lifecycle:
//   active     - learner is currently enrolled
//   unenrolled - learner voluntarily left (progress and history are preserved)
//   suspended  - access temporarily disabled by an administrator
const ENROLLMENT_STATUSES = ['active', 'unenrolled', 'suspended'];
const INACTIVE_STATUSES = ['unenrolled', 'suspended'];

// Matches active enrollments, including legacy records that predate the
// `status` field (a missing status means active).
const ACTIVE_FILTER = { status: { $nin: INACTIVE_STATUSES } };

// Pass as `status` in a query filter to opt out of the active-only scope and
// see every enrollment, e.g. { userId, courseId, status: Enrollment.ANY_STATUS }.
const ANY_STATUS = { $in: [null, ...ENROLLMENT_STATUSES] };

const statusHistorySchema = new mongoose.Schema({
  status: {
    type: String,
    enum: ENROLLMENT_STATUSES,
    required: true
  },
  changedAt: {
    type: Date,
    default: Date.now
  },
  changedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  reason: {
    type: String,
    maxlength: 500,
    default: null
  }
}, { _id: false });

const enrollmentSchema = new mongoose.Schema({
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
  enrollmentDate: {
    type: Date,
    default: Date.now
  },
  completionStatus: {
    type: String,
    enum: ['enrolled', 'in-progress', 'completed'],
    default: 'enrolled'
  },
  progress: {
    type: Number,
    default: 0,
    min: [0, 'Progress cannot be negative'],
    max: [100, 'Progress cannot exceed 100']
  },
  completedLessons: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Lesson'
  }],
  completedSections: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Section'
  }],
  certificateEligible: {
    type: Boolean,
    default: false
  },
  paymentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Payment'
  },
  accessExpirationDate: {
    type: Date,
    default: null // Will be calculated when enrollment is created based on course accessDurationDays
  },
  rating: {
    type: Number,
    min: [1, 'Rating must be at least 1'],
    max: [5, 'Rating cannot exceed 5'],
    default: null
  },
  feedback: {
    type: String,
    maxlength: [1000, 'Feedback cannot exceed 1000 characters'],
    default: null
  },
  canAccessLiveSessions: {
    type: Boolean,
    default: true
  },
  canAccessChapters: {
    type: Boolean,
    default: true
  },
  status: {
    type: String,
    enum: ENROLLMENT_STATUSES,
    default: 'active'
  },
  unenrolledAt: {
    type: Date,
    default: null
  },
  suspendedAt: {
    type: Date,
    default: null
  },
  // Audit trail so administrators can see when a learner enrolled, left,
  // re-enrolled or was suspended.
  statusHistory: {
    type: [statusHistorySchema],
    default: []
  }
}, {
  timestamps: true
});

// Ensure user can only enroll once per course
enrollmentSchema.index({ userId: 1, courseId: 1 }, { unique: true });
enrollmentSchema.index({ userId: 1 });
enrollmentSchema.index({ courseId: 1 });
enrollmentSchema.index({ status: 1 });

// Record the initial enrollment in the history.
enrollmentSchema.pre('save', function () {
  if (this.isNew && this.statusHistory.length === 0) {
    this.statusHistory.push({
      status: this.status || 'active',
      changedAt: this.enrollmentDate || new Date()
    });
  }
});

// Unless a query explicitly filters on `status`, only active enrollments are
// returned. This keeps every existing "is the user enrolled?" check correct:
// unenrolled and suspended learners are treated as not enrolled, while their
// records stay in the database.
function scopeToActive() {
  const filter = this.getFilter();
  if (Object.prototype.hasOwnProperty.call(filter, 'status')) return;
  this.where(ACTIVE_FILTER);
}

['find', 'findOne', 'countDocuments'].forEach(op => {
  enrollmentSchema.pre(op, scopeToActive);
});

enrollmentSchema.pre('aggregate', function () {
  const pipeline = this.pipeline();
  const first = pipeline[0];
  if (first && first.$match && Object.prototype.hasOwnProperty.call(first.$match, 'status')) return;
  pipeline.unshift({ $match: ACTIVE_FILTER });
});

enrollmentSchema.methods.isActive = function () {
  return !INACTIVE_STATUSES.includes(this.status);
};

// Change status and append to the audit trail. Caller is responsible for save().
enrollmentSchema.methods.setStatus = function (status, { changedBy = null, reason = null } = {}) {
  const now = new Date();
  this.status = status;
  if (status === 'unenrolled') this.unenrolledAt = now;
  if (status === 'suspended') this.suspendedAt = now;
  if (status === 'active') this.suspendedAt = null;
  this.statusHistory.push({ status, changedAt: now, changedBy, reason });
};

enrollmentSchema.statics.STATUSES = ENROLLMENT_STATUSES;
enrollmentSchema.statics.ANY_STATUS = ANY_STATUS;
enrollmentSchema.statics.ACTIVE_FILTER = ACTIVE_FILTER;

module.exports = mongoose.model('Enrollment', enrollmentSchema);