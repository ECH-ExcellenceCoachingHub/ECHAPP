/**
 * School members: staff (school admins, teachers), students and parents.
 */
const User = require('../../models/User');
const Classroom = require('../../models/Classroom');
const ClassSubject = require('../../models/ClassSubject');
const cred = require('../../services/school/credentials.service');
const people = require('../../services/school/people.service');
const { seatsLeft } = require('../../services/school/subscription.service');
const { canManageSchool, isSchoolTeacher, teacherLoad, same } = require('../../services/school/access.service');
const { HttpError, ok, wrap, requireId, schoolFor, paging, pageResult } = require('./helpers');

const STAFF_ROLES = ['instructor', 'school_admin'];

// ── Staff ────────────────────────────────────────────────────────────────

/** GET /schools/:schoolId/staff?role=&search= — teachers and school admins with what they teach. */
const listStaff = wrap(async (req, res) => {
  const school = await schoolFor(req, { manage: false });
  if (!canManageSchool(req.user, school._id) && !isSchoolTeacher(req.user, school._id)) throw new HttpError('Access denied', 403);
  const pg = paging(req.query, { defLimit: 50 });
  const filter = { schoolId: school._id, role: STAFF_ROLES.includes(req.query.role) ? req.query.role : { $in: STAFF_ROLES } };
  if (req.query.active !== 'all') filter.isActive = req.query.active === 'false' ? false : true;
  if (req.query.search) {
    const rx = { $regex: people.escapeRegex(req.query.search), $options: 'i' };
    filter.$or = [{ fullName: rx }, { email: rx }, { phone: rx }];
  }
  const [users, total] = await Promise.all([
    User.find(filter).sort({ role: -1, fullName: 1 }).skip(pg.skip).limit(pg.limit).lean(),
    User.countDocuments(filter),
  ]);
  const ids = users.map((u) => u._id);
  const [classTeacherOf, subjects] = await Promise.all([
    Classroom.find({ classTeacherId: { $in: ids }, isActive: true }).select('name classTeacherId').lean(),
    ClassSubject.find({ teacherId: { $in: ids }, isActive: true }).populate('classroomId', 'name isActive').lean(),
  ]);
  const items = users.map((u) => ({
    ...people.publicMember(u),
    classTeacherOf: classTeacherOf.filter((c) => same(c.classTeacherId, u._id)).map((c) => ({ id: String(c._id), name: c.name })),
    teaches: subjects.filter((s) => same(s.teacherId, u._id) && s.classroomId?.isActive !== false)
      .map((s) => ({ id: String(s._id), subject: s.subject, classroomId: String(s.classroomId?._id), className: s.classroomId?.name })),
  }));
  ok(res, pageResult(items, total, pg, 'staff'));
});

const addStaff = (role) => wrap(async (req, res) => {
  const school = await schoolFor(req);
  if (!school.isActive) throw new HttpError('This school is deactivated.', 403);
  const created = await people.createStaff({ school, actor: req.user, role, data: req.body || {} });
  ok(res, created, role === 'instructor' ? 'Teacher added' : 'School admin added', 201);
});

// ── Students ─────────────────────────────────────────────────────────────

/** Classes whose students the caller may see; null means the whole school. */
async function visibleClassIds(user, schoolId) {
  if (canManageSchool(user, schoolId)) return null;
  if (!isSchoolTeacher(user, schoolId)) throw new HttpError('Access denied', 403);
  const load = await teacherLoad(user);
  return [...new Set([...load.classTeacherOf.map((c) => String(c._id)), ...load.subjects.map((s) => String(s.classroomId._id))])];
}

/** Class teacher (or admin) of the target class may manage its roster. */
async function assertRosterRight(user, school, classroomId) {
  requireId(classroomId, 'class id');
  const room = await Classroom.findOne({ _id: classroomId, schoolId: school._id, isActive: true }).lean();
  if (!room) throw new HttpError('Class not found in this school.', 404);
  if (canManageSchool(user, school._id)) return room;
  if (isSchoolTeacher(user, school._id) && same(room.classTeacherId, user._id)) return room;
  throw new HttpError('Only the class teacher or the school administration can add students to this class.', 403);
}

