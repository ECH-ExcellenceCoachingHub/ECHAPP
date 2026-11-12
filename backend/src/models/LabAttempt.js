const mongoose = require('mongoose');

/**
 * One student's run through a lab scenario. Created when the lab starts,
 * autosaved while it runs (so a student can resume on another device), and
 * finalised on completion.
 */
const labAttemptSchema = new mongoose.Schema({
  // Client-generated UUID: makes offline sync idempotent.
  clientId: { type: String, required: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  scenarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'LabScenario', required: true, index: true },
  scenarioVersion: { type: Number, default: 1 },
  lessonId: { type: mongoose.Schema.Types.ObjectId, ref: 'Lesson', default: null },
  courseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', default: null },

  platform: { type: String, enum: ['android', 'ios', 'windows', 'web', 'quest', 'pcvr', 'other'], default: 'other' },
  mode: { type: String, enum: ['desktop', 'touch', 'cardboard', 'xr', 'fallback'], default: 'desktop' },
  qualityTier: { type: String, enum: ['low', 'medium', 'ultra'], default: 'medium' },
  lang: { type: String, default: 'en' },

  status: { type: String, enum: ['in_progress', 'completed', 'abandoned'], default: 'in_progress', index: true },
  currentStepId: { type: String, default: null },
  completedSteps: [{ type: String }],
  // Readings the student typed in measure steps, e.g. { titre: 20.05 }.
  records: { type: mongoose.Schema.Types.Mixed, default: {} },
  // Compact event log (intent, target, step, t) — becomes the lab notebook.
  log: [{
    _id: false,
    t: Number, // seconds since start
    type: { type: String }, // intent | step | hazard | hint | checkpoint | record
    stepId: String,
    data: mongoose.Schema.Types.Mixed,
  }],
  checkpoints: [{ _id: false, stepId: String, choice: Number, correct: Boolean }],
  hazardsTriggered: [{ _id: false, id: String, t: Number }],
  hintsUsed: { type: Number, default: 0 },
  mistakes: { type: Number, default: 0 },

  score: {
    accuracy: { type: Number, default: 0 },
    procedure: { type: Number, default: 0 },
    safety: { type: Number, default: 0 },
    total: { type: Number, default: 0 },
  },
  passed: { type: Boolean, default: false },
  xpAwarded: { type: Number, default: 0 },
  durationSec: { type: Number, default: 0 },
  perf: {
    avgFps: Number,
    minFps: Number,
    gpu: String,
    deviceModel: String,
  },
  startedAt: { type: Date, default: Date.now },
  completedAt: { type: Date, default: null },
}, { timestamps: true });

labAttemptSchema.index({ userId: 1, clientId: 1 }, { unique: true });
labAttemptSchema.index({ userId: 1, scenarioId: 1, status: 1 });

module.exports = mongoose.model('LabAttempt', labAttemptSchema);
