/**
 * School management: super admin → school → classes/streams → teachers →
 * students (no duplicates) + parents → PIN sign-in (one session) →
 * lessons taught (flags) → homework → student & parent views → billing.
 */
const { startDb, stopDb, clearDb, silenceLogs } = require('./helpers/setup');
const test = require('node:test');
const assert = require('node:assert/strict');

process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret';
process.env.JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'test-refresh-secret';

// Firebase stub: records created accounts; ID tokens are never valid (forces the ECH JWT path).
const admin = require('../src/config/firebase');
const fb = { users: [], failNextCreate: null, customTokens: [] };
const fakeAuth = {
  verifyIdToken: async () => { throw new Error('not a firebase token'); },
  createUser: async (u) => {
    if (fb.failNextCreate) { const e = new Error('x'); e.code = fb.failNextCreate; fb.failNextCreate = null; throw e; }
    const uid = `fb-${fb.users.length + 1}`; fb.users.push({ uid, ...u }); return { uid };
  },
  setCustomUserClaims: async () => {},
  deleteUser: async (uid) => { fb.users = fb.users.filter((u) => u.uid !== uid); },
  updateUser: async () => {},
  revokeRefreshTokens: async () => {},
  createCustomToken: async (uid, claims) => { fb.customTokens.push({ uid, claims }); return `custom-${uid}`; },
  getUser: async () => ({}),
};
Object.defineProperty(admin, 'auth', { configurable: true, writable: true, value: () => fakeAuth });
Object.defineProperty(admin, 'messaging', { configurable: true, writable: true, value: () => ({ send: async () => 'ok', sendEachForMulticast: async () => ({ successCount: 0, failureCount: 0, responses: [] }) }) });

const User = require('../src/models/User');
const School = require('../src/models/School');
const SchoolTerm = require('../src/models/SchoolTerm');
const LessonCoverage = require('../src/models/LessonCoverage');
const Notification = require('../src/models/Notification');
const Course = require('../src/models/Course');
const Section = require('../src/models/Section');
const Lesson = require('../src/models/Lesson');
const schools = require('../src/controllers/school/schools.controller');
const classes = require('../src/controllers/school/classes.controller');
const members = require('../src/controllers/school/members.controller');
const teaching = require('../src/controllers/school/teaching.controller');
const learner = require('../src/controllers/school/learner.controller');
const reports = require('../src/controllers/school/reports.controller');
const studentReports = require('../src/controllers/school/studentReports.controller');
const pinAuth = require('../src/controllers/pinAuth.controller');
const { protect } = require('../src/middleware/auth.middleware');
const { denySelfRegisteredTeacher } = require('../src/services/teacherAccess.service');
const { hasSchoolCourseAccess, subscriptionStatus } = require('../src/services/school/subscription.service');

let restoreLogs;
test.before(async () => {
  restoreLogs = silenceLogs();
  await startDb();
  for (const m of [User, School, SchoolTerm, require('../src/models/Classroom'), require('../src/models/ClassSubject'), require('../src/models/AssessmentSubmission')]) await m.syncIndexes();
});
test.after(async () => { await stopDb(); restoreLogs(); });
test.beforeEach(async () => { await clearDb(); fb.users = []; fb.customTokens = []; pinAuth.resetLimits(); });

function call(handler, req) {
  return new Promise((resolve, reject) => {
    const res = {
      statusCode: 200,
      headers: {},
      status(code) { this.statusCode = code; return this; },
      set(k, v) { this.headers[k] = v; return this; },
      json(payload) { resolve({ status: this.statusCode, body: payload }); return this; },
    };
    Promise.resolve(handler({ params: {}, body: {}, query: {}, headers: {}, ip: '10.0.0.1', ...req }, res)).catch(reject);
  });
}

const me = async (id) => User.findById(id);

async function superAdmin() {
  return User.create({ fullName: 'ECH Admin', email: 'admin@ech.rw', role: 'admin' });
}

/** School + school admin + term paid for 3 students, classes S3 A/B and S5 MPC, two teachers. */
async function setupSchool() {
  const sa = await superAdmin();
  const r = await call(schools.createSchool, { user: sa, body: { name: 'Groupe Scolaire Butare', address: { district: 'Huye', sector: 'Ngoma' }, admin: { fullName: 'Director Uwase', email: 'Director@GSB.rw' } } });
  assert.equal(r.status, 201, JSON.stringify(r.body));
  const schoolId = r.body.data.school.id;
  const headId = r.body.data.schoolAdmin.id;
  const head = await me(headId);

  const c1 = await call(classes.createClasses, { user: head, params: { schoolId }, body: { level: 's3', streams: ['A', 'B'], academicYear: '2026' } });
  assert.equal(c1.status, 201, JSON.stringify(c1.body));
  const c2 = await call(classes.createClasses, { user: head, params: { schoolId }, body: { level: 'S5', combination: 'mpc', stream: 'A', academicYear: '2026' } });
  assert.equal(c2.body.data.classes[0].name, 'S5 MPC A');

  const t1 = await call(members.addTeacher, { user: head, params: { schoolId }, body: { fullName: 'Jean Teacher', email: 'jean@gsb.rw', address: { district: 'Huye', sector: 'Tumba' }, teacherProfile: { subjects: ['Biology'], levels: ['S3'] } } });
  assert.equal(t1.status, 201, JSON.stringify(t1.body));
  const t2 = await call(members.addTeacher, { user: head, params: { schoolId }, body: { fullName: 'Marie Maths', phone: '0788000111' } });
  assert.equal(t2.status, 201, JSON.stringify(t2.body));
  const classTeacher = await me(t1.body.data.user.id);
  const mathsTeacher = await me(t2.body.data.user.id);

  const s3a = c1.body.data.classes.find((c) => c.name === 'S3 A');
  const s3b = c1.body.data.classes.find((c) => c.name === 'S3 B');
  await call(classes.updateClass, { user: head, params: { classId: s3a.id }, body: { classTeacherId: classTeacher.id } });

  const course = await Course.create({ title: 'Biology S3', description: 'x', createdBy: sa._id, price: 5000, duration: 10, level: 'beginner', isPublished: true });
  const sec = await Section.create({ courseId: course._id, title: 'Unit 1: Cells', order: 1 });
  const lessons = [];
  for (let i = 1; i <= 6; i++) lessons.push(await Lesson.create({ courseId: course._id, sectionId: sec._id, title: `Lesson ${i}`, order: i }));

  const subj = await call(classes.addSubjects, { user: head, params: { classId: s3a.id }, body: { subjects: [
    { subject: 'Biology', teacherId: classTeacher.id, courseId: String(course._id) },
    { subject: 'Mathematics', teacherId: mathsTeacher.id },
  ] } });
  assert.equal(subj.status, 201, JSON.stringify(subj.body));
  const bio = subj.body.data.subjects.find((s) => s.subject === 'Biology');
  const maths = subj.body.data.subjects.find((s) => s.subject === 'Mathematics');

  const now = Date.now();
  const term = await SchoolTerm.create({ schoolId, academicYear: '2026', term: 3, startDate: new Date(now - 30 * 864e5), endDate: new Date(now + 60 * 864e5), billing: { studentsPaid: 3, pricePerStudent: 2000, status: 'paid' } });

  return { sa, head, schoolId, s3a, s3b, classTeacher, mathsTeacher, bio, maths, course, lessons, term, createBody: r.body.data };
}

async function addStudent(actor, schoolId, body) {
  return call(members.addStudent, { user: actor, params: { schoolId }, body });
}

test('super admin creates a school: generated password returned once, no hard-coded default', async () => {
  const sa = await superAdmin();
  const r = await call(schools.createSchool, { user: sa, body: { name: 'Lycée de Kigali', admin: { fullName: 'Head One', email: 'head@ldk.rw' } } });
  assert.equal(r.status, 201);
  const { credentials, school } = r.body.data;
  assert.equal(credentials.generated, true);
  assert.ok(credentials.password.length >= 12);
  assert.notEqual(credentials.password, 'Echapp2026!SchoolAdmin');
  assert.equal(fb.users[0].password, credentials.password);
  assert.equal(school.code, 'LDK');
  assert.equal(school.subscription.status, 'trial');
});

