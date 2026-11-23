const { sendForbidden } = require('../utils/response.utils');
const { blockReason } = require('../services/teacherAccess.service');
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return sendForbidden(res, 'Access denied. No user found.');
    }

    if (!roles.includes(req.user.role)) {
      console.log('Authorization failed. User role:', req.user.role, 'Required roles:', roles);
      return sendForbidden(res, 'Access denied. Insufficient permissions. Required: ' + roles.join(', '));
    }

    if (typeof next !== 'function') {
      console.error('CRITICAL: next is not a function in authorize middleware');
      return sendForbidden(res, 'Internal Server Error: Middleware chain broken');
    }

    // Super admin limits are checked in protect() (auth.middleware).

    // Self-registered teachers must be approved and hold a course before any
    // instructor feature works. Admin-created teachers (no teacherStatus) are unaffected.
    if (req.user.role !== 'instructor' || !req.user.teacherStatus) return next();
    return blockReason(req.user)
      .then((reason) => (reason ? res.status(403).json({ success: false, ...reason }) : next()))
      .catch(() => res.status(500).json({ success: false, message: 'Could not check teacher access' }));
  };
};

module.exports = { authorize };
