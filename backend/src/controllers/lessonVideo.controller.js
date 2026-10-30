const mongoose = require('mongoose');
const Course = require('../models/Course');
const CourseBuildJob = require('../models/CourseBuildJob');
const CourseBuildItem = require('../models/CourseBuildItem');
const Lesson = require('../models/Lesson');
const FigureAsset = require('../models/FigureAsset');
const GenerationJob = require('../models/GenerationJob');
const queue = require('../services/jobs/queue.service');
const videoJobs = require('../services/video/video-jobs.service');
const figures = require('../services/course-builder/figures.service');
const cost = require('../services/video/cost.service');
const storage = require('../services/video/storage.service');
const pauses = require('../services/video/pause.service');
const { sendSuccess, sendError, sendNotFound, sendForbidden } = require('../utils/response.utils');

/**
 * Admin / teacher endpoints for textbook figures and generated lesson videos.
 * Mounted under /api/course-builder (same auth as the rest of the builder).
 */

const VARIANTS = ['explainer', 'experiment'];
const MODES = ['retry', 'full', 'script', 'audio', 'visuals'];

async function canManageCourse(user, courseId) {
  if (!user || !mongoose.isValidObjectId(courseId)) return false;
  if (user.role === 'admin') return true;
  if (user.role !== 'instructor') return false;
  const course = await Course.findById(courseId).select('assignedTeacherIds createdBy').lean();
  if (!course) return false;
  const uid = String(user._id || user.id);
  return String(course.createdBy) === uid || (course.assignedTeacherIds || []).some(id => String(id) === uid);
}

async function load(Model, id, res, label) {
  if (!mongoose.isValidObjectId(id)) { sendNotFound(res, `${label} not found`); return null; }
  const doc = await Model.findById(id);
  if (!doc) { sendNotFound(res, `${label} not found`); return null; }
  return doc;
}

async function guard(req, res, courseId) {
  if (await canManageCourse(req.user, courseId)) return true;
  sendForbidden(res, 'You cannot manage this course');
  return false;
}

function jobView(j) {
  if (!j) return null;
  return {
    _id: j._id,
    variant: j.variant,
    state: j.state,
    status: videoJobs.statusFromJob(j),
    stage: j.stage,
    contentVersion: j.contentVersion,
    attempts: j.attempts,
    maxAttempts: j.maxAttempts,
    nextRunAt: j.nextRunAt,
    error: j.error?.message ? j.error : null,
    review: j.review,
    checks: j.checks,
    cost: { estimatedUsd: j.cost?.estimatedUsd || 0, actualUsd: j.cost?.actualUsd || 0, llmTokens: j.cost?.llmTokens || 0, ttsChars: j.cost?.ttsChars || 0 },
    providerRequests: (j.providerRequests || []).slice(-10),
    stageHistory: (j.stageHistory || []).slice(-20),
    output: j.output ? { url: j.output.url, captionsUrl: j.output.captionsUrl, durationSeconds: j.output.durationSeconds, sceneCount: j.output.sceneCount, narrated: j.output.narrated, provider: j.output.provider } : null,
    storyboard: j.artifacts?.storyboard ? { title: j.artifacts.storyboard.title, plannedSeconds: j.artifacts.storyboard.plannedSeconds, scenes: j.artifacts.storyboard.scenes.map(s => ({ n: s.n, type: s.type, heading: s.heading, narration: s.narration, phase: s.phase })) } : null,
    storyboardWarnings: j.artifacts?.storyboardWarnings || [],
    createdAt: j.createdAt,
    finishedAt: j.finishedAt,
  };
}

// ─── Build-level media overview ──────────────────────────────────────────────