test('a Firebase failure leaves no half-created school or user', async () => {
  const sa = await superAdmin();
  fb.failNextCreate = 'auth/email-already-exists';
  const r = await call(schools.createSchool, { user: sa, body: { name: 'X School', admin: { fullName: 'Head X', email: 'x@x.rw' } } });
  assert.equal(r.status, 409);
  assert.equal(await School.countDocuments(), 0);
  assert.equal(await User.countDocuments({ role: 'school_admin' }), 0);
});

test('students: class teacher registers, subject teacher cannot, duplicates are caught, seat limit enforced', async () => {
  const s = await setupSchool();

  const ok1 = await addStudent(s.classTeacher, s.schoolId, { fullName: 'Aline Mukamana', gender: 'female', dateOfBirth: '2011-03-02', classroomId: s.s3a.id, guardians: [{ name: 'Paul Habimana', phone: '0788123456', relationship: 'Father' }] });
  assert.equal(ok1.status, 201, JSON.stringify(ok1.body));
  assert.match(ok1.body.data.credentials.studentCode, /^GSB\d{6}$/);
  assert.match(ok1.body.data.credentials.pin, /^\d{6}$/);
  assert.equal(ok1.body.data.parents.length, 1);
  assert.match(ok1.body.data.parents[0].pin, /^\d{6}$/);

  // Subject teacher of S3 A may not add students.
  const denied = await addStudent(s.mathsTeacher, s.schoolId, { fullName: 'Other Kid', classroomId: s.s3a.id });
  assert.equal(denied.status, 403);
  // Class teacher of S3 A may not add to S3 B.
  const otherClass = await addStudent(s.classTeacher, s.schoolId, { fullName: 'Other Kid', classroomId: s.s3b.id });
  assert.equal(otherClass.status, 403);

  // Same name + birth date → asked to confirm, not registered twice.
  const dup = await addStudent(s.head, s.schoolId, { fullName: 'mukamana aline', dateOfBirth: '2011-03-02', classroomId: s.s3b.id });
  assert.equal(dup.status, 409);
  assert.equal(dup.body.code, 'POSSIBLE_DUPLICATE');
  assert.equal(dup.body.candidates[0].strong, true);
  assert.equal(await User.countDocuments({ role: 'student' }), 1);

  // A second child of the same parent links to the same parent account.
  const sibling = await addStudent(s.head, s.schoolId, { fullName: 'Eric Habimana', classroomId: s.s3a.id, guardians: [{ name: 'Paul Habimana', phone: '+250788123456' }] });
  assert.equal(sibling.status, 201);
  assert.equal(sibling.body.data.parents[0].existing, true);
  assert.equal(await User.countDocuments({ role: 'parent' }), 1);

  await addStudent(s.head, s.schoolId, { fullName: 'Third Student', classroomId: s.s3a.id });
  const full = await addStudent(s.head, s.schoolId, { fullName: 'Fourth Student', classroomId: s.s3a.id });
  assert.equal(full.status, 403);
  assert.equal(full.body.code, 'STUDENT_LIMIT_REACHED');

  // Subject teacher sees only the classes they teach.
  const list = await call(members.listStudents, { user: s.mathsTeacher, params: { schoolId: s.schoolId }, query: {} });
  assert.equal(list.body.data.total, 3);
  const forbidden = await call(members.listStudents, { user: s.mathsTeacher, params: { schoolId: s.schoolId }, query: { classId: s.s3b.id } });
  assert.equal(forbidden.status, 403);
});

test('PIN sign-in: student code + PIN, lockout, one active session, parent by phone', async () => {
  const s = await setupSchool();
  const r = await addStudent(s.head, s.schoolId, { fullName: 'Aline Mukamana', classroomId: s.s3a.id, guardians: [{ name: 'Paul', phone: '0788123456' }] });
  const { studentCode, pin } = r.body.data.credentials;

  const first = await call(pinAuth.pinLogin, { body: { identifier: studentCode.toLowerCase().replace(/(\d{2})/, '-$1'), pin, deviceId: 'lab-pc-1' } });
  assert.equal(first.status, 200, JSON.stringify(first.body));
  assert.equal(first.body.data.user.role, 'student');
  assert.equal(first.body.data.firebaseCustomToken, `custom-ech-${r.body.data.student.id}`);
  assert.ok(fb.customTokens[0].claims.sid);

  const auth = (token) => new Promise((resolve) => {
    const res = { statusCode: 200, status(c) { this.statusCode = c; return this; }, json(b) { resolve({ status: this.statusCode, body: b }); return this; } };
    protect({ headers: { authorization: `Bearer ${token}` }, method: 'GET', originalUrl: '/x' }, res, () => resolve('next'));
  });
  assert.equal(await auth(first.body.data.token), 'next');

  // Signing in on another PC ends the first session.
  const second = await call(pinAuth.pinLogin, { body: { identifier: studentCode, pin, deviceId: 'lab-pc-2' } });
  assert.equal(second.status, 200);
  const old = await auth(first.body.data.token);
  assert.equal(old.status, 401);
  assert.equal(old.body.code, 'SESSION_REPLACED');
  assert.equal(await auth(second.body.data.token), 'next');
  assert.ok(await Notification.exists({ userId: r.body.data.student.id, title: 'New sign-in' }));

  // Wrong PIN 5 times → locked, even with the right PIN.
  const wrong = pin === '111112' ? '111113' : '111112';
  for (let i = 0; i < 5; i++) await call(pinAuth.pinLogin, { body: { identifier: studentCode, pin: wrong }, ip: `10.0.1.${i}` });
  const locked = await call(pinAuth.pinLogin, { body: { identifier: studentCode, pin }, ip: '10.0.2.1' });
  assert.equal(locked.status, 423);

  // Parent signs in with phone + PIN in any format.
  const parentPin = r.body.data.parents[0].pin;
  const p = await call(pinAuth.pinLogin, { body: { identifier: '0788 123 456', pin: parentPin }, ip: '10.0.3.1' });
  assert.equal(p.status, 200, JSON.stringify(p.body));
  assert.equal(p.body.data.user.role, 'parent');
});

