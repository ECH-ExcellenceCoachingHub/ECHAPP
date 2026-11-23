/**
 * Super admins managing other super admins: editing details, changing the
 * password (Firebase + MongoDB), setting per-area limits and having those
 * limits enforced, and the guards that stop a limited admin from escalating.
 */
const { startDb, stopDb, clearDb, silenceLogs } = require('./helpers/setup');
const test = require('node:test');
const assert = require('node:assert/strict');

// Fake Firebase Admin auth: records calls, can be told to fail. Installed in
// the module cache before anything loads the real SDK (its `auth` property
// cannot be reassigned), so no test ever reaches the real Firebase project.
const fb = { calls: [], fail: null };
const fakeAuth = {
  updateUser: async (uid, update) => {
    fb.calls.push(['updateUser', uid, update]);
    if (fb.fail) throw fb.fail;
  },
  revokeRefreshTokens: async (uid) => { fb.calls.push(['revoke', uid]); },
};
const fbPath = require.resolve('../src/config/firebase');
require.cache[fbPath] = { id: fbPath, filename: fbPath, loaded: true, exports: { auth: () => fakeAuth } };

const User = require('../src/models/User');
const admins = require('../src/controllers/admin/admins.controller');
const limits = require('../src/services/adminLimits.service');

let restoreLogs;
test.before(async () => {
  restoreLogs = silenceLogs();
  await startDb();
  await User.syncIndexes();
});
test.after(async () => { delete require.cache[fbPath]; await stopDb(); restoreLogs(); });
test.beforeEach(async () => { await clearDb(); fb.calls = []; fb.fail = null; });

function call(handler, req) {
  return new Promise((resolve, reject) => {
    const res = {
      statusCode: 200,
      status(code) { this.statusCode = code; return this; },
      json(payload) { resolve({ status: this.statusCode, body: payload }); return this; },
    };
    Promise.resolve(handler({ params: {}, body: {}, query: {}, method: 'PUT', ...req }, res, () => resolve('next'))).catch(reject);
  });
}

async function makeAdmin(email, extra = {}) {
  return User.create({ fullName: email.split('@')[0], email, password: 'oldpass123', role: 'admin', ...extra });
}

// Same shape the API stores: every area set, missing ones = none.
const restricted = (areas) => limits.normalizeLimits({ restricted: true, areas }).limits;

test('a super admin edits another admin\'s details and the sign-in account follows', async () => {
  const me = await makeAdmin('boss@ech.rw');
  const other = await makeAdmin('alice@ech.rw', { firebaseUid: 'fb-alice' });

  const r = await call(admins.updateAdminDetails, {
    user: me, params: { id: String(other._id) },
    body: { fullName: 'Alice Uwase', email: 'Alice.New@ech.rw', phone: '+250788000111' },
  });
  assert.equal(r.status, 200);
  assert.deepEqual(fb.calls[0], ['updateUser', 'fb-alice', { email: 'alice.new@ech.rw', displayName: 'Alice Uwase' }]);
  const saved = await User.findById(other._id);
  assert.equal(saved.fullName, 'Alice Uwase');
  assert.equal(saved.email, 'alice.new@ech.rw');
  assert.equal(saved.phone, '+250788000111');
});

test('details are not saved when Firebase rejects the email', async () => {
  const me = await makeAdmin('boss@ech.rw');
  const other = await makeAdmin('alice@ech.rw', { firebaseUid: 'fb-alice' });
  fb.fail = Object.assign(new Error('taken'), { code: 'auth/email-already-exists' });

  const r = await call(admins.updateAdminDetails, { user: me, params: { id: String(other._id) }, body: { email: 'x@ech.rw' } });
  assert.equal(r.status, 409);
  assert.equal((await User.findById(other._id)).email, 'alice@ech.rw');
});

test('an email used by another account is refused', async () => {
  const me = await makeAdmin('boss@ech.rw');
  const other = await makeAdmin('alice@ech.rw');
  const r = await call(admins.updateAdminDetails, { user: me, params: { id: String(other._id) }, body: { email: 'boss@ech.rw' } });
  assert.equal(r.status, 409);
});

test('changing another admin\'s password updates Firebase and MongoDB and signs them out', async () => {
  const me = await makeAdmin('boss@ech.rw');
  const other = await makeAdmin('alice@ech.rw', { firebaseUid: 'fb-alice' });

  const short = await call(admins.setAdminPassword, { user: me, params: { id: String(other._id) }, body: { newPassword: 'short' } });
  assert.equal(short.status, 400);

  const r = await call(admins.setAdminPassword, { user: me, params: { id: String(other._id) }, body: { newPassword: 'BrandNew#2026' } });
  assert.equal(r.status, 200);
  assert.deepEqual(fb.calls[0], ['updateUser', 'fb-alice', { password: 'BrandNew#2026' }]);
  assert.deepEqual(fb.calls[1], ['revoke', 'fb-alice']);
  const saved = await User.findById(other._id).select('+password');
  assert.equal(await saved.comparePassword('BrandNew#2026'), true);
  assert.equal(await saved.comparePassword('oldpass123'), false);
});

test('the password is left alone when Firebase fails', async () => {
  const me = await makeAdmin('boss@ech.rw');
  const other = await makeAdmin('alice@ech.rw', { firebaseUid: 'fb-alice' });
  fb.fail = new Error('network');
  const r = await call(admins.setAdminPassword, { user: me, params: { id: String(other._id) }, body: { newPassword: 'BrandNew#2026' } });
  assert.equal(r.status, 502);
  const saved = await User.findById(other._id).select('+password');
  assert.equal(await saved.comparePassword('oldpass123'), true);
});

