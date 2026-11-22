const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  title: {
    type: String,
    required: true,
    trim: true
  },
  message: {
    type: String,
    required: true,
    trim: true
  },
  type: {
    type: String,
    enum: ['info', 'success', 'warning', 'error', 'achievement', 'payment', 'course', 'exam', 'reminder', 'promotion', 'homework', 'school'],
    default: 'info'
  },
  isRead: {
    type: Boolean,
    default: false,
    index: true
  },
  data: {
    type: mongoose.Schema.Types.Mixed,
    // Can store additional data like courseId, examId, etc.
  },
  createdAt: {
    type: Date,
    default: Date.now,
    index: true
  },
  readAt: {
    type: Date
  }
}, {
  timestamps: true
});

// Index for efficient querying
notificationSchema.index({ userId: 1, isRead: 1, createdAt: -1 });
notificationSchema.index({ userId: 1, createdAt: -1 });

// Removed pre-save middleware - handling readAt in static methods directly

// Static method to create notification
notificationSchema.statics.createNotification = async function(notificationData) {
  try {
    const notification = new this(notificationData);
    await notification.save();
    return notification;
  } catch (error) {
    throw new Error(`Failed to create notification: ${error.message}`);
  }
};

// Static method to get user notifications
notificationSchema.statics.getUserNotifications = async function(userId, limit = 50) {
  try {
    return await this.find({ userId })
      .sort({ createdAt: -1 })
      .limit(limit);
  } catch (error) {
    throw new Error(`Failed to fetch notifications: ${error.message}`);
  }
};

// Static method to get unread notifications count
notificationSchema.statics.getUnreadCount = async function(userId) {
  try {
    return await this.countDocuments({ userId, isRead: false });
  } catch (error) {
    throw new Error(`Failed to count unread notifications: ${error.message}`);
  }
};

// Static method to mark notification as read
notificationSchema.statics.markAsRead = async function(notificationId, userId) {
  try {
    const notification = await this.findOne({ _id: notificationId, userId });
    if (!notification) {
      throw new Error('Notification not found');
    }
    
    if (!notification.isRead) {
      notification.isRead = true;
      notification.readAt = new Date();
      await notification.save();
    }
    
    return notification;
  } catch (error) {
    throw new Error(`Failed to mark notification as read: ${error.message}`);
  }
};

// Static method to mark all notifications as read
notificationSchema.statics.markAllAsRead = async function(userId) {
  try {
    const result = await this.updateMany(
      { userId, isRead: false },
      { 
        $set: { 
          isRead: true,
          readAt: new Date()
        }
      }
    );
    return result.modifiedCount;
  } catch (error) {
    throw new Error(`Failed to mark all notifications as read: ${error.message}`);
  }
};

module.exports = mongoose.model('Notification', notificationSchema);