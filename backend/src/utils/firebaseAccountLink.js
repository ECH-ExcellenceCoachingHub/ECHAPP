/**
 * Rules for connecting a Firebase sign-in to an EXISTING ECH account that was
 * found by email (e.g. teachers/admins created directly in MongoDB).
 *
 * Linking by email alone is an account-takeover hole: anyone can create a
 * Firebase email/password account with someone else's address. So we only
 * link when Firebase says the email is verified (Google sign-ins always are),
 * and never replace an account's existing Firebase link.
 *
 * When the email isn't verified yet we email a Firebase verification link
 * (rate-limited per address) and the caller returns 403 EMAIL_NOT_VERIFIED.
 */
const admin = require('../config/firebase');

const RESEND_WINDOW_MS = 10 * 60 * 1000;
const lastSent = new Map();

function canLinkByEmail(decodedToken, existingUser) {
  if (!existingUser || existingUser.firebaseUid) return false;
  return decodedToken.email_verified === true;
}

async function sendVerificationIfNeeded(decodedToken, existingUser) {
  const email = decodedToken.email;
  if (!email) return false;
  const key = email.toLowerCase();
  const now = Date.now();
  if (lastSent.has(key) && now - lastSent.get(key) < RESEND_WINDOW_MS) return true;
  try {
    const link = await admin.auth().generateEmailVerificationLink(email);
    const emailService = require('../services/email.service');
    await emailService.sendEmailVerificationEmail(email, link, existingUser?.fullName);
    lastSent.set(key, now);
    if (lastSent.size > 5000) for (const [k, t] of lastSent) if (now - t > RESEND_WINDOW_MS) lastSent.delete(k);
    return true;
  } catch (e) {
    console.error('[auth] could not send verification email:', e.message);
    return false;
  }
}

/** JSON body for the 403 the client receives. */
function notVerifiedMessage(sent) {
  return sent
    ? 'An account with this email already exists. We sent you a verification link — open it, then sign in again.'
    : 'An account with this email already exists. Please verify your email address, then sign in again.';
}

module.exports = { canLinkByEmail, sendVerificationIfNeeded, notVerifiedMessage };
