const User = require('../models/User');
const { verifyToken } = require('../utils/jwt.utils');
const { sendUnauthorized } = require('../utils/response.utils');
const admin = require('../config/firebase');
const { canLinkByEmail, sendVerificationIfNeeded, notVerifiedMessage } = require('../utils/firebaseAccountLink');
const { sessionProblem } = require('../services/school/session.service');
const { clientIp } = require('../utils/clientIp');

// Never log tokens or the Authorization header: anyone who can read the
// server logs could reuse them to act as the user.
const protect = async (req, res, next) => {
  let token;

  // Check for token in header
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    // Get token from header
    token = req.headers.authorization.split(' ')[1];
    if (!token) {
      return sendUnauthorized(res, 'Not authorized, no token provided');
    }

    // Try to verify as Firebase ID token first
    try {
      const decodedToken = await admin.auth().verifyIdToken(token);

      // Find user by Firebase UID
      req.user = await User.findOne({ firebaseUid: decodedToken.uid }).select('-password');
      
      // Fallback: teacher/admin accounts created directly in MongoDB (no firebaseUid set yet).
      // Link by email ONLY when Firebase has verified the email and the account
      // isn't already linked to another Firebase user (prevents account takeover).
      if (!req.user && decodedToken.email) {
        const userByEmail = await User.findOne({ email: decodedToken.email.toLowerCase() });
        if (userByEmail) {
          if (!canLinkByEmail(decodedToken, userByEmail)) {
            return res.status(403).json({
              success: false,
              code: userByEmail.firebaseUid ? 'EMAIL_IN_USE' : 'EMAIL_NOT_VERIFIED',
              message: userByEmail.firebaseUid
                ? 'An account with this email already exists. Please sign in with your original method.'
                : notVerifiedMessage(await sendVerificationIfNeeded(decodedToken, userByEmail)),
            });
          }
          console.log('Linking verified Firebase user to existing account by email:', decodedToken.uid);
          userByEmail.firebaseUid = decodedToken.uid;
          await userByEmail.save();
          req.user = await User.findById(userByEmail._id).select('-password');
        }
      }

      if (!req.user) {
        console.warn(`[auth] no ECH user for Firebase UID ${decodedToken.uid}`);
        return sendUnauthorized(res, 'User not found in database');
      }

      if (!req.user.isActive) {
        return sendUnauthorized(res, 'User account is deactivated');
      }

      const sessionIssue = await sessionProblem(req.user, decodedToken.sid, clientIp(req));
      if (sessionIssue) {
        return res.status(401).json(sessionIssue);
      }

      return next();
    } catch (firebaseError) {
      // Not a Firebase ID token (or expired) — try the legacy ECH JWT.
      try {
        const decoded = verifyToken(token);

        const user = await User.findById(decoded.id).select('-password');
        if (!user) {
          return sendUnauthorized(res, 'User not found in database');
        }

        if (!user.isActive) {
          return sendUnauthorized(res, 'User account is deactivated');
        }

        const sessionIssue = await sessionProblem(user, decoded.sid, clientIp(req));
        if (sessionIssue) {
          return res.status(401).json(sessionIssue);
        }

        req.user = user;
        return next();
      } catch (jwtError) {
        console.warn(`[auth] rejected token on ${req.method} ${req.originalUrl.split('?')[0]}: ${firebaseError.code || firebaseError.message} / ${jwtError.message}`);
        return sendUnauthorized(res, 'Not authorized, invalid token');
      }
    }
  } else {
    return sendUnauthorized(res, 'Not authorized, no token provided');
  }
};

const optionalProtect = (req, res, next) => {
  let token;

  // Check for token in header
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
    
    // Try to verify as Firebase ID token
    admin.auth().verifyIdToken(token)
      .then(async (decodedToken) => {
        req.user = await User.findOne({ firebaseUid: decodedToken.uid }).select('-password');
        if (typeof next === 'function') next();
      })
      .catch((firebaseError) => {
        // If Firebase verification fails, try JWT verification
        try {
          const decoded = verifyToken(token);
          User.findById(decoded.id).select('-password')
            .then((user) => {
              req.user = user;
              if (typeof next === 'function') next();
            })
            .catch(() => {
              if (typeof next === 'function') next();
            });
        } catch (jwtError) {
          if (typeof next === 'function') next();
        }
      });
  } else {
    if (typeof next === 'function') next();
  }
};

module.exports = { protect, optionalProtect };