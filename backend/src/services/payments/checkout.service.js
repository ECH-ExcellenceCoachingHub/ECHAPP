/**
 * Automatic payments through iTechPay for every paid ECH service.
 *
 *   start()   validates what is being bought (the SERVER sets the price),
 *             asks iTechPay to charge the customer, stores a pending Payment.
 *   refresh() asks iTechPay for the live status and, once paid, claims the
 *             payment atomically and fulfils it (fulfillment.service).
 *
 * refresh() is reached four ways, because the iTechPay webhook is not reliably
 * delivered: the webhook, the app polling while the user waits, a background
 * sweeper (user closed the app), and an admin "check again" button. The atomic
 * claim (status pending/failed/cancelled → completed) means only one of them
 * ever fulfils a payment.
 */
const mongoose = require('mongoose');
const Payment = require('../../models/Payment');
const Course = require('../../models/Course');
const Enrollment = require('../../models/Enrollment');
const User = require('../../models/User');
const itecpay = require('./itecpay.service');
const { fulfillPayment } = require('./fulfillment.service');

const MIN = 60 * 1000;
// After this long with no answer from iTechPay the app stops waiting and shows
// "failed". The sweeper keeps checking for SWEEP_WINDOW in case money still arrives.
const TIMEOUT = { mtn_momo: 10 * MIN, airtel_money: 10 * MIN, card: 60 * MIN };
const SWEEP_WINDOW = 48 * 60 * MIN;
const MIN_RECHECK_MS = 4000;

class CheckoutError extends Error {
  constructor(message, status = 400, extra = {}) {
    super(message);
    this.status = status;
    this.extra = extra;
  }
}

const idOf = (v) => String(v?._id || v || '');

// ── What is being bought ─────────────────────────────────────────────────────

async function quoteCourse(user, body) {
  const { courseId } = body;
  if (!mongoose.isValidObjectId(courseId)) throw new CheckoutError('Course not found', 404);
  const course = await Course.findById(courseId).select('title price').lean();
  if (!course) throw new CheckoutError('Course not found', 404);

  const { hasSchoolCourseAccess } = require('../school/subscription.service');
  if (await hasSchoolCourseAccess(user._id, course)) {
    throw new CheckoutError('Your school already gives you this course for free. Enroll directly from the course page.');
  }
  if (!(course.price > 0)) throw new CheckoutError('This course is free. Enroll directly from the course page.');

  const enrollment = await Enrollment.findOne({ userId: user._id, courseId, status: Enrollment.ANY_STATUS });
  if (enrollment?.status === 'suspended') {
    throw new CheckoutError('Your access to this course has been suspended by an administrator. Please contact support.', 403);
  }
  if (enrollment?.status === 'unenrolled') {
    const expired = enrollment.accessExpirationDate && new Date() > enrollment.accessExpirationDate;
    const paid = enrollment.paymentId || await Payment.exists({ userId: user._id, courseId, status: { $in: ['completed', 'approved'] } });
    if (!expired && paid) throw new CheckoutError('You have already paid for this course. Re-enroll from the course page.');
  } else if (enrollment) {
    throw new CheckoutError('You are already enrolled in this course');
  }
  return { purpose: 'course', courseId: course._id, amount: course.price, label: course.title, match: { courseId: course._id, purpose: { $in: ['course', null] } } };
}

async function quoteTeacherGuide(user, body) {
  if (user.role !== 'instructor') throw new CheckoutError('Teachers only', 403);
  const access = require('../teacherAccess.service');
  if (access.isSelfRegisteredTeacher(user) && user.teacherStatus !== 'approved') {
    const reason = await access.blockReason(user);
    throw new CheckoutError(reason?.message || 'Your teacher account is not approved yet', 403, reason || {});
  }
  const { courseId } = body;
  if (!mongoose.isValidObjectId(courseId)) throw new CheckoutError('Course not found', 404);
  const course = await Course.findById(courseId).select('title teacherGuide').lean();
  if (!course || !course.teacherGuide?.enabled) throw new CheckoutError('This teacher\'s guide is not available', 404);
  const price = course.teacherGuide.price || 0;
  if (!(price > 0)) throw new CheckoutError('This teacher\'s guide is free. Request it from the catalog.');

  const TeacherAssignment = require('../../models/TeacherAssignment');
  if (await TeacherAssignment.exists({ teacherId: user._id, courseId, isActive: true })) {
    throw new CheckoutError('You already have this course');
  }
  return { purpose: 'teacher_guide', courseId: course._id, amount: price, label: `Teacher's guide: ${course.title}`, match: { courseId: course._id, purpose: 'teacher_guide' } };
}