test('lessons taught: ECH flags future dates, bulk marking and student disputes', async () => {
  const s = await setupSchool();
  const kids = [];
  for (const n of ['Aline Mukamana', 'Eric Habimana', 'Grace Uwera']) {
    const r = await addStudent(s.head, s.schoolId, { fullName: n, classroomId: s.s3a.id });
    kids.push(await me(r.body.data.student.id));
  }
  const lastWeekday = new Date();
  while ([0, 6].includes(lastWeekday.getDay())) lastWeekday.setDate(lastWeekday.getDate() - 1);

  const good = await call(teaching.markTaught, { user: s.classTeacher, params: { id: s.bio.id }, body: { lessonId: String(s.lessons[0]._id), taughtOn: lastWeekday, notes: 'Drew and labelled an animal cell; pupils copied notes.' } });
  assert.equal(good.status, 201, JSON.stringify(good.body));
  assert.equal(good.body.data.coverage.status, 'ok');

  const twice = await call(teaching.markTaught, { user: s.classTeacher, params: { id: s.bio.id }, body: { lessonId: String(s.lessons[0]._id), taughtOn: lastWeekday } });
  assert.equal(twice.status, 409);

  // Maths teacher cannot mark Biology.
  const notMine = await call(teaching.markTaught, { user: s.mathsTeacher, params: { id: s.bio.id }, body: { topic: 'x' } });
  assert.equal(notMine.status, 403);

  const future = await call(teaching.markTaught, { user: s.classTeacher, params: { id: s.bio.id }, body: { lessonId: String(s.lessons[1]._id), taughtOn: new Date(Date.now() + 864e5) } });
  assert.equal(future.body.data.coverage.status, 'flagged');
  assert.ok(future.body.data.coverage.flags.some((f) => f.code === 'FUTURE_DATE'));

  // 4 marks within minutes → bulk marking flagged.
  for (const l of s.lessons.slice(2, 4)) {
    await call(teaching.markTaught, { user: s.classTeacher, params: { id: s.bio.id }, body: { lessonId: String(l._id), taughtOn: lastWeekday, notes: 'Covered the full lesson in class today.' } });
  }
  assert.ok(await LessonCoverage.exists({ lessonId: s.lessons[3]._id, status: 'flagged', 'flags.code': 'BULK_MARKING' }));

  // Students say the first lesson was not taught → flagged for review.
  const covId = good.body.data.coverage.id;
  const home = await call(learner.studentHome, { user: kids[0] });
  assert.ok(home.body.data.lessonChecks.some((c) => c.id === covId));
  for (const k of kids) await call(learner.checkLesson, { user: k, params: { id: covId }, body: { taught: false } });
  const disputed = await LessonCoverage.findById(covId);
  assert.equal(disputed.status, 'flagged');
  assert.ok(disputed.flags.some((f) => f.code === 'STUDENTS_DISPUTE'));

  // Head teacher reviews it.
  const review = await call(reports.reviewCoverage, { user: s.head, params: { schoolId: s.schoolId, id: covId }, body: { status: 'confirmed', note: 'Checked the timetable.' } });
  assert.equal(review.body.data.coverage.status, 'confirmed');
  const prog = await call(reports.progress, { user: s.head, params: { schoolId: s.schoolId }, query: {} });
  const bioRow = prog.body.data.classes.find((c) => c.name === 'S3 A').subjects.find((x) => x.subject === 'Biology');
  assert.equal(bioRow.syllabusLessons, 6);
  assert.equal(bioRow.confirmedNotTaught, 1);
});

test('homework: teacher assigns, students notified, student hands in, teacher marks, parent sees it', async () => {
  const s = await setupSchool();
  const r = await addStudent(s.head, s.schoolId, { fullName: 'Aline Mukamana', classroomId: s.s3a.id, guardians: [{ name: 'Paul', phone: '0788123456' }] });
  const kid = await me(r.body.data.student.id);
  const parent = await me(r.body.data.parents[0].id);

  const hw = await call(teaching.createAssessment, { user: s.classTeacher, params: { id: s.bio.id }, body: { title: 'Read chapter 3', instructions: 'Read and draw a plant cell. Upload a photo.', dueAt: new Date(Date.now() + 3 * 864e5), maxScore: 10, submissionMode: 'photo' } });
  assert.equal(hw.status, 201, JSON.stringify(hw.body));
  const hwId = hw.body.data.assessment.id;
  assert.ok(await Notification.exists({ userId: kid._id, type: 'homework' }));
  assert.ok(await Notification.exists({ userId: parent._id, type: 'homework' }));

  let home = await call(learner.studentHome, { user: kid });
  assert.equal(home.body.data.todo.length, 1);
  assert.equal(home.body.data.todo[0].state, 'todo');

  const empty = await call(learner.submitAssessment, { user: kid, params: { id: hwId }, body: {} });
  assert.equal(empty.status, 400);
  const sub = await call(learner.submitAssessment, { user: kid, params: { id: hwId }, body: { attachments: [{ url: 'https://cdn.example/x.jpg', name: 'x.jpg', type: 'image/jpeg' }] } });
  assert.equal(sub.status, 201);

  const detail = await call(teaching.getAssessment, { user: s.classTeacher, params: { id: hwId } });
  const row = detail.body.data.students.find((x) => x.id === String(kid._id));
  const tooHigh = await call(teaching.gradeSubmission, { user: s.classTeacher, params: { id: hwId, subId: row.submission.id }, body: { score: 11 } });
  assert.equal(tooHigh.status, 400);
  const graded = await call(teaching.gradeSubmission, { user: s.classTeacher, params: { id: hwId, subId: row.submission.id }, body: { score: 8, feedback: 'Good drawing' } });
  assert.equal(graded.status, 200);

  home = await call(learner.studentHome, { user: kid });
  assert.equal(home.body.data.todo.length, 0);
  assert.equal(home.body.data.recent[0].state, 'graded');
  assert.equal(home.body.data.subjects.find((x) => x.subject === 'Biology').averagePercent, 80);

  const kids = await call(learner.parentChildren, { user: parent });
  assert.equal(kids.body.data.children.length, 1);
  const child = await call(learner.parentChild, { user: parent, params: { id: String(kid._id) } });
  assert.equal(child.body.data.recent[0].submission.score, 8);
  // A parent cannot open someone else's child.
  const other = await addStudent(s.head, s.schoolId, { fullName: 'Someone Else', classroomId: s.s3a.id });
  const nope = await call(learner.parentChild, { user: parent, params: { id: other.body.data.student.id } });
  assert.equal(nope.status, 404);

  const results = await call(reports.results, { user: s.head, params: { schoolId: s.schoolId }, query: { classId: s.s3a.id } });
  assert.equal(results.body.data.subjectAverages.Biology, 80);
});

test('student, class and school reports: right people only, numbers agree', async () => {
  const s = await setupSchool();
  const a = await addStudent(s.head, s.schoolId, { fullName: 'Aline Mukamana', gender: 'female', classroomId: s.s3a.id, guardians: [{ name: 'Paul', phone: '0788123456' }] });
  const b = await addStudent(s.head, s.schoolId, { fullName: 'Eric Niyonzima', gender: 'male', classroomId: s.s3a.id });
  const aline = await me(a.body.data.student.id);

  // One graded homework (Aline 8/10), one past due that nobody handed in.
  const hw = await call(teaching.createAssessment, { user: s.classTeacher, params: { id: s.bio.id }, body: { title: 'Draw a cell', dueAt: new Date(Date.now() + 864e5), maxScore: 10, submissionMode: 'text' } });
  await call(learner.submitAssessment, { user: aline, params: { id: hw.body.data.assessment.id }, body: { text: 'cell' } });
  const detail = await call(teaching.getAssessment, { user: s.classTeacher, params: { id: hw.body.data.assessment.id } });
  const subId = detail.body.data.students.find((x) => x.id === String(aline._id)).submission.id;
  await call(teaching.gradeSubmission, { user: s.classTeacher, params: { id: hw.body.data.assessment.id, subId }, body: { score: 8 } });
  const Assessment = require('../src/models/Assessment');
  await Assessment.create({ schoolId: s.schoolId, classroomId: s.s3a.id, classSubjectId: s.maths.id, subject: 'Mathematics', teacherId: s.mathsTeacher._id, title: 'Fractions', dueAt: new Date(Date.now() - 864e5), maxScore: 20, submissionMode: 'text' });

  // Student report: class teacher yes, subject teacher no.
  const sr = await call(studentReports.studentReport, { user: s.classTeacher, params: { schoolId: s.schoolId, userId: String(aline._id) } });
  assert.equal(sr.status, 200, JSON.stringify(sr.body));
  assert.equal(sr.body.data.student.guardians[0].name, 'Paul');
  assert.equal(sr.body.data.stats.average, 80);
  assert.equal(sr.body.data.stats.missing, 1);
  assert.equal(sr.body.data.assessments.find((x) => x.title === 'Draw a cell').percent, 80);
  const denied = await call(studentReports.studentReport, { user: s.mathsTeacher, params: { schoolId: s.schoolId, userId: String(aline._id) } });
  assert.equal(denied.status, 403);

  // Class report.
  const cr = await call(studentReports.classReport, { user: s.classTeacher, params: { classId: s.s3a.id } });
  assert.equal(cr.status, 200, JSON.stringify(cr.body));
  assert.equal(cr.body.data.summary.studentCount, 2);
  assert.deepEqual(cr.body.data.summary.genders, { male: 1, female: 1, other: 0 });
  assert.equal(cr.body.data.subjects.find((x) => x.subject === 'Biology').average, 80);
  const row = cr.body.data.students.find((x) => x.id === String(aline._id));
  assert.equal(row.position, 1);
  assert.equal(cr.body.data.students.find((x) => x.id === b.body.data.student.id).stats.missing, 1);
  assert.equal((await call(studentReports.classReport, { user: s.mathsTeacher, params: { classId: s.s3a.id } })).status, 403);

  // School report: managers only (route) — every active class is listed.
  const sch = await call(studentReports.schoolReport, { user: s.head, params: { schoolId: s.schoolId } });
  assert.equal(sch.status, 200, JSON.stringify(sch.body));
  assert.equal(sch.body.data.classes.length, 3);
  assert.equal(sch.body.data.summary.studentCount, 2);
  assert.equal((await call(studentReports.schoolReport, { user: s.classTeacher, params: { schoolId: s.schoolId } })).status, 403);
});

