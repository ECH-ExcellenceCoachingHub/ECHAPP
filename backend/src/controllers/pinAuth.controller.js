/**
 * Sign-in with a PIN:
 *   students — student code (e.g. GSB260001) + 6-digit PIN
 *              (+ the class code shown by the teacher when the school is "School only")
 *   young pupils (pinless levels) — class code, then tap their name
 *   parents  — phone number + 6-digit PIN (from anywhere)
 *
 * Security (students share lab PCs, so device binding is off):
 *   - wrong PINs lock the account for 15 min after 5 tries; per-IP rate limit
 *   - ONE active session: a new sign-in signs the previous device out
 *   - "School only" schools: class code or school internet required, and the
 *     session ends at the end of the school day
 *   - every attempt goes to LoginAudit; 3+ devices in 24 h is flagged to the school
 *   - the student is told when their account is used on a new device
 */
const crypto = require('crypto');
const User = require('../models/User');
const School = require('../models/School');
const Classroom = require('../models/Classroom');
const LoginAudit = require('../models/LoginAudit');
const admin = require('../config/firebase');
const { generateToken, generateRefreshToken } = require('../utils/jwt.utils');
const { clientIp } = require('../utils/clientIp');
const cred = require('../services/school/credentials.service');
const access = require('../services/school/accessPolicy.service');
const { schoolFields } = require('../services/school/session.service');
const { notifyUsers } = require('../services/school/notify.service');

const WRONG = 'Wrong code or PIN.';
const IP_WINDOW_MS = 10 * 60 * 1000;
// A whole class signs in from one school IP; every account also has its own lockout.
const IP_MAX = 300;
const ipHits = new Map();

function ipLimited(ip) {
  const now = Date.now();
  let e = ipHits.get(ip);
  if (!e || e.reset <= now) { e = { n: 0, reset: now + IP_WINDOW_MS }; ipHits.set(ip, e); }
  if (ipHits.size > 20000) for (const [k, v] of ipHits) if (v.reset <= now) ipHits.delete(k);
  return ++e.n > IP_MAX;
}

/** For tests. */
function resetLimits() {
  ipHits.clear();
}

async function audit(req, data) {
  try {
    await LoginAudit.create({
      ip: clientIp(req),
      userAgent: String(req.headers?.['user-agent'] || '').slice(0, 300),
      deviceId: req.body?.deviceId ? String(req.body.deviceId).slice(0, 200) : undefined,
      ...data,
    });
  } catch (err) {
    console.error('[pin-auth] audit failed:', err.message);
  }
}

/** Starts the session and answers with tokens. Shared by every PIN flow. */
async function startSession(req, res, user, { method, identifier, accessCode = null, viaNetwork = false, expiresAt = null }) {
  const sid = crypto.randomBytes(16).toString('hex');
  const hadSession = !!user.activeSessionId;
  user.pinFailedCount = 0;
  user.pinLockedUntil = null;
  user.lastActive = new Date();
  if (user.singleSession) {
    user.activeSessionId = sid;
    user.activeSessionExpiresAt = expiresAt;
  }
  if (!user.firebaseUid) user.firebaseUid = cred.pinAccountUid(user._id);
  await user.save();

  // Shared-account detection.
  const deviceId = req.body?.deviceId ? String(req.body.deviceId).slice(0, 200) : null;
  const dayAgo = new Date(Date.now() - 24 * 3600 * 1000);
  const recent = await LoginAudit.find({ userId: user._id, success: true, at: { $gte: dayAgo } }).select('deviceId ip').lean();
  const devices = new Set(recent.map((r) => r.deviceId || r.ip).filter(Boolean));
  devices.add(deviceId || clientIp(req));
  const lastOk = await LoginAudit.findOne({ userId: user._id, success: true }).sort({ at: -1 }).select('deviceId').lean();
  const newDevice = !!(lastOk && deviceId && lastOk.deviceId && lastOk.deviceId !== deviceId);
  const suspicious = user.role === 'student' && devices.size >= 3;
  await audit(req, {
    userId: user._id, schoolId: user.schoolId, identifier, method, success: true,
    accessCodeId: accessCode?._id || null, viaSchoolNetwork: viaNetwork,
    suspicious, suspiciousReason: suspicious ? `Signed in on ${devices.size} different devices in 24 hours` : undefined,
  });
  if (user.role === 'student' && newDevice && hadSession) {
    notifyUsers([user._id], {
      title: 'New sign-in',
      message: 'Your account was just used on another device. If it was not you, ask your teacher for a new PIN.',
      type: 'school', push: true,
    }).catch(() => {});
  }

  // Older Firebase sessions stop refreshing; older ECH tokens fail the sid check immediately.
  if (user.singleSession) {
    try { await admin.auth().revokeRefreshTokens(user.firebaseUid); } catch (_) { /* uid created on first sign-in */ }
  }
  let firebaseCustomToken = null;
  try {
    firebaseCustomToken = await admin.auth().createCustomToken(user.firebaseUid, { sid, role: user.role });
  } catch (err) {
    console.error('[pin-auth] custom token failed:', err.message);
  }

  const payload = user.singleSession ? { id: user._id, sid } : { id: user._id };
  return res.json({
    success: true,
    message: 'Signed in',
    data: {
      user: {
        id: user._id,
        firebaseUid: user.firebaseUid,
        fullName: user.fullName,
        email: user.email || null,
        role: user.role,
        teacherStatus: null,
        needsRoleSelection: false,
        ...schoolFields(user),
        phone: user.phone || null,
        avatar: user.avatar || null,
        hasCompletedOnboarding: true,
        interests: user.interests || [],
        createdAt: user.createdAt.getTime(),
      },
      token: generateToken(payload),
      refreshToken: generateRefreshToken(payload),
      firebaseCustomToken,
      sessionEndsAt: user.singleSession ? expiresAt : null,
    },
  });
}

