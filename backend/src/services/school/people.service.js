/**
 * Creating school members without duplicates.
 *
 * Students belong to a CLASS. Whoever adds a student (school admin or the class
 * teacher) goes through findStudentDuplicates first; a student who already
 * exists is moved/linked, never registered twice. Subject teachers never
 * register students; they see them through their classes.
 */
const mongoose = require('mongoose');
const User = require('../../models/User');
const Classroom = require('../../models/Classroom');
const cred = require('./credentials.service');
const { seatsLeft } = require('./subscription.service');

class SchoolError extends Error {
  constructor(message, status = 400, extra = {}) {
    super(message);
    this.status = status;
    this.extra = extra;
    this.expose = true;
  }
}

const escapeRegex = (s) => String(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const normName = (s) => String(s || '').toLowerCase().normalize('NFKD').replace(/[^a-z\s]/g, '').split(/\s+/).filter(Boolean).sort().join(' ');
const sameDay = (a, b) => a && b && new Date(a).toISOString().slice(0, 10) === new Date(b).toISOString().slice(0, 10);

function cleanAddress(a) {
  if (!a || typeof a !== 'object') return undefined;
  const out = {};
  for (const k of ['province', 'district', 'sector', 'cell', 'village', 'street']) {
    if (a[k] != null && String(a[k]).trim()) out[k] = String(a[k]).trim();
  }
  return out;
}

function parseDate(v) {
  if (!v) return null;
  const d = new Date(v);
  return Number.isNaN(d.getTime()) ? null : d;
}

/** What the apps may see about a member (no hashes, no session ids). */
function publicMember(u) {
  if (!u) return null;
  const o = u.toObject ? u.toObject() : u;
  return {
    id: String(o._id),
    fullName: o.fullName,
    email: o.email || null,
    phone: o.phone || null,
    role: o.role,
    schoolId: o.schoolId ? String(o.schoolId._id || o.schoolId) : null,
    classroomId: o.classroomId ? String(o.classroomId._id || o.classroomId) : null,
    classroom: o.classroomId && o.classroomId.name ? { id: String(o.classroomId._id), name: o.classroomId.name, level: o.classroomId.level } : undefined,
    studentCode: o.studentCode || null,
    gender: o.gender || null,
    dateOfBirth: o.dateOfBirth || null,
    guardians: (o.guardians || []).map((g) => ({ name: g.name, phone: g.phone, relationship: g.relationship, hasAccount: !!g.userId, userId: g.userId ? String(g.userId) : null })),
    address: o.address || {},
    teacherProfile: o.role === 'instructor' || o.role === 'school_admin' ? (o.teacherProfile || {}) : undefined,
    isActive: o.isActive !== false,
    lastActive: o.lastActive || null,
    createdAt: o.createdAt,
  };
}

/** Possible duplicates of a new student inside the school (and conflicts anywhere). */
async function findStudentDuplicates(schoolId, data) {
  const out = [];
  const email = cred.normalizeEmail(data.email);
  const phone = cred.normalizePhone(data.phone);
  if (email || phone) {
    const or = [];
    if (email) or.push({ email });
    if (phone) or.push({ phone });
    const taken = await User.find({ $or: or }).select('fullName role schoolId classroomId studentCode email phone').populate('classroomId', 'name level').lean();
    for (const u of taken) out.push({ ...publicMember(u), reason: 'same_contact', otherSchool: !u.schoolId || String(u.schoolId) !== String(schoolId) });
  }

  const name = normName(data.fullName);
  if (name) {
    const firstToken = name.split(' ')[0];
    const candidates = await User.find({
      schoolId,
      role: 'student',
      fullName: { $regex: escapeRegex(firstToken), $options: 'i' },
    }).select('fullName schoolId classroomId studentCode dateOfBirth guardians isActive').populate('classroomId', 'name level').limit(50).lean();
    const guardianPhones = new Set((data.guardians || []).map((g) => cred.normalizePhone(g.phone)).filter(Boolean));
    for (const c of candidates) {
      if (normName(c.fullName) !== name) continue;
      if (out.some((o) => o.id === String(c._id))) continue;
      const dob = parseDate(data.dateOfBirth);
      const reasons = [];
      if (dob && sameDay(dob, c.dateOfBirth)) reasons.push('same_name_and_birth_date');
      if ((c.guardians || []).some((g) => guardianPhones.has(cred.normalizePhone(g.phone)))) reasons.push('same_name_and_parent_phone');
      if (data.classroomId && String(c.classroomId?._id || c.classroomId) === String(data.classroomId)) reasons.push('same_name_in_class');
      out.push({ ...publicMember(c), reason: reasons[0] || 'same_name', strong: reasons.length > 0 });
    }
  }
  return out;
}

/** Links (or creates) parent accounts for a student's guardians. Returns credentials of new parents. */
async function attachGuardians(student, guardians, { actorId } = {}) {
  const result = { parents: [], warnings: [] };
  const list = [];
  for (const g of (guardians || []).slice(0, 4)) {
    const name = String(g.name || '').trim();
    const phone = cred.normalizePhone(g.phone);
    if (!name && !phone) continue;
    const entry = { name: name || 'Parent', phone, relationship: String(g.relationship || '').trim() || 'Parent', userId: null };
    if (phone) {
      let parent = await User.findOne({ phone });
      if (parent && parent.role === 'parent') {
        entry.userId = parent._id;
        result.parents.push({ id: String(parent._id), name: parent.fullName, phone, existing: true });
      } else if (parent) {
        result.warnings.push(`${phone} is already used by another ECH account, so no parent account was created for ${entry.name}.`);
      } else {
        const pin = cred.generatePin();
        const _id = new mongoose.Types.ObjectId();
        parent = await User.create({
          _id,
          fullName: entry.name,
          phone,
          role: 'parent',
          firebaseUid: cred.pinAccountUid(_id),
          pinHash: await cred.hashPin(pin),
          isVerified: true,
          isActive: true,
          hasCompletedOnboarding: true,
          createdBy: actorId || null,
        });
        entry.userId = parent._id;
        result.parents.push({ id: String(parent._id), name: parent.fullName, phone, pin, existing: false });
      }
    }
    list.push(entry);
  }
  // Keep guardians already on the student that were not resent.
  const merged = [...(student.guardians || [])];
  for (const e of list) {
    const i = merged.findIndex((m) => (e.phone && cred.normalizePhone(m.phone) === e.phone) || (!e.phone && m.name === e.name));
    if (i >= 0) merged[i] = e; else merged.push(e);
  }
  student.guardians = merged;
  return result;
}

/**
 * Registers a new student in a class.
 * Throws SchoolError 409 { code: 'POSSIBLE_DUPLICATE', candidates } unless data.confirmNew.
 */
async function createStudent({ school, actor, data }) {
  const fullName = String(data.fullName || '').trim();
  if (fullName.length < 3) throw new SchoolError('Enter the student\'s full name.');
  if (!data.classroomId) throw new SchoolError('Choose the student\'s class.');
  const classroom = await Classroom.findOne({ _id: data.classroomId, schoolId: school._id, isActive: true });
  if (!classroom) throw new SchoolError('Class not found in this school.', 404);

  const seats = await seatsLeft(school);
  if (seats.left <= 0) {
    throw new SchoolError(
      seats.subscription.status === 'trial'
        ? `Trial limit reached (${seats.limit} students). Pay for the term to add more students.`
        : `All ${seats.limit} paid student places are used. Ask ECH to add places for this term.`,
      403, { code: 'STUDENT_LIMIT_REACHED', used: seats.used, limit: seats.limit });
  }

  const duplicates = await findStudentDuplicates(school._id, data);
  const contactTaken = duplicates.filter((d) => d.reason === 'same_contact');
  if (contactTaken.length) {
    throw new SchoolError('This email or phone already belongs to an ECH account.', 409, { code: 'CONTACT_IN_USE', candidates: contactTaken });
  }
  if (duplicates.length && !data.confirmNew) {
    throw new SchoolError('A student with this name already exists in your school. Is it the same student?', 409, { code: 'POSSIBLE_DUPLICATE', candidates: duplicates });
  }

  const _id = new mongoose.Types.ObjectId();
  const pin = cred.generatePin();
  const studentCode = await cred.nextStudentCode(school._id);
  const student = new User({
    _id,
    fullName,
    email: cred.normalizeEmail(data.email) || undefined,
    phone: cred.normalizePhone(data.phone) || undefined,
    role: 'student',
    schoolId: school._id,
    classroomId: classroom._id,
    studentCode,
    pinHash: await cred.hashPin(pin),
    firebaseUid: cred.pinAccountUid(_id),
    gender: ['male', 'female', 'other'].includes(data.gender) ? data.gender : null,
    dateOfBirth: parseDate(data.dateOfBirth),
    address: cleanAddress(data.address),
    isPrivateStudent: false,
    isVerified: true,
    isActive: true,
    hasCompletedOnboarding: true,
    singleSession: true,
    createdBy: actor?._id || null,
  });
  const guardianResult = await attachGuardians(student, data.guardians, { actorId: actor?._id });
  await student.save();
  await student.populate('classroomId', 'name level');

  return {
    student: publicMember(student),
    credentials: { studentCode, pin },
    parents: guardianResult.parents,
    warnings: guardianResult.warnings,
  };
}

/** Creates a school admin or teacher. Returns the password once (typed or generated). */
async function createStaff({ school, actor, role, data }) {
  if (!['instructor', 'school_admin'].includes(role)) throw new SchoolError('Invalid staff role.');
  const fullName = String(data.fullName || '').trim();
  const email = cred.normalizeEmail(data.email);
  const phone = cred.normalizePhone(data.phone);
  if (fullName.length < 3) throw new SchoolError('Enter the full name.');
  if (!email && !phone) throw new SchoolError('Enter an email or a phone number so they can sign in.');
  if (email && !/^\S+@\S+\.\S+$/.test(email)) throw new SchoolError('This email address is not valid.');

  const or = [];
  if (email) or.push({ email });
  if (phone) or.push({ phone });
  const existing = await User.findOne({ $or: or }).select('fullName role schoolId').lean();
  if (existing) {
    throw new SchoolError(
      existing.schoolId && String(existing.schoolId) === String(school._id)
        ? 'This person is already a member of your school.'
        : 'This email or phone already belongs to another ECH account.',
      409, { code: 'CONTACT_IN_USE' });
  }

  const typed = data.password ? String(data.password) : '';
  if (typed && typed.length < 8) throw new SchoolError('Password must be at least 8 characters.');
  const password = typed || cred.generatePassword();

  const firebaseUid = email ? await cred.createFirebaseStaff({ email, password, fullName, phone, role }) : null;
  try {
    const profile = data.teacherProfile || {};
    const user = await User.create({
      fullName,
      email: email || undefined,
      phone: phone || undefined,
      password,
      role,
      schoolId: school._id,
      firebaseUid: firebaseUid || undefined,
      gender: ['male', 'female', 'other'].includes(data.gender) ? data.gender : null,
      address: cleanAddress(data.address),
      teacherProfile: {
        school: school.name,
        qualification: profile.qualification ? String(profile.qualification).trim() : undefined,
        yearsExperience: Number.isFinite(+profile.yearsExperience) ? +profile.yearsExperience : undefined,
        subjects: Array.isArray(profile.subjects) ? profile.subjects.map((s) => String(s).trim()).filter(Boolean).slice(0, 20) : [],
        levels: Array.isArray(profile.levels) ? profile.levels.map((s) => String(s).trim()).filter(Boolean).slice(0, 20) : [],
        phone: phone || undefined,
      },
      isVerified: true,
      isActive: true,
      hasCompletedOnboarding: true,
      createdBy: actor?._id || null,
    });
    return {
      user: publicMember(user),
      credentials: { email: email || null, phone: phone || null, password, generated: !typed },
    };
  } catch (err) {
    await cred.deleteFirebaseUser(firebaseUid);
    if (err.code === 11000) throw new SchoolError('This email or phone already belongs to another ECH account.', 409);
    throw err;
  }
}

module.exports = { SchoolError, publicMember, findStudentDuplicates, attachGuardians, createStudent, createStaff, cleanAddress, parseDate, escapeRegex };
