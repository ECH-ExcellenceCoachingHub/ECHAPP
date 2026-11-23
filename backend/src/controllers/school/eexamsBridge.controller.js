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
const { createAssessmentFor, eexamsStartPath } = require('./teaching.controller');
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
    })),
  });
});

/**
 * POST /integrations/eexams/school/assign
 * { examId, title, classSubjectIds[], dueAt, type?: 'exam'|'quiz', maxScore?, instructions? }
 * Sending again to the same class updates the title / due date instead of
 * creating a duplicate.
 */
const assign = wrap(async (req, res) => {
  const user = await serviceTeacher(req);
  const b = req.body || {};
  const examId = cleanExamId(b.examId);
  const ids = Array.isArray(b.classSubjectIds) ? [...new Set(b.classSubjectIds.map(String))].slice(0, 30) : [];
  if (!ids.length) throw new HttpError('Choose at least one class.');
  const title = String(b.title || '').trim().slice(0, 200);
  if (!title) throw new HttpError('The exam needs a title.');
  const dueAt = b.dueAt ? new Date(b.dueAt) : new Date(Date.now() + 7 * DAY);
  if (Number.isNaN(+dueAt) || dueAt < Date.now() - 3600 * 1000) throw new HttpError('Choose a date in the future.');
  const type = b.type === 'quiz' ? 'quiz' : 'exam';

  const created = [];
  const updated = [];
  for (const id of ids) {
    requireId(id, 'class');
    const cs = await ClassSubject.findById(id).populate('classroomId');
    if (!cs || !cs.isActive) throw new HttpError('Class not found', 404);
    const access = await classSubjectAccess(user, cs);
    if (!access.canTeach) throw new HttpError(`You do not teach ${cs.subject} in ${cs.classroomId.name}.`, 403);

    const existing = await Assessment.findOne({ classSubjectId: cs._id, eexamsExamId: examId });
    if (existing) {
      Object.assign(existing, { title, dueAt, type, status: 'published', eexamsPath: eexamsStartPath(examId) });
      if (b.instructions != null) existing.instructions = String(b.instructions).trim().slice(0, 5000);
      await existing.save();
      updated.push({ id: String(existing._id), className: cs.classroomId.name, subject: cs.subject });
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
    });
    created.push({ id: String(a._id), className: cs.classroomId.name, subject: cs.subject, notified });
  }
  ok(res, { created, updated }, created.length ? 'Sent to the class' : 'Updated', created.length ? 201 : 200);
});

module.exports = { classes, assignments, assign };
