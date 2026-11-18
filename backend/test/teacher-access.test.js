/**
 * Self-registered teacher journey: role choice, profile, admin approval,
 * teacher's-guide request (paid like a course), unlocking the tools, and the
 * guarantees around it (no self-made admins, no student access via a guide).
 */
const { startDb, stopDb, clearDb, oid, silenceLogs } = require('./helpers/setup');
const test = require('node:test');
const assert = require('node:assert/strict');

const User = require('../src/models/User');
const Course = require('../src/models/Course');
const Payment = require('../src/models/Payment');
const TeacherAssignment = require('../src/models/TeacherAssignment');
const CourseBuildJob = require('../src/models/CourseBuildJob');
const CourseBuildItem = require('../src/models/CourseBuildItem');
const auth = require('../src/controllers/auth.controller');
const t = require('../src/controllers/teacherAccess.controller');
const a = require('../src/controllers/teacherAdmin.controller');
const pay = require('../src/controllers/payment_workflow.controller');
const { authorize } = require('../src/middleware/role.middleware');
const { denySelfRegisteredTeacher } = require('../src/services/teacherAccess.service');
const { publishApproved } = require('../src/services/course-builder/publisher.service');
const runner = require('../src/services/course-builder/runner.service');
const ai = require('../src/services/course-builder/ai.service');

let restoreLogs;
test.before(async () => {
  restoreLogs = silenceLogs();
  await startDb();
  await TeacherAssignment.syncIndexes();
});
test.after(async () => { await stopDb(); restoreLogs(); });
test.beforeEach(clearDb);

function call(handler, req) {
  return new Promise((resolve, reject) => {
    const res = {
      statusCode: 200,
      status(code) { this.statusCode = code; return this; },
      json(payload) { resolve({ status: this.statusCode, body: payload }); return this; },
      send(payload) { return this.json(payload); },
    };
    Promise.resolve(handler({ params: {}, body: {}, query: {}, ...req }, res)).catch(reject);
  });
}

/** Runs a middleware; resolves 'next' when it lets the request through. */
function gate(mw, user) {
  return new Promise((resolve) => {
    const res = { statusCode: 200, status(c) { this.statusCode = c; return this; }, json(b) { resolve({ status: this.statusCode, body: b }); return this; } };
    mw({ user, url: '/x' }, res, () => resolve('next'));
  });
}

const asReq = (u) => ({ ...u.toObject(), id: String(u._id), _id: u._id });

async function course(extra = {}) {
  return Course.create({
    title: 'Biology S2', description: 'Bio', createdBy: oid(), price: 5000, duration: 10,
    level: 'beginner', isPublished: true, ...extra,
  });
}

test('chooseRole: only once, never admin; teacher starts with an incomplete profile', async () => {
  const u = await User.create({ fullName: 'Google User', email: 'g@x.rw', needsRoleSelection: true });
  let r = await call(auth.chooseRole, { user: asReq(u), body: { role: 'admin' } });
  assert.equal(r.status, 400);
  r = await call(auth.chooseRole, { user: asReq(u), body: { role: 'teacher' } });
  assert.equal(r.status, 200);
  assert.equal(r.body.data.user.role, 'instructor');
  assert.equal(r.body.data.user.teacherStatus, 'profile_incomplete');
  r = await call(auth.chooseRole, { user: asReq(u), body: { role: 'student' } });
  assert.equal(r.status, 409, 'role can only be chosen once');
});

