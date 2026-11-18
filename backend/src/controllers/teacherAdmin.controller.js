const mongoose = require('mongoose');
const User = require('../models/User');
const Course = require('../models/Course');
const Payment = require('../models/Payment');
const TeacherAssignment = require('../models/TeacherAssignment');
const CourseBuildJob = require('../models/CourseBuildJob');
const CourseBuildItem = require('../models/CourseBuildItem');
const { sendSuccess, sendError, sendNotFound } = require('../utils/response.utils');
const { notify, profileView } = require('./teacherAccess.controller');
const { LEVEL_GROUPS } = require('../services/teacherAccess.service');

// ─── Teacher applications ────────────────────────────────────────────────────

/** GET /api/admin/teacher-applications?status=pending|approved|rejected|profile_incomplete|all */
const listApplications = async (req, res) => {
  try {
    const status = String(req.query.status || 'pending');
    const filter = { role: 'instructor', teacherStatus: { $ne: null } };
    if (status !== 'all') filter.teacherStatus = status;
    const search = String(req.query.search || '').trim().slice(0, 80);
    if (search) {
      const rx = new RegExp(search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
      filter.$or = [{ fullName: rx }, { email: rx }, { phone: rx }, { 'teacherProfile.school': rx }, { 'teacherProfile.district': rx }];
    }
    const users = await User.find(filter)
      .select('fullName email phone avatar createdAt teacherStatus teacherProfile teacherReview')
      .populate('teacherReview.reviewedBy', 'fullName')
      .sort({ 'teacherProfile.submittedAt': -1, createdAt: -1 })
      .limit(200)
      .lean();
    const ids = users.map(u => u._id);
    const [courseCounts, requestCounts, counts] = await Promise.all([
      TeacherAssignment.aggregate([{ $match: { teacherId: { $in: ids }, isActive: true } }, { $group: { _id: '$teacherId', n: { $sum: 1 } } }]),
      Payment.aggregate([{ $match: { userId: { $in: ids }, purpose: 'teacher_guide', status: { $in: ['pending', 'admin_review'] } } }, { $group: { _id: '$userId', n: { $sum: 1 } } }]),
      User.aggregate([{ $match: { role: 'instructor', teacherStatus: { $ne: null } } }, { $group: { _id: '$teacherStatus', n: { $sum: 1 } } }]),
    ]);
    const cc = new Map(courseCounts.map(r => [String(r._id), r.n]));
    const rc = new Map(requestCounts.map(r => [String(r._id), r.n]));
    sendSuccess(res, {
      counts: Object.fromEntries(counts.map(c => [c._id, c.n])),
      applications: users.map(u => ({
        id: u._id,
        fullName: u.fullName,
        email: u.email || '',
        phone: u.phone || '',
        avatar: u.avatar || null,
        createdAt: u.createdAt,
        status: u.teacherStatus,
        profile: profileView(u),
        review: u.teacherReview?.reviewedAt ? {
          reviewedAt: u.teacherReview.reviewedAt,
          reviewedBy: u.teacherReview.reviewedBy?.fullName || null,
          reason: u.teacherReview.reason || '',
        } : null,
        courseCount: cc.get(String(u._id)) || 0,
        pendingRequests: rc.get(String(u._id)) || 0,
      })),
    });
  } catch (err) {
    sendError(res, 'Failed to load teacher applications', 500, err.message);
  }
};

/** POST /api/admin/teacher-applications/:id/review { decision: 'approve'|'reject', reason } */
const reviewApplication = async (req, res) => {
  try {
    const { id } = req.params;
    const decision = String(req.body?.decision || '');
    const reason = String(req.body?.reason || '').trim().slice(0, 1000);
    if (!['approve', 'reject'].includes(decision)) return sendError(res, 'decision must be approve or reject', 400);
    if (decision === 'reject' && !reason) return sendError(res, 'Please give the teacher a reason', 400);
    if (!mongoose.isValidObjectId(id)) return sendNotFound(res, 'Teacher not found');
    const user = await User.findOne({ _id: id, role: 'instructor', teacherStatus: { $ne: null } });
    if (!user) return sendNotFound(res, 'Teacher application not found');
    if (user.teacherStatus === 'profile_incomplete') return sendError(res, 'This teacher has not submitted a profile yet', 400);

    user.teacherStatus = decision === 'approve' ? 'approved' : 'rejected';
    user.teacherReview = { reviewedBy: req.user._id, reviewedAt: new Date(), reason };
    await user.save();

    const approved = decision === 'approve';
    await notify([user._id],
      approved ? 'Your teacher account is approved' : 'Your teacher application needs changes',
      approved
        ? 'Welcome to ECH! Open the app and choose the course(s) you teach to unlock your teacher\'s guides and tools.'
        : `Your application was not approved: ${reason}. Please update your profile and submit it again.`,
      { type: 'teacher_review', status: user.teacherStatus },
      { email: { to: user.email ? [user.email] : [] } });

    sendSuccess(res, { id: user._id, status: user.teacherStatus }, approved ? 'Teacher approved' : 'Teacher rejected');
  } catch (err) {
    sendError(res, 'Failed to review teacher', 500, err.message);
  }
};

// ─── Teacher's guides per course ─────────────────────────────────────────────

/** GET /api/admin/teacher-guides — every course with its guide settings and build state. */
const listGuides = async (req, res) => {
  try {
    const courses = await Course.find({})
      .select('title thumbnail isPublished price teacherGuide category')
      .populate('category', 'name')
      .sort({ title: 1 })
      .lean();
    const ids = courses.map(c => c._id);
    const [jobs, teacherCounts, requestCounts] = await Promise.all([
      CourseBuildJob.find({ courseId: { $in: ids }, purpose: 'teacher_guide' })
        .select('courseId status progress.percent progress.message stats source.fileName createdAt')
        .sort({ createdAt: -1 })
        .lean(),
      TeacherAssignment.aggregate([{ $match: { courseId: { $in: ids }, isActive: true, source: 'guide_purchase' } }, { $group: { _id: '$courseId', n: { $sum: 1 } } }]),
      Payment.aggregate([{ $match: { courseId: { $in: ids }, purpose: 'teacher_guide', status: { $in: ['pending', 'admin_review'] } } }, { $group: { _id: '$courseId', n: { $sum: 1 } } }]),
    ]);
    const latestJob = new Map();
    for (const j of jobs) if (!latestJob.has(String(j.courseId))) latestJob.set(String(j.courseId), j);
    const tc = new Map(teacherCounts.map(r => [String(r._id), r.n]));
    const rc = new Map(requestCounts.map(r => [String(r._id), r.n]));
    const publishedCounts = new Map();
    const guideJobIds = courses.map(c => c.teacherGuide?.buildJobId).filter(Boolean);
    if (guideJobIds.length) {
      const rows = await CourseBuildItem.aggregate([
        { $match: { jobId: { $in: guideJobIds }, kind: 'lesson', status: 'published' } },
        { $group: { _id: '$jobId', n: { $sum: 1 } } },
      ]);
      rows.forEach(r => publishedCounts.set(String(r._id), r.n));
    }

    sendSuccess(res, {
      levelGroups: LEVEL_GROUPS,
      courses: courses.map((c) => {
        const g = c.teacherGuide || {};
        const job = latestJob.get(String(c._id));
        return {
          courseId: c._id,
          title: c.title,
          thumbnail: c.thumbnail,
          category: c.category?.name || null,
          isPublished: !!c.isPublished,
          guide: {
            enabled: !!g.enabled,
            price: g.price || 0,
            classLevels: g.classLevels || [],
            subject: g.subject || '',
            description: g.description || '',
            buildJobId: g.buildJobId || null,
            publishedAt: g.publishedAt || null,
            publishedLessons: g.buildJobId ? (publishedCounts.get(String(g.buildJobId)) || 0) : 0,
          },
          latestBuild: job ? {
            id: job._id, status: job.status, percent: job.progress?.percent || 0, message: job.progress?.message || '',
            fileName: job.source?.fileName || '', lessons: job.stats?.lessons || 0, createdAt: job.createdAt,
          } : null,
          teachers: tc.get(String(c._id)) || 0,
          pendingRequests: rc.get(String(c._id)) || 0,
        };
      }),
    });
  } catch (err) {
    sendError(res, 'Failed to load teacher guides', 500, err.message);
  }
};

/** PUT /api/admin/teacher-guides/:courseId { enabled, price, classLevels, subject, description } */
const updateGuide = async (req, res) => {
  try {
    const { courseId } = req.params;
    if (!mongoose.isValidObjectId(courseId)) return sendNotFound(res, 'Course not found');
    const b = req.body || {};
    const set = {};
    if (b.enabled != null) set['teacherGuide.enabled'] = b.enabled === true || b.enabled === 'true';
    if (b.price != null) {
      const p = Number(b.price);
      if (!Number.isFinite(p) || p < 0) return sendError(res, 'Price must be 0 or more', 400);
      set['teacherGuide.price'] = Math.round(p);
    }
    if (Array.isArray(b.classLevels)) {
      set['teacherGuide.classLevels'] = [...new Set(b.classLevels.map(x => String(x).trim()).filter(Boolean))].slice(0, 30);
    }
    if (typeof b.subject === 'string') set['teacherGuide.subject'] = b.subject.trim().slice(0, 80);
    if (typeof b.description === 'string') set['teacherGuide.description'] = b.description.trim().slice(0, 2000);
    const course = await Course.findByIdAndUpdate(courseId, { $set: set }, { new: true }).select('title teacherGuide').lean();
    if (!course) return sendNotFound(res, 'Course not found');
    sendSuccess(res, { courseId: course._id, guide: course.teacherGuide }, 'Teacher guide settings saved');
  } catch (err) {
    sendError(res, 'Failed to save teacher guide settings', 500, err.message);
  }
};

module.exports = { listApplications, reviewApplication, listGuides, updateGuide };
