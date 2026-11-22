/**
 * What the headmaster / director of studies needs: overview, syllabus
 * coverage, flagged lessons, teacher activity, results, sign-in activity.
 */
const mongoose = require('mongoose');
const User = require('../../models/User');
const Classroom = require('../../models/Classroom');
const ClassSubject = require('../../models/ClassSubject');
const LessonCoverage = require('../../models/LessonCoverage');
const Assessment = require('../../models/Assessment');
const AssessmentSubmission = require('../../models/AssessmentSubmission');
const ExternalExamResult = require('../../models/ExternalExamResult');
const LoginAudit = require('../../models/LoginAudit');
const Lesson = require('../../models/Lesson');
const { coverageView } = require('./teaching.controller');
const { schoolSummary } = require('./schools.controller');
const { HttpError, ok, wrap, requireId, schoolFor, paging, pageResult } = require('./helpers');

const DAY = 24 * 3600 * 1000;
const oid = (v) => new mongoose.Types.ObjectId(String(v));

/** GET /schools/:schoolId/overview */
const overview = wrap(async (req, res) => {
  const school = await schoolFor(req);
  const now = Date.now();
  const weekAgo = new Date(now - 7 * DAY);
  const [summary, flaggedCount, markedWeek, homeworkWeek, subsWeek, teachers, suspicious, flaggedLatest, unassignedStudents, subjectsWithoutTeacher] = await Promise.all([
    schoolSummary(school),
    LessonCoverage.countDocuments({ schoolId: school._id, status: 'flagged' }),
    LessonCoverage.countDocuments({ schoolId: school._id, createdAt: { $gte: weekAgo } }),
    Assessment.find({ schoolId: school._id, createdAt: { $gte: weekAgo } }).select('_id classroomId').lean(),
    AssessmentSubmission.countDocuments({ schoolId: school._id, submittedAt: { $gte: weekAgo } }),
    User.find({ schoolId: school._id, role: 'instructor', isActive: true }).select('fullName lastActive').lean(),
    LoginAudit.countDocuments({ schoolId: school._id, suspicious: true, at: { $gte: weekAgo } }),
    LessonCoverage.find({ schoolId: school._id, status: 'flagged' }).populate('teacherId', 'fullName').populate('classroomId', 'name').sort({ createdAt: -1 }).limit(5).lean(),
    User.countDocuments({ schoolId: school._id, role: 'student', isActive: true, classroomId: null }),
    ClassSubject.countDocuments({ schoolId: school._id, isActive: true, teacherId: null }),
  ]);

  // Expected hand-ins this week = sum of class sizes of the homework given.
  const sizes = await User.aggregate([
    { $match: { schoolId: school._id, role: 'student', isActive: true, classroomId: { $in: homeworkWeek.map((h) => h.classroomId) } } },
    { $group: { _id: '$classroomId', n: { $sum: 1 } } },
  ]);
  const sizeMap = new Map(sizes.map((s) => [String(s._id), s.n]));
  const expected = homeworkWeek.reduce((n, h) => n + (sizeMap.get(String(h.classroomId)) || 0), 0);

  // Teachers with no lesson marked in 7 days.
  const activeTeacherIds = await LessonCoverage.distinct('teacherId', { schoolId: school._id, createdAt: { $gte: weekAgo } });
  const activeSet = new Set(activeTeacherIds.map(String));
  const quiet = teachers.filter((t) => !activeSet.has(String(t._id))).map((t) => ({ id: String(t._id), fullName: t.fullName, lastActive: t.lastActive || null }));

  // "Get your school ready" checklist.
  const SchoolTerm = require('../../models/SchoolTerm');
  const [termCount, subjectCount, teacherCount, studentCount] = await Promise.all([
    SchoolTerm.countDocuments({ schoolId: school._id }),
    ClassSubject.countDocuments({ schoolId: school._id, isActive: true }),
    User.countDocuments({ schoolId: school._id, role: 'instructor', isActive: true }),
    User.countDocuments({ schoolId: school._id, role: 'student', isActive: true }),
  ]);
  const steps = [
    { key: 'profile', section: 'profile', label: 'Complete the school profile (address, phone)', done: !!(school.address?.district && school.phone) },
    { key: 'terms', section: 'billing', label: 'Add the school terms with their dates', done: termCount > 0, count: termCount },
    { key: 'classes', section: 'classes', label: 'Create classes and streams', done: summary.classCount > 0, count: summary.classCount },
    { key: 'teachers', section: 'staff', label: 'Add teachers', done: teacherCount > 0, count: teacherCount },
    { key: 'subjects', section: 'classes', label: 'Give every class its subjects and teachers', done: subjectCount > 0 && subjectsWithoutTeacher === 0, count: subjectCount },
    { key: 'students', section: 'students', label: 'Register students and print their login cards', done: studentCount > 0 && unassignedStudents === 0, count: studentCount },
    { key: 'access', section: 'access', label: 'Choose where students may sign in', done: !!school.studentAccess?.reviewedAt },
    { key: 'payment', section: 'billing', label: 'Pay for the term to unlock ECH courses', done: summary.subscription.status === 'active' },
  ];

  ok(res, {
    school: summary,
    setup: { steps, done: steps.filter((s) => s.done).length, total: steps.length },
    week: {
      lessonsMarked: markedWeek,
      homeworkGiven: homeworkWeek.length,
      handIns: subsWeek,
      handInRate: expected ? Math.round((subsWeek / expected) * 100) : null,
    },
    attention: {
      flaggedLessons: flaggedCount,
      suspiciousSignIns: suspicious,
      teachersWithoutMarksThisWeek: quiet,
      studentsWithoutClass: unassignedStudents,
      subjectsWithoutTeacher,
    },
    flaggedLatest: flaggedLatest.map((c) => ({ ...coverageView(c), teacher: c.teacherId?.fullName, className: c.classroomId?.name, subject: c.subject })),
  });
});

