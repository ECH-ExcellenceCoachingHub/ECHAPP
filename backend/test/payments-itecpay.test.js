/**
 * Automatic payments through iTechPay (gateway mocked by stubbing fetch):
 * course purchase, teacher's guide, school term seats; webhook + polling +
 * sweeper racing for the same payment; declines, timeouts, late money,
 * amount mismatch and the public webhook never trusting its body.
 */
const { startDb, stopDb, clearDb, oid, silenceLogs } = require('./helpers/setup');
const test = require('node:test');
const assert = require('node:assert/strict');

process.env.ITECPAY_API_KEY_MOBILE_MONEY = 'test-mtn-key';
process.env.ITECPAY_API_KEY_AIRTEL_MONEY = 'test-airtel-key';
process.env.ITECPAY_API_KEY_CARD = 'test-card-key';
process.env.ITECPAY_BASE_URL = 'https://pay.itecpay.rw/api';
process.env.ITECPAY_CALLBACK_URL = 'https://ech.test/api/payments/itecpay/callback';

const User = require('../src/models/User');
const Course = require('../src/models/Course');
const Payment = require('../src/models/Payment');
const Enrollment = require('../src/models/Enrollment');
const TeacherAssignment = require('../src/models/TeacherAssignment');
const School = require('../src/models/School');
const SchoolTerm = require('../src/models/SchoolTerm');
const ctl = require('../src/controllers/checkout.controller');
const checkout = require('../src/services/payments/checkout.service');
const itecpay = require('../src/services/payments/itecpay.service');

// ── Fake iTechPay ────────────────────────────────────────────────────────────
const gw = { calls: [], status: {}, amount: {}, payReply: null };
const realFetch = global.fetch;
function installFakeGateway() {
  global.fetch = async (url, opts) => {
    const body = JSON.parse(opts.body);
    gw.calls.push({ url, body });
    let reply;
    if (url.endsWith('/api2/pay')) reply = gw.payReply || { status: 200, data: { transaction_id: 'TX-' + body.req_ref.slice(0, 6) } };
    else if (url.endsWith('/pesapal/generatecode')) reply = { status: 200, PCODE: 'PC123' };
    else if (url.endsWith('/api2/verify')) {
      reply = { status: 200, data: { status: gw.status[body.req_ref] || 'PENDING', amount: gw.amount[body.req_ref], transaction_id: 'MTN-9' } };
    } else reply = { status: 404 };
    return { ok: true, status: 200, text: async () => JSON.stringify(reply) };
  };
}

let restoreLogs;
test.before(async () => {
  restoreLogs = silenceLogs();
  await startDb();
  await Payment.syncIndexes();
  installFakeGateway();
});
test.after(async () => { global.fetch = realFetch; await stopDb(); restoreLogs(); });
test.beforeEach(async () => { await clearDb(); gw.calls = []; gw.status = {}; gw.amount = {}; gw.payReply = null; });

function call(handler, req) {
  return new Promise((resolve, reject) => {
    const res = {
      statusCode: 200,
      status(code) { this.statusCode = code; return this; },
      json(payload) { resolve({ status: this.statusCode, body: payload }); return this; },
      type() { return this; },
      send(payload) { resolve({ status: this.statusCode, body: payload }); return this; },
    };
    Promise.resolve(handler({ params: {}, body: {}, query: {}, method: 'POST', ...req }, res)).catch(reject);
  });
}
const asReq = (u) => ({ ...u.toObject(), id: String(u._id), _id: u._id });
const course = (extra = {}) => Course.create({ title: 'Chemistry S4', description: 'Chem', createdBy: oid(), price: 8000, duration: 10, level: 'beginner', isPublished: true, ...extra });
const ref = (r) => r.body.data.reference;
const age = (reference, minutes) => Payment.collection.updateOne({ 'gateway.reference': reference }, { $set: { createdAt: new Date(Date.now() - minutes * 60000), 'gateway.lastCheckedAt': null } });

