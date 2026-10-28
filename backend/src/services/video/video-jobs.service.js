const CourseBuildItem = require('../../models/CourseBuildItem');
const CourseBuildJob = require('../../models/CourseBuildJob');
const Lesson = require('../../models/Lesson');
const Course = require('../../models/Course');
const GenerationJob = require('../../models/GenerationJob');
const { isVideoWatchable } = require('../../models/schemas/aiVideo.schema');
const queue = require('../jobs/queue.service');
const { detectSubject } = require('./subjects');
const { assessExperiment, SIMULATION_DISCLOSURE } = require('./experiment');

/**
 * Lesson video jobs: when to create them, keeping lesson/draft video status
 * in sync with the job, and swapping in a finished video safely.
 *
 * Policy (environment):
 *   VIDEO_AUTOGEN_ENABLED       true  — queue a video automatically for every generated lesson
 *   VIDEO_AUTOGEN_TRIGGER       draft — as soon as the lesson draft is saved | publish — on publish
 *   VIDEO_REGENERATE_ON_CHANGE  manual — edited lessons are only marked "stale" | auto — re-queue
 * Per build: options.generateVideos=false turns it off for that course build.
 */

const AI_VIDEO_PREFIX = 'ai-videos/';
const RENDERER_VERSION = 'programmatic-v1';

const flag = (name, def) => String(process.env[name] ?? def).toLowerCase() !== 'false';
const policy = () => ({
  enabled: flag('VIDEO_AUTOGEN_ENABLED', 'true'),
  trigger: (process.env.VIDEO_AUTOGEN_TRIGGER || 'draft').toLowerCase(),
  onChange: (process.env.VIDEO_REGENERATE_ON_CHANGE || 'manual').toLowerCase(),
});

const itemField = (variant) => (variant === 'experiment' ? 'experimentVideo' : 'video');
const lessonField = (variant) => (variant === 'experiment' ? 'aiExperimentVideo' : 'aiVideo');

/** Read-modify-write of a video subdocument (the field may be null on old docs). */
async function setVideoMeta(Model, id, field, patch) {
  const doc = await Model.findById(id).select(field).lean();
  if (!doc) return null;
  const current = doc[field] || {};
  const merged = { variant: field.toLowerCase().includes('experiment') ? 'experiment' : 'explainer', ...current, ...patch, updatedAt: new Date() };
  await Model.updateOne({ _id: id }, { $set: { [field]: merged } });
  return merged;
}

async function videoConfig({ buildJob, course, variant }) {
  const c = course || (buildJob ? await Course.findById(buildJob.courseId).select('title description').lean() : null);
  const subject = detectSubject(buildJob?.outline?.subject, buildJob?.outline?.bookTitle, c?.title, c?.description);
  return {
    variant,
    subject: subject.key,
    level: buildJob?.outline?.level || '',
    language: buildJob?.options?.videoLanguage || buildJob?.options?.language || 'English',
    durationSec: subject.durationSec,
    renderer: RENDERER_VERSION,
    tts: (process.env.VIDEO_TTS_PROVIDER || 'auto').toLowerCase(),
  };
}

/**
 * Queue a video for a draft item or a lesson. Duplicate requests for the same
 * content version and configuration return the existing job.
 *
 * @returns {Promise<{job, created:boolean, requeued:boolean}>}
 */
