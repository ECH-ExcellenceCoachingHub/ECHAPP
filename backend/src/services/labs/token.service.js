/**
 * Short-lived "lab tokens" for the Unity lab engine (embedded on mobile,
 * standalone on Windows/VR, iframe on web).
 *
 * They are signed with a secret DIFFERENT from JWT_SECRET, so the normal
 * `protect` middleware rejects them: a lab token only grants access to the
 * lab endpoints, never to the rest of the account.
 */
const crypto = require('crypto');
const jwt = require('jsonwebtoken');

const LAB_TOKEN_TTL = process.env.LAB_TOKEN_TTL || '4h'; // a long practical + offline sync margin

function labSecret() {
  if (process.env.LAB_TOKEN_SECRET) return process.env.LAB_TOKEN_SECRET;
  if (!process.env.JWT_SECRET) throw new Error('JWT_SECRET is not configured');
  // Derived, never equal to JWT_SECRET.
  return crypto.createHmac('sha256', process.env.JWT_SECRET).update('ech-lab-token-v1').digest('hex');
}

function signLabToken({ userId, scenarioId = null, lessonId = null, courseId = null }) {
  return jwt.sign(
    { sub: String(userId), scope: 'lab', sid: scenarioId ? String(scenarioId) : null, lid: lessonId ? String(lessonId) : null, cid: courseId ? String(courseId) : null },
    labSecret(),
    { expiresIn: LAB_TOKEN_TTL, audience: 'ech-labs' },
  );
}

function verifyLabToken(token) {
  const payload = jwt.verify(token, labSecret(), { audience: 'ech-labs' });
  if (payload.scope !== 'lab') throw new Error('Not a lab token');
  return payload;
}

module.exports = { signLabToken, verifyLabToken, LAB_TOKEN_TTL };
