const mongoose = require('mongoose');

/**
 * A figure (diagram, graph, photo, table image) extracted from a textbook.
 * The image file lives in object storage; this document keeps provenance and
 * everything needed to reuse it in lessons and videos. Assets are keyed by
 * the book's content hash, so the same book version is never extracted twice
 * and assets are shared by every build of that book.
 *
 * The original extraction is never modified: crops, highlights or animated
 * derivatives are stored in `derivatives` with their own storage keys.
 */
const figureAssetSchema = new mongoose.Schema({
  bookHash: { type: String, required: true },          // sha256 of the source file
  extractorVersion: { type: String, required: true },
  figureId: { type: String, required: true },          // extractor id, e.g. "p12_f2"
  extractionId: { type: mongoose.Schema.Types.ObjectId, ref: 'FigureExtraction' },
  sourceJobId: { type: mongoose.Schema.Types.ObjectId, ref: 'CourseBuildJob', default: null },
  sourceFileName: String,

  chapterIndex: { type: Number, default: null },
  chapterTitle: String,
  sectionTitle: String,
  page: { type: Number, required: true },
  printedPage: String,

  caption: { type: String, default: null },
  captionLabel: { type: String, default: null },       // "2.1"
  kind: { type: String, default: 'figure' },           // figure | table | diagram | photo
  classification: { type: String, default: null },     // optional finer label (graph, apparatus, map …)

  storageKey: { type: String, default: null },
  url: { type: String, default: null },
  widthPx: Number,
  heightPx: Number,
  dpi: Number,
  bbox: [Number],                                      // PDF points [x0,y0,x1,y1]
  pageSize: [Number],

  labels: [String],
  // Label positions inside the rendered image (0..1 fractions) for highlights.
  labelBoxes: [{ text: String, box: [Number], _id: false }],
  ocrText: { type: String, default: null },
  surroundingText: { type: String, default: '' },
  extractionMethod: String,                            // image_bbox | vector_cluster | merged | caption_search | table | caption_only
  hasRaster: Boolean,
  hasVector: Boolean,
  needsOcr: Boolean,
  quality: { type: String, enum: ['ok', 'needs_review', 'incomplete'], default: 'needs_review' },
  warnings: [String],
  hash: String,
  duplicateOf: { type: String, default: null },
  continuationOf: { type: String, default: null },

  derivatives: [{
    kind: String,            // crop | highlight | animation
    storageKey: String,
    url: String,
    createdAt: { type: Date, default: Date.now },
    _id: false,
  }],
  provenance: {
    source: { type: String, default: 'textbook' },
    pdfSha256: String,
    pymupdfVersion: String,
  },
}, { timestamps: true });

figureAssetSchema.index({ bookHash: 1, extractorVersion: 1, figureId: 1 }, { unique: true });
figureAssetSchema.index({ bookHash: 1, page: 1 });

module.exports = mongoose.model('FigureAsset', figureAssetSchema);
