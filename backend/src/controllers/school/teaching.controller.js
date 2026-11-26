/**
 * Teacher portal: my classes, marking lessons taught, homework and grading.
 */
const mongoose = require('mongoose');
const Classroom = require('../../models/Classroom');
const ClassSubject = require('../../models/ClassSubject');
const LessonCoverage = require('../../models/LessonCoverage');
const Assessment = require('../../models/Assessment');
const AssessmentSubmission = require('../../models/AssessmentSubmission');
const SchoolTerm = require('../../models/SchoolTerm');
const Section = require('../../models/Section');
const Lesson = require('../../models/Lesson');
const User = require('../../models/User');
const { teacherLoad, classSubjectAccess, canManageSchool } = require('../../services/school/access.service');
const flagsSvc = require('../../services/school/coverageFlags.service');
const { notifyUsers } = require('../../services/school/notify.service');
const { HttpError, ok, wrap, requireId } = require('./helpers');

const DAY = 24 * 3600 * 1000;
const UNMARK_HOURS = 48;

function cleanAttachments(list) {
  if (!Array.isArray(list)) return [];
  return list.slice(0, 10).map((a) => ({
    url: String(a.url || '').trim(),
    name: String(a.name || '').trim().slice(0, 200),
    type: String(a.type || '').trim().slice(0, 60),
  })).filter((a) => /^https?:\/\//i.test(a.url));
}

async function currentTermId(schoolId, at = new Date()) {
  const t = await SchoolTerm.findOne({ schoolId, startDate: { $lte: at }, endDate: { $gte: at } }).select('_id').lean();
  return t?._id || null;
}

async function loadClassSubject(req, id, { teach = false } = {}) {
  requireId(id, 'subject id');
  const cs = await ClassSubject.findById(id).populate('classroomId').populate('courseId', 'title');
  if (!cs || !cs.isActive) throw new HttpError('Subject not found', 404);
  const access = await classSubjectAccess(req.user, cs);
  if (!access.canView) throw new HttpError('You do not teach this subject in this class.', 403);
  if (teach && !access.canTeach) throw new HttpError('Only the subject teacher can do this.', 403);
  return { cs, access };
}

const guardianIds = (students) => students.flatMap((s) => (s.guardians || []).map((g) => g.userId).filter(Boolean));

/** GET /teaching/me — classes I lead, subjects I teach, work waiting for me. */
const myTeaching = wrap(async (req, res) => {
  if (req.user.role !== 'instructor' || !req.user.schoolId) {
    return ok(res, { schoolTeacher: false, classTeacherOf: [], subjects: [] });
  }
  const load = await teacherLoad(req.user);
  const classIds = [...new Set([...load.classTeacherOf.map((c) => String(c._id)), ...load.subjects.map((s) => String(s.classroomId._id))])];
  const csIds = load.subjects.map((s) => s._id);
  const myAssessments = await Assessment.find({ teacherId: req.user._id, status: 'published' }).select('_id classSubjectId').lean();
  const csOfAssessment = new Map(myAssessments.map((a) => [String(a._id), String(a.classSubjectId)]));
  const [counts, ungraded, flagged, lessonsMarked] = await Promise.all([
    User.aggregate([{ $match: { classroomId: { $in: classIds.map((id) => new mongoose.Types.ObjectId(id)) }, role: 'student', isActive: true } }, { $group: { _id: '$classroomId', n: { $sum: 1 } } }]),
    AssessmentSubmission.aggregate([
      { $match: { assessmentId: { $in: myAssessments.map((a) => a._id) }, status: 'submitted' } },
      { $group: { _id: '$assessmentId', n: { $sum: 1 } } },
    ]),
    LessonCoverage.aggregate([{ $match: { classSubjectId: { $in: csIds }, status: 'flagged' } }, { $group: { _id: '$classSubjectId', n: { $sum: 1 } } }]),
    LessonCoverage.aggregate([{ $match: { classSubjectId: { $in: csIds }, status: { $ne: 'confirmed' } } }, { $group: { _id: '$classSubjectId', n: { $sum: 1 }, last: { $max: '$taughtOn' } } }]),
  ]);
  const m = (arr) => new Map(arr.map((x) => [String(x._id), x]));
  const countMap = m(counts);
  const gradeMap = new Map();
  for (const u of ungraded) {
    const cs = csOfAssessment.get(String(u._id));
    gradeMap.set(cs, { n: (gradeMap.get(cs)?.n || 0) + u.n });
  }
  const flagMap = m(flagged);
  const markMap = m(lessonsMarked);
  const lessonTotals = new Map();
  for (const s of load.subjects) {
    if (s.courseId && !lessonTotals.has(String(s.courseId))) lessonTotals.set(String(s.courseId), await Lesson.countDocuments({ courseId: s.courseId }));
  }

  ok(res, {
    schoolTeacher: true,
    classTeacherOf: load.classTeacherOf.map((c) => ({ id: String(c._id), name: c.name, level: c.level, studentCount: countMap.get(String(c._id))?.n || 0 })),
    subjects: load.subjects.map((s) => {
      const total = s.courseId ? lessonTotals.get(String(s.courseId)) || 0 : 0;
      const marked = markMap.get(String(s._id))?.n || 0;
      return {
        id: String(s._id),
        subject: s.subject,
        classroomId: String(s.classroomId._id),
        className: s.classroomId.name,
        level: s.classroomId.level,
        courseId: s.courseId ? String(s.courseId) : null,
        studentCount: countMap.get(String(s.classroomId._id))?.n || 0,
        toGrade: gradeMap.get(String(s._id))?.n || 0,
        flagged: flagMap.get(String(s._id))?.n || 0,
        lessonsMarked: marked,
        syllabusLessons: total,
        coveragePercent: total ? Math.min(100, Math.round((marked / total) * 100)) : null,
        lastTaughtOn: markMap.get(String(s._id))?.last || null,
      };
    }),
  });
});

/** GET /teaching/class-subjects/:id/syllabus — chapters/lessons of the linked course with what is taught. */
const syllabus = wrap(async (req, res) => {
  const { cs, access } = await loadClassSubject(req, req.params.id);
  const coverage = await LessonCoverage.find({ classSubjectId: cs._id }).sort({ taughtOn: -1 }).lean();
  const byLesson = new Map();
  for (const c of coverage) if (c.lessonId && !byLesson.has(String(c.lessonId))) byLesson.set(String(c.lessonId), c);

  let chapters = [];
  if (cs.courseId) {
    const [sections, lessons] = await Promise.all([
      Section.find({ courseId: cs.courseId._id }).sort({ order: 1 }).select('title order').lean(),
      Lesson.find({ courseId: cs.courseId._id }).sort({ order: 1 }).select('title order sectionId').lean(),
    ]);
    chapters = sections.map((sec) => ({
      id: String(sec._id),
      title: sec.title,
      lessons: lessons.filter((l) => String(l.sectionId) === String(sec._id)).map((l) => {
        const c = byLesson.get(String(l._id));
        return { id: String(l._id), title: l.title, coverage: c ? coverageView(c) : null };
      }),
    }));
  }
  const total = chapters.reduce((n, ch) => n + ch.lessons.length, 0);
  const taught = chapters.reduce((n, ch) => n + ch.lessons.filter((l) => l.coverage && l.coverage.status !== 'confirmed').length, 0);
  ok(res, {
    classSubject: { id: String(cs._id), subject: cs.subject, className: cs.classroomId.name, classroomId: String(cs.classroomId._id), course: cs.courseId ? { id: String(cs.courseId._id), title: cs.courseId.title } : null },
    canTeach: !!access.canTeach,
    chapters,
    otherTopics: coverage.filter((c) => !c.lessonId).map(coverageView),
    summary: { total, taught, percent: total ? Math.round((taught / total) * 100) : null, flagged: coverage.filter((c) => c.status === 'flagged').length },
  });
});

function coverageView(c) {
  return {
    id: String(c._id),
    topic: c.topic,
    chapterTitle: c.chapterTitle || null,
    lessonId: c.lessonId ? String(c.lessonId) : null,
    taughtOn: c.taughtOn,
    notes: c.notes || '',
    attachments: c.attachments || [],
    status: c.status,
    flags: c.flags || [],
    studentChecks: { yes: (c.studentChecks || []).filter((s) => s.taught).length, no: (c.studentChecks || []).filter((s) => s.taught === false).length },
    review: c.review?.at ? { at: c.review.at, note: c.review.note || '' } : null,
    markedAt: c.createdAt,
  };
}

/** POST /teaching/class-subjects/:id/coverage { lessonId? | topic, taughtOn, notes?, attachments? } */
const markTaught = wrap(async (req, res) => {
  const { cs } = await loadClassSubject(req, req.params.id, { teach: true });
  const b = req.body || {};
  const taughtOn = b.taughtOn ? new Date(b.taughtOn) : new Date();
  if (Number.isNaN(+taughtOn)) throw new HttpError('Invalid date');
  if (taughtOn - Date.now() > 2 * DAY) throw new HttpError('You cannot mark a lesson more than a day ahead.');

  let topic = String(b.topic || '').trim();
  let lessonId = null;
  let sectionId = null;
  let chapterTitle = String(b.chapterTitle || '').trim() || undefined;
  if (b.lessonId) {
    requireId(b.lessonId, 'lesson id');
    if (!cs.courseId) throw new HttpError('This subject has no ECH course linked.');
    const lesson = await Lesson.findOne({ _id: b.lessonId, courseId: cs.courseId._id }).select('title sectionId').lean();
    if (!lesson) throw new HttpError('Lesson not found in this subject\'s course.', 404);
    const already = await LessonCoverage.findOne({ classSubjectId: cs._id, lessonId: lesson._id, status: { $ne: 'confirmed' } }).lean();
    if (already) throw new HttpError('This lesson is already marked as taught.', 409);
    lessonId = lesson._id;
    sectionId = lesson.sectionId;
    topic = lesson.title;
    const sec = await Section.findById(lesson.sectionId).select('title').lean();
    chapterTitle = sec?.title;
  }
  if (!topic) throw new HttpError('Choose a lesson or type the topic you taught.');

  const cov = new LessonCoverage({
    schoolId: cs.schoolId,
    classroomId: cs.classroomId._id,
    classSubjectId: cs._id,
    subject: cs.subject,
    teacherId: req.user._id,
    termId: await currentTermId(cs.schoolId, taughtOn),
    courseId: cs.courseId?._id || null,
    sectionId,
    lessonId,
    chapterTitle,
    topic,
    taughtOn,
    notes: b.notes ? String(b.notes).trim() : undefined,
    attachments: cleanAttachments(b.attachments),
  });
  await cov.save();
  await flagsSvc.evaluate(cov);
  if (cov.flags.some((f) => f.code === 'BULK_MARKING')) await flagsSvc.reevaluateBurst(cov);
  ok(res, { coverage: coverageView(cov.toObject()) }, cov.status === 'flagged' ? 'Marked as taught — ECH flagged it for review' : 'Marked as taught', 201);
});

/** DELETE /teaching/coverage/:id — undo own mark within 48 h (not after a review). */
const unmarkTaught = wrap(async (req, res) => {
  requireId(req.params.id, 'id');
  const cov = await LessonCoverage.findById(req.params.id);
  if (!cov) throw new HttpError('Not found', 404);
  if (String(cov.teacherId) !== String(req.user._id)) throw new HttpError('You can only undo your own marks.', 403);
  if (cov.review?.at) throw new HttpError('This mark was already reviewed by the school.', 403);
  if (Date.now() - cov.createdAt > UNMARK_HOURS * 3600 * 1000) throw new HttpError(`Marks can only be undone within ${UNMARK_HOURS} hours.`, 403);
  await cov.deleteOne();
  ok(res, { id: String(cov._id) }, 'Mark removed');
});

// ── Homework / assessments ───────────────────────────────────────────────

function assessmentView(a, extra = {}) {
  return {
    id: String(a._id),
    classSubjectId: String(a.classSubjectId._id || a.classSubjectId),
    classroomId: String(a.classroomId._id || a.classroomId),
    className: a.classroomId?.name,
    subject: a.subject,
    teacher: a.teacherId?.fullName ? { id: String(a.teacherId._id), fullName: a.teacherId.fullName } : undefined,
    type: a.type,
    title: a.title,
    instructions: a.instructions || '',
    attachments: a.attachments || [],
    submissionMode: a.submissionMode,
    maxScore: a.maxScore,
    dueAt: a.dueAt,
    allowLate: a.allowLate,
    eexamsExamId: a.eexamsExamId || null,
    eexamsPath: a.eexamsPath || null,
    // 0 = whole class; otherwise the number of chosen students.
    forStudents: a.studentIds?.length || 0,
    status: a.status,
    createdAt: a.createdAt,
    ...extra,
  };
}

const eexamsStartPath = (examId) => `/student/exam/start/${encodeURIComponent(String(examId))}`;

function submissionView(s) {
  return {
    id: String(s._id),
    assessmentId: String(s.assessmentId._id || s.assessmentId),
    student: s.studentId?.fullName ? { id: String(s.studentId._id), fullName: s.studentId.fullName, studentCode: s.studentId.studentCode } : { id: String(s.studentId) },
    text: s.text || '',
    attachments: s.attachments || [],
    submittedAt: s.submittedAt,
    isLate: s.isLate,
    status: s.status,
    score: s.score,
    feedback: s.feedback || '',
    gradedAt: s.gradedAt || null,
    // 'student', 'parent' (handed in from the parent's account) or 'eexams' (exam result).
    submittedVia: s.submittedVia || 'student',
  };
}

/**
 * The chosen students, checked to be active members of the class. An empty
 * or missing list means the whole class (returns []).
 */
async function classStudentIds(cs, ids) {
  if (!Array.isArray(ids) || !ids.length) return [];
  const wanted = [...new Set(ids.map(String))].filter((id) => /^[a-f0-9]{24}$/i.test(id)).slice(0, 500);
  const found = await User.find({ _id: { $in: wanted }, classroomId: cs.classroomId._id, role: 'student', isActive: true }).select('_id').lean();
  if (!found.length) throw new HttpError('None of the chosen students are in this class.');
  return found.map((s) => s._id);
}

/**
 * Creates homework / a quiz / an exam for one class subject and tells the
 * students and their parents. `cs` must have classroomId populated. Used by
 * the teacher screens and by eexams ("Send to my ECH class").
 */
async function createAssessmentFor(teacher, cs, b = {}) {
  const title = String(b.title || '').trim();
  if (!title) throw new HttpError('Give the homework a title.');
  const dueAt = new Date(b.dueAt);
  if (!b.dueAt || Number.isNaN(+dueAt)) throw new HttpError('Choose the due date.');
  if (dueAt < Date.now() - 3600 * 1000) throw new HttpError('The due date is in the past.');
  const type = ['homework', 'quiz', 'exam'].includes(b.type) ? b.type : 'homework';
  const mode = ['photo', 'file', 'text', 'none', 'eexams'].includes(b.submissionMode) ? b.submissionMode : (b.eexamsExamId ? 'eexams' : 'photo');
  if (mode === 'eexams' && !b.eexamsExamId) throw new HttpError('Choose the eexams exam.');
  let coverageId = null;
  if (b.coverageId) {
    requireId(b.coverageId, 'lesson id');
    if (await LessonCoverage.exists({ _id: b.coverageId, classSubjectId: cs._id })) coverageId = b.coverageId;
  }
  const a = await Assessment.create({
    schoolId: cs.schoolId,
    classroomId: cs.classroomId._id,
    classSubjectId: cs._id,
    subject: cs.subject,
    teacherId: teacher._id,
    termId: await currentTermId(cs.schoolId),
    type,
    title,
    instructions: b.instructions ? String(b.instructions).trim() : '',
    attachments: cleanAttachments(b.attachments),
    submissionMode: mode,
    maxScore: Math.max(0, Number(b.maxScore ?? 10) || 0),
    dueAt,
    allowLate: b.allowLate !== false,
    coverageId,
    eexamsExamId: b.eexamsExamId ? String(b.eexamsExamId) : null,
    eexamsPath: b.eexamsExamId ? eexamsStartPath(b.eexamsExamId) : null,
    studentIds: await classStudentIds(cs, b.studentIds),
  });

  // Tell only the students it is for (everyone when it's for the whole class).
  const students = await User.find({
    classroomId: cs.classroomId._id, role: 'student', isActive: true,
    ...(a.studentIds.length ? { _id: { $in: a.studentIds } } : {}),
  }).select('_id guardians').lean();
  const label = type === 'homework' ? 'New homework' : type === 'quiz' ? 'New quiz' : 'New exam';
  const due = dueAt.toLocaleDateString('en-GB', { weekday: 'short', day: 'numeric', month: 'short' });
  await notifyUsers(students.map((s) => s._id), { title: `${label}: ${cs.subject}`, message: `${title} — due ${due}`, type: 'homework', data: { kind: 'assessment', assessmentId: String(a._id), route: `/school/homework/${a._id}` } });
  await notifyUsers(guardianIds(students), { title: `${label} for your child`, message: `${cs.subject}: ${title} — due ${due}`, type: 'homework', data: { kind: 'assessment', assessmentId: String(a._id) }, push: false });
  return { assessment: a, notified: students.length };
}

/** POST /teaching/class-subjects/:id/assessments */
const createAssessment = wrap(async (req, res) => {
  const { cs } = await loadClassSubject(req, req.params.id, { teach: true });
  const { assessment: a, notified } = await createAssessmentFor(req.user, cs, req.body || {});
  ok(res, { assessment: assessmentView(a.toObject(), { notified }) }, 'Homework sent to the class', 201);
});

/** GET /teaching/class-subjects/:id/assessments */
const listAssessments = wrap(async (req, res) => {
  const { cs } = await loadClassSubject(req, req.params.id);
  const list = await Assessment.find({ classSubjectId: cs._id }).sort({ dueAt: -1 }).limit(200).lean();
  const stats = await AssessmentSubmission.aggregate([
    { $match: { assessmentId: { $in: list.map((a) => a._id) } } },
    { $group: { _id: '$assessmentId', submitted: { $sum: 1 }, graded: { $sum: { $cond: [{ $eq: ['$status', 'graded'] }, 1, 0] } }, avg: { $avg: '$score' } } },
  ]);
  const sm = new Map(stats.map((s) => [String(s._id), s]));
  const classSize = await User.countDocuments({ classroomId: cs.classroomId._id, role: 'student', isActive: true });
  ok(res, {
    classSize,
    assessments: list.map((a) => {
      const s = sm.get(String(a._id)) || {};
      return assessmentView(a, { submitted: s.submitted || 0, graded: s.graded || 0, averageScore: s.avg != null ? Math.round(s.avg * 10) / 10 : null, classSize: a.studentIds?.length || classSize });
    }),
  });
});

async function loadAssessmentForStaff(req, { teach = false } = {}) {
  requireId(req.params.id, 'id');
  const a = await Assessment.findById(req.params.id).populate('classroomId', 'name').populate('teacherId', 'fullName');
  if (!a) throw new HttpError('Homework not found', 404);
  const cs = await ClassSubject.findById(a.classSubjectId);
  const access = await classSubjectAccess(req.user, cs);
  const own = String(a.teacherId._id) === String(req.user._id);
  if (!access.canView && !own) throw new HttpError('Access denied', 403);
  if (teach && !own && !canManageSchool(req.user, a.schoolId)) throw new HttpError('Only the teacher who set it can do this.', 403);
  return a;
}

/** GET /teaching/assessments/:id — with every student's submission (or missing). */
const getAssessment = wrap(async (req, res) => {
  const a = await loadAssessmentForStaff(req);
  const [students, subs] = await Promise.all([
    User.find({
      classroomId: a.classroomId._id, role: 'student', isActive: true,
      ...(a.studentIds?.length ? { _id: { $in: a.studentIds } } : {}),
    }).select('fullName studentCode').sort({ fullName: 1 }).lean(),
    AssessmentSubmission.find({ assessmentId: a._id }).populate('studentId', 'fullName studentCode').lean(),
  ]);
  const byStudent = new Map(subs.map((s) => [String(s.studentId._id || s.studentId), s]));
  ok(res, {
    assessment: assessmentView(a.toObject()),
    students: students.map((st) => {
      const s = byStudent.get(String(st._id));
      return { id: String(st._id), fullName: st.fullName, studentCode: st.studentCode, submission: s ? submissionView(s) : null };
    }),
  });
});

/** PATCH /teaching/assessments/:id { title?, instructions?, dueAt?, status?: 'closed'|'published', maxScore? } */
const updateAssessment = wrap(async (req, res) => {
  const a = await loadAssessmentForStaff(req, { teach: true });
  const b = req.body || {};
  if (b.title !== undefined) { if (!String(b.title).trim()) throw new HttpError('Title is required'); a.title = String(b.title).trim(); }
  if (b.instructions !== undefined) a.instructions = String(b.instructions).trim();
  if (b.dueAt !== undefined) { const d = new Date(b.dueAt); if (Number.isNaN(+d)) throw new HttpError('Invalid due date'); a.dueAt = d; }
  if (b.maxScore !== undefined) a.maxScore = Math.max(0, Number(b.maxScore) || 0);
  if (b.allowLate !== undefined) a.allowLate = !!b.allowLate;
  if (b.attachments !== undefined) a.attachments = cleanAttachments(b.attachments);
  if (b.status !== undefined && ['published', 'closed'].includes(b.status)) a.status = b.status;
  await a.save();
  ok(res, { assessment: assessmentView(a.toObject()) }, 'Saved');
});

/** DELETE /teaching/assessments/:id — only while nobody has submitted. */
const deleteAssessment = wrap(async (req, res) => {
  const a = await loadAssessmentForStaff(req, { teach: true });
  if (await AssessmentSubmission.exists({ assessmentId: a._id })) throw new HttpError('Students already submitted; close it instead.');
  await a.deleteOne();
  ok(res, { id: String(a._id) }, 'Homework deleted');
});

/** POST /teaching/assessments/:id/submissions/:subId/grade { score, feedback } */
const gradeSubmission = wrap(async (req, res) => {
  const a = await loadAssessmentForStaff(req, { teach: true });
  requireId(req.params.subId, 'submission id');
  const s = await AssessmentSubmission.findOne({ _id: req.params.subId, assessmentId: a._id });
  if (!s) throw new HttpError('Submission not found', 404);
  const score = Number(req.body?.score);
  if (!Number.isFinite(score) || score < 0 || score > a.maxScore) throw new HttpError(`Score must be between 0 and ${a.maxScore}.`);
  const firstGrade = s.status !== 'graded';
  s.score = score;
  s.feedback = req.body?.feedback ? String(req.body.feedback).trim() : '';
  s.status = 'graded';
  s.gradedBy = req.user._id;
  s.gradedAt = new Date();
  await s.save();
  if (firstGrade) {
    const student = await User.findById(s.studentId).select('fullName guardians').lean();
    const msg = `${a.subject}: ${a.title} — ${score}/${a.maxScore}`;
    await notifyUsers([s.studentId], { title: 'Homework marked', message: msg, type: 'homework', data: { kind: 'assessment', assessmentId: String(a._id), route: `/school/homework/${a._id}` } });
    await notifyUsers(guardianIds([student]), { title: `${student?.fullName || 'Your child'}'s homework was marked`, message: msg, type: 'homework', data: { kind: 'assessment', assessmentId: String(a._id) }, push: false });
  }
  await s.populate('studentId', 'fullName studentCode');
  ok(res, { submission: submissionView(s.toObject()) }, 'Marked');
});

module.exports = {
  myTeaching, syllabus, markTaught, unmarkTaught,
  createAssessment, createAssessmentFor, classStudentIds, guardianIds, eexamsStartPath, listAssessments, getAssessment, updateAssessment, deleteAssessment, gradeSubmission,
  assessmentView, submissionView, coverageView, cleanAttachments,
};
