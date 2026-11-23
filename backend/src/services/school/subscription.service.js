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
/** True when `course` is one the school offers to `classroom` (marked for its level, or a class syllabus). */
async function courseFitsClass(course, classroom) {
  if (!course || !classroom) return false;
  const sa = course.schoolAccess || {};
  if (sa.enabled && (sa.levels || []).map((l) => String(l).toUpperCase()).includes(String(classroom.level).toUpperCase())) return true;
  const ClassSubject = require('../../models/ClassSubject');
  return !!(await ClassSubject.exists({ classroomId: classroom._id, courseId: course._id, isActive: true }));
}

/**
 * A school student gets `course` free while the school's term is paid (or in
 * grace), but only courses meant for their class: the ones the super admin
 * marked for their level and the syllabus courses of their class subjects.
 */
async function hasSchoolCourseAccess(userId, course) {
  try {
    if (!course) return false;
    const user = await User.findById(userId).select('schoolId role isActive classroomId').lean();
    if (!user || !user.schoolId || user.role !== 'student' || !user.classroomId) return false;
    const Classroom = require('../../models/Classroom');
    const classroom = await Classroom.findById(user.classroomId).select('_id level').lean();
    if (!(await courseFitsClass(course, classroom))) return false;
    const school = await School.findById(user.schoolId).lean();
    if (!school) return false;
    return (await subscriptionStatus(school)).hasAccess;
  } catch (error) {
    console.error('hasSchoolCourseAccess failed:', error.message);
    return false;
  }
}

/** Courses a class gets for free (marked for its level + its syllabus courses), published only. */
async function coursesForClass(classroom) {
  if (!classroom) return [];
  const Course = require('../../models/Course');
  const ClassSubject = require('../../models/ClassSubject');
  const syllabusIds = await ClassSubject.find({ classroomId: classroom._id, isActive: true, courseId: { $ne: null } }).distinct('courseId');
  return Course.find({
    isPublished: true,
    $or: [{ 'schoolAccess.enabled': true, 'schoolAccess.levels': String(classroom.level).toUpperCase() }, { _id: { $in: syllabusIds } }],
  }).select('title description thumbnail level schoolAccess duration durationUnit').sort({ title: 1 }).limit(60).lean();
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

module.exports = { subscriptionStatus, hasSchoolCourseAccess, courseFitsClass, coursesForClass, activeStudentCount, seatsLeft };