async function enqueueVideo({ buildJob = null, item = null, lesson = null, variant = 'explainer', requestedBy = null, restartFrom = null, force = false }) {
  if (!item && !lesson) throw new Error('enqueueVideo needs an item or a lesson');
  const targetType = item ? 'item' : 'lesson';
  const target = item || lesson;
  const version = target.contentVersion || 1;
  const config = await videoConfig({ buildJob, variant });
  const configHash = queue.hashConfig(config);
  const key = `video:${targetType}:${target._id}:v${version}:${variant}:${configHash}`;

  const { job, created } = await queue.enqueue({
    type: 'lesson_video',
    key,
    courseId: target.courseId,
    buildJobId: buildJob?._id || item?.jobId || null,
    buildItemId: item?._id || lesson?.buildItemId || null,
    lessonId: lesson?._id || item?.published?.lessonId || null,
    variant,
    contentVersion: version,
    config,
    configHash,
    requestedBy,
    maxAttempts: parseInt(process.env.VIDEO_MAX_ATTEMPTS || '3', 10),
    restartFrom: null,
  });

  let requeued = false;
  let current = job;
  // Existing job: a plain retry resumes a failed/cancelled job from its saved
  // stage outputs; a regeneration ("script" | "audio" | "visuals" | "full")
  // redoes work from that stage even when the video was completed.
  const wantsRegeneration = !!restartFrom;
  const retryable = force && ['failed', 'cancelled'].includes(job.state);
  if (!created && (wantsRegeneration || retryable)) {
    if (job.state === 'running') {
      throw Object.assign(new Error('This video is being generated right now — wait for it to finish or cancel it first.'), { status: 409 });
    }
    if (restartFrom === 'full') {
      await GenerationJob.updateOne({ _id: job._id }, { $set: { artifacts: {}, checks: [], output: null } });
    }
    current = await queue.requeue(job._id, { restartFrom: restartFrom === 'full' ? null : restartFrom, requestedBy });
    requeued = !!current;
    if (!current) current = job;
  }

  if (created || requeued) {
    const patch = { status: 'queued', jobId: current._id, provider: RENDERER_VERSION, pendingContentVersion: version, error: null, variant };
    if (item) await setVideoMeta(CourseBuildItem, item._id, itemField(variant), patch);
    const lessonId = lesson?._id || item?.published?.lessonId;
    if (lessonId) await setVideoMeta(Lesson, lessonId, lessonField(variant), patch);
  }
  return { job: current, created, requeued };
}

/**
 * Called after the course builder saved a generated (or regenerated) lesson draft.
 * Never throws — video problems must not fail lesson generation.
 */
async function onLessonContentSaved(buildJobId, itemId, { log = () => {} } = {}) {
  try {
    const p = policy();
    if (!p.enabled || p.trigger !== 'draft') return null;
    const buildJob = await CourseBuildJob.findById(buildJobId).lean();
    if (!buildJob || buildJob.options?.generateVideos === false) return null;
    const item = await CourseBuildItem.findById(itemId).lean();
    if (!item || item.kind !== 'lesson' || !item.content) return null;
    return queueForTarget({ buildJob, item, policyOnChange: p.onChange, log });
  } catch (err) {
    log(`Could not queue lesson video: ${err.message}`, 'warn');
    return null;
  }
}

async function queueForTarget({ buildJob, item = null, lesson = null, policyOnChange, log = () => {} }) {
  const target = item || lesson;
  const meta = item ? item.video : lesson.aiVideo;
  // An existing video for an older version: only re-queue when policy says so.
  if (meta?.s3Key && meta.contentVersion !== target.contentVersion && policyOnChange !== 'auto') {
    log(`"${target.title}" changed — its video is marked outdated (regenerate it from the video panel)`);
    return { skipped: 'stale_manual' };
  }
  const results = { explainer: await enqueueVideo({ buildJob, item, lesson, variant: 'explainer' }) };
  const config = await videoConfig({ buildJob, variant: 'experiment' });
  const content = item ? item.content : lesson.aiContent;
  const assessment = assessExperiment(config.subject, content);
  if (assessment.experiment) {
    results.experiment = await enqueueVideo({ buildJob, item, lesson, variant: 'experiment' });
  }
  const created = Object.values(results).filter(r => r.created).length;
  if (created) log(`Queued ${created} video job(s) for "${target.title}"`);
  return results;
}

/** Publisher hook: copy draft video state to the lesson and apply the publish trigger. */
async function onLessonPublished(item, lessonId) {
  const set = { contentVersion: item.contentVersion || 1 };
  if (item.video) set.aiVideo = item.video;
  if (item.experimentVideo) set.aiExperimentVideo = item.experimentVideo;
  await Lesson.updateOne({ _id: lessonId }, { $set: set });
  // Running/queued jobs must update the lesson as well from now on.
  await GenerationJob.updateMany({ buildItemId: item._id, lessonId: null }, { $set: { lessonId } });
  await syncLessonVideoId(lessonId);

  const p = policy();
  if (p.enabled && p.trigger === 'publish' && item.kind === 'lesson' && item.content) {
    const buildJob = await CourseBuildJob.findById(item.jobId).lean();
    if (buildJob?.options?.generateVideos !== false) {
      const fresh = await CourseBuildItem.findById(item._id).lean();
      await queueForTarget({ buildJob, item: fresh, policyOnChange: p.onChange }).catch(() => {});
    }
  }
}

