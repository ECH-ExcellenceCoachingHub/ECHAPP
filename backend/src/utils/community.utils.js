const Enrollment = require('../models/Enrollment');
const TeacherAssignment = require('../models/TeacherAssignment');
const CoursePresence = require('../models/community/CoursePresence');

/** Fields safe to expose about another community member. */
const PUBLIC_USER_FIELDS = 'fullName avatar role interests lastActive';

/** Everyone enrolled in a course (student user ids). */
const getStudentIds = async (courseId) => {
  const enrollments = await Enrollment.find({ courseId }).select('userId').lean();
  return enrollments.map((e) => String(e.userId));
};

/** Teachers actively assigned to a course. */
const getTeacherIds = async (courseId) => {
  const assignments = await TeacherAssignment.find({ courseId, isActive: true, source: { $ne: 'guide_purchase' } })
    .select('teacherId')
    .lean();
  return assignments.map((a) => String(a.teacherId));
};

/** Students + teachers — the full notification audience for a course. */
const getCourseMemberIds = async (courseId) => {
  const [students, teachers] = await Promise.all([
    getStudentIds(courseId),
    getTeacherIds(courseId)
  ]);
  return [...new Set([...students, ...teachers])];
};

/**
 * Maps user ids to a coarse presence label. Never returns a precise location —
 * only "active now" / "recently active" / "offline" plus a rounded last-seen.
 */
const getPresenceMap = async (courseId, userIds = []) => {
  const rows = await CoursePresence.find({
    courseId,
    userId: { $in: userIds },
    isVisible: true
  })
    .select('userId lastSeenAt')
    .lean();

  const map = {};
  const now = Date.now();
  const activeWindow = CoursePresence.ACTIVE_WINDOW_MINUTES * 60 * 1000;
  const recentWindow = 60 * 60 * 1000; // an hour

  rows.forEach((row) => {
    const age = now - new Date(row.lastSeenAt).getTime();
    let status = 'offline';
    if (age <= activeWindow) status = 'active';
    else if (age <= recentWindow) status = 'recent';

    map[String(row.userId)] = {
      status,
      lastSeenAt: row.lastSeenAt,
      minutesAgo: Math.max(0, Math.floor(age / 60000))
    };
  });

  return map;
};

/** Shapes a populated user document into the payload the app expects. */
const toPublicMember = (user, presence = null, extra = {}) => {
  if (!user) return null;
  const id = String(user._id || user.id);
  return {
    id,
    fullName: user.fullName || 'ECH Student',
    avatar: user.avatar || null,
    role: user.role || 'student',
    interests: user.interests || [],
    presence: presence || { status: 'offline', lastSeenAt: null, minutesAgo: null },
    ...extra
  };
};

module.exports = {
  PUBLIC_USER_FIELDS,
  getStudentIds,
  getTeacherIds,
  getCourseMemberIds,
  getPresenceMap,
  toPublicMember
};
