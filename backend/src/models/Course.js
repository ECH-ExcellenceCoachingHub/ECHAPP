const mongoose = require('mongoose');

const courseSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Course title is required'],
    trim: true,
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  description: {
    type: String,
    required: [true, 'Course description is required'],
    maxlength: [2000, 'Description cannot exceed 2000 characters']
  },
  price: {
    type: Number,
    required: [true, 'Price is required'],
    min: [0, 'Price cannot be negative']
  },
  duration: {
    type: Number,
    required: [true, 'Duration is required'],
    min: [0, 'Duration cannot be negative']
  },
  durationUnit: {
    type: String,
    enum: ['minutes', 'hours', 'days', 'weeks', 'months'],
    default: 'minutes'
  },
  level: {
    type: String,
    required: [true, 'Level is required'],
    enum: ['beginner', 'intermediate', 'advanced']
  },
  thumbnail: {
    type: String,
    default: null
  },
  instructorName: {
    type: String,
    trim: true,
    default: null
  },
  isPublished: {
    type: Boolean,
    default: false
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  category: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Category'
  },
  type: {
    type: String,
    required: false // Making it optional to avoid breaking existing functionality
  },
  learningObjectives: [{
    type: String
  }],
  requirements: [{
    type: String
  }],
  accessDuration: {
    type: Number,
    default: null, // null means unlimited access
    min: [1, 'Access duration must be at least 1']
  },
  accessDurationUnit: {
    type: String,
    enum: ['hours', 'days', 'weeks', 'months', 'years'],
    default: 'days'
  },
  accessDurationDays: {
    type: Number,
    default: null, // null means unlimited access
    min: [1, 'Access duration must be at least 1 day']
  },
  enrollmentCount: {
    type: Number,
    default: 0
  },
  averageRating: {
    type: Number,
    default: 0
  },
  assignedTeacherIds: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  // Lesson-video generation paused by an admin: its videos wait in the queue
  // and workers make other courses' videos instead.
  videoGeneration: {
    paused: { type: Boolean, default: false },
    pausedAt: { type: Date, default: null },
    pausedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null }
  }
}, {
  timestamps: true
});

// Index for better search performance
courseSchema.index({ title: 'text', description: 'text' });
courseSchema.index({ level: 1 });
courseSchema.index({ price: 1 });
courseSchema.index({ isPublished: 1 });
courseSchema.index({ assignedTeacherIds: 1 });

module.exports = mongoose.model('Course', courseSchema);