test('phone helpers', () => {
  assert.equal(itecpay.normalizePhone('+250 788 123 456'), '0788123456');
  assert.equal(itecpay.normalizePhone('788123456'), '0788123456');
  assert.equal(itecpay.normalizePhone('12345'), null);
  assert.ok(itecpay.phoneMatchesMethod('0788123456', 'mtn_momo'));
  assert.ok(!itecpay.phoneMatchesMethod('0788123456', 'airtel_money'));
  assert.ok(itecpay.phoneMatchesMethod('0731234567', 'airtel_money'));
});

test('course: MoMo prompt → poll → paid → enrolled once, even when webhook and poll race', async () => {
  const s = await User.create({ fullName: 'Stu', email: 's@x.rw', phone: '0788000111' });
  const c = await course();
  // An old manual request is retired when paying online.
  await Payment.create({ userId: s._id, courseId: c._id, amount: 8000, paymentMethod: 'mtn_momo', transactionId: 'OLD1', contactInfo: 'x', status: 'pending' });

  let r = await call(ctl.start, { user: asReq(s), body: { courseId: c._id, paymentMethod: 'mtn_momo' } });
  assert.equal(r.status, 201, JSON.stringify(r.body));
  assert.equal(r.body.data.amount, 8000, 'server sets the price');
  const pay = gw.calls.find((x) => x.url.endsWith('/api2/pay'));
  assert.deepEqual({ ...pay.body, req_ref: undefined }, { amount: 8000, phone: '0788000111', key: 'test-mtn-key', req_ref: undefined });
  assert.equal((await Payment.findOne({ transactionId: 'OLD1' })).status, 'cancelled');

  // Still pending
  r = await call(ctl.status, { user: asReq(s), params: { reference: ref(r) } });
  const reference = r.body.data.reference;
  assert.equal(r.body.data.status, 'pending');
  assert.equal(await Enrollment.countDocuments({ userId: s._id }), 0);

  // Paid: webhook, poll and sweeper all at once
  gw.status[reference] = 'SUCCESSFUL';
  gw.amount[reference] = 8000;
  await Payment.updateOne({ 'gateway.reference': reference }, { $set: { 'gateway.lastCheckedAt': null } });
  const results = await Promise.all([
    call(ctl.callback, { body: { req_ref: reference, status: 'success', amount: 8000 } }),
    call(ctl.status, { user: asReq(s), params: { reference } }),
    checkout.sweep(),
  ]);
  assert.equal(results[1].body.data.paid, true);
  const p = await Payment.findOne({ 'gateway.reference': reference });
  assert.equal(p.status, 'completed');
  assert.equal(await Enrollment.countDocuments({ userId: s._id, courseId: c._id }), 1);

  // Already enrolled now → cannot buy again
  r = await call(ctl.start, { user: asReq(s), body: { courseId: c._id, paymentMethod: 'mtn_momo' } });
  assert.equal(r.status, 400);
});

test('webhook body is never trusted: "success" in the body does nothing until iTechPay confirms', async () => {
  const s = await User.create({ fullName: 'Stu', email: 's2@x.rw' });
  const c = await course();
  const r = await call(ctl.start, { user: asReq(s), body: { courseId: c._id, paymentMethod: 'airtel_money', phone: '0731234567' } });
  assert.equal(r.status, 201);
  const cb = await call(ctl.callback, { body: { req_ref: ref(r), status: 'success', amount: 8000, transaction_id: 'fake' } });
  assert.equal(cb.body.status, 'pending');
  assert.equal(await Enrollment.countDocuments({}), 0);
  const unknown = await call(ctl.callback, { body: { req_ref: 'not-ours', status: 'success' } });
  assert.equal(unknown.status, 404);
});

