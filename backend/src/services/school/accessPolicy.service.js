/**
 * Where and when school students may use ECH (School.studentAccess).
 *
 *   anywhere — student code + PIN from any place.
 *   code     — student code + PIN + the current CLASS code (shown by the
 *              teacher) or SCHOOL code (shown by the admin in the lab).
 *              Devices on the school's internet (allowedIps) skip the code.
 *   network  — only from the school's internet (allowedIps); checked on every
 *              request, so a session cannot be carried home.
 *
 * In both school-only modes students sign in only between dayStartsAt and
 * dayEndsAt (Kigali time); a session ends at dayEndsAt or after
 * maxSessionHours, whichever comes first.
 * Young pupils (pinlessLevels) sign in with the class code + their name.
 */
const crypto = require('crypto');
const School = require('../../models/School');
const AccessCode = require('../../models/AccessCode');
const { ipAllowed } = require('../../utils/clientIp');

const KIGALI_OFFSET_MIN = 120; // Rwanda is UTC+2 all year (no daylight saving)
const RENEW_BEFORE_MS = 5 * 60 * 1000; // show the next code 5 min before the current one expires
const CODE_LENGTH = 6;

const DEFAULTS = {
  mode: 'anywhere',
  codeMinutes: 60,
  dayStartsAt: '06:00',
  dayEndsAt: '17:00',
  maxSessionHours: 9,
  allowedIps: [],
  pinlessLevels: ['N1', 'N2', 'N3', 'P1', 'P2', 'P3'],
};

function policyOf(school) {
  const sa = (school && school.studentAccess && (school.studentAccess.toObject ? school.studentAccess.toObject() : school.studentAccess)) || {};
  return { ...DEFAULTS, ...Object.fromEntries(Object.entries(sa).filter(([, v]) => v !== undefined && v !== null)) };
}

// Small cache: the network check runs on every request of school students.
const cache = new Map();
const CACHE_MS = 60 * 1000;

async function cachedPolicy(schoolId) {
  const key = String(schoolId);
  const hit = cache.get(key);
  if (hit && hit.at > Date.now() - CACHE_MS) return hit.policy;
  const school = await School.findById(schoolId).select('studentAccess isActive').lean();
  const policy = { ...policyOf(school), schoolActive: school?.isActive !== false };
  cache.set(key, { at: Date.now(), policy });
  if (cache.size > 5000) cache.clear();
  return policy;
}

function invalidatePolicy(schoolId) {
  cache.delete(String(schoolId));
}

/** Minutes since midnight in Kigali for a Date. */
function kigaliMinutes(now) {
  const k = new Date(now.getTime() + KIGALI_OFFSET_MIN * 60000);
  return k.getUTCHours() * 60 + k.getUTCMinutes();
}

function toMinutes(hhmm, fallback) {
  const [h, m] = String(hhmm || fallback).split(':').map(Number);
  return h * 60 + m;
}

/** True when `now` is inside the school day (dayStartsAt–dayEndsAt, Kigali time). */
function withinSchoolHours(policy, now = new Date()) {
  const t = kigaliMinutes(now);
  return t >= toMinutes(policy.dayStartsAt, '06:00') && t < toMinutes(policy.dayEndsAt, '17:00');
}

/**
 * When a school-only session started now must end: today's dayEndsAt (Kigali),
 * or maxSessionHours after sign-in if that comes first. Sign-in outside school
 * hours is refused beforehand (see checkStudentSignIn), so nothing stays open
 * overnight.
 */
function sessionExpiry(policy, now = new Date()) {
  const byHours = new Date(now.getTime() + policy.maxSessionHours * 3600 * 1000);
  const minutesLeft = toMinutes(policy.dayEndsAt, '17:00') - kigaliMinutes(now);
  const dayEnd = new Date(now.getTime() + Math.max(0, minutesLeft) * 60000 - (now.getUTCSeconds() * 1000 + now.getUTCMilliseconds()));
  return dayEnd < byHours ? dayEnd : byHours;
}

/** Refusal for a sign-in outside the school day, or null. */
function outsideHoursRefusal(policy, now = new Date()) {
  if (policy.mode === 'anywhere' || withinSchoolHours(policy, now)) return null;
  return {
    ok: false,
    status: 403,
    code: 'OUTSIDE_SCHOOL_HOURS',
    message: `Your school opens ECH for students from ${policy.dayStartsAt || '06:00'} to ${policy.dayEndsAt || '17:00'}. Try again during school hours.`,
  };
}

