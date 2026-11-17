/**
 * ECH ↔ eexams.net integration (ECH is the identity provider).
 *
 * 1. SSO handoff: ECH issues a random single-use code (60 s) and sends the
 *    browser to eexams. The eexams BACKEND exchanges it server-to-server,
 *    authenticated with ECH_EEXAMS_SSO_SECRET, for the user's profile. No
 *    long-lived token ever travels in a URL.
 * 2. Events: eexams pushes signed events (HMAC-SHA256 with
 *    ECH_EEXAMS_WEBHOOK_SECRET over "<timestamp>.<raw body>") so ECH learns
 *    about account links and exam results.
 */
const crypto = require('crypto');
const admin = require('../../config/firebase');
const User = require('../../models/User');
const EexamsSsoCode = require('../../models/EexamsSsoCode');
const ExternalExamResult = require('../../models/ExternalExamResult');
const Notification = require('../../models/Notification');

const CODE_TTL_MS = 60 * 1000;
const WEBHOOK_MAX_SKEW_MS = 5 * 60 * 1000;

const config = () => ({
  baseUrl: (process.env.EEXAMS_BASE_URL || 'https://www.eexams.net').replace(/\/+$/, ''),
  ssoSecret: process.env.ECH_EEXAMS_SSO_SECRET || '',
  webhookSecret: process.env.ECH_EEXAMS_WEBHOOK_SECRET || '',
});

const sha256 = (s) => crypto.createHash('sha256').update(s).digest('hex');

function safeEqual(a, b) {
  const ab = Buffer.from(String(a));
  const bb = Buffer.from(String(b));
  return ab.length === bb.length && crypto.timingSafeEqual(ab, bb);
}

/** Only same-site relative paths, so the SSO link can't become an open redirect. */
function sanitizeRedirect(path) {
  if (typeof path !== 'string' || !path.startsWith('/') || path.startsWith('//') || path.includes('\\')) return '/';
  if (path.length > 300 || /[\r\n]/.test(path)) return '/';
  return path;
}

async function isEmailVerified(user) {
  if (!user.email) return false;
  if (user.firebaseUid) {
    try {
      const fbUser = await admin.auth().getUser(user.firebaseUid);
      return !!fbUser.emailVerified;
    } catch (e) {
      console.warn('[eexams] could not read Firebase user:', e.message);
    }
  }
  return !!user.isVerified;
}

/** Creates a one-time code and the eexams URL the client should open. */
async function startSso(user, redirect) {
  const code = crypto.randomBytes(32).toString('base64url');
  const safeRedirect = sanitizeRedirect(redirect);
  await EexamsSsoCode.create({
    codeHash: sha256(code),
    user: user._id,
    redirect: safeRedirect,
    expiresAt: new Date(Date.now() + CODE_TTL_MS),
  });
  const url = `${config().baseUrl}/ech/sso?code=${encodeURIComponent(code)}`;
  return { url, expiresInSeconds: CODE_TTL_MS / 1000 };
}

function checkServiceAuth(req) {
  const { ssoSecret } = config();
  if (!ssoSecret) return false;
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  return token.length > 0 && safeEqual(token, ssoSecret);
}

/** Single use: the code is deleted the moment it is redeemed. */
async function exchangeCode(code) {
  if (typeof code !== 'string' || code.length < 20 || code.length > 100) return null;
  const record = await EexamsSsoCode.findOneAndDelete({ codeHash: sha256(code), expiresAt: { $gt: new Date() } });
  if (!record) return null;

  const user = await User.findById(record.user).select('-password');
  if (!user || !user.isActive) return null;

  return {
    echUserId: String(user._id),
    email: user.email || null,
    emailVerified: await isEmailVerified(user),
    fullName: user.fullName || '',
    phone: user.phone || null,
    avatar: user.avatar || null,
    role: user.role,
    redirect: record.redirect,
  };
}

function verifyWebhook(req) {
  const { webhookSecret } = config();
  if (!webhookSecret || !req.rawBody) return false;
  const ts = req.headers['x-ech-timestamp'];
  const sig = req.headers['x-ech-signature'];
  if (!ts || !sig) return false;
  const tsNum = Number(ts);
  if (!Number.isFinite(tsNum) || Math.abs(Date.now() - tsNum) > WEBHOOK_MAX_SKEW_MS) return false;
  const expected = crypto.createHmac('sha256', webhookSecret).update(`${ts}.`).update(req.rawBody).digest('hex');
  return safeEqual(sig, expected);
}

async function findLinkedUser(echUserId) {
  if (!echUserId || !/^[a-f0-9]{24}$/i.test(String(echUserId))) return null;
  return User.findById(echUserId).select('_id fullName eexamsUserId');
}

