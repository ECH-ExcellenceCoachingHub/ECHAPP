const mongoose = require('mongoose');

const teacherAssignmentSchema = new mongoose.Schema({
  teacherId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Teacher ID is required']
  },
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: [true, 'Course ID is required']
  },
  assignedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Assigner ID is required']
  },
  assignedAt: {
    type: Date,
    default: Date.now
  },
  isActive: {
    type: Boolean,
    default: true
  },
  // 'admin' = assigned by an admin; 'guide_purchase' = approved teacher's-guide request
  source: {
    type: String,
    enum: ['admin', 'guide_purchase'],
    default: 'admin'
  },
  paymentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Payment',
    default: null
  },
  notes: {
    type: String,
    maxlength: [500, 'Notes cannot exceed 500 characters']
  }
}, {
  timestamps: true
});

// Ensure a teacher can only be assigned once to a course
teacherAssignmentSchema.index({ teacherId: 1, courseId: 1 }, { unique: true });
teacherAssignmentSchema.index({ teacherId: 1, isActive: 1 });
teacherAssignmentSchema.index({ courseId: 1, isActive: 1 });

module.exports = mongoose.model('TeacherAssignment', teacherAssignmentSchema);
