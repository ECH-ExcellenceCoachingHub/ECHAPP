const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');
const c = require('../controllers/courseBuilder.controller');
const v = require('../controllers/lessonVideo.controller');
const d = require('../controllers/demo.controller');
const { generationLimiter } = require('../middleware/generationLimiter.middleware');

// AI Course Builder — admins and teachers assigned to the course
router.use(protect, authorize('admin', 'instructor'));

// Builds for a course
router.get('/courses/:courseId/jobs', c.listJobs);
router.post('/courses/:courseId/jobs', c.createJob);

// One build
router.get('/jobs/:jobId', c.getJob);
router.put('/jobs/:jobId/outline', c.updateOutline);
router.post('/jobs/:jobId/generate', c.startGeneration);
router.post('/jobs/:jobId/cancel', c.cancelJob);
router.post('/jobs/:jobId/retry-analysis', c.retryAnalysis);
router.post('/jobs/:jobId/approve', c.approveItems);
router.post('/jobs/:jobId/publish', c.publishJob);
router.post('/jobs/:jobId/repair', c.repairJob);
router.get('/jobs/:jobId/question-bank', c.exportQuestionBank);
router.delete('/jobs/:jobId', c.deleteJob);

// Draft items (lessons, chapter tests, revision notes, mock exam)
router.get('/items/:itemId', c.getItem);
router.put('/items/:itemId', c.updateItem);
router.post('/items/:itemId/status', c.setItemStatus);
router.post('/items/:itemId/regenerate', c.regenerateItem);
router.post('/items/:itemId/questions/:questionId/regenerate', c.regenerateQuestion);
router.get('/items/:itemId/source', c.getSourcePages);
router.post('/items/:itemId/images/search', c.searchItemImage);
// See a draft exactly as students will, including taking its quiz (nothing is saved)
router.get('/items/:itemId/preview', c.previewItem);
router.post('/items/:itemId/preview-submit', c.previewSubmit);

// Textbook figures + generated lesson videos
router.get('/jobs/:jobId/media', v.getBuildMedia);
router.get('/jobs/:jobId/figures', v.listFigures);
router.post('/jobs/:jobId/figures/extract', generationLimiter, v.extractFigures);
router.get('/items/:itemId/videos', v.getItemVideos);
router.post('/items/:itemId/videos', generationLimiter, v.requestItemVideo);
router.get('/lessons/:lessonId/videos', v.getLessonVideos);
router.post('/lessons/:lessonId/videos', generationLimiter, v.requestLessonVideo);
router.get('/video-jobs/:videoJobId', v.getVideoJob);
router.post('/video-jobs/:videoJobId/cancel', v.cancelVideoJob);
router.post('/video-jobs/:videoJobId/review', v.reviewVideoJob);

// Real experiment demonstrations (YouTube) for a draft lesson
router.get('/items/:itemId/demo', d.getDemo);
router.post('/items/:itemId/demo/search', generationLimiter, d.searchDemos);
router.post('/items/:itemId/demo/select', generationLimiter, d.selectDemo);
router.put('/items/:itemId/demo/steps', d.saveDemoSteps);
router.delete('/items/:itemId/demo', d.removeDemo);

module.exports = router;
