/**
 * Student details and printable reports.
 *
 *   GET /schools/:schoolId/students/:userId/report   one student  (school admin, class teacher of the student)
 *   GET /school/classes/:classId/report              one class    (school admin, class teacher)
 *   GET /schools/:schoolId/report                    whole school (school admin)
 *
 * The app turns these into PDFs; the numbers are computed here so the screen
 * and the PDF always agree.
 */
const User = require('../../models/User');
const School = require('../../models/School');
const Classroom = require('../../models/Classroom');
const ClassSubject = require('../../models/ClassSubject');
const Assessment = require('../../models/Assessment');
const AssessmentSubmission = require('../../models/AssessmentSubmission');
const ExternalExamResult = require('../../models/ExternalExamResult');
const LessonCoverage = require('../../models/LessonCoverage');
const LoginAudit = require('../../models/LoginAudit');
const Lesson = require('../../models/Lesson');
const { publicMember } = require('../../services/school/people.service');
const { canManageSchool, isSchoolTeacher, same } = require('../../services/school/access.service');
const { HttpError, ok, wrap, requireId, schoolFor } = require('./helpers');

const avg = (vals) => (vals.length ? Math.round(vals.reduce((a, b) => a + b, 0) / vals.length) : null);
const pct = (score, max) => (max > 0 && score != null ? (score / max) * 100 : null);

/** School admin, or the class teacher of this class. */
function canSeeClassReport(user, classroom) {
  if (canManageSchool(user, classroom.schoolId)) return true;
  return isSchoolTeacher(user, classroom.schoolId) && same(classroom.classTeacherId, user._id);
}

/** Everything needed to report on one class, loaded in a few queries. */
async function loadClassData(classroom, { studentId = null } = {}) {
  const studentFilter = studentId
    ? { _id: studentId }
    : { classroomId: classroom._id, role: 'student', isActive: true };
  const [students, subjects, assessments] = await Promise.all([
    User.find(studentFilter)
      .select('fullName studentCode gender dateOfBirth guardians address phone email isActive lastActive classroomId schoolId role createdAt')
      .sort({ fullName: 1 }).lean(),
    ClassSubject.find({ classroomId: classroom._id, isActive: true }).populate('teacherId', 'fullName').sort({ subject: 1 }).lean(),
    Assessment.find({ classroomId: classroom._id }).populate('teacherId', 'fullName').sort({ dueAt: -1 }).lean(),
  ]);
  const ids = students.map((s) => s._id);
  const [subs, exams, coverage] = await Promise.all([
    AssessmentSubmission.find({ assessmentId: { $in: assessments.map((a) => a._id) }, studentId: { $in: ids } }).lean(),
    ExternalExamResult.find({ user: { $in: ids } }).select('user examTitle score maxScore percentage passed completedAt').sort({ completedAt: -1 }).lean(),
    subjects.length
      ? LessonCoverage.aggregate([
        { $match: { classSubjectId: { $in: subjects.map((s) => s._id) }, status: { $ne: 'confirmed' } } },
        { $group: { _id: '$classSubjectId', n: { $sum: 1 }, last: { $max: '$taughtOn' } } },
      ])
      : [],
  ]);
  const courseIds = [...new Set(subjects.filter((s) => s.courseId).map((s) => String(s.courseId)))];
  const totals = courseIds.length
    ? await Lesson.aggregate([{ $match: { courseId: { $in: subjects.filter((s) => s.courseId).map((s) => s.courseId) } } }, { $group: { _id: '$courseId', n: { $sum: 1 } } }])
    : [];
  const totalMap = new Map(totals.map((t) => [String(t._id), t.n]));
  const covMap = new Map(coverage.map((c) => [String(c._id), c]));

  const subjectViews = subjects.map((s) => {
    const c = covMap.get(String(s._id));
    const total = s.courseId ? totalMap.get(String(s.courseId)) || 0 : 0;
    return {
      id: String(s._id),
      subject: s.subject,
      teacher: s.teacherId ? { id: String(s.teacherId._id), fullName: s.teacherId.fullName } : null,
      lessonsTaught: c?.n || 0,
      syllabusLessons: total,
      coveragePercent: total ? Math.min(100, Math.round(((c?.n || 0) / total) * 100)) : null,
      lastTaughtOn: c?.last || null,
    };
  });

  const subsByStudent = new Map();
  for (const s of subs) {
    const k = String(s.studentId);
    if (!subsByStudent.has(k)) subsByStudent.set(k, new Map());
    subsByStudent.get(k).set(String(s.assessmentId), s);
  }
  const examsByStudent = new Map();
  for (const e of exams) {
    const k = String(e.user);
    if (!examsByStudent.has(k)) examsByStudent.set(k, []);
    examsByStudent.get(k).push(e);
  }
  return { students, subjects: subjectViews, assessments, subsByStudent, examsByStudent };
}