/** POST /api/auth/pin-login { identifier, pin, accessCode?, deviceId? } or { accessCode, studentId } (young pupils) */
const pinLogin = async (req, res) => {
  const ip = clientIp(req) || 'unknown';
  if (ipLimited(ip)) {
    return res.status(429).json({ success: false, message: 'Too many attempts from this network. Wait 10 minutes and try again.' });
  }
  try {
    if (req.body?.studentId) return await pinlessLogin(req, res);

    const identifier = String(req.body?.identifier || req.body?.code || '').trim();
    const pin = String(req.body?.pin || '').trim();
    if (!identifier || !pin) return res.status(400).json({ success: false, message: 'Enter your code and PIN.' });

    const isPhone = /^[+\d\s()-]+$/.test(identifier) && identifier.replace(/\D/g, '').length >= 9;
    const query = isPhone
      ? { phone: cred.normalizePhone(identifier), role: 'parent' }
      : { studentCode: cred.normalizeCode(identifier), role: 'student' };
    const method = isPhone ? 'phone_pin' : 'code_pin';
    const user = await User.findOne(query).select('+pinHash +pinFailedCount +pinLockedUntil +activeSessionId');

    if (!user || !user.pinHash) {
      await audit(req, { identifier: identifier.slice(0, 40), method, success: false, reason: 'unknown_identifier' });
      return res.status(401).json({ success: false, message: WRONG });
    }
    if (user.pinLockedUntil && user.pinLockedUntil > new Date()) {
      const mins = Math.ceil((user.pinLockedUntil - Date.now()) / 60000);
      await audit(req, { userId: user._id, schoolId: user.schoolId, identifier, method, success: false, reason: 'locked' });
      return res.status(423).json({ success: false, code: 'PIN_LOCKED', message: `Too many wrong PINs. Try again in ${mins} minute${mins > 1 ? 's' : ''}, or ask your teacher for a new PIN.` });
    }
    if (!(await cred.comparePin(pin, user.pinHash))) {
      user.pinFailedCount = (user.pinFailedCount || 0) + 1;
      let message = WRONG;
      if (user.pinFailedCount >= cred.MAX_PIN_FAILURES) {
        user.pinLockedUntil = new Date(Date.now() + cred.PIN_LOCK_MINUTES * 60000);
        user.pinFailedCount = 0;
        message = `Too many wrong PINs. Try again in ${cred.PIN_LOCK_MINUTES} minutes.`;
      }
      await user.save();
      await audit(req, { userId: user._id, schoolId: user.schoolId, identifier, method, success: false, reason: 'wrong_pin' });
      return res.status(401).json({ success: false, message });
    }
    if (!user.isActive) {
      await audit(req, { userId: user._id, schoolId: user.schoolId, identifier, method, success: false, reason: 'inactive' });
      return res.status(401).json({ success: false, message: 'This account is deactivated. Ask your school.' });
    }

    let check = { ok: true, expiresAt: null };
    if (user.role === 'student' && user.schoolId) {
      const school = await School.findById(user.schoolId).select('isActive studentAccess').lean();
      if (!school || school.isActive === false) {
        await audit(req, { userId: user._id, schoolId: user.schoolId, identifier, method, success: false, reason: 'school_inactive' });
        return res.status(403).json({ success: false, message: 'Your school\'s account is not active. Ask your school.' });
      }
      check = await access.checkStudentSignIn(user, school, { ip, accessCode: req.body?.accessCode });
      if (!check.ok) {
        // A correct PIN with a missing/wrong class code does not count as a wrong PIN.
        user.pinFailedCount = 0;
        await user.save();
        await audit(req, { userId: user._id, schoolId: user.schoolId, identifier, method, success: false, reason: check.code.toLowerCase() });
        return res.status(check.status).json({ success: false, code: check.code, message: check.message });
      }
    }

    return await startSession(req, res, user, { method, identifier, accessCode: check.accessCode, viaNetwork: !!check.viaNetwork, expiresAt: check.expiresAt || null });
  } catch (err) {
    console.error('[pin-auth] error:', err);
    return res.status(500).json({ success: false, message: 'Sign-in failed. Please try again.' });
  }
};