test('billing: paid term gives course access, grace period, then expiry', async () => {
  const s = await setupSchool();
  const r = await addStudent(s.head, s.schoolId, { fullName: 'Aline Mukamana', classroomId: s.s3a.id });
  // The class syllabus course (Biology S3) is free; other courses only when the super admin marks them for S3.
  assert.equal(await hasSchoolCourseAccess(r.body.data.student.id, s.course), true);
  assert.equal(await hasSchoolCourseAccess(r.body.data.student.id), false);
  const chem = await Course.create({ title: 'Chemistry S3', description: 'x', createdBy: s.sa._id, price: 5000, duration: 10, level: 'beginner', isPublished: true });
  const physS4 = await Course.create({ title: 'Physics S4', description: 'x', createdBy: s.sa._id, price: 5000, duration: 10, level: 'beginner', isPublished: true });
  assert.equal(await hasSchoolCourseAccess(r.body.data.student.id, chem), false);
  const schoolCourses = require('../src/controllers/school/courses.controller');
  const mark = await call(schoolCourses.updateCourseAccess, { user: s.sa, params: { courseId: String(chem._id) }, body: { enabled: true, levels: ['s3', 'S2'], subject: 'Chemistry' } });
  assert.equal(mark.status, 200, JSON.stringify(mark.body));
  assert.deepEqual(mark.body.data.course.schoolAccess.levels, ['S3', 'S2']);
  assert.equal((await call(schoolCourses.updateCourseAccess, { user: s.sa, params: { courseId: String(physS4._id) }, body: { enabled: true, levels: ['X9'] } })).status, 400);
  await call(schoolCourses.updateCourseAccess, { user: s.sa, params: { courseId: String(physS4._id) }, body: { enabled: true, levels: ['S4'] } });
  assert.equal(await hasSchoolCourseAccess(r.body.data.student.id, await Course.findById(chem._id)), true);
  assert.equal(await hasSchoolCourseAccess(r.body.data.student.id, await Course.findById(physS4._id)), false);
  const home = await call(learner.studentHome, { user: await me(r.body.data.student.id) });
  assert.deepEqual(home.body.data.courses.map((c) => c.title), ['Biology S3', 'Chemistry S3']);
  assert.equal(home.body.data.courses.find((c) => c.title === 'Chemistry S3').subject, 'Chemistry');

  // Only ECH records payments.
  const headTries = await call(schools.updateTerm, { user: s.head, params: { schoolId: s.schoolId, termId: String(s.term._id) }, body: { billing: { studentsPaid: 999 } } });
  assert.equal(headTries.status, 403);

  const DAY = 864e5;
  await SchoolTerm.updateOne({ _id: s.term._id }, { startDate: new Date(Date.now() - 100 * DAY), endDate: new Date(Date.now() - 10 * DAY) });
  assert.equal((await subscriptionStatus(s.schoolId)).status, 'grace');
  await SchoolTerm.updateOne({ _id: s.term._id }, { endDate: new Date(Date.now() - 40 * DAY) });
  assert.equal((await subscriptionStatus(s.schoolId)).status, 'expired');
  assert.equal(await hasSchoolCourseAccess(r.body.data.student.id, s.course), false);
});

test('school teachers cannot edit ECH course content; staff passwords never default', async () => {
  const s = await setupSchool();
  const result = await new Promise((resolve) => {
    const res = { statusCode: 200, status(c) { this.statusCode = c; return this; }, json(b) { resolve({ status: this.statusCode, body: b }); return this; } };
    denySelfRegisteredTeacher({ user: s.classTeacher }, res, () => resolve('next'));
  });
  assert.equal(result.status, 403);
  // Teacher created with phone only still gets a generated password (backend sign-in).
  const maths = await User.findById(s.mathsTeacher._id).select('+password');
  assert.ok(maths.password && maths.password.startsWith('$2'));
  assert.equal(s.classTeacher.address.sector, 'Tumba');
});

// ── "School only" sign-in: class codes, school network, end of day ─────────
const accessCtl = require('../src/controllers/school/access.controller');
const accessSvc = require('../src/services/school/accessPolicy.service');
const AccessCode = require('../src/models/AccessCode');

function authCall(token, ip) {
  return new Promise((resolve) => {
    const res = { statusCode: 200, status(c) { this.statusCode = c; return this; }, json(b) { resolve({ status: this.statusCode, body: b }); return this; } };
    protect({ headers: { authorization: `Bearer ${token}`, ...(ip ? { 'x-forwarded-for': ip } : {}) }, method: 'GET', originalUrl: '/x' }, res, () => resolve('next'));
  });
}

test('school-only (code): class code required, scoped to the class, spoofed IP refused, session ends', async () => {
  await AccessCode.syncIndexes();
  const s = await setupSchool();
  const kid = await addStudent(s.head, s.schoolId, { fullName: 'Aline Mukamana', classroomId: s.s3a.id });
  const { studentCode, pin } = kid.body.data.credentials;

  const setMode = await call(schools.updateSchool, { user: s.head, params: { schoolId: s.schoolId }, body: { studentAccess: { mode: 'code', allowedIps: ['41.186.10.0/24'], dayStartsAt: '00:00', dayEndsAt: '23:59' } } });
  assert.equal(setMode.status, 200, JSON.stringify(setMode.body));
  const noIps = await call(schools.updateSchool, { user: s.head, params: { schoolId: s.schoolId }, body: { studentAccess: { mode: 'network', allowedIps: [] } } });
  assert.equal(noIps.status, 400);

  const home = { 'x-forwarded-for': '102.22.1.5' };
  const noCode = await call(pinAuth.pinLogin, { headers: home, body: { identifier: studentCode, pin } });
  assert.equal(noCode.status, 403);
  assert.equal(noCode.body.code, 'ACCESS_CODE_REQUIRED');

  // Maths teacher teaches S3 A: may show its code, not the code of S3 B.
  const codeA = await call(accessCtl.currentAccessCode, { user: s.mathsTeacher, query: { classId: s.s3a.id } });
  assert.equal(codeA.status, 200, JSON.stringify(codeA.body));
  assert.match(codeA.body.data.code, /^\d{6}$/);
  const codeB = await call(accessCtl.currentAccessCode, { user: s.mathsTeacher, query: { classId: s.s3b.id } });
  assert.equal(codeB.status, 403);
  // The same code is shown again until it nearly expires.
  const again = await call(accessCtl.currentAccessCode, { user: s.classTeacher, query: { classId: s.s3a.id } });
  assert.equal(again.body.data.code, codeA.body.data.code);

  // Another class code does not work for this student.
  const headB = await call(accessCtl.currentAccessCode, { user: s.head, query: { classId: s.s3b.id } });
  const wrong = await call(pinAuth.pinLogin, { headers: home, body: { identifier: studentCode, pin, accessCode: headB.body.data.code } });
  assert.equal(wrong.body.code, 'ACCESS_CODE_INVALID');

  const okLogin = await call(pinAuth.pinLogin, { headers: home, body: { identifier: studentCode, pin, accessCode: codeA.body.data.code, deviceId: 'pc1' } });
  assert.equal(okLogin.status, 200, JSON.stringify(okLogin.body));
  assert.ok(okLogin.body.data.sessionEndsAt);
  assert.equal(await authCall(okLogin.body.data.token), 'next');

  // The teacher sees who signed in with the class code.
  const after = await call(accessCtl.currentAccessCode, { user: s.classTeacher, query: { classId: s.s3a.id } });
  assert.equal(after.body.data.signIns[0].fullName, 'Aline Mukamana');

  // School-wide (lab) code works for any student of the school.
  const lab = await call(accessCtl.currentAccessCode, { user: s.head, query: {} });
  assert.equal(lab.body.data.scope, 'school');
  const viaLab = await call(pinAuth.pinLogin, { headers: home, body: { identifier: studentCode, pin, accessCode: lab.body.data.code } });
  assert.equal(viaLab.status, 200);

  // On the school network no code is needed; a forged first X-Forwarded-For entry is ignored.
  const onNet = await call(pinAuth.pinLogin, { headers: { 'x-forwarded-for': '41.186.10.77' }, body: { identifier: studentCode, pin } });
  assert.equal(onNet.status, 200, JSON.stringify(onNet.body));
  const forged = await call(pinAuth.pinLogin, { headers: { 'x-forwarded-for': '41.186.10.77, 102.22.1.5' }, body: { identifier: studentCode, pin } });
  assert.equal(forged.body.code, 'ACCESS_CODE_REQUIRED');

  // At the end of the school day the session stops working.
  await User.updateOne({ _id: kid.body.data.student.id }, { activeSessionExpiresAt: new Date(Date.now() - 1000) });
  const expired = await authCall(onNet.body.data.token);
  assert.equal(expired.status, 401);
  assert.equal(expired.body.code, 'SESSION_EXPIRED');

  // A missing or wrong class code never counts as a wrong PIN.
  const u = await User.findById(kid.body.data.student.id).select('+pinFailedCount');
  assert.equal(u.pinFailedCount, 0);
});