/** One student's work in the class: every assessment with its state, and the totals. */
function studentWork(student, data) {
  const now = Date.now();
  const mine = data.subsByStudent.get(String(student._id)) || new Map();
  const items = [];
  for (const a of data.assessments) {
    if (a.studentIds?.length && !a.studentIds.some((id) => same(id, student._id))) continue;
    const s = mine.get(String(a._id));
    let state;
    if (s) state = s.status === 'graded' ? 'graded' : 'submitted';
    else if (a.submissionMode === 'none') state = 'no_hand_in';
    else if (new Date(a.dueAt) < now) state = 'missing';
    else state = 'pending';
    items.push({
      id: String(a._id),
      subject: a.subject,
      type: a.type,
      title: a.title,
      teacher: a.teacherId?.fullName || null,
      dueAt: a.dueAt,
      maxScore: a.maxScore,
      state,
      submittedAt: s?.submittedAt || null,
      isLate: !!s?.isLate,
      score: s?.status === 'graded' ? s.score : null,
      percent: s?.status === 'graded' && a.maxScore > 0 ? Math.round(pct(s.score, a.maxScore)) : null,
      feedback: s?.feedback || '',
      submittedVia: s?.submittedVia || null,
    });
  }

  const subjectNames = data.subjects.map((s) => s.subject);
  for (const it of items) if (it.subject && !subjectNames.includes(it.subject)) subjectNames.push(it.subject);
  const bySubject = {};
  for (const subj of subjectNames) {
    const graded = items.filter((i) => i.subject === subj && i.percent != null);
    bySubject[subj] = graded.length ? avg(graded.map((g) => (g.score / g.maxScore) * 100)) : null;
  }
  const subjectAvgs = Object.values(bySubject).filter((v) => v != null);
  const expected = items.filter((i) => i.state !== 'no_hand_in' && i.state !== 'pending').length;
  const handedIn = items.filter((i) => i.state === 'graded' || i.state === 'submitted').length;
  const exams = (data.examsByStudent.get(String(student._id)) || []).map((e) => ({
    title: e.examTitle, score: e.score, maxScore: e.maxScore, percentage: Math.round(e.percentage || 0), passed: e.passed, completedAt: e.completedAt,
  }));
  return {
    items,
    bySubject,
    stats: {
      average: avg(subjectAvgs),
      given: items.length,
      handedIn,
      expected,
      missing: items.filter((i) => i.state === 'missing').length,
      late: items.filter((i) => i.isLate).length,
      waitingForMark: items.filter((i) => i.state === 'submitted').length,
      handInRate: expected ? Math.min(100, Math.round((handedIn / expected) * 100)) : null,
      examCount: exams.length,
      examAverage: avg(exams.map((e) => e.percentage)),
    },
    exams,
  };
}

function studentProfile(st, classroom) {
  return {
    ...publicMember(st),
    classroom: classroom ? { id: String(classroom._id), name: classroom.name, level: classroom.level } : undefined,
  };
}

/** Class summary + one row per student. */
function classSummary(classroom, data) {
  const rows = data.students.map((st) => {
    const w = studentWork(st, data);
    return {
      ...studentProfile(st, classroom),
      bySubject: w.bySubject,
      stats: w.stats,
    };
  });
  // Rank by overall average (students without marks last).
  const ranked = [...rows].filter((r) => r.stats.average != null).sort((a, b) => b.stats.average - a.stats.average);
  ranked.forEach((r, i) => { r.position = i + 1; });
  const subjectAverages = {};
  for (const s of data.subjects) subjectAverages[s.subject] = avg(rows.map((r) => r.bySubject[s.subject]).filter((v) => v != null));
  const genders = { male: 0, female: 0, other: 0 };
  for (const r of rows) if (genders[r.gender] != null) genders[r.gender] += 1;
  return {
    class: {
      id: String(classroom._id),
      name: classroom.name,
      level: classroom.level,
      academicYear: classroom.academicYear,
      room: classroom.room || null,
      classTeacher: classroom.classTeacherId?.fullName ? { id: String(classroom.classTeacherId._id), fullName: classroom.classTeacherId.fullName } : null,
    },
    subjects: data.subjects.map((s) => ({ ...s, average: subjectAverages[s.subject] ?? null })),
    students: rows,
    summary: {
      studentCount: rows.length,
      genders,
      withParentAccount: rows.filter((r) => r.guardians.some((g) => g.hasAccount)).length,
      assessmentsGiven: data.assessments.length,
      classAverage: avg(rows.map((r) => r.stats.average).filter((v) => v != null)),
      handInRate: avg(rows.map((r) => r.stats.handInRate).filter((v) => v != null)),
      examAverage: avg(rows.map((r) => r.stats.examAverage).filter((v) => v != null)),
      atRisk: rows.filter((r) => r.stats.average != null && r.stats.average < 50).map((r) => ({ id: r.id, fullName: r.fullName, average: r.stats.average })),
      mostMissing: rows.filter((r) => r.stats.missing >= 3).sort((a, b) => b.stats.missing - a.stats.missing).slice(0, 10).map((r) => ({ id: r.id, fullName: r.fullName, missing: r.stats.missing })),
    },
  };
}