test('an admin cannot change their own limits, status or password here', async () => {
  const me = await makeAdmin('boss@ech.rw');
  for (const handler of [admins.setAdminLimits, admins.setAdminStatus, admins.setAdminPassword, admins.updateAdminDetails]) {
    const r = await call(handler, { user: me, params: { id: String(me._id) }, body: { restricted: true, active: false, newPassword: 'whatever123' } });
    assert.equal(r.status, 400);
  }
});

test('only admins can be managed through these endpoints', async () => {
  const me = await makeAdmin('boss@ech.rw');
  const student = await User.create({ fullName: 'S', email: 's@ech.rw', role: 'student' });
  const r = await call(admins.setAdminLimits, { user: me, params: { id: String(student._id) }, body: { restricted: true } });
  assert.equal(r.status, 404);
});

test('limits are saved, validated, and default missing areas to no access', async () => {
  const me = await makeAdmin('boss@ech.rw');
  const other = await makeAdmin('alice@ech.rw');

  const bad = await call(admins.setAdminLimits, { user: me, params: { id: String(other._id) }, body: restricted({ users: 'everything' }) });
  assert.equal(bad.status, 400);

  const r = await call(admins.setAdminLimits, { user: me, params: { id: String(other._id) }, body: restricted({ users: 'full', payments: 'view' }) });
  assert.equal(r.status, 200);
  assert.deepEqual(r.body.data.adminLimits, {
    restricted: true,
    areas: { users: 'full', courses: 'none', schools: 'none', payments: 'view', communication: 'none', settings: 'none', admins: 'none' },
  });

  const cleared = await call(admins.setAdminLimits, { user: me, params: { id: String(other._id) }, body: { restricted: false } });
  assert.equal(cleared.body.data.adminLimits.restricted, false);
  assert.equal(cleared.body.data.adminLimits.areas.payments, 'full');
});

test('limits are enforced per area and per method', async () => {
  const full = await makeAdmin('boss@ech.rw');
  const limited = await makeAdmin('alice@ech.rw', { adminLimits: restricted({ users: 'full', payments: 'view' }) });
  const req = (method, originalUrl) => ({ method, originalUrl });

  // Unrestricted admins are never limited.
  assert.equal(limits.checkRequest(full, req('DELETE', '/api/payments/1')), null);

  assert.equal(limits.checkRequest(limited, req('PUT', '/api/admin/students/abc')), null);
  assert.equal(limits.checkRequest(limited, req('GET', '/api/payments?status=pending')), null);
  assert.equal(limits.checkRequest(limited, req('PUT', '/api/payments/1/approve')).code, 'ADMIN_LIMITED');
  assert.equal(limits.checkRequest(limited, req('GET', '/api/admin/backups')).area, 'settings');
  assert.equal(limits.checkRequest(limited, req('GET', '/api/schools')).area, 'schools');
  assert.equal(limits.checkRequest(limited, req('PUT', '/api/admin/admins/x/password')).area, 'admins');
  assert.equal(limits.checkRequest(limited, req('POST', '/api/notifications/send-push')).area, 'communication');
  assert.equal(limits.checkRequest(limited, req('POST', '/api/notifications')).area, 'communication');

  // Their own account, inbox and profile picture keep working.
  assert.equal(limits.checkRequest(limited, req('GET', '/api/admin/my-access')), null);
  assert.equal(limits.checkRequest(limited, req('GET', '/api/notifications/unread-count')), null);
  assert.equal(limits.checkRequest(limited, req('PUT', '/api/notifications/fcm-token')), null);
  assert.equal(limits.checkRequest(limited, req('POST', '/api/upload/image')), null);
  assert.equal(limits.checkRequest(limited, req('GET', '/api/auth/me')), null);

  // '/schools' must not swallow '/schools-courses' or a lookalike prefix.
  assert.equal(limits.areaForPath('/schools-courses/1'), 'schools');
  assert.equal(limits.areaForPath('/coursesX'), null);
});

test('an admin limited to users cannot reach admin accounts through the student endpoints', async () => {
  const boss = await makeAdmin('boss@ech.rw');
  const limited = await makeAdmin('alice@ech.rw', { adminLimits: restricted({ users: 'full' }) });
  const student = await User.create({ fullName: 'S', email: 's@ech.rw', role: 'student' });

  // Reset a full admin's password via /students/:id/reset-password → blocked.
  let r = await call(admins.guardAdminTarget, { user: limited, params: { id: String(boss._id) }, body: { newPassword: 'x' } });
  assert.equal(r.status, 403);
  // Promote a student to admin → blocked.
  r = await call(admins.guardAdminTarget, { user: limited, params: { id: String(student._id) }, body: { role: 'admin' } });
  assert.equal(r.status, 403);
  // Ordinary student management still works.
  r = await call(admins.guardAdminTarget, { user: limited, params: { id: String(student._id) }, body: { role: 'instructor' } });
  assert.equal(r, 'next');
  // A full admin can do both.
  r = await call(admins.guardAdminTarget, { user: boss, params: { id: String(student._id) }, body: { role: 'admin' } });
  assert.equal(r, 'next');
});

test('deactivating an admin disables the Firebase account and signs them out', async () => {
  const me = await makeAdmin('boss@ech.rw');
  const other = await makeAdmin('alice@ech.rw', { firebaseUid: 'fb-alice' });
  const r = await call(admins.setAdminStatus, { user: me, params: { id: String(other._id) }, body: { active: false } });
  assert.equal(r.status, 200);
  assert.equal(r.body.data.disabled, true);
  assert.deepEqual(fb.calls, [['updateUser', 'fb-alice', { disabled: true }], ['revoke', 'fb-alice']]);
});
