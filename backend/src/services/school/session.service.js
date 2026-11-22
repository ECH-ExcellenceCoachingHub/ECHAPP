/**
 * One active session at a time for accounts with singleSession (school students).
 * Each PIN sign-in creates a new session id (sid); it is carried in the ECH JWT
 * and in the Firebase custom-token claims. Tokens of older sessions are refused.
 *
 * Schools in a "School only" mode also limit sessions in time (end of the
 * school day) and — in network mode — in place (school internet only).
 */
const User = require('../../models/User');
const { cachedPolicy } = require('./accessPolicy.service');
const { ipAllowed } = require('../../utils/clientIp');

const SESSION_REPLACED = {
  success: false,
  code: 'SESSION_REPLACED',
  message: 'You were signed out because your account was used to sign in on another device. If that was not you, tell your teacher.',
};

const SESSION_EXPIRED = {
  success: false,
  code: 'SESSION_EXPIRED',
  message: 'Your school session has ended. Sign in again at school.',
};

const SCHOOL_NETWORK_REQUIRED = {
  success: false,
  code: 'SCHOOL_NETWORK_REQUIRED',
  message: 'Your school allows ECH only on the school\'s internet. You were signed out.',
};

/**
 * Why this token may not be used (response body), or null when it is fine.
 * `ip` is the caller's address (only needed for network-mode schools).
 */
async function sessionProblem(user, sid, ip) {
  if (!user || !user.singleSession) return null;
  const row = await User.findById(user._id).select('+activeSessionId +activeSessionExpiresAt').lean();
  if (!row?.activeSessionId || row.activeSessionId !== sid) return SESSION_REPLACED;
  if (row.activeSessionExpiresAt && new Date(row.activeSessionExpiresAt) <= new Date()) return SESSION_EXPIRED;
  if (user.role === 'student' && user.schoolId && ip !== undefined) {
    const policy = await cachedPolicy(user.schoolId);
    if (policy.mode === 'network' && !ipAllowed(ip, policy.allowedIps)) return SCHOOL_NETWORK_REQUIRED;
  }
  return null;
}

/** Back-compat helper: true when the session may be used. */
async function isCurrentSession(user, sid, ip) {
  return (await sessionProblem(user, sid, ip)) === null;
}

/** Extra fields the apps need about a school member. */
function schoolFields(user) {
  return {
    schoolId: user.schoolId ? String(user.schoolId) : null,
    classroomId: user.classroomId ? String(user.classroomId) : null,
    studentCode: user.studentCode || null,
  };
}

/** Device binding is skipped for staff, parents and school students (shared lab PCs). */
function usesDeviceBinding(user) {
  return !['admin', 'instructor', 'school_admin', 'parent'].includes(user.role) && !user.schoolId;
}

module.exports = { sessionProblem, isCurrentSession, SESSION_REPLACED, SESSION_EXPIRED, SCHOOL_NETWORK_REQUIRED, schoolFields, usesDeviceBinding };