/** GET /schools/:schoolId/progress — syllabus coverage per class and subject. */
const progress = wrap(async (req, res) => {
  const school = await schoolFor(req);
  const classFilter = { schoolId: school._id, isActive: true };
  if (req.query.classId) classFilter._id = requireId(req.query.classId, 'class id');
  const classes = await Classroom.find(classFilter).sort({ level: 1, combination: 1, stream: 1 }).lean();
  const subjects = await ClassSubject.find({ classroomId: { $in: classes.map((c) => c._id) }, isActive: true }).populate('teacherId', 'fullName').lean();
  const agg = await LessonCoverage.aggregate([
    { $match: { classSubjectId: { $in: subjects.map((s) => s._id) } } },
    { $group: {
      _id: '$classSubjectId',
      marked: { $sum: { $cond: [{ $ne: ['$status', 'confirmed'] }, 1, 0] } },
      flagged: { $sum: { $cond: [{ $eq: ['$status', 'flagged'] }, 1, 0] } },
      notTaught: { $sum: { $cond: [{ $eq: ['$status', 'confirmed'] }, 1, 0] } },
      last: { $max: '$taughtOn' },
    } },
  ]);
  const aggMap = new Map(agg.map((a) => [String(a._id), a]));
  const courseIds = [...new Set(subjects.filter((s) => s.courseId).map((s) => String(s.courseId)))];
  const totals = await Lesson.aggregate([{ $match: { courseId: { $in: courseIds.map(oid) } } }, { $group: { _id: '$courseId', n: { $sum: 1 } } }]);
  const totalMap = new Map(totals.map((t) => [String(t._id), t.n]));

  ok(res, {
    classes: classes.map((c) => ({
      id: String(c._id),
      name: c.name,
      subjects: subjects.filter((s) => String(s.classroomId) === String(c._id)).map((s) => {
        const a = aggMap.get(String(s._id)) || {};
        const total = s.courseId ? totalMap.get(String(s.courseId)) || 0 : 0;
        const daysSince = a.last ? Math.floor((Date.now() - new Date(a.last)) / DAY) : null;
        return {
          id: String(s._id),
          subject: s.subject,
          teacher: s.teacherId ? { id: String(s.teacherId._id), fullName: s.teacherId.fullName } : null,
          lessonsMarked: a.marked || 0,
          flagged: a.flagged || 0,
          confirmedNotTaught: a.notTaught || 0,
          syllabusLessons: total,
          coveragePercent: total ? Math.min(100, Math.round(((a.marked || 0) / total) * 100)) : null,
          lastTaughtOn: a.last || null,
          daysSinceLastLesson: daysSince,
        };
      }).sort((x, y) => x.subject.localeCompare(y.subject)),
    })),
  });
});

