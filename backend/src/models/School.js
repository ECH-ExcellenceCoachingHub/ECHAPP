const mongoose = require('mongoose');

const addressSchema = new mongoose.Schema({
  country: { type: String, trim: true, maxlength: 80, default: 'Rwanda' },
  province: { type: String, trim: true, maxlength: 80 },
  district: { type: String, trim: true, maxlength: 80 },
  sector: { type: String, trim: true, maxlength: 80 },
  cell: { type: String, trim: true, maxlength: 80 },
  village: { type: String, trim: true, maxlength: 80 },
  street: { type: String, trim: true, maxlength: 200 },
}, { _id: false });

const schoolSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'School name is required'],
    trim: true,
    maxlength: [200, 'School name cannot exceed 200 characters']
  },
  // Short unique code used as the prefix of every student code (e.g. GSB → GSB260001).
  code: {
    type: String,
    trim: true,
    uppercase: true,
    unique: true,
    sparse: true,
    match: [/^[A-Z0-9]{2,8}$/, 'School code must be 2-8 letters or digits']
  },
  description: {
    type: String,
    trim: true,
    maxlength: [1000, 'Description cannot exceed 1000 characters']
  },
  type: {
    type: String,
    enum: ['nursery', 'primary', 'secondary', 'tvet', 'combined', 'university', 'other'],
    default: 'secondary'
  },
  ownership: {
    type: String,
    enum: ['public', 'government_aided', 'private', 'other'],
    default: 'private'
  },
  address: { type: addressSchema, default: () => ({}) },
  phone: { type: String, trim: true, maxlength: 30 },
  email: { type: String, trim: true, lowercase: true, maxlength: 120 },
  website: { type: String, trim: true, maxlength: 200 },
  logo: { type: String, trim: true },
  // Levels the school teaches (N1…P6, S1…S6, L3…L5) and A-level combinations (MPC, PCB…).
  levels: [{ type: String, trim: true, maxlength: 20 }],
  combinations: [{ type: String, trim: true, uppercase: true, maxlength: 20 }],
  // Director / head teacher name shown on reports.
  headTeacherName: { type: String, trim: true, maxlength: 120 },

  // Main school admin user (more admins may exist: User.role = school_admin + schoolId).
  admin: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: false
  },

  // ── Billing: schools pay per student per term (see SchoolTerm.billing) ──
  pricePerStudentPerTerm: { type: Number, min: 0, default: 0 },
  currency: { type: String, default: 'RWF' },
  // Days after a paid term ends during which access continues (holidays, late payment).
  graceDays: { type: Number, min: 0, max: 120, default: 21 },
  // Students allowed while no term has been paid yet (trial).
  trialStudentLimit: { type: Number, min: 0, default: 30 },

  // Legacy fields (kept so older app versions keep working).
  plan: { type: String, enum: ['free', 'basic', 'premium'], default: 'free' },
  studentLimit: { type: Number, min: 0, default: 50 },
  studentCount: { type: Number, default: 0 },

  // ── Where and when students may sign in ─────────────────────────────
  //   anywhere — code + PIN from any place (default)
  //   code     — also needs the current class/school code a teacher shows at school
  //              (devices on allowedIps skip the code)
  //   network  — only from the school's internet connection (allowedIps)
  studentAccess: {
    mode: { type: String, enum: ['anywhere', 'code', 'network'], default: 'anywhere' },
    codeMinutes: { type: Number, enum: [30, 45, 60, 90], default: 60 },
    // School sessions end at this local time (Africa/Kigali) or after maxSessionHours.
    dayEndsAt: { type: String, match: /^([01]\d|2[0-3]):[0-5]\d$/, default: '17:00' },
    maxSessionHours: { type: Number, min: 1, max: 16, default: 9 },
    // School public IP addresses (IPv4/IPv6, IPv4 CIDR like 41.186.0.0/24).
    allowedIps: [{ type: String, trim: true, maxlength: 64 }],
    // Levels whose pupils sign in by class code + tapping their name (no PIN).
    pinlessLevels: { type: [String], default: ['N1', 'N2', 'N3', 'P1', 'P2', 'P3'] },
    // Set when the school admin saved the sign-in rules (setup checklist).
    reviewedAt: { type: Date, default: null },
  },

  // Next number used when generating student codes.
  studentSeq: { type: Number, default: 0 },

  isActive: { type: Boolean, default: true },
}, {
  timestamps: true
});

schoolSchema.index({ admin: 1 });
schoolSchema.index({ isActive: 1 });
schoolSchema.index({ name: 'text' });

module.exports = mongoose.model('School', schoolSchema);