/** GET /schools/:schoolId/students?classId=&search=&active= */
const listStudents = wrap(async (req, res) => {
  const school = await schoolFor(req, { manage: false });
  const allowed = await visibleClassIds(req.user, school._id);
  const pg = paging(req.query, { defLimit: 50, maxLimit: 500 });
  const filter = { schoolId: school._id, role: 'student' };
  if (req.query.active !== 'all') filter.isActive = req.query.active === 'false' ? false : true;
  if (req.query.classId) {
    if (allowed && !allowed.includes(String(req.query.classId))) throw new HttpError('You do not teach this class.', 403);
    filter.classroomId = requireId(req.query.classId, 'class id');
  } else if (req.query.unassigned === 'true') {
    filter.classroomId = null;
  } else if (allowed) {
    filter.classroomId = { $in: allowed };
  }
  if (req.query.search) {
    const rx = { $regex: people.escapeRegex(req.query.search), $options: 'i' };
    filter.$or = [{ fullName: rx }, { studentCode: { $regex: people.escapeRegex(cred.normalizeCode(req.query.search)) || '^$', $options: 'i' } }];
  }
  const [students, total] = await Promise.all([
    User.find(filter).populate('classroomId', 'name level').sort({ fullName: 1 }).skip(pg.skip).limit(pg.limit).lean(),
    User.countDocuments(filter),
  ]);
  ok(res, pageResult(students.map(people.publicMember), total, pg, 'students'));
});

/** GET /schools/:schoolId/students/lookup?q= — find an existing student before registering (by code or name). */
const lookupStudents = wrap(async (req, res) => {
  const school = await schoolFor(req, { manage: false });
  if (!canManageSchool(req.user, school._id) && !isSchoolTeacher(req.user, school._id)) throw new HttpError('Access denied', 403);
  const q = String(req.query.q || '').trim();
  if (q.length < 2) return ok(res, { students: [] });
  const code = cred.normalizeCode(q);
  const rx = { $regex: people.escapeRegex(q), $options: 'i' };
  const students = await User.find({
    schoolId: school._id,
    role: 'student',
    $or: [{ fullName: rx }, ...(code.length >= 4 ? [{ studentCode: code }] : [])],
  }).populate('classroomId', 'name level').limit(20).lean();
  ok(res, { students: students.map(people.publicMember) });
});

/** POST /schools/:schoolId/students — admin or class teacher of body.classroomId. 409 POSSIBLE_DUPLICATE asks to confirm. */
const addStudent = wrap(async (req, res) => {
  const school = await schoolFor(req, { manage: false });
  if (!school.isActive) throw new HttpError('This school is deactivated.', 403);
  await assertRosterRight(req.user, school, req.body?.classroomId);
  const created = await people.createStudent({ school, actor: req.user, data: req.body || {} });
  ok(res, created, 'Student registered', 201);
});

/**
 * POST /schools/:schoolId/students/import { classroomId, students: [{ fullName, gender, dateOfBirth, guardians }] }
 * Registers many students; rows that look like duplicates are returned, not created.
 */
const importStudents = wrap(async (req, res) => {
  const school = await schoolFor(req, { manage: false });
  if (!school.isActive) throw new HttpError('This school is deactivated.', 403);
  const classroomId = req.body?.classroomId;
  await assertRosterRight(req.user, school, classroomId);
  const rows = Array.isArray(req.body?.students) ? req.body.students.slice(0, 500) : [];
  if (!rows.length) throw new HttpError('No students to import');
  const results = [];
  for (const [i, row] of rows.entries()) {
    try {
      const r = await people.createStudent({ school, actor: req.user, data: { ...row, classroomId, confirmNew: !!row.confirmNew } });
      results.push({ row: i + 1, ok: true, ...r });
    } catch (e) {
      results.push({ row: i + 1, ok: false, fullName: row.fullName, message: e.message, code: e.extra?.code, candidates: e.extra?.candidates });
      if (e.extra?.code === 'STUDENT_LIMIT_REACHED') break;
    }
  }
  ok(res, { results, created: results.filter((r) => r.ok).length, failed: results.filter((r) => !r.ok).length }, 'Import finished');
});

/** POST /schools/:schoolId/students/:userId/enroll { classroomId } — put an existing student in a class. */
const enrollExistingStudent = wrap(async (req, res) => {
  const school = await schoolFor(req, { manage: false });
  const room = await assertRosterRight(req.user, school, req.body?.classroomId);
  requireId(req.params.userId, 'student id');
  const student = await User.findOne({ _id: req.params.userId, schoolId: school._id, role: 'student' });
  if (!student) throw new HttpError('Student not found in this school.', 404);
  const manager = canManageSchool(req.user, school._id);
  if (!manager && student.classroomId && !same(student.classroomId, room._id)) {
    throw new HttpError('This student is already in another class. Ask the school administration to move them.', 403);
  }
  if (!student.isActive) {
    const seats = await seatsLeft(school);
    if (seats.left <= 0) throw new HttpError('All paid student places are used.', 403, { code: 'STUDENT_LIMIT_REACHED' });
    student.isActive = true;
  }
  student.classroomId = room._id;
  await student.save();
  await student.populate('classroomId', 'name level');
  ok(res, { student: people.publicMember(student) }, `Student added to ${room.name}`);
});

