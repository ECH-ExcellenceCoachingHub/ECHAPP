const mongoose = require('mongoose');

const schoolSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'School name is required'],
    trim: true,
    maxlength: [200, 'School name cannot exceed 200 characters']
  },
  description: {
    type: String,
    trim: true,
    maxlength: [1000, 'Description cannot exceed 1000 characters']
  },
  // The school admin user who owns and manages this school
  admin: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: false
  },
  // Subscription plan purchased by the school
  plan: {
    type: String,
    enum: ['free', 'basic', 'premium'],
    default: 'free'
  },
  // Maximum number of students allowed under this school (from the paid plan)
  studentLimit: {
    type: Number,
    min: [0, 'Student limit cannot be negative'],
    default: 50
  },
  // Cached count of active students under this school
  studentCount: {
    type: Number,
    default: 0
  },
  isActive: {
    type: Boolean,
    default: true
  },
}, {
  timestamps: true
});

schoolSchema.index({ admin: 1 });
schoolSchema.index({ plan: 1 });
schoolSchema.index({ isActive: 1 });

module.exports = mongoose.model('School', schoolSchema);
