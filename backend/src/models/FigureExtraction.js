const mongoose = require('mongoose');

/** One figure-extraction run per book version (bookHash + extractor version). */
const figureExtractionSchema = new mongoose.Schema({
  bookHash: { type: String, required: true },
  extractorVersion: { type: String, required: true },
  status: { type: String, enum: ['queued', 'running', 'completed', 'failed'], default: 'queued' },
  sourceKey: String,
  fileName: String,
  generationJobId: { type: mongoose.Schema.Types.ObjectId, ref: 'GenerationJob', default: null },
  buildJobIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'CourseBuildJob' }],
  manifestKey: String,         // figures.json (reading order, tables, equations) in storage
  summary: { type: mongoose.Schema.Types.Mixed, default: null },
  error: { type: String, default: null },
  startedAt: Date,
  finishedAt: Date,
}, { timestamps: true });

figureExtractionSchema.index({ bookHash: 1, extractorVersion: 1 }, { unique: true });

module.exports = mongoose.model('FigureExtraction', figureExtractionSchema);