async function handleAccountLinked(data) {
  const user = await findLinkedUser(data.echUserId);
  if (!user) return { ignored: 'unknown user' };
  await User.updateOne({ _id: user._id }, { eexamsUserId: String(data.eexamsUserId), eexamsLinkedAt: new Date(data.linkedAt || Date.now()) });
  return { ok: true };
}

const num = (v, d = 0) => (Number.isFinite(Number(v)) ? Number(v) : d);

async function handleExamResult(data) {
  const user = await findLinkedUser(data.echUserId);
  if (!user) return { ignored: 'unknown user' };
  if (!data.resultId) return { ignored: 'missing resultId' };

  const score = num(data.score);
  const maxScore = num(data.maxScore);
  const percentage = maxScore > 0 ? Math.round((score / maxScore) * 1000) / 10 : 0;
  const passingScore = data.passingScore == null ? null : num(data.passingScore, null);

  const update = {
    user: user._id,
    source: 'eexams',
    externalResultId: String(data.resultId),
    externalExamId: data.examId ? String(data.examId) : null,
    examTitle: String(data.examTitle || 'Exam').slice(0, 300),
    level: data.level ? String(data.level).slice(0, 120) : null,
    score,
    maxScore,
    percentage,
    passingScore,
    passed: passingScore == null ? null : percentage >= passingScore,
    startedAt: data.startedAt ? new Date(data.startedAt) : undefined,
    completedAt: data.completedAt ? new Date(data.completedAt) : new Date(),
    reviewPath: data.resultId ? `/student/results/${encodeURIComponent(String(data.resultId))}` : null,
  };

  const res = await ExternalExamResult.findOneAndUpdate(
    { source: 'eexams', externalResultId: update.externalResultId },
    { $set: update },
    { upsert: true, returnDocument: 'after', includeResultMetadata: true },
  );
  const isNew = !res.lastErrorObject?.updatedExisting;

  // Tell the student, once per result (a re-grade updates silently).
  if (isNew) {
    const title = 'Exam result ready';
    const message = `${update.examTitle}: ${percentage}%${update.passed === true ? ' — passed' : update.passed === false ? ' — not passed yet' : ''}`;
    // `route` is what the app's push handler navigates to; source + reviewPath
    // let it open this exact result on eexams instead.
    const payload = { route: '/exams/history', source: 'eexams', resultId: update.externalResultId, reviewPath: update.reviewPath };
    try {
      await Notification.createNotification({ userId: user._id, title, message, type: 'exam', data: payload });
      const notificationController = require('../../controllers/notification.controller');
      await notificationController.sendPushNotification(user._id, title, message, payload, false);
    } catch (e) {
      console.warn('[eexams] result notification failed:', e.message);
    }
  }
  return { ok: true, created: isNew };
}

async function handleEvent(event) {
  if (!event || typeof event !== 'object' || !event.type || !event.data) return { ignored: 'malformed' };
  switch (event.type) {
    case 'account.linked': return handleAccountLinked(event.data);
    case 'exam.result': return handleExamResult(event.data);
    default: return { ignored: `unknown type ${event.type}` };
  }
}

/** What the ECH app shows: link status, results and a small summary. */
async function getStudentOverview(user, { limit = 50 } = {}) {
  const results = await ExternalExamResult.find({ user: user._id, source: 'eexams' })
    .sort({ completedAt: -1 })
    .limit(Math.min(Math.max(Number(limit) || 50, 1), 200))
    .lean();

  const count = await ExternalExamResult.countDocuments({ user: user._id, source: 'eexams' });
  const agg = await ExternalExamResult.aggregate([
    { $match: { user: user._id, source: 'eexams' } },
    { $group: { _id: null, avg: { $avg: '$percentage' }, best: { $max: '$percentage' }, passed: { $sum: { $cond: ['$passed', 1, 0] } } } },
  ]);
  const s = agg[0] || {};

  return {
    linked: !!user.eexamsUserId,
    linkedAt: user.eexamsLinkedAt || null,
    summary: {
      examsTaken: count,
      averagePercentage: s.avg == null ? null : Math.round(s.avg * 10) / 10,
      bestPercentage: s.best == null ? null : s.best,
      passed: s.passed || 0,
    },
    results: results.map((r) => ({
      id: String(r._id),
      examTitle: r.examTitle,
      level: r.level,
      score: r.score,
      maxScore: r.maxScore,
      percentage: r.percentage,
      passed: r.passed,
      completedAt: r.completedAt,
      reviewPath: r.reviewPath,
    })),
  };
}

module.exports = {
  startSso,
  checkServiceAuth,
  exchangeCode,
  verifyWebhook,
  handleEvent,
  getStudentOverview,
  sanitizeRedirect,
};