/** Young pupils: class code + their own name from the class list (no PIN). */
async function pinlessLogin(req, res) {
  const codeDoc = await access.findActiveCode(req.body?.accessCode);
  if (!codeDoc || !codeDoc.classroomId) {
    await audit(req, { identifier: 'class-code', method: 'class_code', success: false, reason: 'access_code_invalid' });
    return res.status(403).json({ success: false, code: 'ACCESS_CODE_INVALID', message: 'This class code is wrong or has expired. Ask your teacher.' });
  }
  const [school, classroom] = await Promise.all([
    School.findById(codeDoc.schoolId).select('isActive studentAccess').lean(),
    Classroom.findById(codeDoc.classroomId).select('level schoolId isActive').lean(),
  ]);
  const policy = access.policyOf(school);
  if (!school || school.isActive === false || !classroom || !access.isPinlessLevel(policy, classroom.level)) {
    return res.status(403).json({ success: false, code: 'PIN_REQUIRED', message: 'This class signs in with student code and PIN.' });
  }
  if (!require('mongoose').Types.ObjectId.isValid(String(req.body.studentId))) {
    return res.status(400).json({ success: false, message: 'Choose your name from the list.' });
  }
  const user = await User.findOne({ _id: req.body.studentId, role: 'student', classroomId: classroom._id, isActive: true }).select('+activeSessionId');
  if (!user) return res.status(404).json({ success: false, message: 'Choose your name from the list.' });
  return startSession(req, res, user, {
    method: 'class_code',
    identifier: user.studentCode,
    accessCode: codeDoc,
    expiresAt: access.sessionExpiry(policy),
  });
}

/**
 * POST /api/auth/class-code { code } — what a class code opens.
 * Young-pupil classes get the list of names to tap; other classes are told to use code + PIN.
 */
const classCodeInfo = async (req, res) => {
  const ip = clientIp(req) || 'unknown';
  if (ipLimited(ip)) return res.status(429).json({ success: false, message: 'Too many attempts. Wait 10 minutes and try again.' });
  try {
    const codeDoc = await access.findActiveCode(req.body?.code);
    if (!codeDoc) {
      await audit(req, { identifier: 'class-code', method: 'class_code', success: false, reason: 'access_code_invalid' });
      return res.status(404).json({ success: false, code: 'ACCESS_CODE_INVALID', message: 'This class code is wrong or has expired.' });
    }
    const school = await School.findById(codeDoc.schoolId).select('name studentAccess isActive').lean();
    if (!codeDoc.classroomId) {
      return res.json({ success: true, data: { pinRequired: true, schoolName: school?.name } });
    }
    const classroom = await Classroom.findById(codeDoc.classroomId).select('name level').lean();
    const policy = access.policyOf(school);
    if (!classroom || !access.isPinlessLevel(policy, classroom.level)) {
      return res.json({ success: true, data: { pinRequired: true, schoolName: school?.name, className: classroom?.name } });
    }
    const students = await User.find({ classroomId: classroom._id, role: 'student', isActive: true }).select('fullName').sort({ fullName: 1 }).lean();
    return res.json({
      success: true,
      data: {
        pinRequired: false,
        schoolName: school?.name,
        className: classroom.name,
        students: students.map((s) => ({ id: String(s._id), fullName: s.fullName })),
      },
    });
  } catch (err) {
    console.error('[pin-auth] class code error:', err);
    return res.status(500).json({ success: false, message: 'Please try again.' });
  }
};

/** POST /api/auth/pin/change { currentPin, newPin } — students and parents choose their own PIN. */
const changePin = async (req, res) => {
  try {
    if (!['student', 'parent'].includes(req.user.role)) return res.status(403).json({ success: false, message: 'Only PIN accounts can do this.' });
    const { currentPin, newPin } = req.body || {};
    const user = await User.findById(req.user._id).select('+pinHash');
    if (!user?.pinHash || !(await cred.comparePin(String(currentPin || ''), user.pinHash))) {
      return res.status(400).json({ success: false, message: 'Your current PIN is wrong.' });
    }
    if (!cred.isAcceptablePin(String(newPin || ''))) {
      return res.status(400).json({ success: false, message: `Choose ${cred.PIN_LENGTH} digits that are not all the same or in a row.` });
    }
    user.pinHash = await cred.hashPin(String(newPin));
    await user.save();
    return res.json({ success: true, message: 'PIN changed' });
  } catch (err) {
    console.error('[pin-auth] change error:', err);
    return res.status(500).json({ success: false, message: 'Could not change the PIN.' });
  }
};

module.exports = { pinLogin, classCodeInfo, changePin, resetLimits };
