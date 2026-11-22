/**
 * Classes (streams + combinations) and who teaches which subject in them.
 */
const Classroom = require('../../models/Classroom');
const ClassSubject = require('../../models/ClassSubject');
const SchoolTerm = require('../../models/SchoolTerm');
const User = require('../../models/User');
const Course = require('../../models/Course');
const { publicMember } = require('../../services/school/people.service');
const { classroomAccess, canManageSchool } = require('../../services/school/access.service');
const { HttpError, ok, wrap, requireId, schoolFor } = require('./helpers');

async function defaultAcademicYear(schoolId) {
  const now = new Date();
  const term = await SchoolTerm.findOne({ schoolId, startDate: { $lte: now }, endDate: { $gte: now } }).lean()
    || await SchoolTerm.findOne({ schoolId }).sort({ startDate: -1 }).lean();
  return term ? term.academicYear : String(now.getFullYear());
}

async function assertSchoolTeacher(schoolId, teacherId) {
  if (!teacherId) return null;
  requireId(teacherId, 'teacher id');
  const t = await User.findOne({ _id: teacherId, schoolId, role: { $in: ['instructor', 'school_admin'] }, isActive: true }).select('_id').lean();
  if (!t) throw new HttpError('This teacher is not an active member of your school.', 400);
  return t._id;
}

function classView(c, extra = {}) {
  return {
    id: String(c._id),
    schoolId: String(c.schoolId),
    academicYear: c.academicYear,
    level: c.level,
    combination: c.combination || '',
    stream: c.stream || '',
    name: c.name,
    room: c.room || null,
    capacity: c.capacity ?? null,
    isActive: c.isActive !== false,
    classTeacher: c.classTeacherId && c.classTeacherId.fullName
      ? { id: String(c.classTeacherId._id), fullName: c.classTeacherId.fullName }
      : null,
    classTeacherId: c.classTeacherId ? String(c.classTeacherId._id || c.classTeacherId) : null,
    ...extra,
  };
}

function subjectView(s) {
  return {
    id: String(s._id),
    classroomId: String(s.classroomId._id || s.classroomId),
    subject: s.subject,
    teacher: s.teacherId && s.teacherId.fullName ? { id: String(s.teacherId._id), fullName: s.teacherId.fullName } : null,
    teacherId: s.teacherId ? String(s.teacherId._id || s.teacherId) : null,
    course: s.courseId && s.courseId.title ? { id: String(s.courseId._id), title: s.courseId.title } : null,
    courseId: s.courseId ? String(s.courseId._id || s.courseId) : null,
    periodsPerWeek: s.periodsPerWeek ?? null,
  };
}

/** GET /schools/:schoolId/classes — all classes with student counts and subjects. */
const listClasses = wrap(async (req, res) => {
  const school = await schoolFor(req, { manage: false });
  const filter = { schoolId: school._id };
  if (req.query.academicYear) filter.academicYear = String(req.query.academicYear);
  if (req.query.includeInactive !== 'true') filter.isActive = true;
  if (req.query.level) filter.level = String(req.query.level).toUpperCase();
  const classes = await Classroom.find(filter).populate('classTeacherId', 'fullName').sort({ level: 1, combination: 1, stream: 1 }).lean();
  const ids = classes.map((c) => c._id);
  const [counts, subjects] = await Promise.all([
    User.aggregate([{ $match: { classroomId: { $in: ids }, role: 'student', isActive: true } }, { $group: { _id: '$classroomId', n: { $sum: 1 } } }]),
    ClassSubject.find({ classroomId: { $in: ids }, isActive: true }).populate('teacherId', 'fullName').populate('courseId', 'title').lean(),
  ]);
  const countMap = new Map(counts.map((c) => [String(c._id), c.n]));
  ok(res, {
    classes: classes.map((c) => classView(c, {
      studentCount: countMap.get(String(c._id)) || 0,
      subjects: subjects.filter((s) => String(s.classroomId) === String(c._id)).map(subjectView),
    })),
  });
});

/**
 * POST /schools/:schoolId/classes
 * { level, combination?, stream? | streams?: ['A','B'], academicYear?, classTeacherId?, room?, capacity? }
 * `streams` creates several streams of one level at once (S3 A, S3 B, S3 C).
 */