test('wrong network, bad phone, missing price and other users are refused', async () => {
  const s = await User.create({ fullName: 'Stu', email: 's3@x.rw' });
  const other = await User.create({ fullName: 'Other', email: 'o@x.rw' });
  const c = await course();
  let r = await call(ctl.start, { user: asReq(s), body: { courseId: c._id, paymentMethod: 'airtel_money', phone: '0788000111' } });
  assert.equal(r.status, 400);
  assert.match(r.body.message, /not an Airtel number/);
  r = await call(ctl.start, { user: asReq(s), body: { courseId: c._id, paymentMethod: 'mtn_momo', phone: '123' } });
  assert.equal(r.status, 400);
  const free = await course({ title: 'Free', price: 0 });
  r = await call(ctl.start, { user: asReq(s), body: { courseId: free._id, paymentMethod: 'mtn_momo', phone: '0788000111' } });
  assert.equal(r.status, 400);
  r = await call(ctl.start, { user: asReq(s), body: { courseId: c._id, paymentMethod: 'mtn_momo', phone: '0788000111' } });
  const o = await call(ctl.status, { user: asReq(other), params: { reference: ref(r) } });
  assert.equal(o.status, 404, 'cannot read someone else\'s payment');
  // Same thing again while in flight → the same payment is resumed, no second prompt
  const before = gw.calls.filter((x) => x.url.endsWith('/api2/pay')).length;
  await Payment.updateOne({ 'gateway.reference': ref(r) }, { $set: { 'gateway.lastCheckedAt': new Date() } });
  const again = await call(ctl.start, { user: asReq(s), body: { courseId: c._id, paymentMethod: 'mtn_momo', phone: '0788000111' } });
  assert.equal(again.body.data.resumed, true);
  assert.equal(again.body.data.reference, ref(r));
  assert.equal(gw.calls.filter((x) => x.url.endsWith('/api2/pay')).length, before);
});

test('declined → failed and never re-checked; timeout → failed but money arriving later is still applied', async () => {
  const s = await User.create({ fullName: 'Stu', email: 's4@x.rw' });
  const c1 = await course({ title: 'A' });
  const c2 = await course({ title: 'B' });
  const r1 = await call(ctl.start, { user: asReq(s), body: { courseId: c1._id, paymentMethod: 'mtn_momo', phone: '0788000111' } });
  const r2 = await call(ctl.start, { user: asReq(s), body: { courseId: c2._id, paymentMethod: 'mtn_momo', phone: '0788000111' } });

  gw.status[ref(r1)] = 'FAILED';
  await age(ref(r1), 1);
  let st = await call(ctl.status, { user: asReq(s), params: { reference: ref(r1) } });
  assert.equal(st.body.data.status, 'failed');
  assert.equal(st.body.data.failureReason, 'declined');

  await age(ref(r2), 11);
  st = await call(ctl.status, { user: asReq(s), params: { reference: ref(r2) } });
  assert.equal(st.body.data.status, 'failed');
  assert.equal(st.body.data.failureReason, 'timeout');

  gw.status[ref(r2)] = 'SUCCESSFUL';
  gw.status[ref(r1)] = 'SUCCESSFUL'; // must be ignored: it was declined
  const out = await checkout.sweep();
  assert.equal(out.completed, 1);
  assert.equal((await Payment.findOne({ 'gateway.reference': ref(r2) })).status, 'completed');
  assert.equal((await Payment.findOne({ 'gateway.reference': ref(r1) })).status, 'failed');
  assert.equal(await Enrollment.countDocuments({ courseId: c2._id }), 1);
  assert.equal(await Enrollment.countDocuments({ courseId: c1._id }), 0);
});

test('amount lower than the price → admin review, no access', async () => {
  const s = await User.create({ fullName: 'Stu', email: 's5@x.rw' });
  const c = await course();
  const r = await call(ctl.start, { user: asReq(s), body: { courseId: c._id, paymentMethod: 'mtn_momo', phone: '0788000111' } });
  gw.status[ref(r)] = 'SUCCESSFUL';
  gw.amount[ref(r)] = 100;
  await age(ref(r), 1);
  const st = await call(ctl.status, { user: asReq(s), params: { reference: ref(r) } });
  assert.equal(st.body.data.status, 'admin_review');
  assert.equal(await Enrollment.countDocuments({}), 0);
});

