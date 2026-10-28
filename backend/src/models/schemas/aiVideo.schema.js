const mongoose = require('mongoose');

/**
 * Generated-video metadata kept on a lesson (Lesson.aiVideo /
 * Lesson.aiExperimentVideo) and on its draft (CourseBuildItem.video /
 * CourseBuildItem.experimentVideo). The video file itself lives in object
 * storage; detailed processing history lives in GenerationJob.
 *
 * Older documents simply have no such field (null) — every reader treats a
 * missing value as "no generated video".
 */

const VIDEO_STATUSES = [
  'queued',
  'generating_script',
  'generating_audio',
  'generating_visuals',
  'assembling',
  'validating',
  'completed',
  'failed',
  'cancelled',
];

const REVIEW_STATUSES = ['not_required', 'pending', 'approved', 'rejected'];

const storedVideoSchema = new mongoose.Schema({
  s3Key: String,
  url: String,
  captionsKey: String,
  captionsUrl: String,
  durationSeconds: Number,
  contentVersion: Number,
  jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'GenerationJob' },
  completedAt: Date,
}, { _id: false });

const aiVideoSchema = new mongoose.Schema({
  variant: { type: String, enum: ['explainer', 'experiment'], default: 'explainer' },
  status: { type: String, enum: VIDEO_STATUSES, default: 'queued' },
  jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'GenerationJob', default: null },
  provider: { type: String, default: null },
  // The currently valid video. Only replaced after a new render passed validation.
  s3Key: { type: String, default: null },
  url: { type: String, default: null },
  captionsKey: { type: String, default: null },
  captionsUrl: { type: String, default: null },
  durationSeconds: { type: Number, default: null },
  transcript: { type: String, default: null },
  // Lesson content version the *current* video was made from.
  contentVersion: { type: Number, default: 1 },
  // Lesson content version a job is currently working on (if any).
  pendingContentVersion: { type: Number, default: null },
  // True when the lesson changed after this video was made.
  stale: { type: Boolean, default: false },
  // Simulated / illustrative content disclosure (experiment videos).
  disclosure: { type: String, default: null },
  reviewStatus: { type: String, enum: REVIEW_STATUSES, default: 'not_required' },
  reviewReason: { type: String, default: null },
  error: { type: String, default: null },
  previous: { type: storedVideoSchema, default: null },
  updatedAt: { type: Date, default: Date.now },
}, { _id: false });

/** True when students may watch it. */
function isVideoWatchable(v) {
  return !!(v && v.s3Key && ['not_required', 'approved'].includes(v.reviewStatus || 'not_required'));
}

module.exports = { aiVideoSchema, VIDEO_STATUSES, REVIEW_STATUSES, isVideoWatchable };
