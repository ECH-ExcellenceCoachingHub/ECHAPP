/**
 * Schools (super admin) + school profile, terms and billing.
 */
const School = require('../../models/School');
const SchoolTerm = require('../../models/SchoolTerm');
const User = require('../../models/User');
const Classroom = require('../../models/Classroom');
const cred = require('../../services/school/credentials.service');
const people = require('../../services/school/people.service');
const { subscriptionStatus, activeStudentCount } = require('../../services/school/subscription.service');
const { HttpError, ok, wrap, requireId, schoolFor, paging, pageResult } = require('./helpers');
const access = require('../../services/school/accessPolicy.service');
const { isValidIpRule } = require('../../utils/clientIp');

const SCHOOL_FIELDS = ['name', 'description', 'type', 'ownership', 'phone', 'email', 'website', 'logo', 'headTeacherName'];
const ADMIN_ONLY_FIELDS = ['pricePerStudentPerTerm', 'currency', 'graceDays', 'trialStudentLimit', 'isActive'];

/** Validates and applies School.studentAccess (where/when students may sign in). */
function applyStudentAccess(school, sa) {
  if (!sa || typeof sa !== 'object') return;
  const cur = { ...access.policyOf(school) };
  delete cur.schoolActive;
  if (sa.mode !== undefined) {
    if (!['anywhere', 'code', 'network'].includes(sa.mode)) throw new HttpError('Invalid sign-in mode');
    cur.mode = sa.mode;
  }
  if (sa.codeMinutes !== undefined) {
    const n = parseInt(sa.codeMinutes, 10);
    if (![30, 45, 60, 90].includes(n)) throw new HttpError('Code duration must be 30, 45, 60 or 90 minutes');
    cur.codeMinutes = n;
  }
  if (sa.dayEndsAt !== undefined) {
    if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(String(sa.dayEndsAt))) throw new HttpError('End of school day must look like 17:00');
    cur.dayEndsAt = String(sa.dayEndsAt);
  }
  if (sa.maxSessionHours !== undefined) {
    const n = parseInt(sa.maxSessionHours, 10);
    if (!(n >= 1 && n <= 16)) throw new HttpError('Session length must be 1 to 16 hours');
    cur.maxSessionHours = n;
  }
  if (sa.allowedIps !== undefined) {
    if (!Array.isArray(sa.allowedIps)) throw new HttpError('allowedIps must be a list');
    const list = [...new Set(sa.allowedIps.map((x) => String(x).trim()).filter(Boolean))].slice(0, 30);
    const bad = list.find((x) => !isValidIpRule(x));
    if (bad) throw new HttpError(`"${bad}" is not a valid internet address`);
    cur.allowedIps = list;
  }
  if (sa.pinlessLevels !== undefined) {
    if (!Array.isArray(sa.pinlessLevels)) throw new HttpError('pinlessLevels must be a list');
    cur.pinlessLevels = [...new Set(sa.pinlessLevels.map((x) => String(x).trim().toUpperCase()).filter(Boolean))];
  }
  if (cur.mode === 'network' && !cur.allowedIps.length) {
    throw new HttpError("Add the school's internet address first, otherwise no student could sign in.");
  }
  cur.reviewedAt = new Date();
  school.studentAccess = cur;
  access.invalidatePolicy(school._id);
}

function applySchoolFields(school, body, { superAdmin }) {
  if (body.studentAccess !== undefined) applyStudentAccess(school, body.studentAccess);
  for (const f of SCHOOL_FIELDS) {
    if (body[f] !== undefined) school[f] = typeof body[f] === 'string' ? body[f].trim() : body[f];
  }
  if (body.address !== undefined) school.address = { ...(school.address?.toObject?.() || school.address || {}), ...people.cleanAddress(body.address) };
  if (Array.isArray(body.levels)) school.levels = [...new Set(body.levels.map((l) => String(l).trim().toUpperCase()).filter(Boolean))];
  if (Array.isArray(body.combinations)) school.combinations = [...new Set(body.combinations.map((l) => String(l).trim().toUpperCase()).filter(Boolean))];
  if (superAdmin) {
    for (const f of ADMIN_ONLY_FIELDS) if (body[f] !== undefined) school[f] = body[f];
  }
}

async function schoolSummary(school) {
  const s = school.toObject ? school.toObject() : school;
  const [studentCount, teacherCount, classCount, sub] = await Promise.all([
    activeStudentCount(s._id),
    User.countDocuments({ schoolId: s._id, role: 'instructor', isActive: true }),
    Classroom.countDocuments({ schoolId: s._id, isActive: true }),
    subscriptionStatus(s),
  ]);
  return {
    ...s,
    id: String(s._id),
    studentCount,
    teacherCount,
    classCount,
    subscription: {
      status: sub.status,
      hasAccess: sub.hasAccess,
      studentLimit: sub.studentLimit,
      daysLeft: sub.daysLeft,
      graceEndsAt: sub.graceEndsAt,
      currentTerm: sub.currentTerm ? termView(sub.currentTerm) : null,
      coveringTerm: sub.coveringTerm ? termView(sub.coveringTerm) : null,
    },
    studentAccess: (() => { const p = access.policyOf(s); delete p.schoolActive; return p; })(),
    // Legacy fields read by older app versions.
    studentLimit: sub.studentLimit,
    plan: sub.hasAccess ? 'premium' : 'free',
  };
}