test('school-only (network): sign-in and every request must come from the school internet', async () => {
  const s = await setupSchool();
  const kid = await addStudent(s.head, s.schoolId, { fullName: 'Aline Mukamana', classroomId: s.s3a.id });
  const { studentCode, pin } = kid.body.data.credentials;
  await call(schools.updateSchool, { user: s.head, params: { schoolId: s.schoolId }, body: { studentAccess: { mode: 'network', allowedIps: ['41.186.10.77'], dayStartsAt: '00:00', dayEndsAt: '23:59' } } });

  const fromHome = await call(pinAuth.pinLogin, { headers: { 'x-forwarded-for': '102.22.1.5' }, body: { identifier: studentCode, pin } });
  assert.equal(fromHome.body.code, 'SCHOOL_NETWORK_REQUIRED');
  const atSchool = await call(pinAuth.pinLogin, { headers: { 'x-forwarded-for': '41.186.10.77' }, body: { identifier: studentCode, pin } });
  assert.equal(atSchool.status, 200);
  assert.equal(await authCall(atSchool.body.data.token, '41.186.10.77'), 'next');
  const carriedHome = await authCall(atSchool.body.data.token, '102.22.1.5');
  assert.equal(carriedHome.body.code, 'SCHOOL_NETWORK_REQUIRED');
});

test('young pupils: class code shows the class list, tapping a name signs in (no PIN)', async () => {
  const s = await setupSchool();
  const p2 = await call(classes.createClasses, { user: s.head, params: { schoolId: s.schoolId }, body: { level: 'P2', stream: 'A', academicYear: '2026' } });
  const p2a = p2.body.data.classes[0];
  const kid = await addStudent(s.head, s.schoolId, { fullName: 'Keza Uwase', classroomId: p2a.id });
  await call(schools.updateSchool, { user: s.head, params: { schoolId: s.schoolId }, body: { studentAccess: { mode: 'code', dayStartsAt: '00:00', dayEndsAt: '23:59' } } });

  const code = await call(accessCtl.currentAccessCode, { user: s.head, query: { classId: p2a.id } });
  assert.equal(code.body.data.pinless, true);
  const info = await call(pinAuth.classCodeInfo, { body: { code: code.body.data.code } });
  assert.equal(info.body.data.pinRequired, false);
  assert.equal(info.body.data.students[0].fullName, 'Keza Uwase');
  const login = await call(pinAuth.pinLogin, { body: { accessCode: code.body.data.code, studentId: info.body.data.students[0].id } });
  assert.equal(login.status, 200, JSON.stringify(login.body));
  assert.equal(String(login.body.data.user.id), kid.body.data.student.id);

  // S3 is not a young-pupil class: its code asks for code + PIN instead of listing names.
  const s3 = await call(accessCtl.currentAccessCode, { user: s.head, query: { classId: s.s3a.id } });
  const s3info = await call(pinAuth.classCodeInfo, { body: { code: s3.body.data.code } });
  assert.equal(s3info.body.data.pinRequired, true);
  assert.equal(s3info.body.data.students, undefined);
});

test('school day end is computed in Kigali time', () => {
  const policy = { ...accessSvc.DEFAULTS, dayEndsAt: '17:00', maxSessionHours: 9 };
  // 10:00 in Kigali = 08:00 UTC: ends 17:00 Kigali = 15:00 UTC.
  assert.equal(accessSvc.sessionExpiry(policy, new Date('2026-11-23T08:00:00Z')).toISOString(), '2026-11-23T15:00:00.000Z');
  // 07:00 Kigali: the 9-hour limit (16:00) comes before 17:00.
  assert.equal(accessSvc.sessionExpiry(policy, new Date('2026-11-23T05:00:00Z')).toISOString(), '2026-11-23T14:00:00.000Z');
  // 19:00 Kigali is outside the default school day (06:00-17:00): sign-in is refused.
  const evening = new Date('2026-11-23T17:00:00Z');
  assert.equal(accessSvc.withinSchoolHours({ ...policy, mode: 'code' }, evening), false);
  assert.equal(accessSvc.outsideHoursRefusal({ ...policy, mode: 'code' }, evening).code, 'OUTSIDE_SCHOOL_HOURS');
  // Boarding school with evening prep until 21:00: allowed, session ends at 21:00.
  const boarding = { ...policy, mode: 'code', dayEndsAt: '21:00' };
  assert.equal(accessSvc.outsideHoursRefusal(boarding, evening), null);
  assert.equal(accessSvc.sessionExpiry(boarding, evening).toISOString(), '2026-11-23T19:00:00.000Z');
  // Anywhere mode never limits hours.
  assert.equal(accessSvc.outsideHoursRefusal({ ...policy, mode: 'anywhere' }, evening), null);
});

test('school only: students cannot sign in outside school hours', async () => {
  const s = await setupSchool();
  const kid = await addStudent(s.head, s.schoolId, { fullName: 'Aline Mukamana', classroomId: s.s3a.id });
  // A window that has certainly closed: the minute before now (Kigali time).
  const k = new Date(Date.now() + 120 * 60000);
  const pad = (n) => String(n).padStart(2, '0');
  const end = `${pad(k.getUTCHours())}:${pad(k.getUTCMinutes())}`;
  const start = k.getUTCHours() === 0 && k.getUTCMinutes() === 0 ? null : '00:00';
  if (!start || end === '00:00') return; // exactly midnight in Kigali: nothing to test
  const res = await call(schools.updateSchool, { user: s.head, params: { schoolId: s.schoolId }, body: { studentAccess: { mode: 'code', dayStartsAt: start, dayEndsAt: end } } });
  assert.equal(res.status, 200, JSON.stringify(res.body));
  const login = await call(pinAuth.pinLogin, { body: { identifier: kid.body.data.credentials.studentCode, pin: kid.body.data.credentials.pin, accessCode: '000000' } });
  assert.equal(login.status, 403);
  assert.equal(login.body.code, 'OUTSIDE_SCHOOL_HOURS');
  // Start must be before end.
  const bad = await call(schools.updateSchool, { user: s.head, params: { schoolId: s.schoolId }, body: { studentAccess: { dayStartsAt: '18:00', dayEndsAt: '17:00' } } });
  assert.equal(bad.status, 400);
});

