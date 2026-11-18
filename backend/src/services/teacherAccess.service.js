const TeacherAssignment = require('../models/TeacherAssignment');

/**
 * Who may use the teacher tools.
 *
 * Self-registered teachers (teacherStatus set) must:
 *   1. complete their profile,
 *   2. be approved by an admin, and
 *   3. hold at least one active course (an approved teacher's-guide request
 *      or an admin assignment).
 * Teachers created by an admin (teacherStatus null) keep full access, as before.
 */

const LEVEL_GROUPS = [
  { group: 'Nursery', levels: ['N1', 'N2', 'N3'] },
  { group: 'Primary', levels: ['P1', 'P2', 'P3', 'P4', 'P5', 'P6'] },
  { group: 'Secondary (O-Level)', levels: ['S1', 'S2', 'S3'] },
  { group: 'Secondary (A-Level)', levels: ['S4', 'S5', 'S6'] },
  { group: 'TVET', levels: ['L3', 'L4', 'L5'] },
  { group: 'Higher education', levels: ['University', 'Professional'] },
];

function isSelfRegisteredTeacher(user) {
  return !!user && user.role === 'instructor' && !!user.teacherStatus;
}

async function activeCourseCount(userId) {
  return TeacherAssignment.countDocuments({ teacherId: userId, isActive: true });
}

/** Summary used by the app to decide which teacher screen to show. */
async function accessFor(user) {
  if (!user || user.role !== 'instructor') {
    return { isTeacher: false, status: null, approved: false, courseCount: 0, canUseTools: false, selfRegistered: false };
  }
  const selfRegistered = isSelfRegisteredTeacher(user);
  const status = user.teacherStatus || 'approved';
  const courseCount = await activeCourseCount(user._id || user.id);
  const approved = status === 'approved';
  return {
    isTeacher: true,
    selfRegistered,
    status,
    approved,
    courseCount,
    // Admin-created teachers keep the old behaviour (tools even before an assignment).
    canUseTools: selfRegistered ? approved && courseCount > 0 : true,
    canEditCourseContent: !selfRegistered,
    reviewReason: user.teacherReview?.reason || null,
  };
}

/** Reason a self-registered teacher is blocked, or null when they may continue. */
async function blockReason(user) {
  if (!isSelfRegisteredTeacher(user)) return null;
  if (user.teacherStatus === 'profile_incomplete') return { code: 'TEACHER_PROFILE_INCOMPLETE', message: 'Please complete your teacher profile first.' };
  if (user.teacherStatus === 'pending') return { code: 'TEACHER_PENDING_APPROVAL', message: 'Your teacher account is waiting for admin approval.' };
  if (user.teacherStatus === 'rejected') return { code: 'TEACHER_REJECTED', message: 'Your teacher application was not approved. Please update your profile and resubmit.' };
  if ((await activeCourseCount(user._id || user.id)) === 0) {
    return { code: 'TEACHER_COURSE_REQUIRED', message: 'Choose a course and get it approved to unlock the teacher tools.' };
  }
  return null;
}

/** Express middleware: blocks self-registered teachers until they are fully cleared. */
async function requireTeacherAccess(req, res, next) {
  try {
    const reason = await blockReason(req.user);
    if (!reason) return next();
    return res.status(403).json({ success: false, ...reason });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Could not check teacher access' });
  }
}

/** Self-registered teachers teach courses; they never create or edit course content. */
function denySelfRegisteredTeacher(req, res, next) {
  if (isSelfRegisteredTeacher(req.user)) {
    return res.status(403).json({ success: false, code: 'TEACHER_CANNOT_EDIT_COURSES', message: 'Course content is managed by ECH admins.' });
  }
  return next();
}

/** Case-insensitive overlap between a teacher's classes and a guide's class levels. */
function levelsMatch(teacherLevels = [], guideLevels = []) {
  const want = new Set(teacherLevels.map(l => String(l).trim().toLowerCase()));
  return guideLevels.some(l => want.has(String(l).trim().toLowerCase()));
}

module.exports = {
  LEVEL_GROUPS,
  isSelfRegisteredTeacher,
  accessFor,
  blockReason,
  requireTeacherAccess,
  denySelfRegisteredTeacher,
  levelsMatch,
};
