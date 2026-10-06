const mongoose = require('mongoose');

const lessonSchema = new mongoose.Schema({
  sectionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Section',
    required: [true, 'Section ID is required']
  },
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: [true, 'Course ID is required']
  },
  title: {
    type: String,
    required: [true, 'Lesson title is required'],
    trim: true,
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  description: {
    type: String,
    maxlength: [1000, 'Description cannot exceed 1000 characters']
  },
  videoId: {
    type: String,
    default: null
  },
  notes: {
    type: String, // Can store PDF path or text content
    default: null
  },
  notesPdfUrl: {
    type: String,
    default: null
  },
  order: {
    type: Number,
    required: [true, 'Order is required'],
    min: [0, 'Order cannot be negative']
  },
  duration: {
    type: Number,
    default: 0, // in minutes
    min: [0, 'Duration cannot be negative']
  },
  status: {
    type: String,
    enum: ['draft', 'processing', 'completed', 'error'],
    default: 'completed' // Default to completed for existing lessons
  },
  // New fields for professional structure
  quizId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Quiz',
    default: null
  },
  materials: [{
    type: String, // Array of material URLs or references
  }],
  lessonType: {
    type: String,
    enum: ['video', 'Video', 'notes', 'Notes', 'quiz', 'Quiz', 'mixed', 'Mixed', 'Video + Notes', 'Video + Quiz', 'Notes + Quiz', 'Content'],
    default: 'Content'
  },
  isPublished: {
    type: Boolean,
    default: true
  },
  // Structured study content produced by the AI Course Builder (summary,
  // objectives, key terms, examples, formulas, flashcards, visuals, sources).
  // `notes` still carries a markdown rendering for older app versions.
  aiContent: {
    type: mongoose.Schema.Types.Mixed,
    default: null
  },
  aiGenerated: {
    type: Boolean,
    default: false
  },
  buildItemId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'CourseBuildItem',
    default: null
  }
}, {
  timestamps: true
});

// Indexes for better performance
lessonSchema.index({ sectionId: 1, order: 1 });
lessonSchema.index({ courseId: 1 });
lessonSchema.index({ quizId: 1 }); // New index for quiz association
lessonSchema.index({ lessonType: 1 }); // New index for lesson type filtering
lessonSchema.index({ isPublished: 1 }); // New index for published status

module.exports = mongoose.model('Lesson', lessonSchema);