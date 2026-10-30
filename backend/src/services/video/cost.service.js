const mongoose = require('mongoose');
const GenerationJob = require('../../models/GenerationJob');

/**
 * Cost estimation and spending limits for video generation.
 *
 * Prices are never hard-coded (they change); configure them:
 *   VIDEO_TTS_COST_PER_1K_CHARS     USD per 1000 characters for the paid TTS provider
 *   VIDEO_LLM_COST_PER_1K_TOKENS    USD per 1000 tokens for the planning model (default 0)
 *   VIDEO_MAX_COST_PER_LESSON_USD   default 1.00
 *   VIDEO_MAX_COST_PER_COURSE_USD   default 25.00 (per-build override: options.videoBudgetUsd)
 *
 * A paid provider with no configured price is refused, so bulk generation can
 * never run up unbounded spend.
 */

function num(v, d) {
  const n = parseFloat(v);
  return Number.isFinite(n) ? n : d;
}

function limits(buildJob) {
  const courseOverride = num(buildJob?.options?.videoBudgetUsd, 0);
  return {
    perLesson: num(process.env.VIDEO_MAX_COST_PER_LESSON_USD, 1),
    perCourse: courseOverride > 0 ? courseOverride : num(process.env.VIDEO_MAX_COST_PER_COURSE_USD, 25),
  };
}

function llmCost(tokens) {
  return (tokens / 1000) * num(process.env.VIDEO_LLM_COST_PER_1K_TOKENS, 0);
}

function ttsCost(provider, chars) {
  if (!provider.paid) return 0;
  const rate = provider.costPer1kChars();
  if (rate == null) {
    throw Object.assign(new Error(`Spending control: set VIDEO_TTS_COST_PER_1K_CHARS for the "${provider.name}" text-to-speech provider before generating videos with it.`), { retryable: false, code: 'BUDGET_RATE_MISSING' });
  }
  return (chars / 1000) * rate;
}

async function courseSpend(courseId) {
  if (!courseId) return 0;
  const [r] = await GenerationJob.aggregate([
    { $match: { courseId: new mongoose.Types.ObjectId(String(courseId)), type: 'lesson_video' } },
    { $group: { _id: null, usd: { $sum: '$cost.actualUsd' } } },
  ]);
  return r?.usd || 0;
}

/**
 * Money other videos of the course have reserved but not spent yet: videos
 * made in parallel each reserve their estimate before paying for anything.
 */
async function reservedByOthers(courseId, jobId) {
  if (!courseId) return 0;
  const [r] = await GenerationJob.aggregate([
    { $match: { courseId: new mongoose.Types.ObjectId(String(courseId)), type: 'lesson_video', state: 'running', _id: { $ne: new mongoose.Types.ObjectId(String(jobId)) } } },
    { $group: { _id: null, usd: { $sum: { $max: [0, { $subtract: [{ $ifNull: ['$cost.estimatedUsd', 0] }, { $ifNull: ['$cost.actualUsd', 0] }] }] } } } },
  ]);
  return r?.usd || 0;
}

/**
 * Throw (non-retryable) if spending `estimateUsd` more would exceed a limit.
 * The estimate is reserved on the job first, then checked against what is
 * spent plus what other running videos have reserved, so videos made in
 * parallel cannot overshoot the course budget together.
 */
async function assertWithinBudget({ job, buildJob, estimateUsd }) {
  const l = limits(buildJob);
  const jobSpent = job.cost?.actualUsd || 0;
  if (jobSpent + estimateUsd > l.perLesson + 1e-9) {
    throw Object.assign(new Error(`Spending limit: this video would cost about $${(jobSpent + estimateUsd).toFixed(2)}, above the per-lesson limit of $${l.perLesson.toFixed(2)} (VIDEO_MAX_COST_PER_LESSON_USD).`), { retryable: false, code: 'BUDGET_EXCEEDED' });
  }
  await GenerationJob.updateOne({ _id: job._id }, { $set: { 'cost.estimatedUsd': jobSpent + estimateUsd } });
  const [actual, reserved] = await Promise.all([courseSpend(job.courseId), reservedByOthers(job.courseId, job._id)]);
  const spent = actual + reserved;
  if (spent + estimateUsd > l.perCourse + 1e-9) {
    await GenerationJob.updateOne({ _id: job._id }, { $set: { 'cost.estimatedUsd': jobSpent } });
    throw Object.assign(new Error(`Spending limit: course video spend would reach $${(spent + estimateUsd).toFixed(2)}, above the course limit of $${l.perCourse.toFixed(2)}${reserved > 0 ? ` (including $${reserved.toFixed(2)} reserved by videos being made right now)` : ''}. Raise the course video budget to continue.`), { retryable: false, code: 'BUDGET_EXCEEDED' });
  }
  return { limits: l, courseSpent: spent };
}

module.exports = { limits, llmCost, ttsCost, courseSpend, reservedByOthers, assertWithinBudget };