function termView(t) {
  return {
    id: String(t._id),
    academicYear: t.academicYear,
    term: t.term,
    label: `${t.academicYear} Term ${t.term}`,
    startDate: t.startDate,
    endDate: t.endDate,
    billing: t.billing || {},
  };
}

/** POST /schools — creates the school and its first school admin. */
const createSchool = wrap(async (req, res) => {
  const b = req.body || {};
  if (!b.name || !String(b.name).trim()) throw new HttpError('School name is required');
  const adminData = b.admin || { fullName: b.adminFullName, email: b.adminEmail, phone: b.adminPhone, password: b.adminPassword };
  if (!adminData.fullName || !adminData.email) throw new HttpError('The school admin\'s full name and email are required');

  const code = await cred.uniqueSchoolCode(b.name, b.code);
  const school = new School({ name: String(b.name).trim(), code });
  applySchoolFields(school, b, { superAdmin: true });
  await school.save();

  let created;
  try {
    created = await people.createStaff({ school, actor: req.user, role: 'school_admin', data: adminData });
  } catch (err) {
    await School.deleteOne({ _id: school._id }); // no half-created school
    throw err;
  }
  school.admin = created.user.id;
  await school.save();

  ok(res, { school: await schoolSummary(school), schoolAdmin: created.user, credentials: created.credentials }, 'School created', 201);
});

/** GET /schools — all schools with counts and subscription status. */
const listSchools = wrap(async (req, res) => {
  const pg = paging(req.query);
  const filter = {};
  if (req.query.search) {
    const rx = { $regex: people.escapeRegex(req.query.search), $options: 'i' };
    filter.$or = [{ name: rx }, { code: rx }, { 'address.district': rx }];
  }
  if (req.query.active === 'true') filter.isActive = true;
  if (req.query.active === 'false') filter.isActive = false;
  const [schools, total] = await Promise.all([
    School.find(filter).populate('admin', 'fullName email phone isActive').sort({ createdAt: -1 }).skip(pg.skip).limit(pg.limit),
    School.countDocuments(filter),
  ]);
  const items = await Promise.all(schools.map(schoolSummary));
  ok(res, pageResult(items, total, pg, 'schools'));
});

/** GET /schools/:schoolId ('me' = own school) — any member may read the profile. */
const getSchool = wrap(async (req, res) => {
  const school = await schoolFor(req, { manage: false });
  await school.populate('admin', 'fullName email phone isActive');
  ok(res, { school: await schoolSummary(school) });
});

/** PATCH /schools/:schoolId — profile (school admin) + billing settings (super admin). */
const updateSchool = wrap(async (req, res) => {
  const school = await schoolFor(req);
  const superAdmin = req.user.role === 'admin';
  if (req.body.name !== undefined && !String(req.body.name).trim()) throw new HttpError('School name is required');
  if (superAdmin && req.body.code) {
    const code = cred.normalizeCode(req.body.code);
    if (code !== school.code) {
      if (await User.exists({ schoolId: school._id, studentCode: { $ne: null } })) {
        throw new HttpError('The school code cannot change after student codes were issued.');
      }
      if (await School.exists({ code, _id: { $ne: school._id } })) throw new HttpError('This school code is already used.', 409);
      school.code = code;
    }
  }
  applySchoolFields(school, req.body || {}, { superAdmin });
  await school.save();
  ok(res, { school: await schoolSummary(school) }, 'School updated');
});

/** DELETE /schools/:schoolId — deactivates (keeps history); ?hard=true deletes an empty school. */
const deleteSchool = wrap(async (req, res) => {
  const school = await schoolFor(req);
  if (req.query.hard === 'true') {
    if (await User.exists({ schoolId: school._id })) throw new HttpError('Deactivate instead: this school still has members.');
    await Promise.all([School.deleteOne({ _id: school._id }), SchoolTerm.deleteMany({ schoolId: school._id }), Classroom.deleteMany({ schoolId: school._id })]);
    return ok(res, { id: String(school._id) }, 'School deleted');
  }
  school.isActive = false;
  await school.save();
  ok(res, { id: String(school._id), isActive: false }, 'School deactivated');
});

// ── Terms & billing ───────────────────────────────────────────────────────