const getBuildMedia = async (req, res) => {
  try {
    const job = await load(CourseBuildJob, req.params.jobId, res, 'Build');
    if (!job || !(await guard(req, res, job.courseId))) return;
    const [videos, courseSpent, figureCount] = await Promise.all([
      videoJobs.summaryForBuild(job._id),
      cost.courseSpend(job.courseId),
      job.figureExtraction?.bookHash
        ? FigureAsset.countDocuments({ bookHash: job.figureExtraction.bookHash, extractorVersion: figures.EXTRACTOR_VERSION, storageKey: { $ne: null } })
        : 0,
    ]);
    const extractionJob = await GenerationJob.findOne({ type: 'figure_extraction', key: `figures:${job.figureExtraction?.bookHash}:${figures.EXTRACTOR_VERSION}` }).lean();
    sendSuccess(res, {
      figureExtraction: { ...(job.figureExtraction?.toObject?.() || job.figureExtraction || {}), figures: figureCount, job: extractionJob ? { state: extractionJob.state, stage: extractionJob.stage, error: extractionJob.error } : null },
      videos,
      budget: { ...cost.limits(job), courseSpentUsd: Math.round(courseSpent * 10000) / 10000 },
      policy: videoJobs.policy(),
      generateVideos: job.options?.generateVideos !== false,
      courseId: job.courseId,
      pause: pauses.status(await Course.findById(job.courseId).select('videoGeneration').lean()),
    });
  } catch (err) {
    sendError(res, 'Failed to load media status', 500, err.message);
  }
};

const listFigures = async (req, res) => {
  try {
    const job = await load(CourseBuildJob, req.params.jobId, res, 'Build');
    if (!job || !(await guard(req, res, job.courseId))) return;
    const bookHash = job.figureExtraction?.bookHash;
    if (!bookHash) return sendSuccess(res, []);
    const filter = { bookHash, extractorVersion: figures.EXTRACTOR_VERSION };
    const page = parseInt(req.query.page, 10);
    if (Number.isFinite(page)) filter.page = page;
    if (req.query.quality) filter.quality = String(req.query.quality);
    const list = await FigureAsset.find(filter)
      .select('figureId page printedPage caption captionLabel kind url quality warnings labels needsOcr extractionMethod chapterTitle duplicateOf widthPx heightPx')
      .sort({ page: 1, figureId: 1 }).limit(500).lean();
    sendSuccess(res, list);
  } catch (err) {
    sendError(res, 'Failed to load figures', 500, err.message);
  }
};

const extractFigures = async (req, res) => {
  try {
    const job = await load(CourseBuildJob, req.params.jobId, res, 'Build');
    if (!job || !(await guard(req, res, job.courseId))) return;
    const extraction = await figures.requestExtraction(job);
    const fresh = await CourseBuildJob.findById(job._id).select('figureExtraction').lean();
    sendSuccess(res, { figureExtraction: fresh.figureExtraction, extraction }, extraction ? 'Figure extraction requested' : 'Figure extraction is not available for this file');
  } catch (err) {
    sendError(res, 'Failed to start figure extraction', 500, err.message);
  }
};

// ─── Videos for a draft item or a lesson ─────────────────────────────────────

async function videosFor(filter) {
  const jobs = await GenerationJob.find({ type: 'lesson_video', ...filter }).sort({ createdAt: -1 }).limit(20).lean();
  const latest = {};
  for (const v of VARIANTS) latest[v] = jobView(jobs.find(j => j.variant === v));
  return { latest, history: jobs.map(j => ({ _id: j._id, variant: j.variant, state: j.state, stage: j.stage, contentVersion: j.contentVersion, createdAt: j.createdAt, finishedAt: j.finishedAt, error: j.error?.message || null, actualUsd: j.cost?.actualUsd || 0 })) };
}

const getItemVideos = async (req, res) => {
  try {
    const item = await load(CourseBuildItem, req.params.itemId, res, 'Item');
    if (!item || !(await guard(req, res, item.courseId))) return;
    const data = await videosFor({ buildItemId: item._id });
    sendSuccess(res, { ...data, video: item.video, experimentVideo: item.experimentVideo, contentVersion: item.contentVersion });
  } catch (err) {
    sendError(res, 'Failed to load videos', 500, err.message);
  }
};

function parseRequest(body) {
  const variant = VARIANTS.includes(body?.variant) ? body.variant : 'explainer';
  const mode = MODES.includes(body?.mode) ? body.mode : 'retry';
  return { variant, mode };
}

