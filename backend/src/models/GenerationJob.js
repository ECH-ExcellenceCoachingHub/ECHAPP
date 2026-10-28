const mongoose = require('mongoose');

/**
 * Persistent background job (MongoDB-backed queue) for long-running media
 * work that must never run inside an API request:
 *   - lesson_video       one generated video for one lesson content version
 *   - figure_extraction  textbook figure extraction for one book version
 *
 * Workers claim jobs atomically with a lease (owner + expiry). A crashed
 * worker's lease simply expires and another worker picks the job up again.
 * `key` is unique, so the same lesson/version/config can never be queued twice.
 */

const STATES = ['queued', 'running', 'retry_wait', 'completed', 'failed', 'cancelled'];

const generationJobSchema = new mongoose.Schema({
  type: { type: String, enum: ['lesson_video', 'figure_extraction'], required: true },
  key: { type: String, required: true, unique: true },

  // Targets
  courseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', default: null },
  buildJobId: { type: mongoose.Schema.Types.ObjectId, ref: 'CourseBuildJob', default: null },
  buildItemId: { type: mongoose.Schema.Types.ObjectId, ref: 'CourseBuildItem', default: null },
  lessonId: { type: mongoose.Schema.Types.ObjectId, ref: 'Lesson', default: null },
  variant: { type: String, enum: ['explainer', 'experiment', null], default: null },
  contentVersion: { type: Number, default: null },
  config: { type: mongoose.Schema.Types.Mixed, default: {} },
  configHash: { type: String, default: null },

  // Queue state
  state: { type: String, enum: STATES, default: 'queued' },
  stage: { type: String, default: 'queued' },
  priority: { type: Number, default: 0 },
  attempts: { type: Number, default: 0 },
  maxAttempts: { type: Number, default: 4 },
  nextRunAt: { type: Date, default: Date.now },
  lease: {
    owner: { type: String, default: null },
    expiresAt: { type: Date, default: null },
  },
  cancelRequested: { type: Boolean, default: false },
  // Regeneration of part of a video: first stage to redo.
  restartFrom: { type: String, enum: ['script', 'audio', 'visuals', null], default: null },

  // Stage outputs kept so a retry resumes instead of starting over.
  artifacts: { type: mongoose.Schema.Types.Mixed, default: {} },
  output: { type: mongoose.Schema.Types.Mixed, default: null },
  checks: [{ name: String, passed: Boolean, detail: String, _id: false }],

  cost: {
    llmTokens: { type: Number, default: 0 },
    ttsChars: { type: Number, default: 0 },
    estimatedUsd: { type: Number, default: 0 },
    actualUsd: { type: Number, default: 0 },
    items: [{ stage: String, provider: String, units: Number, unit: String, usd: Number, requestId: String, at: Date, _id: false }],
  },
  providerRequests: [{ stage: String, provider: String, requestId: String, at: Date, _id: false }],
  stageHistory: [{ stage: String, status: String, at: Date, ms: Number, message: String, _id: false }],

  review: {
    required: { type: Boolean, default: false },
    status: { type: String, enum: ['not_required', 'pending', 'approved', 'rejected'], default: 'not_required' },
    reasons: [String],
    by: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    at: Date,
  },

  error: {
    message: String,
    stage: String,
    code: String,
    retryable: Boolean,
    at: Date,
  },
  requestedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  startedAt: Date,
  finishedAt: Date,
}, { timestamps: true });

generationJobSchema.index({ state: 1, nextRunAt: 1, priority: -1 });
generationJobSchema.index({ buildJobId: 1, type: 1 });
generationJobSchema.index({ buildItemId: 1, variant: 1, createdAt: -1 });
generationJobSchema.index({ lessonId: 1, variant: 1, createdAt: -1 });
generationJobSchema.index({ courseId: 1, type: 1 });

generationJobSchema.statics.STATES = STATES;

module.exports = mongoose.model('GenerationJob', generationJobSchema);