const listTerms = wrap(async (req, res) => {
  const school = await schoolFor(req, { manage: false });
  const terms = await SchoolTerm.find({ schoolId: school._id }).sort({ startDate: -1 }).lean();
  const sub = await subscriptionStatus(school);
  ok(res, { terms: terms.map(termView), subscription: { status: sub.status, studentLimit: sub.studentLimit, daysLeft: sub.daysLeft, hasAccess: sub.hasAccess }, pricePerStudentPerTerm: school.pricePerStudentPerTerm, currency: school.currency });
});

function readTermDates(body, term) {
  const start = body.startDate !== undefined ? new Date(body.startDate) : term?.startDate;
  const end = body.endDate !== undefined ? new Date(body.endDate) : term?.endDate;
  if (!start || !end || Number.isNaN(+start) || Number.isNaN(+end)) throw new HttpError('Start and end dates are required');
  if (end <= start) throw new HttpError('The term must end after it starts');
  return { start, end };
}

async function assertNoOverlap(schoolId, start, end, exceptId) {
  const clash = await SchoolTerm.findOne({ schoolId, _id: { $ne: exceptId }, startDate: { $lt: end }, endDate: { $gt: start } }).lean();
  if (clash) throw new HttpError(`These dates overlap ${clash.academicYear} Term ${clash.term}.`, 409);
}

/** POST /schools/:schoolId/terms — school admin or super admin defines the calendar. */
const createTerm = wrap(async (req, res) => {
  const school = await schoolFor(req);
  const b = req.body || {};
  const termNo = parseInt(b.term, 10);
  if (!b.academicYear || !(termNo >= 1 && termNo <= 4)) throw new HttpError('Academic year and term number (1-4) are required');
  const { start, end } = readTermDates(b);
  await assertNoOverlap(school._id, start, end);
  const term = await SchoolTerm.create({
    schoolId: school._id,
    academicYear: String(b.academicYear).trim(),
    term: termNo,
    startDate: start,
    endDate: end,
    billing: { pricePerStudent: school.pricePerStudentPerTerm || 0 },
  });
  ok(res, { term: termView(term) }, 'Term created', 201);
});

/** PATCH /schools/:schoolId/terms/:termId — dates (school admin) and billing (super admin only). */
const updateTerm = wrap(async (req, res) => {
  const school = await schoolFor(req);
  requireId(req.params.termId, 'term id');
  const term = await SchoolTerm.findOne({ _id: req.params.termId, schoolId: school._id });
  if (!term) throw new HttpError('Term not found', 404);
  const b = req.body || {};
  if (b.startDate !== undefined || b.endDate !== undefined) {
    const { start, end } = readTermDates(b, term);
    await assertNoOverlap(school._id, start, end, term._id);
    term.startDate = start;
    term.endDate = end;
  }
  if (b.billing) {
    if (req.user.role !== 'admin') throw new HttpError('Only ECH can record payments.', 403);
    const bl = b.billing;
    if (bl.studentsPaid !== undefined) {
      const n = parseInt(bl.studentsPaid, 10);
      if (!(n >= 0)) throw new HttpError('Number of students must be 0 or more');
      term.billing.studentsPaid = n;
    }
    if (bl.pricePerStudent !== undefined) term.billing.pricePerStudent = Math.max(0, +bl.pricePerStudent || 0);
    if (bl.status !== undefined) {
      if (!['unpaid', 'pending', 'paid', 'waived'].includes(bl.status)) throw new HttpError('Invalid payment status');
      if (bl.status === 'paid' && term.billing.status !== 'paid') term.billing.paidAt = bl.paidAt ? new Date(bl.paidAt) : new Date();
      term.billing.status = bl.status;
    }
    for (const f of ['method', 'reference', 'notes']) if (bl[f] !== undefined) term.billing[f] = String(bl[f]).trim();
    term.billing.amount = bl.amount !== undefined ? Math.max(0, +bl.amount || 0) : term.billing.studentsPaid * term.billing.pricePerStudent;
    term.billing.recordedBy = req.user._id;
  }
  await term.save();
  ok(res, { term: termView(term) }, 'Term updated');
});

const deleteTerm = wrap(async (req, res) => {
  const school = await schoolFor(req);
  requireId(req.params.termId, 'term id');
  const term = await SchoolTerm.findOne({ _id: req.params.termId, schoolId: school._id });
  if (!term) throw new HttpError('Term not found', 404);
  if (['paid', 'waived'].includes(term.billing?.status) && req.user.role !== 'admin') throw new HttpError('A paid term can only be removed by ECH.', 403);
  await term.deleteOne();
  ok(res, { id: String(term._id) }, 'Term removed');
});

module.exports = { createSchool, listSchools, getSchool, updateSchool, deleteSchool, listTerms, createTerm, updateTerm, deleteTerm, schoolSummary, termView };
