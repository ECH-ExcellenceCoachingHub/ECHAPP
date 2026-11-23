/**
 * Gives the customer what they paid for. One place for every paid service,
 * used both by admin approval (manual payments) and by iTechPay confirmation
 * (automatic payments):
 *
 *   course        → student enrollment (reactivates an unenrolled one)
 *   teacher_guide → TeacherAssignment (source 'guide_purchase')
 *   school_term   → SchoolTerm.billing: term marked paid, seats added
 *
 * Safe to call twice for the same payment: each branch upserts or checks first.
 * It does NOT change payment.status; the caller owns that.
 */
const Enrollment = require('../../models/Enrollment');
const Course = require('../../models/Course');
const User = require('../../models/User');

const METHOD_LABEL = { mtn_momo: 'MTN MoMo', airtel_money: 'Airtel Money', card: 'Card', free: 'Free' };

function notifier() {
  // Lazy: the controller requires models/services that require this file.
  return require('../../controllers/teacherAccess.controller').notify;
}

async function fulfillCourse(payment, { actorId }) {
  const userId = payment.userId?._id || payment.userId;
  const courseId = payment.courseId?._id || payment.courseId;
  const existing = await Enrollment.findOne({ userId, courseId, status: Enrollment.ANY_STATUS });

  if (!existing) {
    await Enrollment.create({ userId, courseId, completionStatus: 'in-progress', paymentId: payment._id });
  } else if (existing.status === 'unenrolled') {
    // Bought again after leaving: reactivate the same record so earlier progress comes back.
    existing.setStatus('active', { changedBy: actorId || null, reason: 'Re-enrolled after payment' });
    existing.unenrolledAt = null;
    existing.paymentId = payment._id;
    if (existing.accessExpirationDate && new Date() > existing.accessExpirationDate) existing.accessExpirationDate = null;
    await existing.save();
    await Course.findByIdAndUpdate(courseId, { $inc: { enrollmentCount: 1 } });
  } else if (!existing.paymentId) {
    existing.paymentId = payment._id;
    await existing.save();
  }

  try {
    const { NotificationController } = require('../../controllers/notification.controller');
    await NotificationController.createPaymentNotification(userId, payment.amount, courseId);
  } catch (e) {
    console.error('[payments] course notification failed:', e.message);
  }
}

async function fulfillTeacherGuide(payment, { actorId }) {
  const TeacherAssignment = require('../../models/TeacherAssignment');
  const userId = payment.userId?._id || payment.userId;
  const courseId = payment.courseId?._id || payment.courseId;
  await TeacherAssignment.findOneAndUpdate(
    { teacherId: userId, courseId },
    {
      $set: { isActive: true, paymentId: payment._id, assignedAt: new Date() },
      // An existing admin assignment keeps its source (and its student access).
      $setOnInsert: { assignedBy: actorId || userId, source: 'guide_purchase' },
    },
    { upsert: true, new: true }
  );
  const course = await Course.findById(courseId).select('title').lean();
  await notifier()([userId], 'Your course is unlocked',
    `Your payment for "${course?.title || 'the course'}" went through. Open your teacher dashboard to start teaching with the guide.`,
    { type: 'teacher_guide_approved', courseId: String(courseId) });
}

async function fulfillSchoolTerm(payment) {
  const SchoolTerm = require('../../models/SchoolTerm');
  const term = await SchoolTerm.findOne({ _id: payment.termId, schoolId: payment.schoolId });
  if (!term) throw new Error('The school term this payment was for no longer exists');

  // Idempotent: a term records each payment reference once.
  const ref = payment.gateway?.reference || String(payment._id);
  if ((term.billing.notes || '').includes(ref)) return;

  const seats = payment.seats || 0;
  const wasPaid = ['paid', 'waived'].includes(term.billing.status);
  term.billing.studentsPaid = (wasPaid ? term.billing.studentsPaid || 0 : 0) + seats;
  term.billing.amount = (wasPaid ? term.billing.amount || 0 : 0) + payment.amount;
  if (seats > 0) term.billing.pricePerStudent = Math.round(payment.amount / seats);
  if (term.billing.status !== 'waived') term.billing.status = 'paid';
  term.billing.paidAt = new Date();
  term.billing.method = `iTechPay · ${METHOD_LABEL[payment.paymentMethod] || payment.paymentMethod}`;
  term.billing.reference = ref;
  term.billing.recordedBy = payment.userId?._id || payment.userId;
  const line = `${new Date().toISOString().slice(0, 10)}: ${seats} students, RWF ${payment.amount.toLocaleString()} (${ref})`;
  term.billing.notes = [term.billing.notes, line].filter(Boolean).join('\n').slice(-500);
  await term.save();

  const managers = await User.find({ schoolId: payment.schoolId, role: 'school_admin', isActive: { $ne: false } }).select('_id').lean();
  const admins = await User.find({ role: 'admin', isActive: { $ne: false } }).select('_id').lean();
  await notifier()([...managers, ...admins].map((u) => u._id), 'School term paid',
    `${term.academicYear} Term ${term.term}: payment for ${seats} students (RWF ${payment.amount.toLocaleString()}) went through.`,
    { type: 'school_term_paid', schoolId: String(payment.schoolId), termId: String(term._id) });
}

async function fulfillPayment(payment, { actorId = null } = {}) {
  switch (payment.purpose) {
    case 'teacher_guide': return fulfillTeacherGuide(payment, { actorId });
    case 'school_term': return fulfillSchoolTerm(payment, { actorId });
    default: return fulfillCourse(payment, { actorId });
  }
}

/** Undo access when an approved payment is reversed (failed/cancelled by an admin). */
async function revokePayment(payment) {
  if (payment.purpose === 'teacher_guide') {
    await require('../../models/TeacherAssignment').updateOne(
      { paymentId: payment._id, source: 'guide_purchase' }, { $set: { isActive: false } });
  }
  // Course enrollments and school terms are left to the admin on purpose
  // (existing behaviour: reversing a course payment never removed the enrollment).
}

module.exports = { fulfillPayment, revokePayment, METHOD_LABEL };
