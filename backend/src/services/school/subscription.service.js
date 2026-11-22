/**
 * School subscription: schools pay per student per term.
 *
 * Status:
 *   active  — a paid (or waived) term covers today
 *   grace   — the last paid term ended less than school.graceDays ago,
 *             or the next term is already paid (holidays between terms)
 *   trial   — nothing paid yet; up to school.trialStudentLimit students, no course access
 *   expired — paid before, but the grace period is over
 *   inactive — the school was deactivated by ECH
 */
const School = require('../../models/School');
const SchoolTerm = require('../../models/SchoolTerm');
const User = require('../../models/User');

const DAY = 24 * 3600 * 1000;
const PAID = ['paid', 'waived'];

async function subscriptionStatus(schoolOrId, now = new Date()) {
  const school = schoolOrId && schoolOrId._id ? schoolOrId : await School.findById(schoolOrId).lean();
  if (!school) return { status: 'inactive', hasAccess: false, studentLimit: 0 };

  const terms = await SchoolTerm.find({ schoolId: school._id }).sort({ startDate: 1 }).lean();
  const currentTerm = terms.find((t) => t.startDate <= now && now <= t.endDate) || null;
  const paidTerms = terms.filter((t) => PAID.includes(t.billing?.status));
  const paidNow = paidTerms.find((t) => t.startDate <= now && now <= t.endDate) || null;
  const lastPaidEnded = paidTerms.filter((t) => t.endDate < now).pop() || null;
  const nextPaid = paidTerms.find((t) => t.startDate > now) || null;
  const graceMs = (school.graceDays ?? 21) * DAY;

  let status;
  let coveringTerm = null;
  if (school.isActive === false) status = 'inactive';
  else if (paidNow) { status = 'active'; coveringTerm = paidNow; }
  else if (lastPaidEnded && (now - lastPaidEnded.endDate <= graceMs || nextPaid)) { status = 'grace'; coveringTerm = lastPaidEnded; }
  else if (nextPaid && !lastPaidEnded) { status = 'grace'; coveringTerm = nextPaid; }
  else if (paidTerms.length === 0) status = 'trial';
  else status = 'expired';

  const studentLimit = coveringTerm
    ? (coveringTerm.billing.studentsPaid || 0)
    : status === 'trial' ? (school.trialStudentLimit ?? 30) : 0;

  let graceEndsAt = null;
  if (status === 'grace' && coveringTerm && coveringTerm.endDate < now) {
    graceEndsAt = new Date(coveringTerm.endDate.getTime() + graceMs);
  }

  return {
    status,
    hasAccess: status === 'active' || status === 'grace',
    studentLimit,
    currentTerm,
    coveringTerm,
    nextPaidTerm: nextPaid,
    graceEndsAt,
    daysLeft: coveringTerm && coveringTerm.endDate >= now
      ? Math.ceil((coveringTerm.endDate - now) / DAY)
      : graceEndsAt ? Math.max(0, Math.ceil((graceEndsAt - now) / DAY)) : 0,
  };
}

/** True when the learner belongs to a school whose subscription currently gives course access. */
async function hasSchoolCourseAccess(userId) {
  try {
    const user = await User.findById(userId).select('schoolId role isActive').lean();
    if (!user || !user.schoolId || user.role !== 'student') return false;
    const school = await School.findById(user.schoolId).lean();
    if (!school) return false;
    return (await subscriptionStatus(school)).hasAccess;
  } catch (error) {
    console.error('hasSchoolCourseAccess failed:', error.message);
    return false;
  }
}

async function activeStudentCount(schoolId) {
  return User.countDocuments({ schoolId, role: 'student', isActive: true });
}

/** Seats left for new students (Infinity never; 0 when full). */
async function seatsLeft(school) {
  const sub = await subscriptionStatus(school);
  const used = await activeStudentCount(school._id);
  return { left: Math.max(0, sub.studentLimit - used), used, limit: sub.studentLimit, subscription: sub };
}

module.exports = { subscriptionStatus, hasSchoolCourseAccess, activeStudentCount, seatsLeft };
