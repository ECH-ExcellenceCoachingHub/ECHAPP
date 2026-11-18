const mongoose = require('mongoose');
const User = require('../models/User');
const Enrollment = require('../models/Enrollment');
const TeacherAssignment = require('../models/TeacherAssignment');

/**
 * Who may message whom.
 *
 * The rule is the platform's real social graph rather than an open directory:
 * you can message people you actually share a course with, the teachers of
 * your courses, and admins (so support is always reachable). Admins and
 * teachers can reach their students.
 *
 * This is deliberately one function so the boundary can be widened in exactly
 * one place. Opening it to *every* account is a product decision with real
 * safety weight on a platform with student accounts — see MESSAGING_POLICY
 * below before changing it.
 */

/** Flip to true to let any signed-in account message any other account. */
const ALLOW_PLATFORM_WIDE_MESSAGING = false;

const PUBLIC_USER_FIELDS = 'fullName avatar role lastActive';

/** Course ids a user is connected to, as a student and as a teacher. */
const getUserCourseIds = async (userId) => {
  const [enrollments, assignments] = await Promise.all([
    Enrollment.find({ userId }).select('courseId').lean(),
    TeacherAssignment.find({ teacherId: userId, isActive: true, source: { $ne: 'guide_purchase' } })
      .select('courseId')
      .lean()
  ]);
  return [
    ...new Set([
      ...enrollments.map((e) => String(e.courseId)),
      ...assignments.map((a) => String(a.courseId))
    ])
  ];
};

/**
 * Decides whether `actor` is allowed to open or continue a conversation with
 * `targetId`. Returns `{ allowed, reason }` so callers can surface a useful
 * message rather than a bare 403.
 */
const canMessage = async (actor, targetId) => {
  if (!targetId || !mongoose.Types.ObjectId.isValid(targetId)) {
    return { allowed: false, reason: 'That person could not be found' };
  }
  if (String(actor._id) === String(targetId)) {
    return { allowed: false, reason: 'You cannot message yourself' };
  }

  const target = await User.findById(targetId).select('role isActive fullName').lean();
  if (!target || target.isActive === false) {
    return { allowed: false, reason: 'That account is not available' };
  }

  if (ALLOW_PLATFORM_WIDE_MESSAGING) return { allowed: true, target };

  // Admins are reachable by everyone, and can reach everyone — they are the
  // support channel of last resort.
  if (actor.role === 'admin' || target.role === 'admin') {
    return { allowed: true, target };
  }

  const [actorCourses, targetCourses] = await Promise.all([
    getUserCourseIds(actor._id),
    getUserCourseIds(targetId)
  ]);

  const shared = actorCourses.filter((id) => targetCourses.includes(id));
  if (shared.length > 0) {
    return { allowed: true, target, sharedCourseIds: shared };
  }

  return {
    allowed: false,
    reason:
      'You can only message people you share a course with. Enrol in a course ' +
      'you have in common, or ask your teacher to connect you.'
  };
};

/**
 * Everyone the user is allowed to start a conversation with — their
 * classmates, the teachers of their courses, and admins.
 */
const listContactableUsers = async (actor, { search = '', limit = 60 } = {}) => {
  const query = { isActive: true, _id: { $ne: actor._id } };

  if (!ALLOW_PLATFORM_WIDE_MESSAGING && actor.role !== 'admin') {
    const courseIds = await getUserCourseIds(actor._id);

    const [classmates, teachers] = await Promise.all([
      Enrollment.find({ courseId: { $in: courseIds } }).select('userId').lean(),
      TeacherAssignment.find({ courseId: { $in: courseIds }, isActive: true, source: { $ne: 'guide_purchase' } })
        .select('teacherId')
        .lean()
    ]);

    const admins = await User.find({ role: 'admin', isActive: true })
      .select('_id')
      .lean();

    const reachable = [
      ...new Set([
        ...classmates.map((c) => String(c.userId)),
        ...teachers.map((t) => String(t.teacherId)),
        ...admins.map((a) => String(a._id))
      ])
    ].filter((id) => id !== String(actor._id));

    query._id = { $in: reachable };
  }

  if (search.trim()) {
    query.fullName = { $regex: search.trim(), $options: 'i' };
  }

  const users = await User.find(query)
    .select(PUBLIC_USER_FIELDS)
    .sort({ fullName: 1 })
    .limit(Math.min(200, limit))
    .lean();

  return users;
};

/** Shapes a user for messaging surfaces — no email, no phone. */
const toContact = (user) => {
  if (!user) return null;
  return {
    id: String(user._id || user.id),
    fullName: user.fullName || 'ECH User',
    avatar: user.avatar || null,
    role: user.role || 'student',
    isTeacher: user.role === 'instructor' || user.role === 'admin',
    lastActive: user.lastActive || null
  };
};

module.exports = {
  ALLOW_PLATFORM_WIDE_MESSAGING,
  PUBLIC_USER_FIELDS,
  getUserCourseIds,
  canMessage,
  listContactableUsers,
  toContact
};
