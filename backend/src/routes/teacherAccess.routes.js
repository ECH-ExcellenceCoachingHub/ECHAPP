const express = require('express');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');
const t = require('../controllers/teacherAccess.controller');
const a = require('../controllers/teacherAdmin.controller');

/**
 * /api/teacher-access   — the self-registered teacher journey (works before approval,
 *                         so it deliberately does not use authorize('instructor')).
 * /api/teacher-guides   — reading a course's teacher's guide (cleared teachers + admins).
 * /api/admin/teacher-*  — approving teachers and configuring guides.
 */
const access = express.Router();
access.use(protect);
access.get('/status', t.getStatus);
access.put('/profile', t.submitProfile);
access.get('/guides', t.listGuides);
access.post('/guides/:courseId/request', t.requestGuide);
access.delete('/requests/:paymentId', t.cancelRequest);

const guides = express.Router();
guides.use(protect, authorize('admin', 'instructor'));
guides.get('/:courseId', t.getGuide);
guides.get('/:courseId/lessons/:itemId', t.getGuideLesson);

const admin = express.Router();
admin.use(protect, authorize('admin'));
admin.get('/teacher-applications', a.listApplications);
admin.post('/teacher-applications/:id/review', a.reviewApplication);
admin.get('/teacher-guides', a.listGuides);
admin.put('/teacher-guides/:courseId', a.updateGuide);

module.exports = { access, guides, admin };
