/**
 * Enrollment lifecycle: unenroll preserves progress, active-only query scope,
 * re-enrollment (free and paid), suspension and admin history.
 */
const { startDb, stopDb, clearDb, oid, silenceLogs } = require('./helpers/setup');
const test = require('node:test');
const assert = require('node:assert/strict');

const Enrollment = require('../src/models/Enrollment');
const Course = require('../src/models/Course');
const Payment = require('../src/models/Payment');
const ctrl = require('../src/controllers/enrollment.controller');

let restoreLogs;
test.before(async () => {
  restoreLogs = silenceLogs();
  await startDb();
  await Enrollment.syncIndexes();
});
test.after(async () => { await stopDb(); restoreLogs(); });
test.beforeEach(clearDb);

function call(handler, { user, params = {}, body = {}, query = {} }) {
  return new Promise((resolve, reject) => {
    const res = {
      statusCode: 200,
      status(code) { this.statusCode = code; return this; },
      json(payload) { resolve({ status: this.statusCode, body: payload }); return this; },
      send(payload) { return this.json(payload); },
    };
    Promise.resolve(handler({ user, params, body, query }, res)).catch(reject);
  });
}

async function seed({ price = 0, accessExpirationDate = null } = {}) {
  const userId = oid();
  const course = await Course.create({
    title: 'Mathematics S3', description: 'Maths', createdBy: oid(),
    price, duration: 10, level: 'intermediate', isPublished: true, enrollmentCount: 1,
  });
  const lessonId = oid();
  const enrollment = await Enrollment.create({
    userId, courseId: course._id, progress: 40, completionStatus: 'in-progress',
    completedLessons: [lessonId], accessExpirationDate,
  });
  return { user: { id: String(userId) }, userId, course, enrollment, lessonId };
}

test('unenroll keeps the record and progress, and hides it from default queries', async () => {
  const { user, userId, course, lessonId } = await seed();

  const r = await call(ctrl.unenrollFromCourse, { user, params: { courseId: String(course._id) } });
  assert.equal(r.status, 200);
  assert.equal(r.body.data.status, 'unenrolled');

  // Default (active-only) scope: treated as not enrolled everywhere
  assert.equal(await Enrollment.findOne({ userId, courseId: course._id }), null);
  assert.equal(await Enrollment.countDocuments({ courseId: course._id }), 0);
  const agg = await Enrollment.aggregate([{ $group: { _id: null, n: { $sum: 1 } } }]);
  assert.equal(agg.length, 0);

  // ...but nothing was deleted
  const stored = await Enrollment.findOne({ userId, courseId: course._id, status: Enrollment.ANY_STATUS });
  assert.equal(stored.status, 'unenrolled');
  assert.ok(stored.unenrolledAt);
  assert.equal(stored.progress, 40);
  assert.deepEqual(stored.completedLessons.map(String), [String(lessonId)]);
  assert.deepEqual(stored.statusHistory.map(h => h.status), ['active', 'unenrolled']);

  const updated = await Course.findById(course._id);
  assert.equal(updated.enrollmentCount, 0);

  // my-courses no longer lists it
  const mine = await call(ctrl.getMyCourses, { user });
  assert.equal(mine.body.data.length, 0);

  // Unenrolling twice is a 404
  const again = await call(ctrl.unenrollFromCourse, { user, params: { courseId: String(course._id) } });
  assert.equal(again.status, 404);
});

test('legacy enrollments without a status field are still treated as active', async () => {
  const { userId, course } = await seed();
  await Enrollment.collection.updateMany({}, { $unset: { status: '' } });
  const found = await Enrollment.findOne({ userId, courseId: course._id });
  assert.ok(found);
  assert.equal(found.isActive(), true);
});