/** Content of a draft/lesson changed: bump version, flag existing videos as outdated. */
function staleFlags(doc, fields) {
  const set = {};
  for (const f of fields) {
    if (doc[f]?.s3Key) set[`${f}.stale`] = true;
  }
  return set;
}

/**
 * Students see the generated explainer through the lesson's existing `videoId`
 * field — but only when it is watchable and the teacher has not uploaded their
 * own video. A teacher video (any key outside ai-videos/) is never replaced.
 */
async function syncLessonVideoId(lessonId) {
  const lesson = await Lesson.findById(lessonId).select('videoId aiVideo').lean();
  if (!lesson) return;
  const v = lesson.aiVideo;
  const isAiKey = (k) => typeof k === 'string' && k.startsWith(AI_VIDEO_PREFIX);
  if (isVideoWatchable(v)) {
    if (!lesson.videoId || isAiKey(lesson.videoId)) {
      if (lesson.videoId !== v.s3Key) await Lesson.updateOne({ _id: lessonId }, { $set: { videoId: v.s3Key } });
    }
  } else if (isAiKey(lesson.videoId)) {
    await Lesson.updateOne({ _id: lessonId }, { $set: { videoId: null } });
  }
}

function statusFromJob(job) {
  if (job.state === 'completed') return 'completed';
  if (job.state === 'failed') return 'failed';
  if (job.state === 'cancelled') return 'cancelled';
  if (job.state === 'running' && ['generating_script', 'generating_audio', 'generating_visuals', 'assembling', 'validating'].includes(job.stage)) return job.stage;
  if (job.state === 'running') return 'generating_script';
  return 'queued';
}

async function targetsOf(job) {
  const out = [];
  if (job.buildItemId) out.push([CourseBuildItem, job.buildItemId, itemField(job.variant)]);
  let lessonId = job.lessonId;
  if (!lessonId && job.buildItemId) {
    const item = await CourseBuildItem.findById(job.buildItemId).select('published.lessonId').lean();
    lessonId = item?.published?.lessonId || null;
  }
  if (lessonId) out.push([Lesson, lessonId, lessonField(job.variant)]);
  return out;
}

/** Mirror the job's state onto the draft/lesson video metadata (never touches the current video file). */
async function applyJobStatus(jobId) {
  const job = await GenerationJob.findById(jobId).lean();
  if (!job || job.type !== 'lesson_video') return;
  const status = statusFromJob(job);
  const patch = { status, jobId: job._id, error: status === 'failed' ? job.error?.message || 'Video generation failed' : (job.state === 'retry_wait' ? `Retrying: ${job.error?.message || ''}`.slice(0, 300) : null) };
  if (['failed', 'cancelled'].includes(status)) patch.pendingContentVersion = null;
  for (const [Model, id, field] of await targetsOf(job)) await setVideoMeta(Model, id, field, patch);
}

/** A job passed validation: make its video the current one. */
async function applyJobResult(jobId) {
  const job = await GenerationJob.findById(jobId).lean();
  if (!job || job.state !== 'completed' || !job.output?.s3Key) return;
  const o = job.output;
  const review = job.review?.required ? (job.review.status === 'not_required' ? 'pending' : job.review.status) : 'not_required';
  for (const [Model, id, field] of await targetsOf(job)) {
    const doc = await Model.findById(id).select(`${field} contentVersion`).lean();
    if (!doc) continue;
    const cur = doc[field] || {};
    // A newer job may already have finished for a newer content version.
    if (cur.s3Key && cur.contentVersion > job.contentVersion) continue;
    const previous = cur.s3Key && cur.s3Key !== o.s3Key
      ? { s3Key: cur.s3Key, url: cur.url, captionsKey: cur.captionsKey, captionsUrl: cur.captionsUrl, durationSeconds: cur.durationSeconds, contentVersion: cur.contentVersion, jobId: cur.jobId, completedAt: cur.updatedAt }
      : (cur.previous || null);
    await setVideoMeta(Model, id, field, {
      status: 'completed',
      jobId: job._id,
      provider: o.provider,
      s3Key: o.s3Key,
      url: o.url,
      captionsKey: o.captionsKey,
      captionsUrl: o.captionsUrl,
      durationSeconds: o.durationSeconds,
      transcript: o.transcript,
      contentVersion: job.contentVersion,
      pendingContentVersion: null,
      stale: (doc.contentVersion || 1) > job.contentVersion,
      disclosure: job.variant === 'experiment' ? SIMULATION_DISCLOSURE : null,
      reviewStatus: review,
      reviewReason: (job.review?.reasons || []).join('; ') || null,
      error: null,
      previous,
    });
    if (Model === Lesson && job.variant !== 'experiment') await syncLessonVideoId(id);
  }
}