// ── Any member ───────────────────────────────────────────────────────────

async function memberFor(req, school) {
  requireId(req.params.userId, 'user id');
  const user = await User.findOne({ _id: req.params.userId, schoolId: school._id });
  if (!user) throw new HttpError('Member not found in this school.', 404);
  return user;
}

/** GET /schools/:schoolId/members/:userId */
const getMember = wrap(async (req, res) => {
  const school = await schoolFor(req, { manage: false });
  const user = await memberFor(req, school);
  if (!canManageSchool(req.user, school._id)) {
    const allowed = await visibleClassIds(req.user, school._id);
    if (user.role !== 'student' || !allowed.includes(String(user.classroomId))) throw new HttpError('Access denied', 403);
  }
  await user.populate('classroomId', 'name level');
  ok(res, { member: people.publicMember(user) });
});

/**
 * PATCH /schools/:schoolId/members/:userId
 * School admin: everything. Class teacher: their own students' details (not class moves).
 */
const updateMember = wrap(async (req, res) => {
  const school = await schoolFor(req, { manage: false });
  const user = await memberFor(req, school);
  const manager = canManageSchool(req.user, school._id);
  if (!manager) {
    const room = user.classroomId ? await Classroom.findById(user.classroomId).lean() : null;
    if (user.role !== 'student' || !room || !same(room.classTeacherId, req.user._id)) throw new HttpError('Only the school administration can edit this member.', 403);
  }
  if (user.role === 'school_admin' && same(school.admin, user._id) && req.body.isActive === false) {
    throw new HttpError('Choose another main school admin before deactivating this one.');
  }
  const b = req.body || {};
  if (b.fullName !== undefined) {
    if (String(b.fullName).trim().length < 3) throw new HttpError('Enter the full name.');
    user.fullName = String(b.fullName).trim();
  }
  if (b.phone !== undefined && user.role !== 'parent') {
    const phone = cred.normalizePhone(b.phone);
    if (phone && await User.exists({ phone, _id: { $ne: user._id } })) throw new HttpError('This phone number is used by another account.', 409);
    user.phone = phone || undefined;
  }
  if (b.gender !== undefined) user.gender = ['male', 'female', 'other'].includes(b.gender) ? b.gender : null;
  if (b.dateOfBirth !== undefined) user.dateOfBirth = people.parseDate(b.dateOfBirth);
  if (b.address !== undefined) user.address = people.cleanAddress(b.address);
  if (b.teacherProfile && STAFF_ROLES.includes(user.role)) {
    const p = b.teacherProfile;
    const tp = user.teacherProfile || {};
    if (p.qualification !== undefined) tp.qualification = String(p.qualification).trim();
    if (p.yearsExperience !== undefined) tp.yearsExperience = Number(p.yearsExperience) || 0;
    if (Array.isArray(p.subjects)) tp.subjects = p.subjects.map((s) => String(s).trim()).filter(Boolean).slice(0, 20);
    if (Array.isArray(p.levels)) tp.levels = p.levels.map((s) => String(s).trim()).filter(Boolean).slice(0, 20);
    user.teacherProfile = tp;
  }
  let parents = [];
  let warnings = [];
  if (Array.isArray(b.guardians) && user.role === 'student') {
    const r = await people.attachGuardians(user, b.guardians, { actorId: req.user._id });
    parents = r.parents;
    warnings = r.warnings;
  }
  if (manager && b.classroomId !== undefined && user.role === 'student') {
    if (b.classroomId) {
      const room = await Classroom.findOne({ _id: requireId(b.classroomId, 'class id'), schoolId: school._id, isActive: true });
      if (!room) throw new HttpError('Class not found', 404);
      user.classroomId = room._id;
    } else {
      user.classroomId = null;
    }
  }
  if (manager && b.isActive !== undefined) {
    const activate = !!b.isActive;
    if (activate && !user.isActive && user.role === 'student') {
      const seats = await seatsLeft(school);
      if (seats.left <= 0) throw new HttpError('All paid student places are used.', 403, { code: 'STUDENT_LIMIT_REACHED' });
    }
    user.isActive = activate;
    if (!activate) {
      user.activeSessionId = null;
      if (user.role === 'instructor') {
        await Promise.all([
          Classroom.updateMany({ classTeacherId: user._id }, { classTeacherId: null }),
          ClassSubject.updateMany({ teacherId: user._id }, { teacherId: null }),
        ]);
      }
    }
  }
  await user.save();
  await user.populate('classroomId', 'name level');
  ok(res, { member: people.publicMember(user), parents, warnings }, 'Saved');
});

/**
 * POST /schools/:schoolId/members/:userId/reset-credentials
 * Students/parents get a new PIN, staff a new password. Signs them out everywhere.
 */
