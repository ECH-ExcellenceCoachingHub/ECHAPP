const mongoose = require('mongoose');
const Course = require('../models/Course');
const CourseBuildItem = require('../models/CourseBuildItem');
const demos = require('../services/demo/demo.service');
const youtube = require('../services/demo/youtube.service');
const { sendSuccess, sendError, sendNotFound, sendForbidden } = require('../utils/response.utils');

/**
 * Guided experiment demonstrations (real YouTube videos) for a draft lesson.
 * Mounted under /api/course-builder (same auth as the rest of the builder).
 */

async function canManageCourse(user, courseId) {
  if (!user) return false;
  if (user.role === 'admin') return true;
  if (user.role !== 'instructor') return false;
  const course = await Course.findById(courseId).select('assignedTeacherIds createdBy').lean();
  if (!course) return false;
  const uid = String(user._id || user.id);
  return String(course.createdBy) === uid || (course.assignedTeacherIds || []).some(id => String(id) === uid);
}

async function loadItem(req, res) {
  const { itemId } = req.params;
  const item = mongoose.isValidObjectId(itemId) ? await CourseBuildItem.findById(itemId) : null;
  if (!item) { sendNotFound(res, 'Item not found'); return null; }
  if (!(await canManageCourse(req.user, item.courseId))) { sendForbidden(res, 'You cannot manage this course'); return null; }
  if (item.kind !== 'lesson' || !item.content) { sendError(res, 'Demonstrations are added to generated lessons only', 400); return null; }
  return item;
}

const view = (item, demo = item.demo) => ({
  configured: youtube.available(),
  defaultQuery: demos.defaultQuery(item.title),
  demo: demo || null,
  // Shown to students only once every step is placed in the video.
  live: !!demos.publicDemo(demo),
});

const handle = (fn) => async (req, res) => {
  try {
    const item = await loadItem(req, res);
    if (item) sendSuccess(res, view(item, await fn(item, req)));
  } catch (err) {
    sendError(res, err.message, err.status && err.status < 600 ? err.status : 500);
  }
};

module.exports = {
  getDemo: handle(async (item) => item.demo),
  searchDemos: handle((item, req) => demos.suggest(item, { query: req.body?.query })),
  selectDemo: handle((item, req) => demos.select(item, req.body?.videoId)),
  saveDemoSteps: handle((item, req) => demos.saveSteps(item, req.body?.steps)),
  removeDemo: handle((item) => demos.remove(item)),
};
