const User = require('../models/User');
const { protect } = require('./auth.middleware');
const { verifyLabToken } = require('../services/labs/token.service');
const { sendUnauthorized } = require('../utils/response.utils');

/**
 * For endpoints the Unity lab engine calls: accepts a lab token (scope "lab",
 * signed with the lab secret) or, failing that, a normal app login.
 * Sets req.user, and req.lab = token payload when a lab token was used.
 */
const labOrUser = async (req, res, next) => {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (token) {
    let payload = null;
    try { payload = verifyLabToken(token); } catch (_) { payload = null; }
    if (payload) {
      const user = await User.findById(payload.sub).select('-password');
      if (!user || !user.isActive) return sendUnauthorized(res, 'Lab session is no longer valid');
      req.user = user;
      req.lab = payload;
      return next();
    }
  }
  return protect(req, res, next);
};

module.exports = { labOrUser };