/** GET /schools/:schoolId/coverage?status=&classId=&teacherId=&subject= */
const listCoverage = wrap(async (req, res) => {
  const school = await schoolFor(req);
  const pg = paging(req.query, { defLimit: 30 });
  const filter = { schoolId: school._id };
  if (['ok', 'flagged', 'confirmed', 'dismissed'].includes(req.query.status)) filter.status = req.query.status;
  if (req.query.classId) filter.classroomId = requireId(req.query.classId, 'class id');
  if (req.query.teacherId) filter.teacherId = requireId(req.query.teacherId, 'teacher id');
  if (req.query.subject) filter.subject = String(req.query.subject);
  const [items, total] = await Promise.all([
    LessonCoverage.find(filter).populate('teacherId', 'fullName').populate('classroomId', 'name').sort({ taughtOn: -1, createdAt: -1 }).skip(pg.skip).limit(pg.limit).lean(),
    LessonCoverage.countDocuments(filter),
  ]);
  ok(res, pageResult(items.map((c) => ({ ...coverageView(c), teacher: c.teacherId ? { id: String(c.teacherId._id), fullName: c.teacherId.fullName } : null, className: c.classroomId?.name, subject: c.subject })), total, pg, 'coverage'));
});

/** PATCH /schools/:schoolId/coverage/:id { status: 'dismissed' (it was taught) | 'confirmed' (not taught), note } */
const reviewCoverage = wrap(async (req, res) => {
  const school = await schoolFor(req);
  requireId(req.params.id, 'id');
  const cov = await LessonCoverage.findOne({ _id: req.params.id, schoolId: school._id });
  if (!cov) throw new HttpError('Not found', 404);
  if (!['dismissed', 'confirmed', 'flagged'].includes(req.body?.status)) throw new HttpError('Choose: it was taught, or it was not taught.');
  cov.status = req.body.status;
  cov.review = { by: req.user._id, at: new Date(), note: req.body.note ? String(req.body.note).trim() : '' };
  await cov.save();
  if (cov.status === 'confirmed') {
    const { notifyUsers } = require('../../services/school/notify.service');
    await notifyUsers([cov.teacherId], { title: 'Lesson mark rejected', message: `${cov.subject}: "${cov.topic}" was recorded as not taught by the school administration.`, type: 'school', data: { kind: 'coverage', coverageId: String(cov._id) } });
  }
  ok(res, { coverage: coverageView(cov.toObject()) }, 'Review saved');
});

/** GET /schools/:schoolId/teachers/:userId/activity */
const teacherActivity = wrap(async (req, res) => {
  const school = await schoolFor(req);
  requireId(req.params.userId, 'teacher id');
  const teacher = await User.findOne({ _id: req.params.userId, schoolId: school._id, role: { $in: ['instructor', 'school_admin'] } }).lean();
  if (!teacher) throw new HttpError('Teacher not found', 404);
  const since = new Date(Date.now() - (parseInt(req.query.days, 10) || 30) * DAY);
  const [subjects, classTeacherOf, coverage, assessments, logins] = await Promise.all([
    ClassSubject.find({ teacherId: teacher._id, isActive: true }).populate('classroomId', 'name').lean(),
    Classroom.find({ classTeacherId: teacher._id, isActive: true }).select('name').lean(),
    LessonCoverage.find({ teacherId: teacher._id, createdAt: { $gte: since } }).populate('classroomId', 'name').sort({ taughtOn: -1 }).limit(100).lean(),
    Assessment.find({ teacherId: teacher._id, createdAt: { $gte: since } }).populate('classroomId', 'name').sort({ createdAt: -1 }).lean(),
    LoginAudit.find({ userId: teacher._id }).sort({ at: -1 }).limit(10).lean(),
  ]);
  const ungraded = await AssessmentSubmission.countDocuments({ assessmentId: { $in: assessments.map((a) => a._id) }, status: 'submitted' });
  ok(res, {
    teacher: { id: String(teacher._id), fullName: teacher.fullName, email: teacher.email, phone: teacher.phone, address: teacher.address || {}, teacherProfile: teacher.teacherProfile || {}, lastActive: teacher.lastActive || null },
    classTeacherOf: classTeacherOf.map((c) => ({ id: String(c._id), name: c.name })),
    subjects: subjects.map((s) => ({ id: String(s._id), subject: s.subject, className: s.classroomId?.name })),
    stats: {
      lessonsMarked: coverage.length,
      flagged: coverage.filter((c) => c.status === 'flagged').length,
      confirmedNotTaught: coverage.filter((c) => c.status === 'confirmed').length,
      homeworkGiven: assessments.length,
      waitingToBeMarked: ungraded,
    },
    recentLessons: coverage.slice(0, 30).map((c) => ({ ...coverageView(c), className: c.classroomId?.name, subject: c.subject })),
    recentHomework: assessments.slice(0, 20).map((a) => ({ id: String(a._id), title: a.title, subject: a.subject, className: a.classroomId?.name, dueAt: a.dueAt, createdAt: a.createdAt })),
    recentSignIns: logins.map((l) => ({ at: l.at, success: l.success, method: l.method, ip: l.ip, userAgent: l.userAgent })),
  });
});

