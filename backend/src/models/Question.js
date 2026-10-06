const mongoose = require('mongoose');

const questionSchema = new mongoose.Schema({
  quizId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Quiz',
    required: true
  },
  text: {
    type: String,
    required: true,
    trim: true
  },
  type: {
    type: String,
    required: true,
    enum: ['mcq', 'true_false', 'fill_blank', 'essay', 'drag_drop', 'matching', 'ordering', 'hotspot', 'programming'],
    default: 'mcq'
  },
  options: [{
    id: {
      type: mongoose.Schema.Types.Mixed,
      default: null
    },
    text: {
      type: String,
      required: true,
      trim: true
    },
    image: {
      type: String,
      default: null
    },
    isCorrect: {
      type: Boolean,
      default: false
    }
  }],
  correctAnswer: {
    type: mongoose.Schema.Types.Mixed,
    required: function() {
      return this.type === 'mcq' || this.type === 'true_false' || this.type === 'fill_blank' || this.type === 'essay' || this.type === 'programming';
    }
  },
  // Drag and drop specific fields
  dragDropItems: [{
    id: { type: String, required: true },
    content: { type: String, required: true },
    image: { type: String, default: null },
    targetZone: { type: String, required: true }
  }],
  dropZones: [{
    id: { type: String, required: true },
    label: { type: String, required: true },
    correctItems: [{ type: String }],
    acceptsMultiple: { type: Boolean, default: false }
  }],
  // Matching specific fields
  matchingPairs: [{
    leftItem: { type: String, required: true },
    rightItem: { type: String, required: true },
    leftId: { type: String },
    rightId: { type: String }
  }],
  // Ordering specific fields
  correctOrder: [{ type: String }],
  // Hotspot specific fields
  hotspots: [{
    id: { type: String, required: true },
    x: { type: Number, required: true },
    y: { type: Number, required: true },
    width: { type: Number, required: true },
    height: { type: Number, required: true },
    label: { type: String },
    isCorrect: { type: Boolean, default: true }
  }],
  hotspotImage: { type: String },
  points: {
    type: Number,
    default: 1,
    min: 1
  },
  explanation: {
    type: String,
    trim: true
  },
  timeLimit: {
    type: Number,
    default: 30
  },
  difficulty: {
    type: String,
    enum: ['easy', 'medium', 'hard'],
    default: 'medium'
  },
  mediaUrl: {
    type: String,
    trim: true
  },
  starterCode: {
    type: String,
    trim: true
  },
  testCases: [{
    type: [{
      input: { type: String, required: true },
      expectedOutput: { type: String, required: true }
    }],
    default: []
  }],
  allowMultipleAttempts: {
    type: Boolean,
    default: true
  },
  maxAttempts: {
    type: Number,
    default: 3
  },
  isActive: {
    type: Boolean,
    default: true
  },
  // Where an AI-generated question came from in the source book
  source: {
    chapter: { type: String },
    section: { type: String },
    page: { type: Number }
  },
  aiGenerated: {
    type: Boolean,
    default: false
  },
  aiConfidence: {
    type: Number
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Add indexes for better performance
questionSchema.index({ quizId: 1 });
questionSchema.index({ text: 1, type: 1, difficulty: 1 });

module.exports = mongoose.model('Question', questionSchema);