async function requestVideo({ req, res, item = null, lesson = null }) {
  const { variant, mode } = parseRequest(req.body);
  const content = item ? item.content : lesson.aiContent;
  if (!content) return sendError(res, 'This lesson has no generated content to make a video from', 400);
  if (item && item.kind !== 'lesson') return sendError(res, 'Videos are generated for lessons only', 400);
  const buildJob = item ? await CourseBuildJob.findById(item.jobId).lean() : (lesson.buildItemId ? await CourseBuildJob.findOne({ _id: (await CourseBuildItem.findById(lesson.buildItemId).select('jobId').lean())?.jobId }).lean() : null);
  try {
    const result = await videoJobs.enqueueVideo({
      buildJob,
      item: item ? item.toObject() : null,
      lesson: lesson ? lesson.toObject() : null,
      variant,
      requestedBy: req.user._id || req.user.id,
      restartFrom: mode === 'retry' ? null : mode,
      force: true,
    });
    const msg = result.created ? 'Video queued' : result.requeued ? (mode === 'retry' ? 'Video re-queued' : `Regenerating ${mode === 'full' ? 'the whole video' : `from the ${mode} stage`}`) : 'Video already queued';
    sendSuccess(res, jobView(result.job.toObject ? result.job.toObject() : result.job), msg, result.created ? 201 : 200);
  } catch (err) {
    sendError(res, err.message, err.status || 500);
  }
}

const requestItemVideo = async (req, res) => {
  const item = await load(CourseBuildItem, req.params.itemId, res, 'Item');
  if (!item || !(await guard(req, res, item.courseId))) return;
  return requestVideo({ req, res, item });
};

const getLessonVideos = async (req, res) => {
  try {
    const lesson = await load(Lesson, req.params.lessonId, res, 'Lesson');
    if (!lesson || !(await guard(req, res, lesson.courseId))) return;
    const or = [{ lessonId: lesson._id }];
    if (lesson.buildItemId) or.push({ buildItemId: lesson.buildItemId });
    const data = await videosFor({ $or: or });
    sendSuccess(res, { ...data, aiVideo: lesson.aiVideo, aiExperimentVideo: lesson.aiExperimentVideo, contentVersion: lesson.contentVersion });
  } catch (err) {
    sendError(res, 'Failed to load videos', 500, err.message);
  }
};

const requestLessonVideo = async (req, res) => {
  const lesson = await load(Lesson, req.params.lessonId, res, 'Lesson');
  if (!lesson || !(await guard(req, res, lesson.courseId))) return;
  if (lesson.buildItemId) {
    const item = await CourseBuildItem.findById(lesson.buildItemId);
    if (item) return requestVideo({ req, res, item });
  }
  return requestVideo({ req, res, lesson });
};

// ─── Single video job ────────────────────────────────────────────────────────

async function loadVideoJob(req, res) {
  const job = await load(GenerationJob, req.params.videoJobId, res, 'Video job');
  if (!job) return null;
  if (job.type !== 'lesson_video') { sendNotFound(res, 'Video job not found'); return null; }
  if (!(await guard(req, res, job.courseId))) return null;
  return job;
}

const getVideoJob = async (req, res) => {
  try {
    const job = await loadVideoJob(req, res);
    if (!job) return;
    const view = jobView(job.toObject());
    // Private preview link for reviewers (signed when stored in S3).
    if (job.output?.s3Key && storage.driverName() === 's3') {
      try { view.previewUrl = await require('../services/s3.service').generateSignedUrl(job.output.s3Key, 3600); } catch (_) { view.previewUrl = job.output.url; }
    } else if (job.output?.url) {
      view.previewUrl = job.output.url;
    }
    sendSuccess(res, view);
  } catch (err) {
    sendError(res, 'Failed to load video job', 500, err.message);
  }
};

const cancelVideoJob = async (req, res) => {
  try {
    const job = await loadVideoJob(req, res);
    if (!job) return;
    const updated = req.body?.force === true ? await queue.forceCancel(job._id) : await queue.cancel(job._id);
    if (!updated) return sendError(res, 'This video job has already finished', 409);
    await videoJobs.applyJobStatus(job._id);
    sendSuccess(res, jobView(updated.toObject()), updated.state === 'cancelled' ? 'Cancelled' : 'Cancelling — it will stop at the next step');
  } catch (err) {
    sendError(res, 'Failed to cancel video job', 500, err.message);
  }
};

/** Waiting, running and failed videos of a build (with stuck detection). */
const listBuildVideoJobs = async (req, res) => {
  try {
    const job = await load(CourseBuildJob, req.params.jobId, res, 'Build');
    if (!job || !(await guard(req, res, job.courseId))) return;
    const course = await Course.findById(job.courseId).select('videoGeneration').lean();
    sendSuccess(res, { ...(await videoJobs.jobsForBuild(job._id)), courseId: job.courseId, pause: pauses.status(course) });
  } catch (err) {
    sendError(res, 'Failed to load video jobs', 500, err.message);
  }
};