const createClasses = wrap(async (req, res) => {
  const school = await schoolFor(req);
  const b = req.body || {};
  const level = String(b.level || '').trim().toUpperCase();
  if (!level) throw new HttpError('Choose the level (e.g. S3)');
  const combination = String(b.combination || '').trim().toUpperCase();
  const academicYear = String(b.academicYear || await defaultAcademicYear(school._id)).trim();
  const streams = Array.isArray(b.streams) && b.streams.length
    ? [...new Set(b.streams.map((s) => String(s).trim().toUpperCase()))]
    : [String(b.stream || '').trim().toUpperCase()];
  if (streams.length > 1 && b.classTeacherId) throw new HttpError('Set the class teacher on each stream separately.');
  const classTeacherId = await assertSchoolTeacher(school._id, b.classTeacherId);

  if (combination && !school.combinations.includes(combination)) {
    school.combinations.push(combination);
  }
  if (!school.levels.includes(level)) school.levels.push(level);
  await school.save();

  const created = [];
  const skipped = [];
  for (const stream of streams) {
    const exists = await Classroom.findOne({ schoolId: school._id, academicYear, level, combination, stream });
    if (exists) { skipped.push(exists.name); continue; }
    created.push(await Classroom.create({
      schoolId: school._id, academicYear, level, combination, stream,
      classTeacherId, room: b.room, capacity: b.capacity,
    }));
  }
  if (!created.length) throw new HttpError(`${skipped.join(', ')} already exists for ${academicYear}.`, 409);
  ok(res, { classes: created.map((c) => classView(c)), skipped }, `${created.length} class${created.length > 1 ? 'es' : ''} created`, 201);
});

/** GET /classes/:classId — class detail (roster + subjects) for anyone allowed to view it. */
const getClass = wrap(async (req, res) => {
  requireId(req.params.classId, 'class id');
  const c = await Classroom.findById(req.params.classId).populate('classTeacherId', 'fullName email phone');
  if (!c) throw new HttpError('Class not found', 404);
  const access = await classroomAccess(req.user, c);
  if (!access.canView) throw new HttpError('You do not teach this class.', 403);
  const [students, subjects] = await Promise.all([
    User.find({ classroomId: c._id, role: 'student', isActive: req.query.includeInactive === 'true' ? { $in: [true, false] } : true })
      .select('fullName studentCode gender dateOfBirth guardians isActive lastActive classroomId schoolId role createdAt')
      .sort({ fullName: 1 }).lean(),
    ClassSubject.find({ classroomId: c._id, isActive: true }).populate('teacherId', 'fullName').populate('courseId', 'title').sort({ subject: 1 }).lean(),
  ]);
  ok(res, {
    class: classView(c.toObject(), { studentCount: students.length }),
    students: students.map(publicMember),
    subjects: subjects.map(subjectView),
    access: { canManageRoster: access.canManageRoster, isClassTeacher: !!access.isClassTeacher, isAdmin: !!access.isAdmin, mySubjects: (access.subjects || []).map((s) => String(s._id)) },
  });
});

/** PATCH /classes/:classId — school admin: names, class teacher, room, active. */
const updateClass = wrap(async (req, res) => {
  requireId(req.params.classId, 'class id');
  const c = await Classroom.findById(req.params.classId);
  if (!c) throw new HttpError('Class not found', 404);
  if (!canManageSchool(req.user, c.schoolId)) throw new HttpError('Only the school administration can edit classes.', 403);
  const b = req.body || {};
  for (const f of ['level', 'combination', 'stream']) if (b[f] !== undefined) c[f] = String(b[f]).trim().toUpperCase();
  if (b.academicYear !== undefined) c.academicYear = String(b.academicYear).trim();
  if (b.room !== undefined) c.room = b.room;
  if (b.capacity !== undefined) c.capacity = b.capacity === null ? undefined : +b.capacity;
  if (b.classTeacherId !== undefined) c.classTeacherId = b.classTeacherId ? await assertSchoolTeacher(c.schoolId, b.classTeacherId) : null;
  if (b.isActive !== undefined) c.isActive = !!b.isActive;
  await c.save();
  await c.populate('classTeacherId', 'fullName');
  ok(res, { class: classView(c.toObject()) }, 'Class updated');
});

/** DELETE /classes/:classId — removes an empty class, otherwise deactivates it. */
const deleteClass = wrap(async (req, res) => {
  requireId(req.params.classId, 'class id');
  const c = await Classroom.findById(req.params.classId);
  if (!c) throw new HttpError('Class not found', 404);
  if (!canManageSchool(req.user, c.schoolId)) throw new HttpError('Only the school administration can remove classes.', 403);
  const hasStudents = await User.exists({ classroomId: c._id, role: 'student', isActive: true });
  if (hasStudents) throw new HttpError('Move the students to another class first.');
  const Assessment = require('../../models/Assessment');
  const LessonCoverage = require('../../models/LessonCoverage');
  const hasHistory = await User.exists({ classroomId: c._id }) || await Assessment.exists({ classroomId: c._id }) || await LessonCoverage.exists({ classroomId: c._id });
  if (hasHistory) {
    c.isActive = false;
    await c.save();
    return ok(res, { id: String(c._id), isActive: false }, 'Class archived (it has history)');
  }
  await ClassSubject.deleteMany({ classroomId: c._id });
  await c.deleteOne();
  ok(res, { id: String(c._id) }, 'Class removed');
});

