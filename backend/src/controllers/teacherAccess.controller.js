const mongoose = require('mongoose');
const User = require('../models/User');
const Course = require('../models/Course');
const Payment = require('../models/Payment');
const TeacherAssignment = require('../models/TeacherAssignment');
const CourseBuildJob = require('../models/CourseBuildJob');
const CourseBuildItem = require('../models/CourseBuildItem');
const { sendSuccess, sendError, sendNotFound, sendForbidden } = require('../utils/response.utils');
const access = require('../services/teacherAccess.service');

/**
 * Self-registered teacher journey:
 *   profile → admin approval → choose a course's teacher's guide → admin
 *   approves the request (paid like a course) → tools + guide unlocked.
 */

const str = (v, max) => (typeof v === 'string' ? v.trim().slice(0, max) : '');
const list = (v, maxItems, maxLen) => (Array.isArray(v) ? [...new Set(v.map(x => str(x, maxLen)).filter(Boolean))].slice(0, maxItems) : []);

function isTeacher(req) {
  return req.user?.role === 'instructor';
}

/** Best-effort in-app + push + email notice; never fails the request. */
async function notify(userIds, title, message, data = {}, { email = null } = {}) {
  try {
    const Notification = require('../models/Notification');
    const nc = require('./notification.controller');
    for (const userId of userIds) {
      await Notification.createNotification({ userId, title, message, type: 'info', data });
      try { await nc.sendPushNotification(userId, title, message, data, true); } catch (_) { /* push optional */ }
    }
  } catch (e) {
    console.warn('[teacher-access] notification failed:', e.message);
  }
  if (email?.to?.length) {
    try {
      const emailService = require('../services/email.service');
      await emailService.sgMail.send({
        to: email.to,
        from: { email: emailService.fromEmail, name: emailService.fromName },
        subject: title,
        html: `<p>${message}</p>${email.extraHtml || ''}`,
      });
    } catch (e) {
      console.warn('[teacher-access] email failed:', e.message);
    }
  }
}

async function adminIdsAndEmails() {
  const admins = await User.find({ role: 'admin', isActive: { $ne: false } }).select('_id email').lean();
  return { ids: admins.map(a => a._id), emails: admins.map(a => a.email).filter(Boolean) };
}

function profileView(user) {
  const p = user.teacherProfile || {};
  return {
    school: p.school || '',
    schoolType: p.schoolType || '',
    district: p.district || '',
    province: p.province || '',
    country: p.country || 'Rwanda',
    levels: p.levels || [],
    subjects: p.subjects || [],
    yearsExperience: p.yearsExperience ?? null,
    qualification: p.qualification || '',
    phone: p.phone || user.phone || '',
    bio: p.bio || '',
    submittedAt: p.submittedAt || null,
  };
}

// ─── Teacher: status & profile ───────────────────────────────────────────────

const getStatus = async (req, res) => {
  try {
    if (!isTeacher(req)) return sendForbidden(res, 'Teachers only');
    const user = await User.findById(req.user._id).lean();
    const summary = await access.accessFor(user);
    const pendingRequests = await Payment.countDocuments({
      userId: user._id, purpose: 'teacher_guide', status: { $in: ['pending', 'admin_review'] },
    });
    sendSuccess(res, {
      ...summary,
      pendingRequests,
      profile: profileView(user),
      levelGroups: access.LEVEL_GROUPS,
    });
  } catch (err) {
    sendError(res, 'Failed to load teacher status', 500, err.message);
  }
};