test('full journey: profile → approval → guide request → payment approval → tools', async () => {
  const admin = await User.create({ fullName: 'Admin', email: 'admin@x.rw', role: 'admin' });
  const teacher = await User.create({ fullName: 'Teacher T', email: 't@x.rw', role: 'instructor', teacherStatus: 'profile_incomplete' });
  const c = await course({ teacherGuide: { enabled: true, price: 3000, classLevels: ['S2'], subject: 'Biology' } });
  await course({ title: 'Physics S5', teacherGuide: { enabled: true, price: 0, classLevels: ['S5'] } });
  const toolsGate = authorize('admin', 'instructor');

  // Blocked before the profile
  let g = await gate(toolsGate, await User.findById(teacher._id));
  assert.equal(g.body.code, 'TEACHER_PROFILE_INCOMPLETE');

  // Missing fields are named
  let r = await call(t.submitProfile, { user: asReq(teacher), body: { school: 'GS Kigali' } });
  assert.equal(r.status, 400);
  r = await call(t.submitProfile, { user: asReq(teacher), body: {
    school: 'GS Kigali', district: 'Gasabo', levels: ['S2', 'S3'], subjects: ['Biology'], phone: '0788000000', yearsExperience: 4,
  } });
  assert.equal(r.status, 200);
  assert.equal(r.body.data.status, 'pending');

  g = await gate(toolsGate, await User.findById(teacher._id));
  assert.equal(g.body.code, 'TEACHER_PENDING_APPROVAL');
  // Catalog is closed until approval
  r = await call(t.listGuides, { user: asReq(teacher) });
  assert.equal(r.status, 403);

  // Admin sees and approves the application
  r = await call(a.listApplications, { user: asReq(admin), query: { status: 'pending' } });
  assert.equal(r.body.data.applications.length, 1);
  assert.deepEqual(r.body.data.applications[0].profile.levels, ['S2', 'S3']);
  r = await call(a.reviewApplication, { user: asReq(admin), params: { id: String(teacher._id) }, body: { decision: 'reject' } });
  assert.equal(r.status, 400, 'a rejection needs a reason');
  r = await call(a.reviewApplication, { user: asReq(admin), params: { id: String(teacher._id) }, body: { decision: 'approve' } });
  assert.equal(r.body.data.status, 'approved');

  // Approved but no course yet → tools still locked
  g = await gate(toolsGate, await User.findById(teacher._id));
  assert.equal(g.body.code, 'TEACHER_COURSE_REQUIRED');

  // Catalog: recommended first (matches S2)
  r = await call(t.listGuides, { user: asReq(await User.findById(teacher._id)) });
  assert.equal(r.status, 200);
  assert.equal(r.body.data.guides[0].title, 'Biology S2');
  assert.equal(r.body.data.guides[0].recommended, true);
  assert.equal(r.body.data.guides[1].recommended, false);

  // Request (paid) — method required, duplicates refused
  r = await call(t.requestGuide, { user: asReq(teacher), params: { courseId: String(c._id) }, body: {} });
  assert.equal(r.status, 400);
  r = await call(t.requestGuide, { user: asReq(teacher), params: { courseId: String(c._id) }, body: { paymentMethod: 'mtn_momo', contactInfo: '0788000000' } });
  assert.equal(r.status, 201);
  assert.equal(r.body.data.amount, 3000);
  const dup = await call(t.requestGuide, { user: asReq(teacher), params: { courseId: String(c._id) }, body: { paymentMethod: 'mtn_momo' } });
  assert.equal(dup.status, 400);

  // Admin approves the payment → teacher gets the course, not a student enrollment
  r = await call(pay.verifyPayment, { user: asReq(admin), body: { paymentId: String(r.body.data.paymentId), status: 'approved' } });
  assert.equal(r.status, 200);
  const asg = await TeacherAssignment.findOne({ teacherId: teacher._id, courseId: c._id }).lean();
  assert.equal(asg.isActive, true);
  assert.equal(asg.source, 'guide_purchase');
  assert.equal(await require('../src/models/Enrollment').countDocuments({ userId: teacher._id }), 0);

  g = await gate(toolsGate, await User.findById(teacher._id));
  assert.equal(g, 'next', 'tools unlocked');

  // Still cannot create course content
  g = await gate(denySelfRegisteredTeacher, await User.findById(teacher._id));
  assert.equal(g.body.code, 'TEACHER_CANNOT_EDIT_COURSES');

  // Reversing the payment takes the course away again
  const p = await Payment.findOne({ userId: teacher._id });
  await call(pay.verifyPayment, { user: asReq(admin), body: { paymentId: String(p._id), status: 'failed' } });
  g = await gate(toolsGate, await User.findById(teacher._id));
  assert.equal(g.body.code, 'TEACHER_COURSE_REQUIRED');
});

