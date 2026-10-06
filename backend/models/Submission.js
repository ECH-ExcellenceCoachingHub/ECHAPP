const mongoose = require('mongoose');

const submissionSchema = new mongoose.Schema({
  examId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Quiz',
    required: true
  },
  userId: {
    type: String,
    required: true
  },
  totalScore: {
    type: Number,
    required: true,
    min: 0
  },
  maxScore: {
    type: Number,
    required: true,
    min: 0
  },
  percentage: {
    type: Number,
    required: true,
    min: 0,
    max: 100
  },
  passed: {
    type: Boolean,
    required: true
  },
  needsManualGrading: {
    type: Boolean,
    default: false
  },
  results: [{
    questionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Question',
      required: true
    },
    questionType: {
      type: String,
      required: true
    },
    question: {
      type: String,
      required: true
    },
    options: [{
      text: String,
      isCorrect: Boolean
    }],
    correctAnswer: mongoose.Schema.Types.Mixed,
    userAnswer: {
      selectedOption: Number,
      answerText: String
    },
    isCorrect: {
      type: Boolean,
      required: true
    },
    score: {
      type: Number,
      required: true,
      min: 0
    },
    maxScore: {
      type: Number,
      required: true,
      min: 0
    },
    // Marker's comment for written answers and how they were marked (auto | ai | fallback)
    feedback: String,
    gradedBy: String
  }],
  submittedAt: {
    type: Date,
    default: Date.now
  },
  gradedAt: {
    type: Date
  },
  gradedBy: {
    type: String
  }
}, {
  timestamps: true
});

// Index for efficient queries
submissionSchema.index({ examId: 1, userId: 1, submittedAt: -1 });
submissionSchema.index({ userId: 1, submittedAt: -1 });

module.exports = mongoose.model('Submission', submissionSchema);