async function quoteSchoolTerm(user, body) {
  const School = require('../../models/School');
  const SchoolTerm = require('../../models/SchoolTerm');
  const { canManageSchool } = require('../school/access.service');

  const schoolId = body.schoolId === 'me' || !body.schoolId ? user.schoolId : body.schoolId;
  if (!mongoose.isValidObjectId(schoolId) || !mongoose.isValidObjectId(body.termId)) throw new CheckoutError('Term not found', 404);
  const school = await School.findById(schoolId).lean();
  if (!school) throw new CheckoutError('School not found', 404);
  if (!canManageSchool(user, school._id)) throw new CheckoutError('Only the school administration can pay for the school.', 403);

  const term = await SchoolTerm.findOne({ _id: body.termId, schoolId: school._id }).lean();
  if (!term) throw new CheckoutError('Term not found', 404);
  if (term.billing?.status === 'waived') throw new CheckoutError('ECH has waived payment for this term.');
  if (term.endDate < new Date()) throw new CheckoutError('This term has already ended.');

  const seats = parseInt(body.students ?? body.seats, 10);
  if (!(seats >= 1 && seats <= 100000)) throw new CheckoutError('Enter how many students to pay for (at least 1).');
  const price = school.pricePerStudentPerTerm || term.billing?.pricePerStudent || 0;
  if (!(price > 0)) throw new CheckoutError('ECH has not set a price for your school yet. Please contact ECH.');

  const topUp = term.billing?.status === 'paid';
  return {
    purpose: 'school_term',
    schoolId: school._id,
    termId: term._id,
    seats,
    amount: seats * price,
    label: `${school.name} · ${term.academicYear} Term ${term.term}${topUp ? ' (more students)' : ''}`,
    match: { termId: term._id, purpose: 'school_term' },
  };
}

async function quote(user, body) {
  switch (body.purpose || 'course') {
    case 'course': return quoteCourse(user, body);
    case 'teacher_guide': return quoteTeacherGuide(user, body);
    case 'school_term': return quoteSchoolTerm(user, body);
    default: throw new CheckoutError('Unknown purchase type');
  }
}

// ── Start ────────────────────────────────────────────────────────────────────

const view = (p) => ({
  paymentId: p._id,
  reference: p.gateway?.reference,
  transactionId: p.transactionId,
  purpose: p.purpose,
  courseId: p.courseId ? idOf(p.courseId) : null,
  schoolId: p.schoolId ? idOf(p.schoolId) : null,
  termId: p.termId ? idOf(p.termId) : null,
  seats: p.seats || null,
  amount: p.amount,
  currency: p.currency,
  paymentMethod: p.paymentMethod,
  phone: p.gateway?.phone || null,
  paymentUrl: p.gateway?.paymentUrl || null,
  status: p.status,
  gatewayStatus: p.gateway?.lastStatus || null,
  failureReason: p.gateway?.failureReason || null,
  createdAt: p.createdAt,
  timeoutAt: new Date(new Date(p.createdAt).getTime() + (TIMEOUT[p.paymentMethod] || 10 * MIN)),
});

async function start(userId, body = {}) {
  const user = await User.findById(userId).lean();
  if (!user) throw new CheckoutError('User not found', 404);

  const method = String(body.paymentMethod || body.method || '');
  if (!['mtn_momo', 'airtel_money', 'card'].includes(method)) throw new CheckoutError('Choose MTN MoMo, Airtel Money or card');
  if (!itecpay.isConfigured(method)) throw new CheckoutError('This payment method is not available yet. Please choose another one.', 503);

  const q = await quote(user, body);

  // A payment for the same thing still in flight: hand it back so the app
  // resumes waiting instead of sending the customer a second prompt.
  const inFlight = await Payment.findOne({ userId: user._id, ...q.match, 'gateway.provider': 'itecpay', status: 'pending' }).sort({ createdAt: -1 });
  if (inFlight) {
    const fresh = await refresh(inFlight, { via: 'poll' }).catch(() => inFlight);
    if (fresh.status === 'pending' && Date.now() - fresh.createdAt < (TIMEOUT[fresh.paymentMethod] || 10 * MIN)) {
      if (fresh.paymentMethod === method) return { ...view(fresh), resumed: true };
      throw new CheckoutError('A payment for this is already waiting for approval on your phone. Approve it, or wait a few minutes and try again.', 409, { payment: view(fresh) });
    }
    if (fresh.status === 'completed') throw new CheckoutError('This was already paid.', 409, { payment: view(fresh) });
  }

  let phone = null;
  let email = null;
  if (method === 'card') {
    email = String(body.email || user.email || '').trim();
    if (!/^\S+@\S+\.\S+$/.test(email)) throw new CheckoutError('Enter your email address for card payment');
  } else {
    phone = itecpay.normalizePhone(body.phone || user.phone);
    if (!phone) throw new CheckoutError('Enter the mobile money number to charge (07XXXXXXXX)');
    if (!itecpay.phoneMatchesMethod(phone, method)) {
      throw new CheckoutError(method === 'mtn_momo'
        ? 'That is not an MTN number (078/079). Choose Airtel Money or enter an MTN number.'
        : 'That is not an Airtel number (072/073). Choose MTN MoMo or enter an Airtel number.');
    }
  }

  let gw;
  try {
    gw = await itecpay.createPaymentRequest({ amount: q.amount, method, phone, email });
  } catch (e) {
    console.error('[payments] iTechPay start failed:', e.message);
    throw new CheckoutError(e.message || 'Could not start the payment. Please try again.', e.isConfigError ? 503 : 502);
  }

  // Old manual requests for the same thing (made before online payment existed)
  // would keep the course page stuck on "waiting for admin": retire them.
  // 'admin_review' ones are left alone (the user said they already paid).
  await Payment.updateMany(
    { userId: user._id, ...q.match, 'gateway.provider': { $exists: false }, status: 'pending' },
    { $set: { status: 'cancelled', 'adminApproval.adminNotes': `Replaced by online payment ${gw.reference}` } }
  );

  const payment = await Payment.create({
    userId: user._id,
    courseId: q.courseId,
    schoolId: q.schoolId,
    termId: q.termId,
    seats: q.seats,
    purpose: q.purpose,
    amount: q.amount,
    currency: 'RWF',
    paymentMethod: method,
    transactionId: `ITP${Date.now()}${Math.random().toString(36).slice(2, 7).toUpperCase()}`,
    contactInfo: phone || email,
    status: 'pending',
    gateway: {
      provider: 'itecpay',
      reference: gw.reference,
      gatewayId: gw.gatewayId,
      paymentUrl: gw.paymentUrl,
      phone,
      lastStatus: 'initiated',
    },
  });
  return { ...view(payment), label: q.label };
}