/**
 * Bulk actions on a build's video jobs. body: { action: 'stop' | 'force_stop' | 'retry',
 * ids?: [...], stuckOnly?: bool }. Without ids: every active job (stop) or
 * every failed job (retry) of the build.
 */
const bulkVideoJobs = async (req, res) => {
  try {
    const job = await load(CourseBuildJob, req.params.jobId, res, 'Build');
    if (!job || !(await guard(req, res, job.courseId))) return;
    const { action, ids, stuckOnly } = req.body || {};
    if (!['stop', 'force_stop', 'retry'].includes(action)) return sendError(res, 'Unknown action', 400);
    const filter = { buildJobId: job._id, type: 'lesson_video', state: action === 'retry' ? 'failed' : { $in: ['queued', 'retry_wait', 'running'] } };
    if (Array.isArray(ids)) filter._id = { $in: ids.filter(id => mongoose.isValidObjectId(id)) };
    let targets = await GenerationJob.find(filter).lean();
    if (stuckOnly) targets = targets.filter(j => videoJobs.stuckReason(j));
    let count = 0;
    for (const t of targets) {
      const updated = action === 'retry'
        ? await queue.requeue(t._id, { requestedBy: req.user._id || req.user.id })
        : action === 'force_stop' ? await queue.forceCancel(t._id) : await queue.cancel(t._id);
      if (!updated) continue;
      count++;
      await videoJobs.applyJobStatus(t._id);
    }
    const verb = { stop: 'Stopping', force_stop: 'Stopped', retry: 'Retrying' }[action];
    sendSuccess(res, { count }, `${verb} ${count} video${count === 1 ? '' : 's'}`);
  } catch (err) {
    sendError(res, 'Failed to update video jobs', 500, err.message);
  }
};

/** Pause / resume lesson-video generation for a whole course. */
const setCoursePause = (paused) => async (req, res) => {
  try {
    const { courseId } = req.params;
    if (!mongoose.isValidObjectId(courseId)) return sendNotFound(res, 'Course not found');
    if (!(await guard(req, res, courseId))) return;
    const result = paused ? await pauses.pauseCourse(courseId, req.user._id || req.user.id) : await pauses.resumeCourse(courseId);
    const message = paused
      ? `Videos paused for this course${result.returned ? ` — ${result.returned} running video${result.returned === 1 ? '' : 's'} went back to the queue` : ''}`
      : 'Videos resumed for this course';
    sendSuccess(res, result, message);
  } catch (err) {
    sendError(res, err.message, err.status || 500);
  }
};

/** Courses with videos waiting or running, and paused courses (instructors: their own). */
const videoQueueOverview = async (req, res) => {
  try {
    let courseIds = null;
    if (req.user.role !== 'admin') {
      const uid = req.user._id || req.user.id;
      courseIds = await Course.find({ $or: [{ createdBy: uid }, { assignedTeacherIds: uid }] }).distinct('_id');
    }
    sendSuccess(res, await pauses.overview({ courseIds }));
  } catch (err) {
    sendError(res, 'Failed to load the video queue', 500, err.message);
  }
};

const reviewVideoJob = async (req, res) => {
  try {
    const job = await loadVideoJob(req, res);
    if (!job) return;
    if (job.state !== 'completed') return sendError(res, 'Only finished videos can be reviewed', 409);
    const updated = await videoJobs.reviewVideo(job._id, req.body?.status, req.user._id || req.user.id);
    sendSuccess(res, jobView(updated.toObject()), req.body?.status === 'approved' ? 'Video approved — students can watch it' : 'Video rejected — students will not see it');
  } catch (err) {
    sendError(res, err.message, err.status || 500);
  }
};

module.exports = {
  getBuildMedia,
  listFigures,
  extractFigures,
  getItemVideos,
  requestItemVideo,
  getLessonVideos,
  requestLessonVideo,
  getVideoJob,
  cancelVideoJob,
  reviewVideoJob,
  listBuildVideoJobs,
  bulkVideoJobs,
  pauseCourseVideos: setCoursePause(true),
  resumeCourseVideos: setCoursePause(false),
  videoQueueOverview,
};