/** POST /classes/:classId/subjects { subject, teacherId?, courseId?, periodsPerWeek? } — or { subjects: [...] }. */
const addSubjects = wrap(async (req, res) => {
  requireId(req.params.classId, 'class id');
  const c = await Classroom.findById(req.params.classId);
  if (!c) throw new HttpError('Class not found', 404);
  if (!canManageSchool(req.user, c.schoolId)) throw new HttpError('Only the school administration can assign subjects.', 403);
  const list = Array.isArray(req.body.subjects) ? req.body.subjects : [req.body];
  const created = [];
  const errors = [];
  for (const item of list) {
    const subject = String(item.subject || '').trim();
    if (!subject) { errors.push('A subject name is missing'); continue; }
    try {
      const teacherId = await assertSchoolTeacher(c.schoolId, item.teacherId);
      let courseId = null;
      if (item.courseId) {
        requireId(item.courseId, 'course id');
        if (!(await Course.exists({ _id: item.courseId }))) throw new HttpError(`Course for ${subject} not found`, 404);
        courseId = item.courseId;
      }
      const existing = await ClassSubject.findOne({ classroomId: c._id, subject: { $regex: `^${subject.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, $options: 'i' } });
      if (existing && existing.isActive) { errors.push(`${subject} is already taught in ${c.name}`); continue; }
      const doc = existing || new ClassSubject({ schoolId: c.schoolId, classroomId: c._id, subject });
      Object.assign(doc, { teacherId, courseId, periodsPerWeek: item.periodsPerWeek, isActive: true });
      await doc.save();
      created.push(doc);
    } catch (e) {
      errors.push(e.message);
    }
  }
  if (!created.length) throw new HttpError(errors[0] || 'Nothing to add');
  const docs = await ClassSubject.find({ _id: { $in: created.map((d) => d._id) } }).populate('teacherId', 'fullName').populate('courseId', 'title').lean();
  ok(res, { subjects: docs.map(subjectView), errors }, 'Subjects assigned', 201);
});

/** PATCH /class-subjects/:id { teacherId?, courseId?, periodsPerWeek? } */
const updateSubject = wrap(async (req, res) => {
  requireId(req.params.id, 'id');
  const s = await ClassSubject.findById(req.params.id);
  if (!s) throw new HttpError('Subject not found', 404);
  if (!canManageSchool(req.user, s.schoolId)) throw new HttpError('Only the school administration can change this.', 403);
  const b = req.body || {};
  if (b.teacherId !== undefined) s.teacherId = b.teacherId ? await assertSchoolTeacher(s.schoolId, b.teacherId) : null;
  if (b.courseId !== undefined) {
    if (b.courseId) { requireId(b.courseId, 'course id'); if (!(await Course.exists({ _id: b.courseId }))) throw new HttpError('Course not found', 404); }
    s.courseId = b.courseId || null;
  }
  if (b.periodsPerWeek !== undefined) s.periodsPerWeek = b.periodsPerWeek;
  if (b.subject !== undefined && String(b.subject).trim()) s.subject = String(b.subject).trim();
  await s.save();
  await s.populate('teacherId', 'fullName');
  await s.populate('courseId', 'title');
  ok(res, { subject: subjectView(s.toObject()) }, 'Subject updated');
});

/** DELETE /class-subjects/:id — deactivates (history of coverage/homework is kept). */
const removeSubject = wrap(async (req, res) => {
  requireId(req.params.id, 'id');
  const s = await ClassSubject.findById(req.params.id);
  if (!s) throw new HttpError('Subject not found', 404);
  if (!canManageSchool(req.user, s.schoolId)) throw new HttpError('Only the school administration can change this.', 403);
  s.isActive = false;
  await s.save();
  ok(res, { id: String(s._id) }, 'Subject removed from class');
});

module.exports = { listClasses, createClasses, getClass, updateClass, deleteClass, addSubjects, updateSubject, removeSubject, classView, subjectView, defaultAcademicYear };