// ── Class groups (school community) and onboarding skip ────────────────────
const groupsCtl = require('../src/controllers/school/groups.controller');

test('class groups: teacher creates for own class, students discuss, outsiders and other classes are kept out', async () => {
  const s = await setupSchool();
  const a = await addStudent(s.head, s.schoolId, { fullName: 'Aline Mukamana', classroomId: s.s3a.id });
  const b = await addStudent(s.head, s.schoolId, { fullName: 'Eric Habimana', classroomId: s.s3a.id });
  const other = await addStudent(s.head, s.schoolId, { fullName: 'Grace Uwera', classroomId: s.s3b.id });
  const aline = await me(a.body.data.student.id);
  const eric = await me(b.body.data.student.id);
  const grace = await me(other.body.data.student.id);

  // A teacher cannot create a group for a class they do not teach.
  const notMine = await call(groupsCtl.createGroup, { user: s.mathsTeacher, body: { classroomId: s.s3b.id, name: 'Nope' } });
  assert.equal(notMine.status, 403);

  const created = await call(groupsCtl.createGroup, { user: s.mathsTeacher, body: { classroomId: s.s3a.id, name: 'S3 A Maths questions', subject: 'Mathematics' } });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  const gid = created.body.data.group.id;
  assert.equal(created.body.data.group.studentCount, 2);

  // Students of the class see it; students of another class do not.
  const mine = await call(groupsCtl.myGroups, { user: aline });
  assert.equal(mine.body.data.groups.length, 1);
  assert.equal((await call(groupsCtl.myGroups, { user: grace })).body.data.groups.length, 0);
  assert.equal((await call(groupsCtl.listMessages, { user: grace, params: { id: gid } })).status, 403);

  const m1 = await call(groupsCtl.postMessage, { user: aline, params: { id: gid }, body: { text: 'How do we solve question 4?' } });
  assert.equal(m1.status, 201);
  await call(groupsCtl.postMessage, { user: s.mathsTeacher, params: { id: gid }, body: { text: 'Factorise first.', replyTo: m1.body.data.message.id } });

  // Unread count for Eric, then zero after opening.
  assert.equal((await call(groupsCtl.myGroups, { user: eric })).body.data.groups[0].unread, 2);
  const list = await call(groupsCtl.listMessages, { user: eric, params: { id: gid } });
  assert.equal(list.body.data.messages.length, 2);
  assert.equal(list.body.data.messages[1].replyTo, m1.body.data.message.id);
  assert.equal((await call(groupsCtl.myGroups, { user: eric })).body.data.groups[0].unread, 0);

  // Students delete only their own messages; teachers moderate.
  const ericDel = await call(groupsCtl.deleteMessage, { user: eric, params: { id: gid, messageId: m1.body.data.message.id } });
  assert.equal(ericDel.status, 403);
  const teacherDel = await call(groupsCtl.deleteMessage, { user: s.mathsTeacher, params: { id: gid, messageId: m1.body.data.message.id } });
  assert.equal(teacherDel.status, 200);

  // Announcements only: students cannot post.
  await call(groupsCtl.updateGroup, { user: s.mathsTeacher, params: { id: gid }, body: { announcementsOnly: true } });
  const blocked = await call(groupsCtl.postMessage, { user: aline, params: { id: gid }, body: { text: 'hi' } });
  assert.equal(blocked.status, 403);

  // Chosen students only.
  const small = await call(groupsCtl.createGroup, { user: s.classTeacher, body: { classroomId: s.s3a.id, name: 'Revision team', wholeClass: false, studentIds: [String(aline._id), String(grace._id)] } });
  assert.equal(small.status, 201);
  assert.equal(small.body.data.group.studentCount, 1); // Grace is not in S3 A, so she is ignored
  assert.equal((await call(groupsCtl.listMessages, { user: eric, params: { id: small.body.data.group.id } })).status, 403);
});

test('school accounts skip the private-learner onboarding', async () => {
  const s = await setupSchool();
  const r = await addStudent(s.head, s.schoolId, { fullName: 'Aline Mukamana', classroomId: s.s3a.id, guardians: [{ name: 'Paul', phone: '0788123456' }] });
  const kid = await me(r.body.data.student.id);
  const parent = await me(r.body.data.parents[0].id);
  assert.equal(kid.hasCompletedOnboarding, true);
  assert.equal(parent.hasCompletedOnboarding, true);
  assert.equal(s.classTeacher.hasCompletedOnboarding, true);
  // An older school account without the flag gets it on the next save.
  await User.updateOne({ _id: kid._id }, { hasCompletedOnboarding: false });
  const again = await me(kid._id);
  again.lastActive = new Date();
  await again.save();
  assert.equal((await me(kid._id)).hasCompletedOnboarding, true);

  const auth = require('../src/controllers/auth.controller');
  await User.updateOne({ _id: kid._id }, { hasCompletedOnboarding: false });
  const prof = await call(auth.getProfile, { user: { id: String(kid._id) } });
  assert.equal(prof.body.data.hasCompletedOnboarding, true);
  assert.equal(prof.body.data.schoolId, s.schoolId);
});

// ── Setup checklist, login cards, year-end promotion ───────────────────────
const yearCtl = require('../src/controllers/school/year.controller');
const Classroom = require('../src/models/Classroom');
const ClassSubject = require('../src/models/ClassSubject');

test('setup checklist reflects what the school has done', async () => {
  const s = await setupSchool();
  const before = await call(reports.overview, { user: s.head, params: { schoolId: s.schoolId } });
  const steps = Object.fromEntries(before.body.data.setup.steps.map((x) => [x.key, x.done]));
  assert.equal(steps.classes, true);
  assert.equal(steps.terms, true);
  assert.equal(steps.payment, true);
  assert.equal(steps.access, false);
  assert.equal(steps.students, false);
  await call(schools.updateSchool, { user: s.head, params: { schoolId: s.schoolId }, body: { studentAccess: { mode: 'anywhere' } } });
  const after = await call(reports.overview, { user: s.head, params: { schoolId: s.schoolId } });
  assert.equal(after.body.data.setup.steps.find((x) => x.key === 'access').done, true);
});

test('login cards: class teacher gets new PINs for the class; old PIN stops working', async () => {
  const s = await setupSchool();
  const r = await addStudent(s.head, s.schoolId, { fullName: 'Aline Mukamana', classroomId: s.s3a.id });
  const oldPin = r.body.data.credentials.pin;
  const notAllowed = await call(yearCtl.loginCards, { user: s.mathsTeacher, params: { classId: s.s3a.id } });
  assert.equal(notAllowed.status, 403);
  const cards = await call(yearCtl.loginCards, { user: s.classTeacher, params: { classId: s.s3a.id } });
  assert.equal(cards.status, 200, JSON.stringify(cards.body));
  const card = cards.body.data.cards[0];
  assert.equal(card.studentCode, r.body.data.credentials.studentCode);
  assert.match(card.pin, /^\d{6}$/);
  const oldLogin = await call(pinAuth.pinLogin, { body: { identifier: card.studentCode, pin: oldPin } });
  if (oldPin !== card.pin) assert.equal(oldLogin.status, 401);
  const newLogin = await call(pinAuth.pinLogin, { body: { identifier: card.studentCode, pin: card.pin } });
  assert.equal(newLogin.status, 200);
});

