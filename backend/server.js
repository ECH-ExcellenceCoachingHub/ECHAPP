const express = require('express');
const dotenv = require('dotenv');

// Load environment variables as early as possible
dotenv.config();

const cors = require('cors');
const helmet = require('helmet');
const path = require('path');
const connectDB = require('./src/config/database');

// Initialize Firebase Admin SDK
require('./src/config/firebase');

console.log('🚀 Excellence Coaching Hub Backend Server Starting...');

const app = express();

// Basic health check endpoint for Render
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'success', 
    message: 'Server is running',
    timestamp: new Date().toISOString()
  });
});

// Configure CORS to allow all origins (for development)
const corsOptions = {
  origin: '*', // Allow all origins - suitable for development
  credentials: true,
  optionsSuccessStatus: 200
};

// Middleware
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" }
}));
app.use(cors(corsOptions));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Express 5 leaves `req.body` undefined when a request carries no body, where
// Express 4 gave you `{}`. Any handler reading `req.body.something` on a GET
// then throws a TypeError and 500s — which is how the public course chat broke:
// its GET fell through to `req.body.groupId`. Normalising here fixes the whole
// class of bug rather than one call site at a time.
app.use((req, res, next) => {
  if (req.body === undefined) req.body = {};
  next();
});

// Serve static files from uploads directory
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes
app.get('/', (req, res) => {
  res.json({ message: 'ExcellenceCoachingHub API is running' });
});

const authRoutes = require('./src/routes/auth.routes');
const courseRoutes = require('./src/routes/course.routes');
const categoryRoutes = require('./src/routes/category.routes');
const enrollmentRoutes = require('./src/routes/enrollment.routes');
const quizRoutes = require('./src/routes/quiz.routes');
const paymentRoutes = require('./src/routes/payment.routes');
const adminRoutes = require('./src/routes/admin.routes');
const videoRoutes = require('./src/routes/video.routes');
const sectionRoutes = require('./src/routes/section.routes');
const lessonRoutes = require('./src/routes/lesson.routes');
const uploadRoutes = require('./src/routes/upload.routes');
const documentRoutes = require('./src/routes/document.routes');
const notificationRoutes = require('./src/routes/notification.routes');
const platformSettingsRoutes = require('./src/routes/platformSettings.routes');
const feedbackRoutes = require('./src/routes/feedback.routes');
const aiChatRoutes = require('./routes/ai_chat'); // AI Chat routes
const voiceChatRoutes = require('./routes/voice_chat'); // Voice Chat routes
const bookRoutes = require('./src/routes/book.routes'); // Book routes
const teacherRoutes = require('./src/routes/teacher.routes'); // Teacher routes
const liveSessionRoutes = require('./src/routes/liveSession.routes'); // Live Session routes
const bbbAdminRoutes = require('./src/routes/admin/bbb.routes'); // BBB Admin routes
const backupRoutes = require('./src/routes/backup.routes'); // Database backup routes
const videoCleanupRoutes = require('./src/routes/videoCleanup.routes'); // Orphaned S3 video cleanup routes (read-only, see S3_VIDEO_CLEANUP.md)
const mediaRoutes = require('./src/routes/media.routes'); // Media proxy for CORS-safe image/video serving on web
const communityRoutes = require('./src/routes/community.routes'); // Course Community (students, groups, discussions, assignments)
const messagingRoutes = require('./src/routes/messaging.routes'); // One-to-one messaging between students, teachers and admins
const courseBuilderRoutes = require('./src/routes/courseBuilder.routes'); // AI Course Builder (book → course draft → review → publish)

app.use('/api/auth', authRoutes);
app.use('/api/courses', courseRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/enrollments', enrollmentRoutes);
app.use('/api/quizzes', quizRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/admin/bbb', bbbAdminRoutes);
app.use('/api/admin/backups', backupRoutes);
app.use('/api/admin/video-cleanup', videoCleanupRoutes);
app.use('/api/media', mediaRoutes); // Media proxy for CORS-safe image/video serving on web
app.use('/api/videos', videoRoutes);
app.use('/api/sections', sectionRoutes);
app.use('/api/lessons', lessonRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/documents', documentRoutes);
app.use('/api/exam-processing', documentRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/platform-settings', platformSettingsRoutes);
app.use('/api/feedback', feedbackRoutes);
app.use('/api/ai', aiChatRoutes); // AI Chat routes
app.use('/api/voice', voiceChatRoutes); // Voice Chat routes
app.use('/api/books', bookRoutes); // Book routes
app.use('/api/teacher', teacherRoutes); // Teacher routes
app.use('/api/live', liveSessionRoutes); // Live Session routes
app.use('/api/community', communityRoutes); // Course Community routes
app.use('/api/messages', messagingRoutes); // Direct messaging routes
app.use('/api/course-builder', courseBuilderRoutes); // AI Course Builder routes

// Handle undefined routes
app.use((req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    success: false, 
    message: 'Something went wrong!' 
  });
});

const PORT = process.env.PORT || 5000;

// Start server and connect to database asynchronously
const server = app.listen(PORT, '0.0.0.0', async () => {
  console.log(`Server running on port ${PORT}`);
  try {
    await connectDB();
    console.log('✅ Database connected successfully');
    
    // Initialize Course Expiration Service AFTER database connection
    const CourseExpirationService = require('./src/services/course-expiration.service');
    const NotificationSchedulerService = require('./src/services/notification-scheduler.service');

    // Schedule course expiration checks (every 60 minutes)
    CourseExpirationService.scheduleExpirationChecks(60);
    console.log('🔄 Course expiration checks scheduled (every 60 minutes)');

    // Schedule notification checks (daily at 9am server time)
    NotificationSchedulerService.schedule(9);
    console.log('📧 Notification checks scheduled (daily at 9am)');

    // Study session reminders, auto-completion and BBB recording collection
    const CommunitySessionScheduler = require('./src/services/community-session-scheduler.service');
    CommunitySessionScheduler.schedule(5);

    // Schedule database backups (daily at 2am server time, low-traffic hour)
    const BackupService = require('./src/services/backup.service');
    BackupService.schedule(parseInt(process.env.BACKUP_HOUR || '2', 10));

    // Continue AI course builds interrupted by a restart/deploy
    require('./src/services/course-builder/runner.service').resumeInterrupted()
      .catch(err => console.error('⚠️  Course builder resume failed:', err.message));

    // Initialize BBB config from environment variables (if not already in database)
    const BBBConfig = require('./src/models/BBBConfig');
    try {
      const bbbConfig = await BBBConfig.initializeFromEnv();
      if (bbbConfig) {
        console.log('✅ BBB configuration initialized');
      } else {
        console.log('⚠️  No BBB configuration found. Set BBB_SERVER_URL and BBB_SHARED_SECRET in .env');
      }
    } catch (bbbError) {
      console.error('⚠️  BBB config initialization failed:', bbbError.message);
    }
    
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    process.exit(1);
  }
});

// Handle server errors
server.on('error', (error) => {
  console.error('Server error:', error);
  process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});
