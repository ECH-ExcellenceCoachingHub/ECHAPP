/**
 * /api/teacher-tools — ECH teacher tools backed by eexams.net
 *
 *   GET  /status                       link the teacher's eexams account (teacher role) + planner limits
 *   ANY  /planner/lesson-plans/...     → eexams /api/lesson-plans/...       (Lesson Plan)
 *   ANY  /planner/resources/...        → eexams /api/planner-resources/...  (Slides, Exercises, Scheme of Work)
 *   GET  /exams                        the teacher's exams on eexams
 *   POST /exams/ai     {prompt,...}    AI-describe an exam → saved on eexams as a draft
 *   POST /exams/upload (multipart)     exam document (+ optional answer sheet) → eexams draft
 *   GET  /levels                       eexams levels (for the exam form)
 */
const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth.middleware');
const { authorize } = require('../middleware/role.middleware');
const tools = require('../services/integrations/eexamsTeacher.service');

router.use(protect, authorize('admin', 'instructor'));

/** Small fixed-window per-teacher limiter (protects the AI endpoints). */
function makeLimiter({ windowMs, max }) {
  const hits = new Map();
  // Returns seconds to wait when over the limit, otherwise 0.
  const hit = (userId) => {
    const now = Date.now();
    const key = String(userId);
    let e = hits.get(key);
    if (!e || e.reset <= now) { e = { count: 0, reset: now + windowMs }; hits.set(key, e); }
    if (hits.size > 10000) for (const [k, v] of hits) if (v.reset <= now) hits.delete(k);
    return ++e.count > max ? Math.ceil((e.reset - now) / 1000) : 0;
  };
  const middleware = (req, res, next) => {
    const wait = hit(req.user._id);
    if (!wait) return next();
    res.set('Retry-After', String(wait));
    return res.status(429).json({ success: false, message: 'Too many requests — please wait a moment and try again.' });
  };
  return { hit, middleware };
}
const ai = makeLimiter({ windowMs: 60 * 1000, max: 6 });
const aiLimiter = ai.middleware;

/** eexams errors keep their status and message (quota reached, plan limits…). */
function sendError(res, e, fallback) {
  if (e instanceof tools.EexamsError) {
    const status = e.status >= 400 && e.status < 600 ? e.status : 502;
    return res.status(status).json({ success: false, message: e.body?.message || fallback, code: e.body?.code, upgradeRequired: e.body?.upgradeRequired });
  }
  if (e?.name === 'TimeoutError' || e?.name === 'AbortError') {
    return res.status(504).json({ success: false, message: 'eexams took too long to answer. Please try again.' });
  }
  console.error('[teacher-tools]', fallback, e);
  return res.status(502).json({ success: false, message: fallback });
}

router.get('/status', async (req, res) => {
  try {
    const p = await tools.provision(req.user, { force: true });
    return res.json({ success: true, data: { linked: true, eexamsRole: p.role, subscriptionPlan: p.subscriptionPlan, subscriptionStatus: p.subscriptionStatus, subscriptionExpiresAt: p.subscriptionExpiresAt, plannerLimits: tools.plannerLimits() } });
  } catch (e) {
    if (e instanceof tools.EexamsError && e.body?.code === 'LINK_REQUIRED') {
      return res.json({ success: true, data: { linked: false, linkRequired: true, message: e.body.message } });
    }
    return sendError(res, e, 'Could not reach eexams');
  }
});

// ── Planner (ECH feature, engine on eexams) ──────────────────────────────────
const plannerProxy = (prefix) => async (req, res) => {
  try {
    // req.url is the part after the mount point, query string included.
    const isGenerate = /\/generate(\?|$)/.test(req.url);
    if (isGenerate) {
      const wait = ai.hit(req.user._id);
      if (wait) {
        res.set('Retry-After', String(wait));
        return res.status(429).json({ success: false, message: 'Too many requests — please wait a moment and try again.' });
      }
    }
    return await tools.forward(req, res, `${prefix}${req.url === '/' ? '' : req.url}`, { timeout: isGenerate ? 180000 : 90000 });
  } catch (e) {
    if (res.headersSent) return undefined;
    return sendError(res, e, 'The planner is not available right now');
  }
};
router.use('/planner/lesson-plans', plannerProxy('/lesson-plans'));
router.use('/planner/resources', plannerProxy('/planner-resources'));

// ── Exams (created here, saved + managed on eexams) ─────────────────────────
router.get('/exams', async (req, res) => {
  try {
    return res.json({ success: true, data: await tools.listExams(req.user) });
  } catch (e) { return sendError(res, e, 'Could not load your eexams exams'); }
});

router.post('/exams/ai', aiLimiter, async (req, res) => {
  const prompt = String(req.body?.prompt || '').trim();
  if (prompt.length < 10) return res.status(400).json({ success: false, message: 'Describe the exam: subject, class, topics and how many questions of each type.' });
  if (prompt.length > 4000) return res.status(400).json({ success: false, message: 'Please keep the description under 4000 characters.' });
  try {
    const data = await tools.createExamWithAi(req.user, { prompt, level: req.body?.level, subLevel: req.body?.subLevel });
    return res.status(201).json({ success: true, message: 'Exam saved on eexams as a draft', data: { ...data, managePath: '/teacher' } });
  } catch (e) { return sendError(res, e, 'Could not create the exam'); }
});

router.post('/exams/upload', aiLimiter, async (req, res) => {
  if (!(req.headers['content-type'] || '').startsWith('multipart/form-data')) {
    return res.status(400).json({ success: false, message: 'Send the exam as a file upload (examFile).' });
  }
  try {
    return await tools.forward(req, res, '/admin/exams', { timeout: 300000 });
  } catch (e) {
    if (res.headersSent) return undefined;
    return sendError(res, e, 'Could not upload the exam');
  }
});

router.get('/levels', async (req, res) => {
  try {
    return await tools.forward(req, res, '/levels');
  } catch (e) {
    if (res.headersSent) return undefined;
    return sendError(res, e, 'Could not load levels');
  }
});

module.exports = router;
