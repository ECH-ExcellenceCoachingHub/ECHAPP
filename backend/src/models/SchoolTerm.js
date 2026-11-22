const mongoose = require('mongoose');

/**
 * One school term (e.g. 2026 Term 2) and what the school paid for it.
 * Schools pay per student per term: billing.studentsPaid is the seat limit
 * while the term is current.
 */
const schoolTermSchema = new mongoose.Schema({
  schoolId: { type: mongoose.Schema.Types.ObjectId, ref: 'School', required: true, index: true },
  academicYear: { type: String, required: true, trim: true, maxlength: 20 }, // "2026" or "2025-2026"
  term: { type: Number, required: true, min: 1, max: 4 },
  startDate: { type: Date, required: true },
  endDate: { type: Date, required: true },
  billing: {
    studentsPaid: { type: Number, min: 0, default: 0 },
    pricePerStudent: { type: Number, min: 0, default: 0 },
    amount: { type: Number, min: 0, default: 0 },
    status: { type: String, enum: ['unpaid', 'pending', 'paid', 'waived'], default: 'unpaid' },
    method: { type: String, trim: true, maxlength: 40 },
    reference: { type: String, trim: true, maxlength: 120 },
    paidAt: Date,
    recordedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    notes: { type: String, trim: true, maxlength: 500 },
  },
}, { timestamps: true });

schoolTermSchema.index({ schoolId: 1, academicYear: 1, term: 1 }, { unique: true });
schoolTermSchema.index({ schoolId: 1, startDate: 1 });

schoolTermSchema.virtual('label').get(function () {
  return `${this.academicYear} Term ${this.term}`;
});

module.exports = mongoose.model('SchoolTerm', schoolTermSchema);