const schoolHeader = (school) => ({ id: String(school._id), name: school.name, code: school.code || null, logo: school.logo || null, district: school.address?.district || null, phone: school.phone || null });

/** GET /schools/:schoolId/students/:userId/report */
const studentReport = wrap(async (req, res) => {
  const school = await schoolFor(req, { manage: false });
  requireId(req.params.userId, 'student id');
  const student = await User.findOne({ _id: req.params.userId, schoolId: school._id, role: 'student' }).lean();
  if (!student) throw new HttpError('Student not found', 404);
  const classroom = student.classroomId ? await Classroom.findById(student.classroomId).populate('classTeacherId', 'fullName phone').lean() : null;
  if (!canManageSchool(req.user, school._id)) {
    if (!classroom || !canSeeClassReport(req.user, classroom)) throw new HttpError('Only the class teacher or the school administration can see this report.', 403);
  }
  let work = { items: [], bySubject: {}, stats: {}, exams: [] };
  let subjects = [];
  if (classroom) {
    const data = await loadClassData(classroom, { studentId: student._id });
    work = studentWork(student, data);
    subjects = data.subjects.map((s) => ({ ...s, average: work.bySubject[s.subject] ?? null }));
  } else {
    const exams = await ExternalExamResult.find({ user: student._id }).sort({ completedAt: -1 }).lean();
    work.exams = exams.map((e) => ({ title: e.examTitle, score: e.score, maxScore: e.maxScore, percentage: Math.round(e.percentage || 0), passed: e.passed, completedAt: e.completedAt }));
  }
  const signIns = await LoginAudit.find({ userId: student._id }).sort({ at: -1 }).limit(10).lean();
  ok(res, {
    generatedAt: new Date(),
    school: schoolHeader(school),
    student: studentProfile(student, classroom),
    classroom: classroom ? {
      id: String(classroom._id), name: classroom.name, level: classroom.level, academicYear: classroom.academicYear,
      classTeacher: classroom.classTeacherId?.fullName ? { fullName: classroom.classTeacherId.fullName, phone: classroom.classTeacherId.phone || null } : null,
    } : null,
    subjects,
    assessments: work.items,
    exams: work.exams,
    stats: work.stats,
    signIns: signIns.map((l) => ({ at: l.at, success: l.success, method: l.method, suspicious: !!l.suspicious, reason: l.reason || null })),
  });
});

/** GET /school/classes/:classId/report */
const classReport = wrap(async (req, res) => {
  requireId(req.params.classId, 'class id');
  const classroom = await Classroom.findById(req.params.classId).populate('classTeacherId', 'fullName').lean();
  if (!classroom) throw new HttpError('Class not found', 404);
  if (!canSeeClassReport(req.user, classroom)) throw new HttpError('Only the class teacher or the school administration can download the class report.', 403);
  const school = await School.findById(classroom.schoolId).lean();
  const data = await loadClassData(classroom);
  ok(res, { generatedAt: new Date(), school: schoolHeader(school), ...classSummary(classroom, data) });
});

/** GET /schools/:schoolId/report — every active class, one after the other. */
const schoolReport = wrap(async (req, res) => {
  const school = await schoolFor(req);
  const classes = await Classroom.find({ schoolId: school._id, isActive: true }).populate('classTeacherId', 'fullName').sort({ level: 1, combination: 1, stream: 1 }).lean();
  const out = [];
  for (const c of classes) out.push(classSummary(c, await loadClassData(c)));
  const [teacherCount, unassigned] = await Promise.all([
    User.countDocuments({ schoolId: school._id, role: 'instructor', isActive: true }),
    User.find({ schoolId: school._id, role: 'student', isActive: true, classroomId: null }).select('fullName studentCode gender').sort({ fullName: 1 }).lean(),
  ]);
  const all = out.flatMap((c) => c.students);
  ok(res, {
    generatedAt: new Date(),
    school: schoolHeader(school),
    summary: {
      classCount: out.length,
      studentCount: all.length + unassigned.length,
      teacherCount,
      schoolAverage: avg(all.map((r) => r.stats.average).filter((v) => v != null)),
      handInRate: avg(all.map((r) => r.stats.handInRate).filter((v) => v != null)),
      atRiskCount: all.filter((r) => r.stats.average != null && r.stats.average < 50).length,
    },
    classes: out,
    unassignedStudents: unassigned.map((u) => ({ id: String(u._id), fullName: u.fullName, studentCode: u.studentCode || null, gender: u.gender || null })),
  });
});

module.exports = { studentReport, classReport, schoolReport };