test('year-end promotion: promote, repeat, leave, graduate, copy subjects, archive', async () => {
  const s = await setupSchool();
  await School.updateOne({ _id: s.schoolId }, { levels: ['S1', 'S2', 'S3', 'S4', 'S5', 'S6'] });
  await SchoolTerm.updateOne({ _id: s.term._id }, { 'billing.studentsPaid': 20 });
  const ids = [];
  for (const n of ['Aline Mukamana', 'Eric Habimana', 'Grace Uwera', 'Jean Bosco']) {
    const r = await addStudent(s.head, s.schoolId, { fullName: n, classroomId: s.s3a.id });
    ids.push(r.body.data.student.id);
  }
  const s6 = await call(classes.createClasses, { user: s.head, params: { schoolId: s.schoolId }, body: { level: 'S6', combination: 'MPC', stream: 'A', academicYear: '2026' } });
  const s6id = s6.body.data.classes[0].id;
  const fin = await addStudent(s.head, s.schoolId, { fullName: 'Finalist Student', classroomId: s6id });

  const preview = await call(yearCtl.promotionPreview, { user: s.head, params: { schoolId: s.schoolId }, query: { fromYear: '2026' } });
  assert.equal(preview.status, 200, JSON.stringify(preview.body));
  assert.equal(preview.body.data.toYear, '2027');
  const p3a = preview.body.data.classes.find((c) => c.name === 'S3 A');
  assert.equal(p3a.suggested.action, 'promote');
  assert.equal(p3a.suggested.name, 'S4 A');
  assert.equal(p3a.needsCombination, true);
  assert.equal(preview.body.data.classes.find((c) => c.name === 'S6 MPC A').suggested.action, 'graduate');

  const run = await call(yearCtl.runPromotion, { user: s.head, params: { schoolId: s.schoolId }, body: {
    fromYear: '2026', toYear: '2027',
    plan: [
      { classId: s.s3a.id, action: 'promote', toLevel: 'S4', toCombination: 'PCB', toStream: 'A', repeaterIds: [ids[2]], leaverIds: [ids[3]] },
      { classId: s6id, action: 'graduate' },
      { classId: s.s3b.id, action: 'skip' },
    ],
  } });
  assert.equal(run.status, 200, JSON.stringify(run.body));
  assert.deepEqual(
    { p: run.body.data.summary.promoted, r: run.body.data.summary.repeated, g: run.body.data.summary.graduated, l: run.body.data.summary.left },
    { p: 2, r: 1, g: 1, l: 1 },
  );

  const s4 = await Classroom.findOne({ schoolId: s.schoolId, academicYear: '2027', level: 'S4', combination: 'PCB', stream: 'A' });
  assert.ok(s4);
  assert.equal((await me(ids[0])).classroomId.toString(), String(s4._id));
  const repeater = await me(ids[2]);
  const repeatClass = await Classroom.findById(repeater.classroomId);
  assert.equal(repeatClass.level, 'S3');
  assert.equal(repeatClass.academicYear, '2027');
  assert.equal((await me(ids[3])).leftReason, 'left');
  const finalist = await me(fin.body.data.student.id);
  assert.equal(finalist.isActive, false);
  assert.equal(finalist.leftReason, 'graduated');
  // Subjects and teachers copied; old classes archived; skipped class untouched.
  const s4subjects = await ClassSubject.find({ classroomId: s4._id }).lean();
  assert.deepEqual(s4subjects.map((x) => x.subject).sort(), ['Biology', 'Mathematics']);
  assert.equal(String(s4subjects.find((x) => x.subject === 'Biology').teacherId), String(s.classTeacher._id));
  assert.equal(s4subjects.find((x) => x.subject === 'Biology').courseId, null);
  assert.equal((await Classroom.findById(s.s3a.id)).isActive, false);
  assert.equal((await Classroom.findById(s.s3b.id)).isActive, true);
  assert.equal(yearCtl.nextYear('2025-2026'), '2026-2027');
  assert.equal(yearCtl.nextLevel('P6', ['P1', 'P2', 'P3', 'P4', 'P5', 'P6']), null);
  assert.equal(yearCtl.nextLevel('P6', []), 'S1');
});


test('class teacher can manage the roster from the class page (populated class teacher)', async () => {
  const s = await setupSchool();
  const page = await call(classes.getClass, { user: s.classTeacher, params: { classId: s.s3a.id } });
  assert.equal(page.status, 200, JSON.stringify(page.body));
  assert.equal(page.body.data.access.isClassTeacher, true);
  assert.equal(page.body.data.access.canManageRoster, true);
  const subjectTeacher = await call(classes.getClass, { user: s.mathsTeacher, params: { classId: s.s3a.id } });
  assert.equal(subjectTeacher.body.data.access.canManageRoster, false);
});

test('eexams exam sent to an ECH class: students and parents see it, the result becomes the mark; parents hand in homework', async () => {
  process.env.ECH_EEXAMS_SSO_SECRET = 'sso-secret-for-tests';
  const bridge = require('../src/controllers/school/eexamsBridge.controller');
  const eexams = require('../src/services/integrations/eexams.service');
  const AssessmentSubmission = require('../src/models/AssessmentSubmission');
  const s = await setupSchool();
  const r = await addStudent(s.head, s.schoolId, { fullName: 'Aline Mukamana', classroomId: s.s3a.id, guardians: [{ name: 'Paul', phone: '0788123456' }] });
  const kid = await me(r.body.data.student.id);
  const parent = await me(r.body.data.parents[0].id);
  const svc = (teacher) => ({ authorization: 'Bearer sso-secret-for-tests', 'x-ech-user': String(teacher._id) });

  // Service auth is required.
  const noAuth = await call(bridge.classes, { headers: { 'x-ech-user': String(s.classTeacher._id) } });
  assert.equal(noAuth.status, 401);

  const cls = await call(bridge.classes, { headers: svc(s.classTeacher) });
  assert.equal(cls.status, 200, JSON.stringify(cls.body));
  assert.deepEqual(cls.body.data.classes.map((c) => `${c.className} ${c.subject}`), ['S3 A Biology']);

  // The maths teacher cannot send to Biology.
  const wrong = await call(bridge.assign, { headers: svc(s.mathsTeacher), body: { examId: 'exam123', title: 'Cells test', classSubjectIds: [s.bio.id] } });
  assert.equal(wrong.status, 403);

  const due = new Date(Date.now() + 2 * 864e5);
  const sent = await call(bridge.assign, { headers: svc(s.classTeacher), body: { examId: 'exam123', title: 'Cells test', classSubjectIds: [s.bio.id], dueAt: due } });
  assert.equal(sent.status, 201, JSON.stringify(sent.body));
  assert.equal(sent.body.data.created.length, 1);
  // Sending again updates instead of duplicating.
  const again = await call(bridge.assign, { headers: svc(s.classTeacher), body: { examId: 'exam123', title: 'Cells test (Unit 1)', classSubjectIds: [s.bio.id], dueAt: due } });
  assert.equal(again.body.data.updated.length, 1);
  const listed = await call(bridge.assignments, { headers: svc(s.classTeacher), query: { examId: 'exam123' } });
  assert.equal(listed.body.data.assignments.length, 1);

  let home = await call(learner.studentHome, { user: kid });
  const exam = home.body.data.todo.find((a) => a.eexamsExamId === 'exam123');
  assert.ok(exam);
  assert.equal(exam.title, 'Cells test (Unit 1)');
  assert.equal(exam.eexamsPath, '/student/exam/start/exam123');
  assert.ok(await Notification.exists({ userId: parent._id, type: 'homework' }));

  // The parent opens the exam as the child (one-time eexams sign-in link).
  const open = await call(learner.parentOpenExam, { user: parent, params: { id: String(kid._id), aid: exam.id } });
  assert.equal(open.status, 200, JSON.stringify(open.body));
  assert.match(open.body.data.url, /\/ech\/sso\?code=/);

  // eexams pushes the graded result → it becomes the class exam mark.
  await eexams.handleEvent({ type: 'exam.result', data: { echUserId: String(kid._id), resultId: 'res1', examId: 'exam123', examTitle: 'Cells test', score: 15, maxScore: 20, passingScore: 50, completedAt: new Date() } });
  home = await call(learner.studentHome, { user: kid });
  const done = home.body.data.recent.find((a) => a.eexamsExamId === 'exam123');
  assert.equal(done.state, 'graded');
  assert.equal(done.submission.score, 75);
  assert.equal(done.submission.submittedVia, 'eexams');
  const child = await call(learner.parentChild, { user: parent, params: { id: String(kid._id) } });
  assert.equal(child.body.data.recent.find((a) => a.eexamsExamId === 'exam123').submission.score, 75);

  // A teacher's hand-typed mark is never overwritten by a later eexams push.
  await AssessmentSubmission.updateOne({ studentId: kid._id }, { submittedVia: 'student', score: 90 });
  await eexams.handleEvent({ type: 'exam.result', data: { echUserId: String(kid._id), resultId: 'res1', examId: 'exam123', score: 10, maxScore: 20 } });
  assert.equal((await AssessmentSubmission.findOne({ studentId: kid._id })).score, 90);

  // Homework handed in by the parent from home is marked as such.
  const hw = await call(teaching.createAssessment, { user: s.classTeacher, params: { id: s.bio.id }, body: { title: 'Draw a cell', dueAt: new Date(Date.now() + 864e5), submissionMode: 'text' } });
  const hwId = hw.body.data.assessment.id;
  const view = await call(learner.parentAssessment, { user: parent, params: { id: String(kid._id), aid: hwId } });
  assert.equal(view.status, 200);
  const handed = await call(learner.parentSubmit, { user: parent, params: { id: String(kid._id), aid: hwId }, body: { text: 'A cell has a nucleus.' } });
  assert.equal(handed.status, 201, JSON.stringify(handed.body));
  assert.equal(handed.body.data.submission.submittedVia, 'parent');
  // Not the parent's child → 404; the parent cannot open plain homework on eexams.
  const other = await addStudent(s.head, s.schoolId, { fullName: 'Someone Else', classroomId: s.s3a.id });
  assert.equal((await call(learner.parentSubmit, { user: parent, params: { id: other.body.data.student.id, aid: hwId }, body: { text: 'x' } })).status, 404);
  assert.equal((await call(learner.parentOpenExam, { user: parent, params: { id: String(kid._id), aid: hwId } })).status, 400);
});

