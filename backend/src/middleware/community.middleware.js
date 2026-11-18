const mongoose = require('mongoose');
const Course = require('../models/Course');
const Enrollment = require('../models/Enrollment');
const TeacherAssignment = require('../models/TeacherAssignment');
const { sendError, sendNotFound, sendForbidden } = require('../utils/response.utils');

/**
 * Resolves who the caller is inside a course community and attaches the
 * result to `req.community`.
 *
 * Membership rules (deliberately mirroring the rest of the platform so the
 * community never becomes a separate permission system):
 *  - admins are members of every course community with teacher powers
 *  - a teacher with an active TeacherAssignment for the course gets teacher powers
 *  - a student with an Enrollment for the course is a member
 *  - everyone else gets 403
 *
 * An expired enrollment keeps read/write access to the community: the peer
 * work a student did there (their groups, discussions, submissions) should not
 * vanish the moment their course access window lapses. `hasExpiredAccess` is
 * exposed so callers can surface it if they need to.
 */
const loadCommunityContext = async (req, res, next) => {
  try {
    const courseId =
      req.params.courseId || (req.body && req.body.courseId) || req.query.courseId;

    if (!courseId || !mongoose.Types.ObjectId.isValid(courseId)) {
      return sendError(res, 'A valid course ID is required', 400);
    }

    const course = await Course.findById(courseId).select(
      'title thumbnail instructorName isPublished createdBy'
    );
    if (!course) {
      return sendNotFound(res, 'Course not found');
    }

    const userId = req.user._id;
    const isAdmin = req.user.role === 'admin';

    let role = null;
    let enrollment = null;

    if (isAdmin) {
      role = 'admin';
    } else {
      const assignment = await TeacherAssignment.findOne({
        teacherId: userId,
        courseId,
        isActive: true, source: { $ne: 'guide_purchase' }
      }).lean();

      if (assignment) {
        role = 'instructor';
      } else {
        enrollment = await Enrollment.findOne({ userId, courseId })
          .select('accessExpirationDate progress completionStatus')
          .lean();
        if (enrollment) role = 'student';
      }
    }

    if (!role) {
      return sendForbidden(
        res,
        'You need to be enrolled in this course to access its community'
      );
    }

    const isTeacher = role === 'instructor' || role === 'admin';

    req.community = {
      courseId: String(courseId),
      course,
      userId,
      role,
      isTeacher,
      isStudent: role === 'student',
      hasExpiredAccess: Boolean(
        enrollment &&
        enrollment.accessExpirationDate &&
        new Date() > new Date(enrollment.accessExpirationDate)
      )
    };

    return next();
  } catch (error) {
    console.error('Community access check failed:', error);
    return sendError(res, 'Failed to verify community access', 500, error.message);
  }
};

/** Guards teacher-only actions (announcements, assignments, grading, pinning). */
const requireCommunityTeacher = (req, res, next) => {
  if (!req.community || !req.community.isTeacher) {
    return sendForbidden(res, 'Only the course teacher can perform this action');
  }
  return next();
};

module.exports = { loadCommunityContext, requireCommunityTeacher };
