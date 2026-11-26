/**
 * Service API for eexams: a teacher who created an exam on eexams sends it
 * to the ECH classes they teach. eexams authenticates with the shared
 * ECH_EEXAMS_SSO_SECRET (Authorization: Bearer) and names the teacher with
 * X-ECH-User (their ECH id, known from SSO). The exam then appears on the
 * students' and parents' ECH dashboards with a "Join exam" button.
 */
const Assessment = require('../../models/Assessment');
const ClassSubject = require('../../models/ClassSubject');
const User = require('../../models/User');
const eexams = require('../../services/integrations/eexams.service');
const { teacherLoad, classSubjectAccess } = require('../../services/school/access.service');
const { createAssessmentFor, classStudentIds, guardianIds, eexamsStartPath } = require('./teaching.controller');
const { notifyUsers } = require('../../services/school/notify.service');
const { HttpError, ok, wrap, requireId } = require('./helpers');

const DAY = 24 * 3600 * 1000;

async function serviceTeacher(req) {
  if (!eexams.checkServiceAuth(req)) throw new HttpError('Invalid service credentials', 401);
  const id = String(req.headers['x-ech-user'] || '');
  if (!/^[a-f0-9]{24}$/i.test(id)) throw new HttpError('Missing ECH user', 400);
  const user = await User.findById(id).select('_id fullName role schoolId isActive');
  if (!user || !user.isActive) throw new HttpError('ECH account not found', 404);
  if (!user.schoolId || !['instructor', 'school_admin'].includes(user.role)) {
    throw new HttpError('This ECH account is not a school teacher.', 403);
  }
  return user;
}

function cleanExamId(v) {
  const id = String(v || '').trim();
  if (!/^[A-Za-z0-9_-]{1,64}$/.test(id)) throw new HttpError('Invalid exam id');
  return id;
}

/** GET /integrations/eexams/school/classes — the class subjects this teacher teaches. */
const classes = wrap(async (req, res) => {
  const user = await serviceTeacher(req);
  const load = await teacherLoad(user);
  const roomIds = [...new Set(load.subjects.map((s) => String(s.classroomId._id)))];
  const counts = await User.aggregate([
    { $match: { classroomId: { $in: load.subjects.map((s) => s.classroomId._id) }, role: 'student', isActive: true } },
    { $group: { _id: '$classroomId', n: { $sum: 1 } } },
  ]);
  const size = new Map(counts.map((c) => [String(c._id), c.n]));
  ok(res, {
    teacher: { id: String(user._id), fullName: user.fullName },
    classes: load.subjects.map((s) => ({
      classSubjectId: String(s._id),
      classId: String(s.classroomId._id),
      className: s.classroomId.name,
      level: s.classroomId.level || null,
      subject: s.subject,
      students: size.get(String(s.classroomId._id)) || 0,
    })),
    classCount: roomIds.length,
  });
});

/** The class subject, checked to be taught by this teacher. */
async function taughtClassSubject(user, id) {
  requireId(id, 'class');
  const cs = await ClassSubject.findById(id).populate('classroomId');
  if (!cs || !cs.isActive) throw new HttpError('Class not found', 404);
  const access = await classSubjectAccess(user, cs);
  if (!access.canTeach) throw new HttpError(`You do not teach ${cs.subject} in ${cs.classroomId.name}.`, 403);
  return cs;
}

/** GET /integrations/eexams/school/students?classSubjectId= — the students of a class the teacher teaches. */
const students = wrap(async (req, res) => {
  const user = await serviceTeacher(req);
  const cs = await taughtClassSubject(user, String(req.query.classSubjectId || ''));
  const list = await User.find({ classroomId: cs.classroomId._id, role: 'student', isActive: true })
    .select('fullName studentCode').sort({ fullName: 1 }).lean();
  ok(res, {
    classSubjectId: String(cs._id),
    className: cs.classroomId.name,
    subject: cs.subject,
    students: list.map((s) => ({ id: String(s._id), fullName: s.fullName || 'Student', studentCode: s.studentCode || null })),
  });
});

/** ECH ids of the students an assessment is for (the whole class when not targeted). */
async function audienceIds(a) {
  if (a.studentIds?.length) return a.studentIds.map(String);
  const all = await User.find({ classroomId: a.classroomId, role: 'student', isActive: true }).select('_id').lean();
  return all.map((s) => String(s._id));
}

/** GET /integrations/eexams/school/assignments?examId= — where this exam was already sent. */
const assignments = wrap(async (req, res) => {
  const user = await serviceTeacher(req);
  const examId = cleanExamId(req.query.examId);
  const list = await Assessment.find({ eexamsExamId: examId, teacherId: user._id }).populate('classroomId', 'name').sort({ createdAt: -1 }).lean();
  ok(res, {
    assignments: list.map((a) => ({
      id: String(a._id),
      classSubjectId: String(a.classSubjectId),
      className: a.classroomId?.name || '',
      subject: a.subject,
      type: a.type,
      dueAt: a.dueAt,
      status: a.status,
      forStudents: a.studentIds?.length || 0, // 0 = whole class
      studentIds: (a.studentIds || []).map(String),
    })),
  });
});

