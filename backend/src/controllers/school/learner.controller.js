/**
 * Student and parent portal.
 */
const School = require('../../models/School');
const Classroom = require('../../models/Classroom');
const ClassSubject = require('../../models/ClassSubject');
const Assessment = require('../../models/Assessment');
const AssessmentSubmission = require('../../models/AssessmentSubmission');
const LessonCoverage = require('../../models/LessonCoverage');
const Lesson = require('../../models/Lesson');
const Enrollment = require('../../models/Enrollment');
const User = require('../../models/User');
const flagsSvc = require('../../services/school/coverageFlags.service');
const { subscriptionStatus, coursesForClass } = require('../../services/school/subscription.service');
const { assessmentView, submissionView, cleanAttachments } = require('./teaching.controller');
const eexams = require('../../services/integrations/eexams.service');
const { HttpError, ok, wrap, requireId } = require('./helpers');

const DAY = 24 * 3600 * 1000;
const CHECK_WINDOW_DAYS = 14;

function requireSchoolStudent(user) {
  if (user.role !== 'student' || !user.schoolId) throw new HttpError('This is for school students.', 403);
  if (!user.classroomId) throw new HttpError('You are not in a class yet. Ask your class teacher.', 404);
}

/** Everything about one student's school life (used by the student and by parents). */
async function studentOverview(student, { forParent = false } = {}) {
  const [school, classroom, subjects] = await Promise.all([
    School.findById(student.schoolId).select('name code logo isActive graceDays').lean(),
    student.classroomId ? Classroom.findById(student.classroomId).populate('classTeacherId', 'fullName phone').lean() : null,
    student.classroomId ? ClassSubject.find({ classroomId: student.classroomId, isActive: true }).populate('teacherId', 'fullName').sort({ subject: 1 }).lean() : [],
  ]);
  const assessments = classroom
    ? await Assessment.find({ classroomId: classroom._id, createdAt: { $gte: new Date(Date.now() - 180 * DAY) }, ...Assessment.visibleTo(student._id) }).populate('teacherId', 'fullName').sort({ dueAt: 1 }).lean()
    : [];
  const subs = await AssessmentSubmission.find({ studentId: student._id, assessmentId: { $in: assessments.map((a) => a._id) } }).lean();
  const subMap = new Map(subs.map((s) => [String(s.assessmentId), s]));
  const now = Date.now();

  const withState = assessments.map((a) => {
    const s = subMap.get(String(a._id));
    let state;
    if (s) state = s.status === 'graded' ? 'graded' : 'submitted';
    else if (a.submissionMode === 'none') state = new Date(a.dueAt) < now ? 'done' : 'todo';
    else if (new Date(a.dueAt) < now) state = a.allowLate && a.status === 'published' ? 'overdue' : 'missed';
    else state = a.status === 'closed' ? 'missed' : 'todo';
    return assessmentView(a, { state, submission: s ? submissionView(s) : null });
  });

  // Progress per subject (lessons marked taught vs syllabus size).
  const csIds = subjects.map((s) => s._id);
  const covAgg = csIds.length ? await LessonCoverage.aggregate([
    { $match: { classSubjectId: { $in: csIds }, status: { $ne: 'confirmed' } } },
    { $group: { _id: '$classSubjectId', n: { $sum: 1 }, last: { $max: '$taughtOn' } } },
  ]) : [];
  const covMap = new Map(covAgg.map((c) => [String(c._id), c]));
  const subjectViews = [];
  for (const s of subjects) {
    const total = s.courseId ? await Lesson.countDocuments({ courseId: s.courseId }) : 0;
    const c = covMap.get(String(s._id));
    const graded = withState.filter((a) => String(a.classSubjectId) === String(s._id) && a.submission?.status === 'graded' && a.maxScore > 0);
    const avg = graded.length ? Math.round(graded.reduce((n, a) => n + (a.submission.score / a.maxScore) * 100, 0) / graded.length) : null;
    subjectViews.push({
      id: String(s._id),
      subject: s.subject,
      teacher: s.teacherId ? { id: String(s.teacherId._id), fullName: s.teacherId.fullName } : null,
      courseId: s.courseId ? String(s.courseId) : null,
      lessonsTaught: c?.n || 0,
      syllabusLessons: total,
      coveragePercent: total ? Math.min(100, Math.round(((c?.n || 0) / total) * 100)) : null,
      lastTaughtOn: c?.last || null,
      averagePercent: avg,
    });
  }

  let lessonChecks = [];
  if (!forParent && classroom) {
    const recent = await LessonCoverage.find({
      classroomId: classroom._id,
      taughtOn: { $gte: new Date(now - CHECK_WINDOW_DAYS * DAY), $lte: new Date(now) },
      'studentChecks.studentId': { $ne: student._id },
      status: { $ne: 'confirmed' },
    }).sort({ taughtOn: -1 }).limit(5).lean();
    lessonChecks = recent.map((c) => ({ id: String(c._id), subject: c.subject, topic: c.topic, taughtOn: c.taughtOn }));
  }

  const sub = school ? await subscriptionStatus(school._id) : null;
  // ECH courses for this class: free while the school's term is paid.
  const classCourses = forParent || !classroom ? [] : await coursesForClass(classroom);
  // Lesson counts and the student's own progress, so the app can show
  // "continue where you left off".
  const courseIds = classCourses.map((c) => c._id);
  const [lessonCounts, enrollments] = courseIds.length
    ? await Promise.all([
        Lesson.aggregate([{ $match: { courseId: { $in: courseIds } } }, { $group: { _id: '$courseId', n: { $sum: 1 } } }]),
        Enrollment.find({ userId: student._id, courseId: { $in: courseIds } }).select('courseId progress completionStatus updatedAt').lean(),
      ])
    : [[], []];
  const lessonsBy = new Map(lessonCounts.map((l) => [String(l._id), l.n]));
  const enrolledBy = new Map(enrollments.map((e) => [String(e.courseId), e]));
  const courses = classCourses.map((c) => {
    const e = enrolledBy.get(String(c._id));
    return {
      id: String(c._id),
      title: c.title,
      description: c.description ? String(c.description).slice(0, 160) : '',
      thumbnail: c.thumbnail || null,
      subject: c.schoolAccess?.subject || subjects.find((s) => String(s.courseId) === String(c._id))?.subject || '',
      lessons: lessonsBy.get(String(c._id)) || 0,
      progress: e ? Math.round(e.progress || 0) : null,
      completed: e?.completionStatus === 'completed',
      lastOpenedAt: e?.updatedAt || null,
    };
  });
  return {
    student: { id: String(student._id), fullName: student.fullName, studentCode: student.studentCode },
    school: school ? { id: String(school._id), name: school.name, logo: school.logo || null, hasCourseAccess: !!sub?.hasAccess } : null,
    classroom: classroom ? {
      id: String(classroom._id), name: classroom.name, level: classroom.level, academicYear: classroom.academicYear,
      classTeacher: classroom.classTeacherId ? { id: String(classroom.classTeacherId._id), fullName: classroom.classTeacherId.fullName, phone: forParent ? classroom.classTeacherId.phone || null : undefined } : null,
    } : null,
    subjects: subjectViews,
    courses,
    todo: withState.filter((a) => a.state === 'todo' || a.state === 'overdue'),
    recent: withState.filter((a) => ['submitted', 'graded', 'missed', 'done'].includes(a.state)).reverse().slice(0, 30),
    lessonChecks,
    stats: {
      todo: withState.filter((a) => a.state === 'todo').length,
      overdue: withState.filter((a) => a.state === 'overdue').length,
      missed: withState.filter((a) => a.state === 'missed').length,
      submitted: withState.filter((a) => a.state === 'submitted' || a.state === 'graded').length,
    },
  };
}

