const express = require('express');
const router = express.Router();
const c = require('../controllers/eexams.controller');
const { protect } = require('../middleware/auth.middleware');

/** Small fixed-window, per-key limiter (same approach as lab.routes.js). */
function limiter({ windowMs, max, key = (req) => req.ip || 'unknown' }) {
  const hits = new Map();
  return (req, res, next) => {
    const now = Date.now();
    const k = key(req);
    let entry = hits.get(k);
    if (!entry || entry.reset <= now) {
      entry = { count: 0, reset: now + windowMs };
      hits.set(k, entry);
      if (hits.size > 10000) for (const [kk, v] of hits) if (v.reset <= now) hits.delete(kk);
    }
    if (++entry.count > max) {
      res.set('Retry-After', String(Math.ceil((entry.reset - now) / 1000)));
      return res.status(429).json({ success: false, message: 'Too many requests, try again shortly' });
    }
    return next();
  };
}

const startLimiter = limiter({ windowMs: 60 * 1000, max: 20, key: (req) => String(req.user?._id || req.ip) });
const serviceLimiter = limiter({ windowMs: 60 * 1000, max: 600 });

// Logged-in ECH user
router.post('/sso/start', protect, startLimiter, c.startSso);
router.get('/me', protect, c.me);

// Called by the eexams backend (service secret / HMAC signature)
router.post('/sso/exchange', serviceLimiter, c.exchange);
router.post('/events', serviceLimiter, c.events);

// eexams teacher → their ECH school classes ("Send to my ECH class")
const bridge = require('../controllers/school/eexamsBridge.controller');
router.get('/school/classes', serviceLimiter, bridge.classes);
router.get('/school/students', serviceLimiter, bridge.students);
router.get('/school/assignments', serviceLimiter, bridge.assignments);
router.post('/school/assign', serviceLimiter, bridge.assign);

module.exports = router;
