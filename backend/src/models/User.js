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
    enum: ['student', 'admin', 'instructor'],
    default: 'student'
  },
  phone: {
    type: String,
    trim: true,
    unique: true,
    sparse: true  // Allows multiple null values but enforces uniqueness for non-null values
  },
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
  }]
}, {
  timestamps: true
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
userSchema.methods.comparePassword = async function(enteredPassword) {
  // If no password exists (Firebase users), return false
  if (!this.password) {
    return false;
  }
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', userSchema);