test('re-enrolling in a free course restores previous progress', async () => {
  const { user, course } = await seed();
  await call(ctrl.unenrollFromCourse, { user, params: { courseId: String(course._id) } });

  const status = await call(ctrl.getEnrollmentStatus, { user, params: { courseId: String(course._id) } });
  assert.equal(status.body.data.status, 'unenrolled');
  assert.equal(status.body.data.canReenrollWithoutPayment, true);

  const r = await call(ctrl.enrollInCourse, { user, body: { courseId: String(course._id) } });
  assert.equal(r.status, 200);
  assert.equal(r.body.data.status, 'active');
  assert.equal(r.body.data.progress, 40);
  assert.equal(r.body.data.statusHistory.length, 3);
  assert.equal((await Course.findById(course._id)).enrollmentCount, 1);
});

test('paid course: re-enroll is free while the original payment is valid, never refunded', async () => {
  const { user, userId, course } = await seed({ price: 5000 });
  const payment = await Payment.create({
    userId, courseId: course._id, amount: 5000, paymentMethod: 'mtn_momo',
    transactionId: 'TX-1', status: 'approved', contactInfo: 'x',
  });

  await call(ctrl.unenrollFromCourse, { user, params: { courseId: String(course._id) } });
  assert.equal((await Payment.findById(payment._id)).status, 'approved');

  const r = await call(ctrl.enrollInCourse, { user, body: { courseId: String(course._id) } });
  assert.equal(r.status, 200);
});

test('paid course: re-enroll after the access period ended requires payment', async () => {
  const past = new Date(Date.now() - 86400000);
  const { user, userId, course } = await seed({ price: 5000, accessExpirationDate: past });
  await Payment.create({
    userId, courseId: course._id, amount: 5000, paymentMethod: 'mtn_momo',
    transactionId: 'TX-2', status: 'completed', contactInfo: 'x',
  });
  // Expired enrollments still exist until the expiration job runs
  await Enrollment.updateOne({ userId }, { status: 'unenrolled' });

  const status = await call(ctrl.getEnrollmentStatus, { user, params: { courseId: String(course._id) } });
  assert.equal(status.body.data.canReenrollWithoutPayment, false);

  const r = await call(ctrl.enrollInCourse, { user, body: { courseId: String(course._id) } });
  assert.equal(r.status, 400);
  assert.match(r.body.message, /Payment required/);
});

test('suspended learners lose access and cannot unenroll or re-enroll around it', async () => {
  const { user, userId, course, enrollment } = await seed();
  const admin = { id: String(oid()) };

  const s = await call(ctrl.updateEnrollmentStatus, {
    user: admin, params: { id: String(enrollment._id) }, body: { status: 'suspended', reason: 'Policy review' },
  });
  assert.equal(s.status, 200);
  assert.equal(await Enrollment.findOne({ userId, courseId: course._id }), null);

  const u = await call(ctrl.unenrollFromCourse, { user, params: { courseId: String(course._id) } });
  assert.equal(u.status, 403);
  const e = await call(ctrl.enrollInCourse, { user, body: { courseId: String(course._id) } });
  assert.equal(e.status, 403);

  const back = await call(ctrl.updateEnrollmentStatus, {
    user: admin, params: { id: String(enrollment._id) }, body: { status: 'active' },
  });
  assert.equal(back.status, 200);
  assert.ok(await Enrollment.findOne({ userId, courseId: course._id }));

  const history = await call(ctrl.getEnrollmentHistory, { user: admin, query: { userId: String(userId) } });
  assert.deepEqual(history.body.data[0].statusHistory.map(h => h.status), ['active', 'suspended', 'active']);
  assert.equal(history.body.data[0].statusHistory[1].reason, 'Policy review');
});

test('admins cannot force a learner who left back into a course', async () => {
  const { user, course, enrollment } = await seed();
  await call(ctrl.unenrollFromCourse, { user, params: { courseId: String(course._id) } });
  const r = await call(ctrl.updateEnrollmentStatus, {
    user: { id: String(oid()) }, params: { id: String(enrollment._id) }, body: { status: 'active' },
  });
  assert.equal(r.status, 400);
});
