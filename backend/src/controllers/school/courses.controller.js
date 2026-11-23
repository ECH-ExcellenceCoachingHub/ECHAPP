/**
 * Which ECH courses school students get for free, by class level.
 * The super admin marks courses; students see the ones for their class.
 */
const Course = require('../../models/Course');
const { HttpError, ok, wrap, requireId } = require('./helpers');

const LEVEL = /^(N[1-3]|P[1-6]|S[1-6]|L[3-5]|Y[1-3])$/;

function view(c) {
  const sa = c.schoolAccess || {};
  return {
    id: String(c._id),
    title: c.title,
    description: c.description ? String(c.description).slice(0, 240) : '',
    thumbnail: c.thumbnail || null,
    price: c.price || 0,
    isPublished: c.isPublished !== false,
    schoolAccess: { enabled: !!sa.enabled, levels: sa.levels || [], subject: sa.subject || '' },
  };
}

/** GET /schools-courses?search=&onlyMarked=true — super admin. */
const listCourses = wrap(async (req, res) => {
  const filter = {};
  const q = String(req.query.search || '').trim();
  if (q) filter.title = new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
  if (req.query.onlyMarked === 'true') filter['schoolAccess.enabled'] = true;
  const list = await Course.find(filter).select('title description thumbnail price isPublished schoolAccess').sort({ 'schoolAccess.enabled': -1, title: 1 }).limit(300).lean();
  ok(res, { courses: list.map(view) });
});

/** PATCH /schools-courses/:courseId { enabled, levels[], subject } — super admin. */
const updateCourseAccess = wrap(async (req, res) => {
  requireId(req.params.courseId, 'course id');
  const b = req.body || {};
  const levels = Array.isArray(b.levels) ? [...new Set(b.levels.map((l) => String(l).trim().toUpperCase()))] : [];
  const bad = levels.filter((l) => !LEVEL.test(l));
  if (bad.length) throw new HttpError(`Unknown level: ${bad.join(', ')}`);
  const enabled = b.enabled === true;
  if (enabled && !levels.length) throw new HttpError('Choose at least one class level.');
  const c = await Course.findByIdAndUpdate(
    req.params.courseId,
    { $set: { schoolAccess: { enabled, levels, subject: String(b.subject || '').trim().slice(0, 80) } } },
    { new: true, runValidators: true },
  ).select('title description thumbnail price isPublished schoolAccess').lean();
  if (!c) throw new HttpError('Course not found', 404);
  ok(res, { course: view(c) }, enabled ? 'Free for school students of these levels' : 'Not offered to schools');
});

module.exports = { listCourses, updateCourseAccess, courseView: view };
