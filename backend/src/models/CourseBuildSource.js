const mongoose = require('mongoose');

/**
 * Extracted text of an uploaded book, page by page. Kept apart from the job
 * document so job polling stays cheap and the 16MB document limit is never
 * an issue for the job itself.
 */
const courseBuildSourceSchema = new mongoose.Schema({
  jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'CourseBuildJob', required: true, unique: true },
  pages: [{ n: Number, text: String, _id: false }],
  // PDF bookmarks, flattened: depth 0 = top level
  bookmarks: [{ title: String, page: Number, depth: Number, _id: false }],
  // Lines that look like headings (bigger font / numbering / "Chapter N")
  headings: [{ page: Number, text: String, size: Number, score: Number, _id: false }],
}, { timestamps: true });

module.exports = mongoose.model('CourseBuildSource', courseBuildSourceSchema);
