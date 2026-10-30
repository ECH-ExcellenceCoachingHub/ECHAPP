const mongoose = require('mongoose');
const Course = require('../../models/Course');
const CourseBuildJob = require('../../models/CourseBuildJob');
const GenerationJob = require('../../models/GenerationJob');
const queue = require('../jobs/queue.service');
const videoJobs = require('./video-jobs.service');

/**
 * Pausing lesson-video generation for a whole course, so the workers make
 * other courses' videos instead. Waiting videos stay in the queue; running
 * ones go back to it (their finished stages are kept) and the worker moves
 * on within one heartbeat. Resuming lets the workers pick them up again.
 */

const ACTIVE = ['queued', 'retry_wait', 'running'];

function status(course) {
  const v = course?.videoGeneration || {};
  return { paused: !!v.paused, pausedAt: v.pausedAt || null, pausedBy: v.pausedBy || null };
}

async function pauseCourse(courseId, userId = null) {
  const course = await Course.findByIdAndUpdate(
    courseId,
    { $set: { 'videoGeneration.paused': true, 'videoGeneration.pausedAt': new Date(), 'videoGeneration.pausedBy': userId } },
    { new: true },
  );
  if (!course) throw Object.assign(new Error('Course not found'), { status: 404 });
  queue.clearPauseCache();
  const running = await GenerationJob.find({ courseId: course._id, type: 'lesson_video', state: 'running' }).select('_id').lean();
  let returned = 0;
  for (const j of running) {
    if (await queue.pauseRunning(j._id)) {
      returned++;
      await videoJobs.applyJobStatus(j._id);
    }
  }
  return { ...status(course), returned };
}

async function resumeCourse(courseId) {
  const course = await Course.findByIdAndUpdate(
    courseId,
    { $set: { 'videoGeneration.paused': false, 'videoGeneration.pausedAt': null, 'videoGeneration.pausedBy': null } },
    { new: true },
  );
  if (!course) throw Object.assign(new Error('Course not found'), { status: 404 });
  queue.clearPauseCache();
  return status(course);
}

/**
 * Every course with lesson videos waiting or running, plus paused courses:
 * counts per state, and the course's latest build. `courseIds` limits the
 * list (instructors see their own courses only).
 */
async function overview({ courseIds = null } = {}) {
  const match = { type: 'lesson_video', state: { $in: ACTIVE }, courseId: { $ne: null } };
  if (courseIds) match.courseId = { $in: courseIds.map(id => new mongoose.Types.ObjectId(String(id))) };
  const counts = await GenerationJob.aggregate([
    { $match: match },
    { $group: { _id: { course: '$courseId', state: '$state' }, n: { $sum: 1 } } },
  ]);
  const byCourse = new Map();
  for (const c of counts) {
    const key = String(c._id.course);
    const row = byCourse.get(key) || { running: 0, waiting: 0 };
    if (c._id.state === 'running') row.running += c.n;
    else row.waiting += c.n;
    byCourse.set(key, row);
  }
  const pausedFilter = { 'videoGeneration.paused': true, ...(courseIds ? { _id: { $in: courseIds } } : {}) };
  const ids = [...new Set([...byCourse.keys(), ...(await Course.find(pausedFilter).distinct('_id')).map(String)])];
  const [courses, builds] = await Promise.all([
    Course.find({ _id: { $in: ids } }).select('title videoGeneration').lean(),
    CourseBuildJob.aggregate([
      { $match: { courseId: { $in: ids.map(id => new mongoose.Types.ObjectId(id)) } } },
      { $sort: { createdAt: -1 } },
      { $group: { _id: '$courseId', buildJobId: { $first: '$_id' } } },
    ]),
  ]);
  const buildOf = new Map(builds.map(b => [String(b._id), b.buildJobId]));
  return courses
    .map(c => ({
      courseId: c._id,
      title: c.title,
      buildJobId: buildOf.get(String(c._id)) || null,
      ...status(c),
      ...(byCourse.get(String(c._id)) || { running: 0, waiting: 0 }),
    }))
    .sort((a, b) => b.running - a.running || b.waiting - a.waiting || a.title.localeCompare(b.title));
}

module.exports = { pauseCourse, resumeCourse, status, overview };