const resetCredentials = wrap(async (req, res) => {
  const school = await schoolFor(req, { manage: false });
  const user = await memberFor(req, school);
  const manager = canManageSchool(req.user, school._id);
  if (!manager) {
    const room = user.classroomId ? await Classroom.findById(user.classroomId).lean() : null;
    if (user.role !== 'student' || !room || !same(room.classTeacherId, req.user._id)) throw new HttpError('Only the school administration can reset this account.', 403);
  }
  const target = await User.findById(user._id).select('+pinHash +pinFailedCount +pinLockedUntil +activeSessionId +password');
  let credentials;
  if (['student', 'parent'].includes(target.role)) {
    const pin = cred.generatePin();
    target.pinHash = await cred.hashPin(pin);
    target.pinFailedCount = 0;
    target.pinLockedUntil = null;
    credentials = target.role === 'student' ? { studentCode: target.studentCode, pin } : { phone: target.phone, pin };
  } else {
    const password = req.body?.password && String(req.body.password).length >= 8 ? String(req.body.password) : cred.generatePassword();
    if (target.firebaseUid && !target.firebaseUid.startsWith('ech-')) await cred.setFirebasePassword(target.firebaseUid, password);
    target.password = password;
    credentials = { email: target.email || null, phone: target.phone || null, password };
  }
  target.activeSessionId = null;
  await target.save();
  if (target.firebaseUid) {
    try { await require('../../config/firebase').auth().revokeRefreshTokens(target.firebaseUid); } catch (_) { /* uid not created yet */ }
  }
  ok(res, { credentials }, 'New sign-in details created');
});

/** Parents of the school's students (school admin). */
const listParents = wrap(async (req, res) => {
  const school = await schoolFor(req);
  const pg = paging(req.query, { defLimit: 50 });
  const students = await User.find({ schoolId: school._id, role: 'student', 'guardians.userId': { $ne: null } }).select('fullName guardians classroomId').populate('classroomId', 'name').lean();
  const byParent = new Map();
  for (const s of students) {
    for (const g of s.guardians || []) {
      if (!g.userId) continue;
      const k = String(g.userId);
      if (!byParent.has(k)) byParent.set(k, { id: k, name: g.name, phone: g.phone, children: [] });
      byParent.get(k).children.push({ id: String(s._id), fullName: s.fullName, className: s.classroomId?.name || null, relationship: g.relationship });
    }
  }
  let list = [...byParent.values()];
  if (req.query.search) {
    const q = String(req.query.search).toLowerCase();
    list = list.filter((p) => (p.name || '').toLowerCase().includes(q) || (p.phone || '').includes(q));
  }
  list.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
  ok(res, pageResult(list.slice(pg.skip, pg.skip + pg.limit), list.length, pg, 'parents'));
});

/** POST /schools/:schoolId/parents/:userId/reset-pin — a parent of one of the school's students. */
const resetParentPin = wrap(async (req, res) => {
  const school = await schoolFor(req);
  requireId(req.params.userId, 'parent id');
  const isParentHere = await User.exists({ schoolId: school._id, role: 'student', 'guardians.userId': req.params.userId });
  if (!isParentHere) throw new HttpError('Parent not found in this school.', 404);
  const parent = await User.findOne({ _id: req.params.userId, role: 'parent' }).select('+pinHash +pinFailedCount +pinLockedUntil');
  if (!parent) throw new HttpError('Parent not found', 404);
  const pin = cred.generatePin();
  parent.pinHash = await cred.hashPin(pin);
  parent.pinFailedCount = 0;
  parent.pinLockedUntil = null;
  await parent.save();
  ok(res, { credentials: { phone: parent.phone, pin } }, 'New PIN created');
});

/** PATCH /schools/:schoolId/main-admin { userId } — super admin picks the main school admin. */
const setMainAdmin = wrap(async (req, res) => {
  const school = await schoolFor(req);
  if (req.user.role !== 'admin') throw new HttpError('Only ECH can change the main school admin.', 403);
  requireId(req.body?.userId, 'user id');
  const u = await User.findOne({ _id: req.body.userId, schoolId: school._id, role: 'school_admin', isActive: true });
  if (!u) throw new HttpError('Choose an active school admin of this school.', 404);
  school.admin = u._id;
  await school.save();
  ok(res, { adminId: String(u._id) }, 'Main school admin changed');
});

module.exports = {
  listStaff,
  addTeacher: addStaff('instructor'),
  addSchoolAdmin: addStaff('school_admin'),
  listStudents,
  lookupStudents,
  addStudent,
  importStudents,
  enrollExistingStudent,
  getMember,
  updateMember,
  resetCredentials,
  listParents,
  resetParentPin,
  setMainAdmin,
  visibleClassIds,
};