/** GET /learning/home */
const studentHome = wrap(async (req, res) => {
  requireSchoolStudent(req.user);
  ok(res, await studentOverview(req.user));
});

async function loadAssessmentOf(student, id) {
  requireId(id, 'id');
  const a = await Assessment.findById(id).populate('teacherId', 'fullName');
  if (!a || String(a.classroomId) !== String(student.classroomId) || !a.isFor(student._id)) throw new HttpError('Homework not found', 404);
  return a;
}

async function loadOwnAssessment(req) {
  requireSchoolStudent(req.user);
  return loadAssessmentOf(req.user, req.params.id);
}

async function assessmentDetail(student, a) {
  const s = await AssessmentSubmission.findOne({ assessmentId: a._id, studentId: student._id }).lean();
  return { assessment: assessmentView(a.toObject(), { submission: s ? submissionView(s) : null }) };
}

/** GET /learning/assessments/:id */
const studentAssessment = wrap(async (req, res) => {
  const a = await loadOwnAssessment(req);
  ok(res, await assessmentDetail(req.user, a));
});

/**
 * Hands in homework for `student`. `by` is the account doing it: the student,
 * or a parent helping at home (school-only schools: students cannot sign in
 * at home, so parents hand in from their own account).
 */
async function handIn(student, a, body, by) {
  if (['none', 'eexams'].includes(a.submissionMode)) throw new HttpError('Nothing to hand in here.');
  const late = Date.now() > new Date(a.dueAt).getTime();
  if (a.status === 'closed' || (late && !a.allowLate)) throw new HttpError('This homework is closed.', 403);
  const text = body?.text ? String(body.text).trim() : '';
  const attachments = cleanAttachments(body?.attachments);
  if (a.submissionMode === 'text' && !text) throw new HttpError('Write the answer first.');
  if (['photo', 'file'].includes(a.submissionMode) && !attachments.length && !text) throw new HttpError('Add a photo of the work first.');
  let s = await AssessmentSubmission.findOne({ assessmentId: a._id, studentId: student._id });
  if (s && s.status === 'graded') throw new HttpError('The teacher already marked this.', 409);
  if (!s) s = new AssessmentSubmission({ assessmentId: a._id, studentId: student._id, schoolId: a.schoolId, classroomId: a.classroomId });
  const viaParent = String(by._id) !== String(student._id);
  Object.assign(s, { text, attachments, submittedAt: new Date(), isLate: late, submittedVia: viaParent ? 'parent' : 'student', submittedBy: by._id });
  await s.save();
  return { submission: submissionView(s.toObject()), late };
}

