const express = require('express');
const router = express.Router();
const c = require('../controllers/lab.controller');
const p = require('../controllers/labProject.controller');
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');
const { labOrUser } = require('../middleware/labAuth.middleware');

const staff = [protect, authorize('admin', 'instructor')];

/** Small fixed-window, per-IP limiter for the unauthenticated pairing endpoints. */
function limiter({ windowMs, max }) {
  const hits = new Map();
  return (req, res, next) => {
    const now = Date.now();
    const key = req.ip || 'unknown';
    let entry = hits.get(key);
    if (!entry || entry.reset <= now) {
      entry = { count: 0, reset: now + windowMs };
      hits.set(key, entry);
      if (hits.size > 10000) for (const [k, v] of hits) if (v.reset <= now) hits.delete(k);
    }
    if (++entry.count > max) {
      res.set('Retry-After', String(Math.ceil((entry.reset - now) / 1000)));
      return res.status(429).json({ success: false, message: 'Too many requests, try again shortly' });
    }
    return next();
  };
}
const pairStartLimiter = limiter({ windowMs: 10 * 60 * 1000, max: 20 });
const pairPollLimiter = limiter({ windowMs: 10 * 60 * 1000, max: 400 }); // headset polls every ~2 s

// Catalog (rooms, equipment, models) — public, cacheable.
router.get('/catalog', c.getCatalog);

// Scenarios — read by app and lab engine, authored by staff.
router.get('/scenarios', labOrUser, c.listScenarios);
router.get('/scenarios/:id', labOrUser, c.getScenario);
router.post('/scenarios/validate', ...staff, c.validateOnly);
router.post('/scenarios/generate', ...staff, c.generateFromLesson);
router.post('/scenarios', ...staff, c.createScenario);
router.put('/scenarios/:id', ...staff, c.updateScenario);
router.post('/scenarios/:id/status', ...staff, c.setStatus);
router.put('/lessons/:lessonId/lab', ...staff, c.attachToLesson);

// Student "My experiments": design your own experiment and run it in the 3D lab.
router.get('/projects/kit', protect, p.kit);
router.post('/projects/check', protect, p.check);
router.post('/projects/from-idea', protect, p.fromIdea);
router.get('/projects/remix/:id', protect, p.remixSpec);
router.get('/projects', protect, p.mine);
router.post('/projects', protect, p.create);
router.get('/projects/:id', protect, p.getOne);
router.put('/projects/:id', protect, p.update);
router.patch('/projects/:id/conclusion', protect, p.saveConclusion);
router.post('/projects/:id/share', protect, p.share);
router.delete('/projects/:id', protect, p.remove);

// Flutter app → lab token for the Unity engine.
router.post('/session', protect, c.createSession);

// Attempts — Unity engine (lab token) or app.
router.post('/attempts', labOrUser, c.startAttempt);
router.patch('/attempts/:clientId', labOrUser, c.updateAttempt);
router.get('/attempts/me', labOrUser, c.myAttempts);
router.get('/me/summary', protect, c.mySummary);

// VR headset pairing (headset has no login).
router.post('/pair/start', pairStartLimiter, c.pairStart);
router.post('/pair/poll', pairPollLimiter, c.pairPoll);
router.post('/pair/confirm', protect, c.pairConfirm);

module.exports = router;