/** GET /schools/:schoolId/results?classId= — averages per class/subject + per student (homework and eexams). */
const results = wrap(async (req, res) => {
  const school = await schoolFor(req);
  if (!req.query.classId) throw new HttpError('Choose a class');
  const classroom = await Classroom.findOne({ _id: requireId(req.query.classId, 'class id'), schoolId: school._id }).lean();
  if (!classroom) throw new HttpError('Class not found', 404);
  const [students, assessments] = await Promise.all([
    User.find({ classroomId: classroom._id, role: 'student', isActive: true }).select('fullName studentCode').sort({ fullName: 1 }).lean(),
    Assessment.find({ classroomId: classroom._id, maxScore: { $gt: 0 } }).select('subject maxScore title dueAt').lean(),
  ]);
  const subs = await AssessmentSubmission.find({ assessmentId: { $in: assessments.map((a) => a._id) }, status: 'graded' }).select('assessmentId studentId score').lean();
  const exams = await ExternalExamResult.find({ user: { $in: students.map((s) => s._id) } }).select('user examTitle percentage completedAt').sort({ completedAt: -1 }).lean();
  const aMap = new Map(assessments.map((a) => [String(a._id), a]));
  const subjects = [...new Set(assessments.map((a) => a.subject))].sort();

  const rows = students.map((st) => {
    const mine = subs.filter((s) => String(s.studentId) === String(st._id));
    const bySubject = {};
    for (const subj of subjects) {
      const list = mine.filter((s) => aMap.get(String(s.assessmentId))?.subject === subj);
      bySubject[subj] = list.length ? Math.round(list.reduce((n, s) => n + (s.score / aMap.get(String(s.assessmentId)).maxScore) * 100, 0) / list.length) : null;
    }
    const vals = Object.values(bySubject).filter((v) => v != null);
    const myExams = exams.filter((e) => String(e.user) === String(st._id));
    return {
      id: String(st._id),
      fullName: st.fullName,
      studentCode: st.studentCode,
      bySubject,
      homeworkAverage: vals.length ? Math.round(vals.reduce((a, b) => a + b, 0) / vals.length) : null,
      handedIn: mine.length,
      examAverage: myExams.length ? Math.round(myExams.reduce((n, e) => n + (e.percentage || 0), 0) / myExams.length) : null,
      exams: myExams.slice(0, 5).map((e) => ({ title: e.examTitle, percentage: e.percentage, completedAt: e.completedAt })),
    };
  });
  const subjectAverages = {};
  for (const subj of subjects) {
    const vals = rows.map((r) => r.bySubject[subj]).filter((v) => v != null);
    subjectAverages[subj] = vals.length ? Math.round(vals.reduce((a, b) => a + b, 0) / vals.length) : null;
  }
  ok(res, {
    class: { id: String(classroom._id), name: classroom.name },
    subjects,
    subjectAverages,
    students: rows.sort((a, b) => (b.homeworkAverage ?? -1) - (a.homeworkAverage ?? -1)),
    atRisk: rows.filter((r) => r.homeworkAverage != null && r.homeworkAverage < 50).map((r) => ({ id: r.id, fullName: r.fullName, homeworkAverage: r.homeworkAverage })),
  });
});

/** GET /schools/:schoolId/sign-ins?suspicious=true&userId= */
const signIns = wrap(async (req, res) => {
  const school = await schoolFor(req);
  const pg = paging(req.query, { defLimit: 50 });
  const filter = { schoolId: school._id };
  if (req.query.suspicious === 'true') filter.suspicious = true;
  if (req.query.userId) filter.userId = requireId(req.query.userId, 'user id');
  const [items, total] = await Promise.all([
    LoginAudit.find(filter).populate('userId', 'fullName role studentCode').sort({ at: -1 }).skip(pg.skip).limit(pg.limit).lean(),
    LoginAudit.countDocuments(filter),
  ]);
  ok(res, pageResult(items.map((l) => ({
    id: String(l._id),
    user: l.userId ? { id: String(l.userId._id), fullName: l.userId.fullName, role: l.userId.role, studentCode: l.userId.studentCode } : null,
    identifier: l.identifier,
    at: l.at,
    success: l.success,
    reason: l.reason || null,
    method: l.method,
    ip: l.ip,
    deviceId: l.deviceId ? `${String(l.deviceId).slice(0, 6)}…` : null,
    userAgent: l.userAgent,
    suspicious: l.suspicious,
    suspiciousReason: l.suspiciousReason || null,
  })), total, pg, 'signIns'));
});

module.exports = { overview, progress, listCoverage, reviewCoverage, teacherActivity, results, signIns };