const submitProfile = async (req, res) => {
  try {
    if (!isTeacher(req)) return sendForbidden(res, 'Teachers only');
    const b = req.body || {};
    const profile = {
      school: str(b.school, 200),
      schoolType: str(b.schoolType, 60),
      district: str(b.district, 100),
      province: str(b.province, 100),
      country: str(b.country, 100) || 'Rwanda',
      levels: list(b.levels, 30, 40),
      subjects: list(b.subjects, 30, 80),
      yearsExperience: Number.isFinite(Number(b.yearsExperience)) ? Math.max(0, Math.min(60, Math.round(Number(b.yearsExperience)))) : null,
      qualification: str(b.qualification, 200),
      phone: str(b.phone, 30),
      bio: str(b.bio, 1000),
      submittedAt: new Date(),
    };
    const missing = [];
    if (!profile.school) missing.push('school');
    if (!profile.district) missing.push('district');
    if (!profile.levels.length) missing.push('classes / levels');
    if (!profile.subjects.length) missing.push('subjects');
    if (!profile.phone) missing.push('phone');
    if (missing.length) return sendError(res, `Please fill in: ${missing.join(', ')}`, 400);

    const user = await User.findById(req.user._id);
    user.teacherProfile = profile;
    // Admin-created teachers just update their profile. Self-registered teachers
    // go (back) to review unless already approved.
    const wasStatus = user.teacherStatus;
    if (wasStatus === 'profile_incomplete' || wasStatus === 'rejected') {
      user.teacherStatus = 'pending';
    }
    await user.save();

    if (user.teacherStatus === 'pending' && wasStatus !== 'pending') {
      const admins = await adminIdsAndEmails();
      await notify(admins.ids, 'New teacher application',
        `${user.fullName} (${profile.school}, ${profile.levels.join(', ')}) is waiting for approval.`,
        { type: 'teacher_application', teacherId: String(user._id) },
        { email: { to: admins.emails } });
    }
    const summary = await access.accessFor(user);
    sendSuccess(res, { ...summary, profile: profileView(user) }, user.teacherStatus === 'pending' ? 'Profile submitted for approval' : 'Profile saved');
  } catch (err) {
    sendError(res, 'Failed to save profile', 500, err.message);
  }
};

// ─── Teacher: guide catalog & requests ───────────────────────────────────────

async function guideStats(courses) {
  const jobIds = courses.map(c => c.teacherGuide?.buildJobId).filter(Boolean);
  if (!jobIds.length) return new Map();
  const rows = await CourseBuildItem.aggregate([
    { $match: { jobId: { $in: jobIds }, status: 'published', kind: 'lesson' } },
    { $group: { _id: '$jobId', lessons: { $sum: 1 }, videos: { $sum: { $cond: [{ $ifNull: ['$video.s3Key', false] }, 1, 0] } }, chapters: { $addToSet: '$chapterIndex' } } },
  ]);
  return new Map(rows.map(r => [String(r._id), { lessons: r.lessons, videos: r.videos, chapters: r.chapters.length }]));
}