test('card: returns the Pesapal page and requires an email', async () => {
  const s = await User.create({ fullName: 'Stu', email: 'card@x.rw' });
  const c = await course();
  const r = await call(ctl.start, { user: asReq(s), body: { courseId: c._id, paymentMethod: 'card' } });
  assert.equal(r.status, 201);
  assert.match(r.body.data.paymentUrl, /PCODE=PC123/);
  const gen = gw.calls.find((x) => x.url.endsWith('/generatecode'));
  assert.equal(gen.body.callback_url, 'https://ech.test/api/payments/itecpay/callback');
  assert.equal(gen.body.email, 'card@x.rw');
});

test('teacher guide: paid online → TeacherAssignment (guide_purchase)', async () => {
  const t = await User.create({ fullName: 'Teacher', email: 't@x.rw', role: 'instructor', teacherStatus: 'approved' });
  const c = await course({ teacherGuide: { enabled: true, price: 3000, classLevels: ['S4'] } });
  const r = await call(ctl.start, { user: asReq(t), body: { purpose: 'teacher_guide', courseId: c._id, paymentMethod: 'mtn_momo', phone: '0791234567' } });
  assert.equal(r.status, 201, JSON.stringify(r.body));
  assert.equal(r.body.data.amount, 3000);
  gw.status[ref(r)] = 'completed';
  await age(ref(r), 1);
  await call(ctl.status, { user: asReq(t), params: { reference: ref(r) } });
  const ta = await TeacherAssignment.findOne({ teacherId: t._id, courseId: c._id });
  assert.ok(ta?.isActive);
  assert.equal(ta.source, 'guide_purchase');

  const student = await User.create({ fullName: 'S', email: 'ss@x.rw' });
  const no = await call(ctl.start, { user: asReq(student), body: { purpose: 'teacher_guide', courseId: c._id, paymentMethod: 'mtn_momo', phone: '0791234567' } });
  assert.equal(no.status, 403);
});

test('school term: school admin pays for seats → term paid; paying again adds seats', async () => {
  const school = await School.create({ name: 'GS Test', code: 'GST', pricePerStudentPerTerm: 1500 });
  const sa = await User.create({ fullName: 'Head', email: 'h@x.rw', role: 'school_admin', schoolId: school._id });
  const teacher = await User.create({ fullName: 'T', email: 'tt@x.rw', role: 'instructor', schoolId: school._id });
  const now = Date.now();
  const term = await SchoolTerm.create({ schoolId: school._id, academicYear: '2026', term: 3, startDate: new Date(now - 864e5), endDate: new Date(now + 60 * 864e5) });

  const no = await call(ctl.start, { user: asReq(teacher), body: { purpose: 'school_term', schoolId: 'me', termId: term._id, students: 10, paymentMethod: 'mtn_momo', phone: '0788000111' } });
  assert.equal(no.status, 403);

  let r = await call(ctl.start, { user: asReq(sa), body: { purpose: 'school_term', schoolId: 'me', termId: term._id, students: 40, paymentMethod: 'mtn_momo', phone: '0788000111' } });
  assert.equal(r.status, 201, JSON.stringify(r.body));
  assert.equal(r.body.data.amount, 60000);
  gw.status[ref(r)] = 'SUCCESSFUL';
  await age(ref(r), 1);
  await call(ctl.status, { user: asReq(sa), params: { reference: ref(r) } });
  let t = await SchoolTerm.findById(term._id);
  assert.equal(t.billing.status, 'paid');
  assert.equal(t.billing.studentsPaid, 40);
  assert.equal(t.billing.amount, 60000);

  r = await call(ctl.start, { user: asReq(sa), body: { purpose: 'school_term', schoolId: 'me', termId: term._id, students: 5, paymentMethod: 'mtn_momo', phone: '0788000111' } });
  gw.status[ref(r)] = 'SUCCESSFUL';
  await age(ref(r), 1);
  await checkout.sweep();
  await checkout.sweep(); // idempotent
  t = await SchoolTerm.findById(term._id);
  assert.equal(t.billing.studentsPaid, 45);
  assert.equal(t.billing.amount, 67500);
});

