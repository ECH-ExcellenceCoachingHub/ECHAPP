/**
 * Credentials for school members.
 *
 *  - Staff (school admins, teachers) sign in with email + password (Firebase).
 *    When no password is typed, a strong one is generated and returned ONCE.
 *  - Students sign in with a student code (e.g. GSB260001) + 6-digit PIN.
 *  - Parents sign in with their phone number + 6-digit PIN.
 *
 * PINs are bcrypt-hashed; nothing is ever stored or logged in clear text.
 */
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const School = require('../../models/School');
const User = require('../../models/User');
const admin = require('../../config/firebase');

const PIN_LENGTH = 6;
const MAX_PIN_FAILURES = 5;
const PIN_LOCK_MINUTES = 15;

function generatePassword(length = 12) {
  // No look-alike characters (0/O, 1/l/I) so it can be read out or printed.
  const lower = 'abcdefghjkmnpqrstuvwxyz';
  const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const digits = '23456789';
  const symbols = '!@#$%*?';
  const all = lower + upper + digits + symbols;
  const pick = (set) => set[crypto.randomInt(set.length)];
  const chars = [pick(lower), pick(upper), pick(digits), pick(symbols)];
  while (chars.length < length) chars.push(pick(all));
  for (let i = chars.length - 1; i > 0; i--) {
    const j = crypto.randomInt(i + 1);
    [chars[i], chars[j]] = [chars[j], chars[i]];
  }
  return chars.join('');
}

function generatePin() {
  // Avoid trivially guessable PINs (all same digit, 123456…).
  for (;;) {
    const pin = String(crypto.randomInt(0, 10 ** PIN_LENGTH)).padStart(PIN_LENGTH, '0');
    if (isAcceptablePin(pin)) return pin;
  }
}

function isAcceptablePin(pin) {
  if (!new RegExp(`^\\d{${PIN_LENGTH}}$`).test(pin)) return false;
  if (/^(\d)\1+$/.test(pin)) return false;
  if ('0123456789'.includes(pin) || '9876543210'.includes(pin)) return false;
  return true;
}

async function hashPin(pin) {
  return bcrypt.hash(pin, 10);
}

async function comparePin(pin, hash) {
  if (!hash || !pin) return false;
  return bcrypt.compare(String(pin), hash);
}

/** Normalizes what a student types: " gsb-26 0001 " → "GSB260001". */
function normalizeCode(code) {
  return String(code || '').toUpperCase().replace(/[^A-Z0-9]/g, '');
}

/** Rwandan-friendly phone normalization: 0788… / 788… / +250788… → +250788… */
function normalizePhone(phone) {
  if (!phone) return null;
  let p = String(phone).replace(/[^\d+]/g, '');
  if (!p) return null;
  if (p.startsWith('00')) p = `+${p.slice(2)}`;
  if (p.startsWith('+')) return p;
  if (p.startsWith('250') && p.length === 12) return `+${p}`;
  if (p.startsWith('0') && p.length === 10) return `+250${p.slice(1)}`;
  if (p.length === 9 && p.startsWith('7')) return `+250${p}`;
  return p;
}

function normalizeEmail(email) {
  const e = String(email || '').trim().toLowerCase();
  return e || null;
}

/** Proposes a school code from its name: "Groupe Scolaire Butare" → "GSB". */
async function uniqueSchoolCode(name, preferred) {
  const clean = (s) => String(s || '').toUpperCase().replace(/[^A-Z0-9]/g, '');
  let base = clean(preferred);
  if (!base) {
    const words = String(name || '').split(/\s+/).filter(Boolean);
    base = clean(words.map((w) => w[0]).join(''));
    if (base.length < 2) base = clean(name).slice(0, 4);
  }
  base = base.slice(0, 6) || 'SCH';
  if (base.length < 2) base = `${base}S`;
  let code = base;
  for (let i = 2; await School.exists({ code }); i++) {
    code = `${base.slice(0, 6)}${i}`;
  }
  return code;
}

/** Next unique student code for a school: <CODE><YY><4-digit seq>. Atomic. */
async function nextStudentCode(schoolId) {
  for (let attempt = 0; attempt < 5; attempt++) {
    const school = await School.findByIdAndUpdate(schoolId, { $inc: { studentSeq: 1 } }, { returnDocument: 'after' }).select('code studentSeq');
    if (!school.code) {
      school.code = await uniqueSchoolCode(school.name);
      await School.updateOne({ _id: school._id }, { code: school.code });
    }
    const yy = String(new Date().getFullYear()).slice(-2);
    const code = `${school.code}${yy}${String(school.studentSeq).padStart(4, '0')}`;
    if (!(await User.exists({ studentCode: code }))) return code;
  }
  throw new Error('Could not generate a unique student code');
}

/** Firebase uid used for PIN-based accounts; Firebase creates the user on first custom-token sign-in. */
function pinAccountUid(userId) {
  return `ech-${userId}`;
}

/**
 * Creates the Firebase email/password account of a staff member.
 * Throws a readable error when Firebase refuses, so no half-created user is left behind.
 */
async function createFirebaseStaff({ email, password, fullName, phone, role }) {
  try {
    const fbUser = await admin.auth().createUser({
      email,
      password,
      displayName: fullName,
      phoneNumber: phone && phone.startsWith('+') ? phone : undefined,
    });
    await admin.auth().setCustomUserClaims(fbUser.uid, { role });
    return fbUser.uid;
  } catch (err) {
    const code = err.code || err.errorInfo?.code || '';
    let message = 'Could not create the sign-in account.';
    if (code.includes('email-already-exists')) message = 'This email already has a sign-in account.';
    else if (code.includes('phone-number-already-exists')) message = 'This phone number already has a sign-in account.';
    else if (code.includes('invalid-password')) message = 'Password must be at least 6 characters.';
    else if (code.includes('invalid-email')) message = 'This email address is not valid.';
    else if (code.includes('invalid-phone-number')) message = 'Phone number must be in international format (e.g. +250788123456).';
    const e = new Error(message);
    e.status = code.includes('already-exists') ? 409 : 400;
    e.expose = true;
    throw e;
  }
}

async function deleteFirebaseUser(uid) {
  if (!uid) return;
  try { await admin.auth().deleteUser(uid); } catch (_) { /* already gone */ }
}

async function setFirebasePassword(uid, password) {
  await admin.auth().updateUser(uid, { password });
}

module.exports = {
  PIN_LENGTH,
  MAX_PIN_FAILURES,
  PIN_LOCK_MINUTES,
  generatePassword,
  generatePin,
  isAcceptablePin,
  hashPin,
  comparePin,
  normalizeCode,
  normalizePhone,
  normalizeEmail,
  uniqueSchoolCode,
  nextStudentCode,
  pinAccountUid,
  createFirebaseStaff,
  deleteFirebaseUser,
  setFirebasePassword,
};