const listGuides = async (req, res) => {
  try {
    if (!isTeacher(req)) return sendForbidden(res, 'Teachers only');
    const user = await User.findById(req.user._id).lean();
    if (access.isSelfRegisteredTeacher(user) && user.teacherStatus !== 'approved') {
      return res.status(403).json({ success: false, ...(await access.blockReason(user)) });
    }
    const filter = { 'teacherGuide.enabled': true };
    const search = str(req.query.search, 80);
    if (search) {
      const rx = new RegExp(search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
      filter.$or = [{ title: rx }, { 'teacherGuide.subject': rx }, { 'teacherGuide.classLevels': rx }];
    }
    const courses = await Course.find(filter)
      .select('title description thumbnail level category teacherGuide')
      .populate('category', 'name')
      .sort({ title: 1 })
      .limit(300)
      .lean();
    const [stats, assignments, requests] = await Promise.all([
      guideStats(courses),
      TeacherAssignment.find({ teacherId: user._id, isActive: true }).select('courseId').lean(),
      Payment.find({ userId: user._id, purpose: 'teacher_guide' }).sort({ createdAt: -1 }).select('courseId status amount paymentMethod transactionId createdAt adminApproval.adminNotes').lean(),
    ]);
    const owned = new Set(assignments.map(a => String(a.courseId)));
    const latestRequest = new Map();
    for (const r of requests) if (!latestRequest.has(String(r.courseId))) latestRequest.set(String(r.courseId), r);
    const myLevels = user.teacherProfile?.levels || [];

    const guides = courses.map((c) => {
      const g = c.teacherGuide || {};
      const r = latestRequest.get(String(c._id));
      return {
        courseId: c._id,
        title: c.title,
        description: g.description || c.description || '',
        thumbnail: c.thumbnail,
        category: c.category?.name || null,
        subject: g.subject || '',
        classLevels: g.classLevels || [],
        price: g.price || 0,
        currency: 'RWF',
        ready: !!g.publishedAt,
        stats: stats.get(String(g.buildJobId)) || { lessons: 0, videos: 0, chapters: 0 },
        recommended: access.levelsMatch(myLevels, g.classLevels || []),
        hasAccess: owned.has(String(c._id)),
        request: r ? { id: r._id, status: r.status, amount: r.amount, paymentMethod: r.paymentMethod, transactionId: r.transactionId, createdAt: r.createdAt, adminNotes: r.adminApproval?.adminNotes || '' } : null,
      };
    });
    guides.sort((a, b) => (b.recommended - a.recommended) || a.title.localeCompare(b.title));
    sendSuccess(res, { guides, myLevels });
  } catch (err) {
    sendError(res, 'Failed to load teacher guides', 500, err.message);
  }
};

const requestGuide = async (req, res) => {
  try {
    if (!isTeacher(req)) return sendForbidden(res, 'Teachers only');
    const user = await User.findById(req.user._id).lean();
    if (access.isSelfRegisteredTeacher(user) && user.teacherStatus !== 'approved') {
      return res.status(403).json({ success: false, ...(await access.blockReason(user)) });
    }
    const { courseId } = req.params;
    if (!mongoose.isValidObjectId(courseId)) return sendNotFound(res, 'Course not found');
    const course = await Course.findById(courseId).select('title teacherGuide').lean();
    if (!course || !course.teacherGuide?.enabled) return sendNotFound(res, 'This teacher\'s guide is not available');

    if (await TeacherAssignment.exists({ teacherId: user._id, courseId, isActive: true })) {
      return sendError(res, 'You already have this course', 400);
    }
    if (await Payment.exists({ userId: user._id, courseId, purpose: 'teacher_guide', status: { $in: ['pending', 'admin_review'] } })) {
      return sendError(res, 'Your request for this course is already waiting for approval', 400);
    }

    const price = course.teacherGuide.price || 0;
    const paymentMethod = price > 0 ? str(req.body?.paymentMethod, 30) : 'free';
    if (price > 0 && !['mtn_momo', 'airtel_money'].includes(paymentMethod)) {
      return sendError(res, 'Choose MTN MoMo or Airtel Money', 400);
    }
    const contactInfo = str(req.body?.contactInfo, 120) || user.teacherProfile?.phone || user.phone || user.email;
    if (!contactInfo) return sendError(res, 'A phone number or email is required', 400);

    const payment = await Payment.create({
      userId: user._id,
      courseId,
      amount: price,
      currency: 'RWF',
      paymentMethod,
      purpose: 'teacher_guide',
      transactionId: `TG${Date.now()}${Math.random().toString(36).slice(2, 8).toUpperCase()}`,
      contactInfo,
      status: 'pending',
    });

    const admins = await adminIdsAndEmails();
    await notify(admins.ids, 'Teacher guide request',
      `${user.fullName} requested the teacher's guide for "${course.title}"${price > 0 ? ` (RWF ${price.toLocaleString()})` : ' (free)'}. Approve it in Payments.`,
      { type: 'teacher_guide_request', paymentId: String(payment._id), courseId: String(courseId) },
      { email: { to: admins.emails } });

    sendSuccess(res, {
      paymentId: payment._id,
      transactionId: payment.transactionId,
      amount: payment.amount,
      currency: payment.currency,
      status: payment.status,
      adminContact: 'info@excellencecoachinghub.com · +250 788 535 156 / +250 793 828 834',
      instructions: price > 0
        ? 'Pay with mobile money, then send the transaction ID to the admin. Your course unlocks as soon as the payment is approved.'
        : 'Your request was sent. Your course unlocks as soon as an admin approves it.',
    }, 'Request sent', 201);
  } catch (err) {
    sendError(res, 'Failed to request the teacher\'s guide', 500, err.message);
  }
};

const cancelRequest = async (req, res) => {
  try {
    const { paymentId } = req.params;
    if (!mongoose.isValidObjectId(paymentId)) return sendNotFound(res, 'Request not found');
    const payment = await Payment.findOne({ _id: paymentId, userId: req.user._id, purpose: 'teacher_guide' });
    if (!payment) return sendNotFound(res, 'Request not found');
    if (!['pending', 'admin_review'].includes(payment.status)) return sendError(res, 'Only waiting requests can be cancelled', 400);
    payment.status = 'cancelled';
    await payment.save();
    sendSuccess(res, { id: payment._id, status: payment.status }, 'Request cancelled');
  } catch (err) {
    sendError(res, 'Failed to cancel request', 500, err.message);
  }
};

// ─── Teacher's guide reader ──────────────────────────────────────────────────

async function canReadGuide(user, courseId) {
  if (user.role === 'admin') return true;
  if (user.role !== 'instructor') return false;
  return !!(await TeacherAssignment.exists({ teacherId: user._id, courseId, isActive: true }));
}

async function signedUrl(key, fallback) {
  if (!key) return fallback || null;
  try {
    return await require('../services/s3.service').generateSignedUrl(key, 3 * 3600);
  } catch (_) {
    return fallback || null;
  }
}

const { isVideoWatchable: playableVideo } = require('../models/schemas/aiVideo.schema');

const getGuide = async (req, res) => {
  try {
    const { courseId } = req.params;
    if (!mongoose.isValidObjectId(courseId)) return sendNotFound(res, 'Course not found');
    if (!(await canReadGuide(req.user, courseId))) return sendForbidden(res, 'Request this course\'s teacher\'s guide first');
    const course = await Course.findById(courseId).select('title description thumbnail teacherGuide').lean();
    if (!course) return sendNotFound(res, 'Course not found');
    const jobId = course.teacherGuide?.buildJobId;
    if (!jobId || !course.teacherGuide?.publishedAt) {
      return sendSuccess(res, { course: { id: course._id, title: course.title, thumbnail: course.thumbnail }, ready: false, chapters: [] });
    }
    const [job, items] = await Promise.all([
      CourseBuildJob.findById(jobId).select('outline').lean(),
      CourseBuildItem.find({ jobId, kind: 'lesson', status: 'published' })
        .select('chapterIndex order title content.summary content.estimatedMinutes video.status video.s3Key video.url video.reviewStatus')
        .sort({ chapterIndex: 1, order: 1 })
        .lean(),
    ]);
    const chapters = (job?.outline?.chapters || [])
      .map(ch => ({
        index: ch.index,
        title: ch.title,
        summary: ch.summary || '',
        lessons: items.filter(i => i.chapterIndex === ch.index).map(i => ({
          id: i._id,
          title: i.title,
          summary: i.content?.summary || '',
          minutes: i.content?.estimatedMinutes || null,
          hasVideo: playableVideo(i.video),
        })),
      }))
      .filter(ch => ch.lessons.length);
    sendSuccess(res, {
      course: { id: course._id, title: course.title, description: course.teacherGuide?.description || course.description, thumbnail: course.thumbnail, classLevels: course.teacherGuide?.classLevels || [], subject: course.teacherGuide?.subject || '' },
      ready: true,
      chapters,
    });
  } catch (err) {
    sendError(res, 'Failed to load the teacher\'s guide', 500, err.message);
  }
};

const getGuideLesson = async (req, res) => {
  try {
    const { courseId, itemId } = req.params;
    if (!mongoose.isValidObjectId(courseId) || !mongoose.isValidObjectId(itemId)) return sendNotFound(res, 'Lesson not found');
    if (!(await canReadGuide(req.user, courseId))) return sendForbidden(res, 'Request this course\'s teacher\'s guide first');
    const course = await Course.findById(courseId).select('teacherGuide').lean();
    const jobId = course?.teacherGuide?.buildJobId;
    const item = jobId ? await CourseBuildItem.findOne({ _id: itemId, jobId, status: 'published' }).lean() : null;
    if (!item) return sendNotFound(res, 'Lesson not found');
    const v = item.video;
    const video = playableVideo(v)
      ? {
          url: await signedUrl(v.s3Key, v.url),
          captionsUrl: v.captionsKey ? await signedUrl(v.captionsKey, v.captionsUrl) : (v.captionsUrl || null),
          durationSeconds: v.durationSeconds || null,
        }
      : null;
    sendSuccess(res, {
      id: item._id,
      title: item.title,
      chapterIndex: item.chapterIndex,
      content: item.content || {},
      video,
      videoStatus: v?.status || null,
    });
  } catch (err) {
    sendError(res, 'Failed to load the lesson guide', 500, err.message);
  }
};

module.exports = {
  getStatus,
  submitProfile,
  listGuides,
  requestGuide,
  cancelRequest,
  getGuide,
  getGuideLesson,
  notify,
  profileView,
};