test('admin re-check applies a payment the user gave up on', async () => {
  const admin = await User.create({ fullName: 'Admin', email: 'a@x.rw', role: 'admin' });
  const s = await User.create({ fullName: 'Stu', email: 's6@x.rw' });
  const c = await course();
  const r = await call(ctl.start, { user: asReq(s), body: { courseId: c._id, paymentMethod: 'mtn_momo', phone: '0788000111' } });
  await Payment.updateOne({ 'gateway.reference': ref(r) }, { $set: { status: 'cancelled' } });
  gw.status[ref(r)] = 'SUCCESSFUL';
  const p = await Payment.findOne({ 'gateway.reference': ref(r) });
  const out = await call(ctl.recheck, { user: asReq(admin), params: { id: String(p._id) } });
  assert.equal(out.body.data.status, 'completed');
  assert.equal(await Enrollment.countDocuments({ courseId: c._id }), 1);
});

test('admin list: server-side search, service/channel/attention filters, paging; overview totals', async () => {
  const pay = require('../src/controllers/payment_workflow.controller');
  const admin = await User.create({ fullName: 'Admin', email: 'adm@x.rw', role: 'admin' });
  const alice = await User.create({ fullName: 'Alice Uwase', email: 'alice@x.rw', phone: '0788111222' });
  const bob = await User.create({ fullName: 'Bob Kalisa', email: 'bob@x.rw' });
  const school = await School.create({ name: 'Lycee de Kigali', code: 'LDK', pricePerStudentPerTerm: 1000 });
  const c = await course({ title: 'Physics S6' });
  const base = { currency: 'RWF', contactInfo: 'x' };
  const mk = (extra) => Payment.create({ ...base, transactionId: 'T' + Math.random().toString(36).slice(2), ...extra });
  await mk({ userId: alice._id, courseId: c._id, amount: 5000, paymentMethod: 'mtn_momo', status: 'completed', paymentDate: new Date(), gateway: { provider: 'itecpay', reference: 'ref-a' } });
  await mk({ userId: bob._id, courseId: c._id, amount: 5000, paymentMethod: 'mtn_momo', status: 'pending' }); // manual waiting → attention
  await mk({ userId: bob._id, courseId: c._id, amount: 3000, paymentMethod: 'airtel_money', purpose: 'teacher_guide', status: 'approved', paymentDate: new Date() });
  await mk({ userId: alice._id, schoolId: school._id, termId: oid(), seats: 10, amount: 10000, paymentMethod: 'card', purpose: 'school_term', status: 'admin_review', gateway: { provider: 'itecpay', reference: 'ref-s' } });

  const list = async (query) => (await call(pay.getAllPayments, { user: asReq(admin), query })).body.data;
  assert.equal((await list({})).total, 4);
  assert.equal((await list({ search: 'alice' })).total, 2, 'search by user name');
  assert.equal((await list({ search: 'Kigali' })).total, 1, 'search by school name');
  assert.equal((await list({ search: 'ref-a' })).total, 1, 'search by iTechPay reference');
  assert.equal((await list({ search: 'Physics' })).total, 3, 'search by course title');
  assert.equal((await list({ purpose: 'school_term' })).total, 1);
  assert.equal((await list({ purpose: 'course' })).total, 2);
  assert.equal((await list({ channel: 'online' })).total, 2);
  assert.equal((await list({ channel: 'manual' })).total, 2);
  assert.equal((await list({ attention: '1' })).total, 2, 'manual pending + admin_review');
  const p1 = await list({ limit: '3', page: '2' });
  assert.equal(p1.payments.length, 1);
  assert.equal(p1.totalPages, 2);
  assert.equal((await list({ search: '(.*' })).total, 0, 'regex characters are escaped');

  const o = (await call(pay.getPaymentOverview, { user: asReq(admin) })).body.data;
  assert.equal(o.total.revenue, 8000);
  assert.equal(o.thisMonth.revenue, 8000);
  assert.equal(o.byPurpose.course.revenue, 5000);
  assert.equal(o.byPurpose.teacher_guide.revenue, 3000);
  assert.equal(o.byChannel.online.revenue, 5000);
  assert.equal(o.byMethod.airtel_money.count, 1);
  assert.equal(o.needsAttention, 2);
  assert.equal(o.daily.length, 30);
  assert.equal(o.daily.at(-1).revenue, 8000);
});