test('year-end promotion: regroup students of S3 A and S3 B into new streams / combinations', async () => {
  const s = await setupSchool();
  await School.updateOne({ _id: s.schoolId }, { levels: ['S1', 'S2', 'S3', 'S4', 'S5', 'S6'] });
  await SchoolTerm.updateOne({ _id: s.term._id }, { 'billing.studentsPaid': 20 });
  const a = [];
  const b = [];
  for (const n of ['Aline Mukamana', 'Eric Habimana', 'Grace Uwera']) a.push((await addStudent(s.head, s.schoolId, { fullName: n, classroomId: s.s3a.id })).body.data.student.id);
  for (const n of ['Kevin Mugisha', 'Diane Uwase', 'Olivier Nshuti']) b.push((await addStudent(s.head, s.schoolId, { fullName: n, classroomId: s.s3b.id })).body.data.student.id);

  const run = await call(yearCtl.runPromotion, { user: s.head, params: { schoolId: s.schoolId }, body: {
    fromYear: '2026', toYear: '2027',
    plan: [
      // S3 A goes to S4 MS-PURE A, but Eric joins the applied sciences class.
      { classId: s.s3a.id, action: 'promote', toLevel: 'S4', toCombination: 'MS-PURE', toStream: 'A', moves: [{ studentId: a[1], toCombination: 'MS-APPLIED', toStream: 'A' }] },
      // S3 B goes to S4 MS-APPLIED A, but Kevin and Diane join the pure sciences class with S3 A.
      { classId: s.s3b.id, action: 'promote', toLevel: 'S4', toCombination: 'MS-APPLIED', toStream: 'A', moves: [
        { studentId: b[0], toCombination: 'MS-PURE', toStream: 'A' },
        { studentId: b[1], toCombination: 'MS-PURE', toStream: 'A' },
        { studentId: 'aaaaaaaaaaaaaaaaaaaaaaaa', toCombination: 'X' }, // not in the class: ignored
      ] },
    ],
  } });
  assert.equal(run.status, 200, JSON.stringify(run.body));
  assert.equal(run.body.data.summary.promoted, 6);
  assert.equal(run.body.data.summary.regrouped, 3);

  const pure = await Classroom.findOne({ schoolId: s.schoolId, academicYear: '2027', level: 'S4', combination: 'MS-PURE', stream: 'A' });
  const applied = await Classroom.findOne({ schoolId: s.schoolId, academicYear: '2027', level: 'S4', combination: 'MS-APPLIED', stream: 'A' });
  assert.ok(pure && applied);
  assert.equal(pure.name, 'S4 MS-PURE A');
  const inClass = async (room) => (await User.find({ classroomId: room._id, role: 'student' }).select('fullName').lean()).map((u) => u.fullName).sort();
  assert.deepEqual(await inClass(pure), ['Aline Mukamana', 'Diane Uwase', 'Grace Uwera', 'Kevin Mugisha']);
  assert.deepEqual(await inClass(applied), ['Eric Habimana', 'Olivier Nshuti']);
  // Both new combinations are remembered on the school.
  const sch = await School.findById(s.schoolId).lean();
  assert.ok(sch.combinations.includes('MS-PURE') && sch.combinations.includes('MS-APPLIED'));
  // Only one class was created per destination (no duplicates).
  assert.equal(await Classroom.countDocuments({ schoolId: s.schoolId, academicYear: '2027', level: 'S4' }), 2);
});

test('year-end promotion: a student of S1 A can go to S2 C (stream change at any level)', async () => {
  const s = await setupSchool();
  await School.updateOne({ _id: s.schoolId }, { levels: ['S1', 'S2', 'S3', 'S4', 'S5', 'S6'] });
  await SchoolTerm.updateOne({ _id: s.term._id }, { 'billing.studentsPaid': 20 });
  const c = await call(classes.createClasses, { user: s.head, params: { schoolId: s.schoolId }, body: { level: 'S1', stream: 'A', academicYear: '2026' } });
  const s1a = c.body.data.classes[0].id;
  const ids = [];
  for (const n of ['Aline Mukamana', 'Eric Habimana']) ids.push((await addStudent(s.head, s.schoolId, { fullName: n, classroomId: s1a })).body.data.student.id);

  const run = await call(yearCtl.runPromotion, { user: s.head, params: { schoolId: s.schoolId }, body: {
    fromYear: '2026', toYear: '2027',
    plan: [{ classId: s1a, action: 'promote', toLevel: 'S2', toCombination: '', toStream: 'A', moves: [{ studentId: ids[1], toCombination: '', toStream: 'C' }] }],
  } });
  assert.equal(run.status, 200, JSON.stringify(run.body));
  const room = async (id) => Classroom.findById((await me(id)).classroomId);
  assert.equal((await room(ids[0])).name, 'S2 A');
  assert.equal((await room(ids[1])).name, 'S2 C');
});

test('school internet: IPv6 /64 ranges, suggested rule for the current connection, private addresses', () => {
  const ipu = require('../src/utils/clientIp');
  // Two devices on the same school Wi-Fi get different IPv6 addresses in the same /64.
  const rule = ipu.suggestedRule('2c0f:eb68:601:3c00:1111:2222:3333:4444');
  assert.equal(rule, '2c0f:eb68:601:3c00::/64');
  assert.equal(ipu.isValidIpRule(rule), true);
  assert.equal(ipu.ipAllowed('2c0f:eb68:601:3c00:a1b2:c3d4:e5f6:1', [rule]), true);
  assert.equal(ipu.ipAllowed('2c0f:eb68:601:3c01::1', [rule]), false);
  // IPv4: the exact address; ranges still work.
  assert.equal(ipu.suggestedRule('41.186.12.34'), '41.186.12.34');
  assert.equal(ipu.ipAllowed('41.186.12.99', ['41.186.12.0/24']), true);
  assert.equal(ipu.ipMatches('2c0f:0:0:0:0:0:0:1', '2c0f::1'), true);
  for (const p of ['192.168.1.4', '10.0.0.2', '127.0.0.1', 'fe80::1']) assert.equal(ipu.isPrivateIp(p), true, p);
  assert.equal(ipu.isPrivateIp('41.186.1.1'), false);
});
