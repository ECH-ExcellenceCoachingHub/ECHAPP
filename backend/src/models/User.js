const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  firebaseUid: {
    type: String,
    unique: true,
    sparse: true  // Allows multiple null values but enforces uniqueness for non-null values
  },
  fullName: {
    type: String,
    required: false,  // Made optional for phone auth users who will collect name later
    trim: true,
    maxlength: [100, 'Name cannot exceed 100 characters']
  },
  email: {
    type: String,
    required: false,
    unique: true,
    sparse: true,
    lowercase: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
  },
  password: {
    type: String,
    minlength: [6, 'Password must be at least 6 characters'],
    select: false,
    required: false  // Make password optional for Firebase users
  },
  role: {
    type: String,
    enum: ['student', 'admin', 'instructor', 'school_admin', 'parent'],
    default: 'student'
  },
  phone: {
    type: String,
    trim: true,
    unique: true,
    sparse: true  // Allows multiple null values but enforces uniqueness for non-null values
  },
  // School this user belongs to. Null = private (self-registered) student.
  schoolId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'School',
    index: true
  },
  // True for students who registered themselves (not added under a school).
  isPrivateStudent: {
    type: Boolean,
    default: false
  },
  // ── School members ────────────────────────────────────────────────────
  // Students of a school sign in with studentCode + PIN (no email needed).
  studentCode: {
    type: String,
    trim: true,
    uppercase: true,
    unique: true,
    sparse: true
  },
  pinHash: {
    type: String,
    select: false
  },
  pinFailedCount: { type: Number, default: 0, select: false },
  pinLockedUntil: { type: Date, default: null, select: false },
  // Current class of a school student.
  classroomId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Classroom',
    default: null,
    index: true
  },
  gender: { type: String, enum: ['male', 'female', 'other', null], default: null },
  dateOfBirth: { type: Date, default: null },
  // Parents / guardians of a student. userId is set when the guardian has a parent account.
  guardians: [{
    _id: false,
    name: { type: String, trim: true, maxlength: 100 },
    phone: { type: String, trim: true, maxlength: 30 },
    relationship: { type: String, trim: true, maxlength: 40 },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null }
  }],
  // Home address (teachers, students, parents).
  address: {
    province: { type: String, trim: true, maxlength: 80 },
    district: { type: String, trim: true, maxlength: 80 },
    sector: { type: String, trim: true, maxlength: 80 },
    cell: { type: String, trim: true, maxlength: 80 },
    village: { type: String, trim: true, maxlength: 80 },
    street: { type: String, trim: true, maxlength: 200 }
  },
  // Why a school student left (year-end promotion / removal).
  leftReason: { type: String, enum: ['graduated', 'left', 'transferred', null], default: null },
  leftAt: { type: Date, default: null },
  // Who created this account (school admin / class teacher / super admin).
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  // One active session at a time (school students): a new sign-in ends the old one.
  singleSession: { type: Boolean, default: false },
  activeSessionId: { type: String, default: null, select: false },
  // School-only sign-ins end at the end of the school day.
  activeSessionExpiresAt: { type: Date, default: null, select: false },
  googleId: {
    type: String,
    unique: true,
    sparse: true  // Allows multiple null values but enforces uniqueness for non-null values
  },
  avatar: {
    type: String
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  isActive: {
    type: Boolean,
    default: true
  },
  fcmToken: {
    type: String,
    sparse: true
  },
  deviceId: {
    type: String,
    sparse: true
  },
  resetPasswordToken: {
    type: String
  },
  resetPasswordExpires: {
    type: Date
  },
  lastActive: {
    type: Date,
    default: Date.now
  },
  totalSessionTime: {
    type: Number,
    default: 0  // Total time spent in app in seconds
  },
  lastSessionStart: {
    type: Date
  },
  sessionCount: {
    type: Number,
    default: 0
  },
  interests: {
    type: [String],
    default: []
  },
  shortTermGoal: {
    type: String
  },
  midTermGoal: {
    type: String
  },
  longTermGoal: {
    type: String
  },
  hasCompletedOnboarding: {
    type: Boolean,
    default: false
  },
  // Virtual-lab gamification
  labXp: {
    type: Number,
    default: 0
  },
  labBadges: [{
    _id: false,
    key: String,
    awardedAt: { type: Date, default: Date.now }
  }],
  // eexams.net single sign-on link (set when eexams reports the accounts linked)
  eexamsUserId: {
    type: String,
    default: null
  },
  eexamsLinkedAt: {
    type: Date,
    default: null
  },
  // Set on accounts created by Google/phone sign-in without a role choice:
  // the app asks "Student or Teacher?" once, then clears it.
  needsRoleSelection: {
    type: Boolean,
    default: false
  },
  // Self-registered teachers only (admin-created teachers leave this null and
  // keep full access). profile_incomplete → pending → approved | rejected.
  teacherStatus: {
    type: String,
    enum: ['profile_incomplete', 'pending', 'approved', 'rejected', null],
    default: null
  },
  teacherProfile: {
    school: { type: String, trim: true, maxlength: 200 },
    schoolType: { type: String, trim: true, maxlength: 60 },
    district: { type: String, trim: true, maxlength: 100 },
    province: { type: String, trim: true, maxlength: 100 },
    country: { type: String, trim: true, maxlength: 100 },
    levels: [{ type: String, trim: true, maxlength: 40 }],
    subjects: [{ type: String, trim: true, maxlength: 80 }],
    yearsExperience: { type: Number, min: 0, max: 60 },
    qualification: { type: String, trim: true, maxlength: 200 },
    phone: { type: String, trim: true, maxlength: 30 },
    bio: { type: String, trim: true, maxlength: 1000 },
    submittedAt: Date
  },
  teacherReview: {
    reviewedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    reviewedAt: Date,
    reason: { type: String, maxlength: 1000 }
  },
  // Super admins only. Not restricted = full access (see adminLimits.service).
  adminLimits: {
    restricted: { type: Boolean, default: false },
    areas: {
      users: { type: String, enum: ['full', 'view', 'none'], default: 'full' },
      courses: { type: String, enum: ['full', 'view', 'none'], default: 'full' },
      schools: { type: String, enum: ['full', 'view', 'none'], default: 'full' },
      payments: { type: String, enum: ['full', 'view', 'none'], default: 'full' },
      communication: { type: String, enum: ['full', 'view', 'none'], default: 'full' },
      settings: { type: String, enum: ['full', 'view', 'none'], default: 'full' },
      admins: { type: String, enum: ['full', 'view', 'none'], default: 'full' }
    },
    updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    updatedAt: { type: Date, default: null }
  }
}, {
  timestamps: true
});

// School members and parents never see the private-learner onboarding
// (interests, goals, phone): the school already gave ECH what it needs.
userSchema.pre('save', function() {
  if (!this.hasCompletedOnboarding && (this.schoolId || this.role === 'parent')) {
    this.hasCompletedOnboarding = true;
  }
});

// Hash password before saving
userSchema.pre('save', async function() {
  // Only hash password if it exists and is being modified
  if (this.isModified('password') && this.password) {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
  }
});

// Compare password method
userSchema.index({ 'guardians.userId': 1 });

userSchema.methods.comparePassword = async function(enteredPassword) {
  // If no password exists (Firebase users), return false
  if (!this.password) {
    return false;
  }
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', userSchema);