/**
 * POST /integrations/eexams/school/assign
 * { examId, title, dueAt, type?: 'exam'|'quiz', maxScore?, instructions?,
 *   targets?: [{ classSubjectId, studentIds?: [ECH student ids] }],   // no studentIds = whole class
 *   classSubjectIds?: [] }                                            // older form: whole classes
 * Sending again to the same class updates the title / due date and adds the
 * new students instead of creating a duplicate. A whole-class send widens a
 * chosen-students one to the whole class.
 * Each result lists studentIds: the ECH ids of everyone the exam is now for,
 * so eexams can show it in those students' exam bank.
 */
const assign = wrap(async (req, res) => {
  const user = await serviceTeacher(req);
  const b = req.body || {};
  const examId = cleanExamId(b.examId);
  const raw = Array.isArray(b.targets) && b.targets.length
    ? b.targets
    : (Array.isArray(b.classSubjectIds) ? b.classSubjectIds.map((id) => ({ classSubjectId: id })) : []);
  const targets = [];
  const seen = new Set();
  for (const t of raw.slice(0, 30)) {
    const id = String(t?.classSubjectId || '');
    if (!id || seen.has(id)) continue;
    seen.add(id);
    targets.push({ classSubjectId: id, studentIds: Array.isArray(t.studentIds) ? t.studentIds.map(String) : [] });
  }
  if (!targets.length) throw new HttpError('Choose at least one class.');
  const title = String(b.title || '').trim().slice(0, 200);
  if (!title) throw new HttpError('The exam needs a title.');
  const dueAt = b.dueAt ? new Date(b.dueAt) : new Date(Date.now() + 7 * DAY);
  if (Number.isNaN(+dueAt) || dueAt < Date.now() - 3600 * 1000) throw new HttpError('Choose a date in the future.');
  const type = b.type === 'quiz' ? 'quiz' : 'exam';

  const created = [];
  const updated = [];
  for (const t of targets) {
    const cs = await taughtClassSubject(user, t.classSubjectId);
    const chosen = await classStudentIds(cs, t.studentIds); // [] = whole class

    const existing = await Assessment.findOne({ classSubjectId: cs._id, eexamsExamId: examId });
    if (existing) {
      const before = new Set((existing.studentIds || []).map(String));
      const wasWholeClass = before.size === 0;
      let added = [];
      if (!wasWholeClass) {
        if (!chosen.length) {
          existing.studentIds = []; // now for the whole class
          added = (await User.find({ classroomId: cs.classroomId._id, role: 'student', isActive: true, _id: { $nin: [...before] } }).select('_id').lean()).map((s) => s._id);
        } else {
          added = chosen.filter((id) => !before.has(String(id)));
          existing.studentIds = [...existing.studentIds, ...added];
        }
      }
      Object.assign(existing, { title, dueAt, type, status: 'published', eexamsPath: eexamsStartPath(examId) });
      if (b.instructions != null) existing.instructions = String(b.instructions).trim().slice(0, 5000);
      await existing.save();
      if (added.length) {
        const newcomers = await User.find({ _id: { $in: added } }).select('_id guardians').lean();
        const label = type === 'quiz' ? 'New quiz' : 'New exam';
        const due = dueAt.toLocaleDateString('en-GB', { weekday: 'short', day: 'numeric', month: 'short' });
        await notifyUsers(newcomers.map((s) => s._id), { title: `${label}: ${cs.subject}`, message: `${title} — due ${due}`, type: 'homework', data: { kind: 'assessment', assessmentId: String(existing._id), route: `/school/homework/${existing._id}` } });
        await notifyUsers(guardianIds(newcomers), { title: `${label} for your child`, message: `${cs.subject}: ${title} — due ${due}`, type: 'homework', data: { kind: 'assessment', assessmentId: String(existing._id) }, push: false });
      }
      updated.push({
        id: String(existing._id), className: cs.classroomId.name, subject: cs.subject,
        notified: added.length, forStudents: existing.studentIds.length, studentIds: await audienceIds(existing),
      });
      continue;
    }
    const { assessment: a, notified } = await createAssessmentFor(user, cs, {
      title,
      dueAt,
      type,
      submissionMode: 'eexams',
      eexamsExamId: examId,
      maxScore: b.maxScore ?? 100,
      instructions: b.instructions || 'Open the exam on eexams. Your result appears here when it is marked.',
      allowLate: false,
      studentIds: chosen.map(String),
    });
    created.push({
      id: String(a._id), className: cs.classroomId.name, subject: cs.subject,
      notified, forStudents: a.studentIds.length, studentIds: await audienceIds(a),
    });
  }
  ok(res, { created, updated }, created.length ? 'Sent' : 'Updated', created.length ? 201 : 200);
});

module.exports = { classes, students, assignments, assign };