// ── Confirm ──────────────────────────────────────────────────────────────────

async function onFulfilmentProblem(payment, reason) {
  await Payment.updateOne({ _id: payment._id }, { $set: { status: 'admin_review', 'gateway.failureReason': reason.slice(0, 300) } });
  try {
    const admins = await User.find({ role: 'admin', isActive: { $ne: false } }).select('_id').lean();
    await require('../../controllers/teacherAccess.controller').notify(admins.map((a) => a._id),
      'Online payment needs a look',
      `iTechPay payment ${payment.gateway?.reference} (RWF ${payment.amount.toLocaleString()}) was paid but could not be applied: ${reason}. Open Payments to approve it.`,
      { type: 'payment_review', paymentId: String(payment._id) });
  } catch (_) { /* best effort */ }
}

/**
 * Checks a gateway payment with iTechPay and fulfils it once paid.
 * Returns the (re-read) payment. Never throws for "still pending".
 */
async function refresh(paymentOrId, { via = 'poll', force = false } = {}) {
  let payment = paymentOrId?._id ? paymentOrId : await Payment.findById(paymentOrId);
  if (!payment || payment.gateway?.provider !== 'itecpay') return payment;
  if (['completed', 'approved', 'admin_review'].includes(payment.status)) return payment;
  if (!force && payment.gateway.lastCheckedAt && Date.now() - payment.gateway.lastCheckedAt < MIN_RECHECK_MS) return payment;

  let result;
  try {
    result = await itecpay.verifyPayment(payment.gateway.reference, payment.paymentMethod);
  } catch (e) {
    await Payment.updateOne({ _id: payment._id }, { $set: { 'gateway.lastCheckedAt': new Date() }, $inc: { 'gateway.checks': 1 } });
    console.warn(`[payments] verify ${payment.gateway.reference} failed: ${e.message}`);
    return Payment.findById(payment._id);
  }

  const base = {
    'gateway.lastStatus': result.status,
    'gateway.lastCheckedAt': new Date(),
    ...(result.transactionId ? { 'gateway.gatewayTransactionId': String(result.transactionId) } : {}),
    ...(result.amount != null ? { 'gateway.amountReported': result.amount } : {}),
  };

  if (result.state === 'paid') {
    const claimed = await Payment.findOneAndUpdate(
      { _id: payment._id, status: { $in: ['pending', 'failed', 'cancelled'] } },
      { $set: { ...base, status: 'completed', paymentDate: new Date(), 'gateway.confirmedBy': via, 'gateway.failureReason': null }, $inc: { 'gateway.checks': 1 } },
      { new: true }
    );
    if (!claimed) return Payment.findById(payment._id); // someone else got there first

    if (result.amount != null && result.amount > 0 && result.amount < claimed.amount) {
      await onFulfilmentProblem(claimed, `iTechPay reports RWF ${result.amount}, expected RWF ${claimed.amount}`);
      return Payment.findById(claimed._id);
    }
    try {
      await fulfillPayment(claimed);
      console.log(`[payments] ✅ ${claimed.gateway.reference} paid (${claimed.purpose}, RWF ${claimed.amount}) via ${via}`);
    } catch (e) {
      console.error(`[payments] fulfilment of ${claimed.gateway.reference} failed:`, e);
      await onFulfilmentProblem(claimed, e.message || 'fulfilment error');
    }
    if (claimed.purpose === 'course' || !claimed.purpose) sendReceipt(claimed).catch(() => {});
    return Payment.findById(claimed._id);
  }

  const set = { ...base };
  if (result.state === 'failed' && payment.status === 'pending') {
    set.status = 'failed';
    set['gateway.failureReason'] = 'declined';
  } else if (payment.status === 'pending' && Date.now() - payment.createdAt > (TIMEOUT[payment.paymentMethod] || 10 * MIN)) {
    // Stop showing "waiting" forever (it invites paying twice). The sweeper
    // still re-checks it for SWEEP_WINDOW in case the money arrives late.
    set.status = 'failed';
    set['gateway.failureReason'] = 'timeout';
  }
  return Payment.findOneAndUpdate({ _id: payment._id, status: payment.status }, { $set: set, $inc: { 'gateway.checks': 1 } }, { new: true })
    .then((p) => p || Payment.findById(payment._id));
}