test('admin-created teachers keep full access', async () => {
  const legacy = await User.create({ fullName: 'Old Teacher', email: 'old@x.rw', role: 'instructor' });
  assert.equal(await gate(authorize('instructor'), legacy), 'next');
  assert.equal(await gate(denySelfRegisteredTeacher, legacy), 'next');
});

test('teacher guide build: lesson items only, guide generator, publish links the course', async () => {
  const admin = await User.create({ fullName: 'Admin', email: 'admin@x.rw', role: 'admin' });
  const c = await course({ teacherGuide: { enabled: true, price: 0 } });
  const job = await CourseBuildJob.create({
    courseId: c._id, createdBy: admin._id, purpose: 'teacher_guide', status: 'outline_ready',
    options: { mode: 'full', generateVideos: false, chapterTestQuestions: 15, mockExamQuestions: 20 },
    outline: { bookTitle: 'Bio TG', chapters: [{ index: 0, title: 'Cells', pageStart: 1, pageEnd: 4, lessons: [{ title: 'Cell structure', pageStart: 1, pageEnd: 2 }, { title: 'Cell division', pageStart: 3, pageEnd: 4 }] }] },
  });
  const n = await runner.planItems(job);
  assert.equal(n, 2, 'no tests, revision or mock exam for a guide');
  const kinds = await CourseBuildItem.distinct('kind', { jobId: job._id });
  assert.deepEqual(kinds, ['lesson']);

  // The guide generator is used (stubbed) and its guide is stored
  const original = ai.generateTeachingGuide;
  ai.generateTeachingGuide = async () => ({
    summary: 'Teach cells', notes: '## Lesson overview\n' + 'Cells are the unit of life. '.repeat(30), keyPoints: ['cells'], learningObjectives: ['describe a cell'],
    keyTerms: [], examples: [], formulas: [], activities: [], visuals: [], sources: [], estimatedMinutes: 40,
    guide: ai.normalizeGuide({ lessonFlow: [{ stage: 'Intro', minutes: 5 }, { stage: 'Activity', minutes: 20 }, { stage: 'Wrap up', minutes: 15 }], modernMethods: [{ method: 'Think-pair-share', how: 'pairs' }], assessment: [{ question: 'What is a cell?' }] }),
  });
  try {
    const item = await CourseBuildItem.findOne({ jobId: job._id, order: 0 });
    await runner.processItem(job.toObject(), item, [{ page: 1, text: 'Cells are the unit of life.' }, { page: 2, text: 'Cell membrane.' }]);
  } finally {
    ai.generateTeachingGuide = original;
  }
  const done = await CourseBuildItem.findOne({ jobId: job._id, order: 0 }).lean();
  assert.ok(done.content.guide.lessonFlow.length >= 3, done.error || 'guide stored');
  assert.equal(done.questions.length, 0);

  await CourseBuildItem.updateOne({ _id: done._id }, { $set: { status: 'approved' } });
  const result = await publishApproved(job._id);
  assert.equal(result.published, 1);
  const updated = await Course.findById(c._id).lean();
  assert.equal(String(updated.teacherGuide.buildJobId), String(job._id));
  assert.ok(updated.teacherGuide.publishedAt);
  // No student sections were created
  assert.equal(await require('../src/models/Section').countDocuments({ courseId: c._id }), 0);

  // A teacher holding the course can read it; one without cannot
  const teacher = await User.create({ fullName: 'T', email: 't@x.rw', role: 'instructor' });
  let r = await call(t.getGuide, { user: asReq(teacher), params: { courseId: String(c._id) } });
  assert.equal(r.status, 403);
  await TeacherAssignment.create({ teacherId: teacher._id, courseId: c._id, assignedBy: admin._id, source: 'guide_purchase' });
  r = await call(t.getGuide, { user: asReq(teacher), params: { courseId: String(c._id) } });
  assert.equal(r.status, 200);
  assert.equal(r.body.data.chapters[0].lessons[0].title, 'Cell structure');
  r = await call(t.getGuideLesson, { user: asReq(teacher), params: { courseId: String(c._id), itemId: String(done._id) } });
  assert.equal(r.body.data.content.guide.modernMethods[0].method, 'Think-pair-share');
});