/** POST /learning/assessments/:id/submit { text?, attachments? } — resubmitting replaces until it is marked. */
const submitAssessment = wrap(async (req, res) => {
  const a = await loadOwnAssessment(req);
  const { submission, late } = await handIn(req.user, a, req.body, req.user);
  ok(res, { submission }, late ? 'Handed in late' : 'Handed in', 201);
});

/** POST /learning/coverage/:id/check { taught: true|false } — "Was this lesson taught?" */
const checkLesson = wrap(async (req, res) => {
  requireSchoolStudent(req.user);
  requireId(req.params.id, 'id');
  if (typeof req.body?.taught !== 'boolean') throw new HttpError('Answer yes or no.');
  const cov = await LessonCoverage.findById(req.params.id);
  if (!cov || String(cov.classroomId) !== String(req.user.classroomId)) throw new HttpError('Lesson not found', 404);
  if (Date.now() - cov.taughtOn > CHECK_WINDOW_DAYS * DAY) throw new HttpError('This lesson is too old to answer.');
  const i = cov.studentChecks.findIndex((c) => String(c.studentId) === String(req.user._id));
  const entry = { studentId: req.user._id, taught: req.body.taught, at: new Date() };
  if (i >= 0) cov.studentChecks[i] = entry; else cov.studentChecks.push(entry);
  await flagsSvc.evaluate(cov);
  ok(res, { id: String(cov._id) }, 'Thank you');
});

// ── Parents ──────────────────────────────────────────────────────────────

async function childrenOf(parent) {
  return User.find({ role: 'student', 'guardians.userId': parent._id, isActive: true }).sort({ fullName: 1 });
}

/** GET /parent/children — summary card per child. */
const parentChildren = wrap(async (req, res) => {
  if (req.user.role !== 'parent') throw new HttpError('This is for parents.', 403);
  const children = await childrenOf(req.user);
  const items = [];
  for (const c of children) {
    const o = await studentOverview(c, { forParent: true });
    items.push({ ...o.student, school: o.school, classroom: o.classroom, stats: o.stats, subjects: o.subjects.map(({ subject, averagePercent, coveragePercent }) => ({ subject, averagePercent, coveragePercent })) });
  }
  ok(res, { children: items });
});

async function loadChild(req) {
  if (req.user.role !== 'parent') throw new HttpError('This is for parents.', 403);
  requireId(req.params.id, 'id');
  const child = await User.findOne({ _id: req.params.id, role: 'student', 'guardians.userId': req.user._id, isActive: true });
  if (!child) throw new HttpError('Child not found', 404);
  return child;
}

/** GET /parent/children/:id — full overview of one child. */
const parentChild = wrap(async (req, res) => {
  const child = await loadChild(req);
  ok(res, await studentOverview(child, { forParent: true }));
});

/** GET /parent/children/:id/assessments/:aid */
const parentAssessment = wrap(async (req, res) => {
  const child = await loadChild(req);
  const a = await loadAssessmentOf(child, req.params.aid);
  ok(res, await assessmentDetail(child, a));
});

/** POST /parent/children/:id/assessments/:aid/submit — the parent hands in the child's homework. */
const parentSubmit = wrap(async (req, res) => {
  const child = await loadChild(req);
  const a = await loadAssessmentOf(child, req.params.aid);
  const { submission, late } = await handIn(child, a, req.body, req.user);
  ok(res, { submission }, late ? 'Handed in late' : 'Handed in', 201);
});

/**
 * POST /parent/children/:id/assessments/:aid/eexams — opens the class exam on
 * eexams as the child (one-time sign-in link), so the child can sit it at
 * home on the parent's phone. Only for exams the teacher sent to the class.
 */
const parentOpenExam = wrap(async (req, res) => {
  const child = await loadChild(req);
  const a = await loadAssessmentOf(child, req.params.aid);
  if (a.submissionMode !== 'eexams' || !a.eexamsPath) throw new HttpError('This is not an eexams exam.');
  if (a.status === 'closed') throw new HttpError('This exam is closed.', 403);
  if (!process.env.ECH_EEXAMS_SSO_SECRET) throw new HttpError('eexams is not available right now.', 503);
  ok(res, await eexams.startSso(child, a.eexamsPath), 'Opening the exam');
});

module.exports = {
  studentHome, studentAssessment, submitAssessment, checkLesson,
  parentChildren, parentChild, parentAssessment, parentSubmit, parentOpenExam, studentOverview,
};