async function sendReceipt(payment) {
  const user = await User.findById(payment.userId).select('email fullName').lean();
  if (!user?.email) return;
  await require('../email.service').sendPaymentStatusEmail(user.email, { fullName: user.fullName }, payment, 'approved');
}

/** Finds a gateway payment from the many shapes an iTechPay callback can take. */
function referenceFrom(body = {}, query = {}) {
  const d = body.data || {};
  return body.req_ref || body.reference || body.reqRef || d.req_ref || d.reference || query.req_ref || query.reference || query.OrderMerchantReference || body.OrderMerchantReference || null;
}

// ── Sweeper ──────────────────────────────────────────────────────────────────

let sweeping = false;
async function sweep({ dryRun = false, log = () => {} } = {}) {
  if (sweeping) return { skipped: true };
  sweeping = true;
  const out = { checked: 0, completed: 0, failed: 0, pending: 0, errors: 0 };
  try {
    const now = Date.now();
    const candidates = await Payment.find({
      'gateway.provider': 'itecpay',
      createdAt: { $gte: new Date(now - SWEEP_WINDOW) },
      $or: [
        { status: 'pending' },
        // Gave up waiting (or the user cancelled) but iTechPay never said "declined":
        // the money may still have arrived.
        { status: { $in: ['failed', 'cancelled'] }, 'gateway.failureReason': { $ne: 'declined' } },
      ],
    }).sort({ createdAt: 1 }).limit(200);

    for (const p of candidates) {
      // Young payments every run; older ones every 30 minutes.
      const age = now - p.createdAt;
      const since = now - (p.gateway.lastCheckedAt?.getTime() || 0);
      if (age > 60 * MIN && since < 30 * MIN) continue;
      out.checked++;
      try {
        if (dryRun) {
          const r = await itecpay.verifyPayment(p.gateway.reference, p.paymentMethod);
          log(`${p.gateway.reference} ${p.purpose} RWF ${p.amount} [${p.status}] → iTechPay: ${r.status} (${r.state})`);
          out[r.state === 'paid' ? 'completed' : r.state === 'failed' ? 'failed' : 'pending']++;
          continue;
        }
        const after = await refresh(p, { via: 'sweeper', force: true });
        log(`${p.gateway.reference} ${p.purpose} RWF ${p.amount}: ${p.status} → ${after?.status} (${after?.gateway?.lastStatus})`);
        if (after?.status === 'completed' && p.status !== 'completed') out.completed++;
        else if (after?.status === 'failed') out.failed++;
        else out.pending++;
      } catch (e) {
        out.errors++;
        log(`${p.gateway.reference}: error ${e.message}`);
      }
    }
  } finally {
    sweeping = false;
  }
  return out;
}

function schedule(everyMinutes = 2) {
  if (!['mtn_momo', 'airtel_money', 'card'].some(itecpay.isConfigured)) {
    console.log('ℹ️  iTechPay keys not set: automatic payments disabled');
    return null;
  }
  const timer = setInterval(() => {
    sweep().then((r) => { if (r.completed) console.log(`[payments] sweeper activated ${r.completed} payment(s)`); })
      .catch((e) => console.error('[payments] sweeper error:', e.message));
  }, everyMinutes * MIN);
  timer.unref?.();
  console.log(`💳 iTechPay payment sweeper scheduled (every ${everyMinutes} min)`);
  return timer;
}

module.exports = { start, refresh, sweep, schedule, referenceFrom, view, CheckoutError, TIMEOUT };