async function reviewVideo(jobId, status, userId) {
  if (!['approved', 'rejected'].includes(status)) throw Object.assign(new Error('status must be approved or rejected'), { status: 400 });
  const job = await GenerationJob.findOneAndUpdate(
    { _id: jobId, type: 'lesson_video' },
    { $set: { 'review.status': status, 'review.by': userId, 'review.at': new Date() } },
    { new: true },
  );
  if (!job) throw Object.assign(new Error('Video job not found'), { status: 404 });
  for (const [Model, id, field] of await targetsOf(job)) {
    const doc = await Model.findById(id).select(field).lean();
    if (String(doc?.[field]?.jobId) !== String(job._id)) continue;
    await setVideoMeta(Model, id, field, { reviewStatus: status });
    if (Model === Lesson && job.variant !== 'experiment') await syncLessonVideoId(id);
  }
  return job;
}

async function notify(jobId, outcome) {
  try {
    const job = await GenerationJob.findById(jobId).lean();
    if (!job) return;
    let userId = job.requestedBy;
    if (!userId && job.buildJobId) userId = (await CourseBuildJob.findById(job.buildJobId).select('createdBy').lean())?.createdBy;
    if (!userId) return;
    const target = job.buildItemId
      ? await CourseBuildItem.findById(job.buildItemId).select('title').lean()
      : await Lesson.findById(job.lessonId).select('title').lean();
    const Notification = require('../../models/Notification');
    const label = job.variant === 'experiment' ? 'Experiment video' : 'Lesson video';
    await Notification.create({
      userId,
      title: outcome === 'completed' ? `${label} ready` : `${label} failed`,
      message: outcome === 'completed'
        ? `"${target?.title || 'Lesson'}" now has a generated video${job.review?.required ? ' waiting for your review' : ''}.`
        : `"${target?.title || 'Lesson'}": ${job.error?.message || 'generation failed'}. You can retry it from the course builder.`,
      type: outcome === 'completed' ? 'course' : 'error',
      data: { generationJobId: job._id, buildJobId: job.buildJobId, buildItemId: job.buildItemId, lessonId: job.lessonId, courseId: job.courseId },
    });
  } catch (e) {
    console.warn('[video] notification failed:', e.message);
  }
}

/** Summary for the admin build screen. */
async function summaryForBuild(buildJobId) {
  const jobs = await GenerationJob.find({ buildJobId, type: 'lesson_video' })
    .select('state stage variant cost.actualUsd buildItemId error review contentVersion attempts createdAt finishedAt').lean();
  const byStatus = {};
  let usd = 0;
  let pendingReview = 0;
  for (const j of jobs) {
    const s = statusFromJob(j);
    byStatus[s] = (byStatus[s] || 0) + 1;
    usd += j.cost?.actualUsd || 0;
    if (j.state === 'completed' && j.review?.required && j.review.status === 'pending') pendingReview++;
  }
  return { total: jobs.length, byStatus, actualUsd: Math.round(usd * 10000) / 10000, pendingReview };
}

module.exports = {
  enqueueVideo,
  onLessonContentSaved,
  onLessonPublished,
  queueForTarget,
  applyJobStatus,
  applyJobResult,
  reviewVideo,
  syncLessonVideoId,
  statusFromJob,
  staleFlags,
  summaryForBuild,
  notify,
  videoConfig,
  policy,
  itemField,
  lessonField,
  AI_VIDEO_PREFIX,
};
