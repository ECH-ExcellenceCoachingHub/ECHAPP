const mongoose = require('mongoose');

/**
 * A virtual-lab experiment: the scenario DSL (validated by
 * services/labs/validator.js) plus publishing metadata. The Unity lab engine
 * downloads `definition` and plays it in any mode (desktop, touch, Cardboard, XR).
 */
const labScenarioSchema = new mongoose.Schema({
  slug: { type: String, required: true, unique: true, trim: true, lowercase: true },
  title: { type: String, required: true, trim: true, maxlength: 120 },
  summary: { type: String, maxlength: 600 },
  subject: { type: String, required: true, index: true },
  environment: { type: String, required: true },
  level: { type: String, default: 'secondary' },
  difficulty: { type: Number, default: 2, min: 1, max: 5, index: true },
  tags: [{ type: String }],
  durationMin: { type: Number, default: 20 },
  xp: { type: Number, default: 100 },
  thumbnail: { type: String, default: null },
  // Full, validated scenario JSON (steps, equipment, hazards, scoring...).
  definition: { type: mongoose.Schema.Types.Mixed, required: true },
  version: { type: Number, default: 1 },
  status: { type: String, enum: ['draft', 'review', 'published', 'archived'], default: 'draft', index: true },
  source: { type: String, enum: ['seed', 'teacher', 'ai'], default: 'teacher' },
  // Lessons this lab was generated for or is attached to.
  lessonIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Lesson' }],
  courseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', default: null },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  reviewedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  publishedAt: { type: Date, default: null },
  stats: {
    attempts: { type: Number, default: 0 },
    completions: { type: Number, default: 0 },
    avgScore: { type: Number, default: 0 },
  },
}, { timestamps: true });

labScenarioSchema.index({ status: 1, subject: 1 });

/** Lightweight shape for lists (no step definitions). */
labScenarioSchema.methods.toCard = function toCard() {
  return {
    id: this._id,
    slug: this.slug,
    title: this.title,
    summary: this.summary,
    subject: this.subject,
    environment: this.environment,
    level: this.level,
    difficulty: this.difficulty || this.definition?.difficulty || 2,
    tags: this.tags || [],
    objectives: Array.isArray(this.definition?.objectives) ? this.definition.objectives : [],
    hintCount: Array.isArray(this.definition?.steps) ? this.definition.steps.reduce((n, s) => n + (Array.isArray(s.hints) ? s.hints.length : 0), 0) : 0,
    durationMin: this.durationMin,
    xp: this.xp,
    thumbnail: this.thumbnail,
    status: this.status,
    version: this.version,
    stepCount: Array.isArray(this.definition?.steps) ? this.definition.steps.length : 0,
    stats: this.stats,
  };
};

module.exports = mongoose.model('LabScenario', labScenarioSchema);