function randomCode() {
  return String(crypto.randomInt(0, 10 ** CODE_LENGTH)).padStart(CODE_LENGTH, '0');
}

/**
 * The code to show now for a class (classroomId) or the whole school (null).
 * Reuses the current one; issues the next one shortly before it expires.
 */
async function currentCode({ school, classroomId = null, createdBy }) {
  const policy = policyOf(school);
  const now = Date.now();
  const existing = await AccessCode.findOne({
    schoolId: school._id,
    classroomId: classroomId || null,
    expiresAt: { $gt: new Date(now + RENEW_BEFORE_MS) },
  }).sort({ expiresAt: -1 }).lean();
  if (existing) return existing;
  for (let i = 0; i < 8; i++) {
    try {
      const doc = await AccessCode.create({
        schoolId: school._id,
        classroomId: classroomId || null,
        code: randomCode(),
        createdBy,
        expiresAt: new Date(now + policy.codeMinutes * 60 * 1000),
      });
      return doc.toObject();
    } catch (err) {
      if (err.code !== 11000) throw err; // code collision: try another
    }
  }
  throw new Error('Could not create a sign-in code');
}

/** The valid code document for this student (their class code or their school's code), or null. */
async function findValidCodeForStudent(code, student) {
  const c = String(code || '').replace(/\D/g, '');
  if (c.length !== CODE_LENGTH) return null;
  const doc = await AccessCode.findOne({ code: c, expiresAt: { $gt: new Date() } }).lean();
  if (!doc || String(doc.schoolId) !== String(student.schoolId)) return null;
  if (doc.classroomId && String(doc.classroomId) !== String(student.classroomId)) return null;
  return doc;
}

/** Active code by value (young-pupil flow: the code tells us the class). */
async function findActiveCode(code) {
  const c = String(code || '').replace(/\D/g, '');
  if (c.length !== CODE_LENGTH) return null;
  return AccessCode.findOne({ code: c, expiresAt: { $gt: new Date() } }).lean();
}

/**
 * Decides whether a student may sign in now.
 * Returns { ok: true, accessCode, viaNetwork, expiresAt } or { ok: false, status, code, message }.
 */
async function checkStudentSignIn(student, school, { ip, accessCode, now = new Date() }) {
  const policy = policyOf(school);
  if (policy.mode === 'anywhere') return { ok: true, policy, expiresAt: null };
  const closed = outsideHoursRefusal(policy, now);
  if (closed) return closed;
  const onNetwork = ipAllowed(ip, policy.allowedIps);
  if (policy.mode === 'network') {
    if (!onNetwork) {
      return { ok: false, status: 403, code: 'SCHOOL_NETWORK_REQUIRED', message: 'Your school allows sign-in only from the school\'s internet (Wi-Fi or computer lab).' };
    }
    return { ok: true, policy, viaNetwork: true, expiresAt: sessionExpiry(policy, now) };
  }
  // mode === 'code'
  if (onNetwork) return { ok: true, policy, viaNetwork: true, expiresAt: sessionExpiry(policy, now) };
  if (!accessCode) {
    return { ok: false, status: 403, code: 'ACCESS_CODE_REQUIRED', message: 'Enter the class code your teacher shows in class.' };
  }
  const doc = await findValidCodeForStudent(accessCode, student);
  if (!doc) {
    return { ok: false, status: 403, code: 'ACCESS_CODE_INVALID', message: 'This class code is wrong or has expired. Ask your teacher for the current code.' };
  }
  return { ok: true, policy, accessCode: doc, expiresAt: sessionExpiry(policy, now) };
}

function isPinlessLevel(policy, level) {
  return (policy.pinlessLevels || []).map((l) => String(l).toUpperCase()).includes(String(level || '').toUpperCase());
}

module.exports = {
  DEFAULTS,
  CODE_LENGTH,
  policyOf,
  cachedPolicy,
  invalidatePolicy,
  sessionExpiry,
  withinSchoolHours,
  outsideHoursRefusal,
  currentCode,
  findValidCodeForStudent,
  findActiveCode,
  checkStudentSignIn,
  isPinlessLevel,
};
