/**
 * Virtual labs API (/api/labs). Used by the Flutter app (catalog, sessions,
 * teacher authoring) and by the Unity lab engine (scenario download, attempt
 * autosave/completion) — see docs in labs-unity/README.md.
 */
const crypto = require('crypto');
const mongoose = require('mongoose');
const LabScenario = require('../models/LabScenario');
const LabAttempt = require('../models/LabAttempt');
const LabPairing = require('../models/LabPairing');
const Lesson = require('../models/Lesson');
const User = require('../models/User');
const catalog = require('../services/labs/catalog.json');
const { validateScenario } = require('../services/labs/validator');
const { generateScenario } = require('../services/labs/generator.service');
const { finalizeAttempt } = require('../services/labs/progress.service');
const { scoreAttempt } = require('../services/labs/scoring.service');
const { signLabToken, LAB_TOKEN_TTL } = require('../services/labs/token.service');
const { ensureSeedScenarios } = require('../services/labs/seed.service');
const { sendSuccess, sendError, sendNotFound, sendForbidden } = require('../utils/response.utils');

const STAFF = ['admin', 'instructor'];
const isStaff = (user) => !!user && STAFF.includes(user.role);
const LAB_WEB_URL = () => process.env.LAB_WEB_URL || 'https://labs.excellencecoachinghub.com';

async function findScenario(idOrSlug) {
  if (mongoose.isValidObjectId(idOrSlug)) {
    const byId = await LabScenario.findById(idOrSlug);
    if (byId) return byId;
  }
  return LabScenario.findOne({ slug: String(idOrSlug).toLowerCase() });
}

function canSee(user, scenario) {
  return scenario.status === 'published' || isStaff(user);
}

// ─── Catalog & scenarios ──────────────────────────────────────────────────────

const getCatalog = (req, res) => sendSuccess(res, catalog);

const listScenarios = async (req, res) => {
  try {
    await ensureSeedScenarios();
    const filter = {};
    if (req.query.subject) filter.subject = String(req.query.subject);
    if (isStaff(req.user) && req.query.status) filter.status = String(req.query.status);
    else if (!isStaff(req.user) || !req.query.all) filter.status = 'published';
    if (req.query.environment) filter.environment = String(req.query.environment);
    const scenarios = await LabScenario.find(filter).sort({ environment: 1, difficulty: 1, title: 1 }).limit(500);
    return sendSuccess(res, scenarios.map((s) => s.toCard()));
  } catch (err) {
    return sendError(res, 'Could not load labs', 500, err.message);
  }
};

const getScenario = async (req, res) => {
  try {
    const scenario = await findScenario(req.params.id);
    if (!scenario || !canSee(req.user, scenario)) return sendNotFound(res, 'Lab not found');
    return sendSuccess(res, { ...scenario.toCard(), definition: scenario.definition });
  } catch (err) {
    return sendError(res, 'Could not load lab', 500, err.message);
  }
};

const validateOnly = (req, res) => {
  const result = validateScenario(req.body && req.body.definition ? req.body.definition : req.body);
  return sendSuccess(res, { ok: result.ok, errors: result.errors, definition: result.value || null });
};

function cardFields(def) {
  return { slug: def.id, title: def.title, summary: def.summary, subject: def.subject, environment: def.environment, level: def.level, difficulty: def.difficulty, tags: def.tags, durationMin: def.durationMin, xp: def.xp };
}

const createScenario = async (req, res) => {
  try {
    const result = validateScenario(req.body.definition || req.body);
    if (!result.ok) return sendError(res, 'The lab has problems', 422, result.errors);
    if (await LabScenario.exists({ slug: result.value.id })) return sendError(res, `A lab with id "${result.value.id}" already exists`, 409);
    const scenario = await LabScenario.create({
      ...cardFields(result.value),
      definition: result.value,
      version: result.value.version,
      status: req.body.publish && req.user.role === 'admin' ? 'published' : 'draft',
      publishedAt: req.body.publish && req.user.role === 'admin' ? new Date() : null,
      source: 'teacher',
      createdBy: req.user._id,
      courseId: req.body.courseId || null,
    });
    return sendSuccess(res, { ...scenario.toCard(), definition: scenario.definition }, 'Lab created', 201);
  } catch (err) {
    return sendError(res, 'Could not create lab', 500, err.message);
  }
};

const updateScenario = async (req, res) => {
  try {
    const scenario = await findScenario(req.params.id);
    if (!scenario) return sendNotFound(res, 'Lab not found');
    if (req.user.role !== 'admin' && String(scenario.createdBy) !== String(req.user._id)) return sendForbidden(res, 'Only the author or an admin can edit this lab');
    const def = { ...(req.body.definition || req.body), id: scenario.slug, version: (scenario.version || 1) + 1 };
    const result = validateScenario(def);
    if (!result.ok) return sendError(res, 'The lab has problems', 422, result.errors);
    Object.assign(scenario, cardFields(result.value), { definition: result.value, version: result.value.version });
    scenario.markModified('definition');
    // Edits to a published lab by a teacher go back to review.
    if (scenario.status === 'published' && req.user.role !== 'admin') scenario.status = 'review';
    await scenario.save();
    return sendSuccess(res, { ...scenario.toCard(), definition: scenario.definition }, 'Lab updated');
  } catch (err) {
    return sendError(res, 'Could not update lab', 500, err.message);
  }
};

const setStatus = async (req, res) => {
  try {
    const status = String(req.body.status || '');
    if (!['draft', 'review', 'published', 'archived'].includes(status)) return sendError(res, 'Invalid status', 400);
    if (status === 'published' && req.user.role !== 'admin' && !(process.env.LAB_TEACHERS_CAN_PUBLISH === 'true')) {
      return sendForbidden(res, 'An admin must publish labs (submit it for review instead)');
    }
    const scenario = await findScenario(req.params.id);
    if (!scenario) return sendNotFound(res, 'Lab not found');
    const check = validateScenario(scenario.definition);
    if (status === 'published' && !check.ok) return sendError(res, 'The lab has problems', 422, check.errors);
    scenario.status = status;
    if (status === 'published') { scenario.publishedAt = new Date(); scenario.reviewedBy = req.user._id; }
    await scenario.save();
    return sendSuccess(res, scenario.toCard(), `Lab ${status}`);
  } catch (err) {
    return sendError(res, 'Could not change status', 500, err.message);
  }
};

const generateFromLesson = async (req, res) => {
  try {
    const lesson = await Lesson.findById(req.body.lessonId);
    if (!lesson) return sendNotFound(res, 'Lesson not found');
    const out = await generateScenario(lesson, { subject: req.body.subject });
    if (!out.ok) return sendError(res, 'The AI could not build a valid lab for this lesson', 422, { errors: out.errors, draft: out.scenario || null });
    let slug = out.scenario.id;
    for (let i = 2; await LabScenario.exists({ slug }); i++) slug = `${out.scenario.id}-${i}`;
    out.scenario.id = slug;
    const scenario = await LabScenario.create({
      ...cardFields(out.scenario),
      definition: out.scenario,
      status: 'review',
      source: 'ai',
      createdBy: req.user._id,
      lessonIds: [lesson._id],
      courseId: lesson.courseId,
    });
    return sendSuccess(res, { ...scenario.toCard(), definition: scenario.definition, rounds: out.rounds }, 'Lab draft generated — review it before publishing', 201);
  } catch (err) {
    return sendError(res, err.message || 'Lab generation failed', 500);
  }
};

const attachToLesson = async (req, res) => {
  try {
    const lesson = await Lesson.findById(req.params.lessonId);
    if (!lesson) return sendNotFound(res, 'Lesson not found');
    if (req.body.scenarioId == null) {
      lesson.lab = { scenarioId: null, required: false };
    } else {
      const scenario = await findScenario(req.body.scenarioId);
      if (!scenario) return sendNotFound(res, 'Lab not found');
      lesson.lab = { scenarioId: scenario._id, required: !!req.body.required };
      await LabScenario.updateOne({ _id: scenario._id }, { $addToSet: { lessonIds: lesson._id } });
    }
    await lesson.save();
    return sendSuccess(res, { lessonId: lesson._id, lab: lesson.lab }, 'Lesson lab updated');
  } catch (err) {
    return sendError(res, 'Could not attach lab', 500, err.message);
  }
};

// ─── Sessions (Flutter → Unity) ───────────────────────────────────────────────

const createSession = async (req, res) => {
  try {
    const scenario = await findScenario(req.body.scenarioId);
    if (!scenario || !canSee(req.user, scenario)) return sendNotFound(res, 'Lab not found');
    let lessonId = null;
    let courseId = null;
    if (req.body.lessonId && mongoose.isValidObjectId(req.body.lessonId)) {
      const lesson = await Lesson.findById(req.body.lessonId).select('courseId');
      if (lesson) { lessonId = lesson._id; courseId = lesson.courseId; }
    }
    const labToken = signLabToken({ userId: req.user._id, scenarioId: scenario._id, lessonId, courseId });
    const resume = await LabAttempt.findOne({ userId: req.user._id, scenarioId: scenario._id, status: 'in_progress' }).sort({ updatedAt: -1 }).select('clientId currentStepId completedSteps updatedAt');
    const launch = { token: labToken, scenario: String(scenario._id), lesson: lessonId ? String(lessonId) : '', api: `${req.protocol}://${req.get('host')}/api/labs`, lang: req.body.lang || 'en' };
    return sendSuccess(res, {
      labToken,
      expiresIn: LAB_TOKEN_TTL,
      scenario: scenario.toCard(),
      lessonId,
      resume: resume ? { clientId: resume.clientId, currentStepId: resume.currentStepId, completedSteps: resume.completedSteps, updatedAt: resume.updatedAt } : null,
      // Web build reads its parameters from the URL fragment (never sent to servers or logs).
      webUrl: `${LAB_WEB_URL()}/#${new URLSearchParams(launch).toString()}`,
      launch,
    });
  } catch (err) {
    return sendError(res, 'Could not start the lab', 500, err.message);
  }
};

// ─── Attempts (Unity → backend) ───────────────────────────────────────────────

const num = (v) => (typeof v === 'number' && Number.isFinite(v) ? v : Number.isFinite(Number(v)) ? Number(v) : undefined);

function sanitizeProgress(body, def) {
  const stepIds = new Set(def.steps.map((s) => s.id));
  const recordKeys = new Set(def.steps.filter((s) => s.record).map((s) => s.record.key));
  const hazardIds = new Set((def.hazards || []).map((h) => h.id));
  const out = {};
  if (Array.isArray(body.completedSteps)) out.completedSteps = [...new Set(body.completedSteps.map(String))].filter((id) => stepIds.has(id));
  if (typeof body.currentStepId === 'string' && stepIds.has(body.currentStepId)) out.currentStepId = body.currentStepId;
  if (body.records && typeof body.records === 'object') {
    out.records = {};
    for (const [k, v] of Object.entries(body.records)) if (recordKeys.has(k) && num(v) !== undefined) out.records[k] = num(v);
  }
  if (Array.isArray(body.checkpoints)) {
    out.checkpoints = body.checkpoints.filter((c) => c && stepIds.has(String(c.stepId))).map((c) => {
      const step = def.steps.find((s) => s.id === String(c.stepId));
      const q = step.checkpoint && step.checkpoint.question;
      const choice = Number(c.choice);
      // Correctness is decided here for inline questions, never trusted from the client.
      return { stepId: step.id, choice, correct: q ? choice === q.answerIndex : !!c.correct };
    });
  }
  if (Array.isArray(body.hazardsTriggered)) out.hazardsTriggered = body.hazardsTriggered.filter((h) => h && hazardIds.has(String(h.id))).map((h) => ({ id: String(h.id), t: num(h.t) || 0 }));
  if (Array.isArray(body.log)) out.log = body.log.slice(-2000).map((e) => ({ t: num(e.t) || 0, type: String(e.type || 'event').slice(0, 20), stepId: e.stepId ? String(e.stepId).slice(0, 40) : undefined, data: e.data && JSON.stringify(e.data).length < 500 ? e.data : undefined }));
  for (const k of ['hintsUsed', 'mistakes', 'durationSec']) if (num(body[k]) !== undefined) out[k] = Math.max(0, Math.round(num(body[k])));
  if (body.perf && typeof body.perf === 'object') out.perf = { avgFps: num(body.perf.avgFps), minFps: num(body.perf.minFps), gpu: body.perf.gpu ? String(body.perf.gpu).slice(0, 120) : undefined, deviceModel: body.perf.deviceModel ? String(body.perf.deviceModel).slice(0, 120) : undefined };
  return out;
}

const startAttempt = async (req, res) => {
  try {
    const clientId = String(req.body.clientId || '').slice(0, 64);
    if (!/^[A-Za-z0-9-]{8,64}$/.test(clientId)) return sendError(res, 'clientId must be a UUID', 400);
    const scenarioRef = req.body.scenarioId || (req.lab && req.lab.sid);
    const scenario = scenarioRef ? await findScenario(scenarioRef) : null;
    if (!scenario || !canSee(req.user, scenario)) return sendNotFound(res, 'Lab not found');
    if (req.lab && req.lab.sid && req.lab.sid !== String(scenario._id)) return sendForbidden(res, 'This lab session is for a different lab');

    const existing = await LabAttempt.findOne({ userId: req.user._id, clientId });
    if (existing) return sendSuccess(res, existing, 'Attempt resumed');

    const lessonId = (req.lab && req.lab.lid) || (mongoose.isValidObjectId(req.body.lessonId) ? req.body.lessonId : null);
    const attempt = await LabAttempt.create({
      clientId,
      userId: req.user._id,
      scenarioId: scenario._id,
      scenarioVersion: scenario.version,
      lessonId,
      courseId: (req.lab && req.lab.cid) || null,
      platform: ['android', 'ios', 'windows', 'web', 'quest', 'pcvr'].includes(req.body.platform) ? req.body.platform : 'other',
      mode: ['desktop', 'touch', 'cardboard', 'xr', 'fallback'].includes(req.body.mode) ? req.body.mode : 'desktop',
      qualityTier: ['low', 'medium', 'ultra'].includes(req.body.qualityTier) ? req.body.qualityTier : 'medium',
      lang: typeof req.body.lang === 'string' ? req.body.lang.slice(0, 5) : 'en',
      startedAt: num(req.body.startedAt) ? new Date(num(req.body.startedAt)) : new Date(),
    });
    await LabScenario.updateOne({ _id: scenario._id }, { $inc: { 'stats.attempts': 1 } });
    return sendSuccess(res, attempt, 'Attempt started', 201);
  } catch (err) {
    return sendError(res, 'Could not start attempt', 500, err.message);
  }
};

const updateAttempt = async (req, res) => {
  try {
    const attempt = await LabAttempt.findOne({ userId: req.user._id, clientId: String(req.params.clientId) });
    if (!attempt) return sendNotFound(res, 'Attempt not found');
    const scenario = await LabScenario.findById(attempt.scenarioId);
    if (!scenario) return sendNotFound(res, 'Lab not found');
    if (attempt.status === 'completed') {
      return sendSuccess(res, { attempt, outcome: { score: attempt.score, passed: attempt.passed, xpAwarded: attempt.xpAwarded } }, 'Attempt already completed');
    }
    Object.assign(attempt, sanitizeProgress(req.body, scenario.definition));
    attempt.markModified('records');

    if (req.body.complete) {
      const outcome = await finalizeAttempt(attempt, scenario);
      return sendSuccess(res, { attempt, outcome }, outcome.passed ? 'Lab passed' : 'Lab completed');
    }
    if (req.body.abandon) attempt.status = 'abandoned';
    await attempt.save();
    // Live preview of the score for the HUD.
    const preview = scoreAttempt(scenario.definition, attempt);
    return sendSuccess(res, { attempt, preview: preview.score }, 'Progress saved');
  } catch (err) {
    return sendError(res, 'Could not save progress', 500, err.message);
  }
};

const myAttempts = async (req, res) => {
  try {
    const filter = { userId: req.user._id };
    if (req.query.scenarioId && mongoose.isValidObjectId(req.query.scenarioId)) filter.scenarioId = req.query.scenarioId;
    const attempts = await LabAttempt.find(filter).sort({ updatedAt: -1 }).limit(100).select('-log').populate('scenarioId', 'slug title subject environment thumbnail xp');
    return sendSuccess(res, attempts);
  } catch (err) {
    return sendError(res, 'Could not load attempts', 500, err.message);
  }
};

const mySummary = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('labXp labBadges');
    const passed = await LabAttempt.aggregate([
      { $match: { userId: req.user._id, passed: true } },
      { $group: { _id: '$scenarioId', best: { $max: '$score.total' } } },
      { $lookup: { from: 'labscenarios', localField: '_id', foreignField: '_id', as: 's' } },
      { $unwind: '$s' },
      { $group: { _id: '$s.subject', count: { $sum: 1 }, avgBest: { $avg: '$best' } } },
    ]);
    const best = await LabAttempt.aggregate([
      { $match: { userId: req.user._id, status: 'completed' } },
      { $group: { _id: '$scenarioId', best: { $max: '$score.total' }, passed: { $max: { $cond: ['$passed', 1, 0] } }, attempts: { $sum: 1 } } },
    ]);
    const inProgress = await LabAttempt.find({ userId: req.user._id, status: 'in_progress' }).sort({ updatedAt: -1 }).limit(5).select('clientId scenarioId currentStepId completedSteps updatedAt').populate('scenarioId', 'slug title subject thumbnail');
    const xp = user?.labXp || 0;
    return sendSuccess(res, {
      xp,
      level: Math.floor(Math.sqrt(xp / 50)) + 1, // L2 at 50xp, L3 at 200xp, L4 at 450xp…
      badges: user?.labBadges || [],
      bySubject: Object.fromEntries(passed.map((p) => [p._id, { passed: p.count, avgBest: Math.round(p.avgBest) }])),
      continue: inProgress,
      scenarios: Object.fromEntries(best.map((b) => [String(b._id), { best: b.best, passed: b.passed === 1, attempts: b.attempts }])),
    });
  } catch (err) {
    return sendError(res, 'Could not load summary', 500, err.message);
  }
};

// ─── Headset pairing ──────────────────────────────────────────────────────────

const PAIR_TTL_MS = 10 * 60 * 1000;

const pairStart = async (req, res) => {
  try {
    let code;
    for (let i = 0; i < 5; i++) {
      code = String(crypto.randomInt(0, 1000000)).padStart(6, '0');
      if (!(await LabPairing.exists({ code, expiresAt: { $gt: new Date() } }))) break;
    }
    const deviceSecret = crypto.randomBytes(32).toString('hex');
    const pairing = await LabPairing.create({ code, deviceSecret, deviceName: String(req.body.deviceName || 'VR headset').slice(0, 60), expiresAt: new Date(Date.now() + PAIR_TTL_MS) });
    return sendSuccess(res, { code, deviceSecret, expiresAt: pairing.expiresAt }, 'Enter this code in the ECH app', 201);
  } catch (err) {
    return sendError(res, 'Could not start pairing', 500, err.message);
  }
};

const pairConfirm = async (req, res) => {
  try {
    const code = String(req.body.code || '').replace(/\D/g, '');
    const pairing = await LabPairing.findOne({ code, expiresAt: { $gt: new Date() }, confirmedAt: null });
    if (!pairing) return sendNotFound(res, 'Code not found or expired — check the code on your headset');
    let scenario = null;
    if (req.body.scenarioId) {
      scenario = await findScenario(req.body.scenarioId);
      if (!scenario || !canSee(req.user, scenario)) return sendNotFound(res, 'Lab not found');
    }
    pairing.userId = req.user._id;
    pairing.scenarioId = scenario ? scenario._id : null;
    pairing.lessonId = mongoose.isValidObjectId(req.body.lessonId) ? req.body.lessonId : null;
    pairing.confirmedAt = new Date();
    await pairing.save();
    return sendSuccess(res, { deviceName: pairing.deviceName }, 'Headset connected');
  } catch (err) {
    return sendError(res, 'Could not confirm pairing', 500, err.message);
  }
};

const pairPoll = async (req, res) => {
  try {
    const pairing = await LabPairing.findOne({ deviceSecret: String(req.body.deviceSecret || '') });
    if (!pairing || pairing.expiresAt < new Date()) return sendNotFound(res, 'Pairing expired — request a new code');
    if (!pairing.confirmedAt) return sendSuccess(res, { status: 'pending' });
    if (pairing.claimedAt) return sendError(res, 'This code was already used', 410);
    pairing.claimedAt = new Date();
    await pairing.save();
    const user = await User.findById(pairing.userId).select('fullName');
    const labToken = signLabToken({ userId: pairing.userId, scenarioId: pairing.scenarioId, lessonId: pairing.lessonId });
    return sendSuccess(res, { status: 'paired', labToken, scenarioId: pairing.scenarioId, lessonId: pairing.lessonId, studentName: user?.fullName || '' });
  } catch (err) {
    return sendError(res, 'Could not check pairing', 500, err.message);
  }
};

module.exports = {
  getCatalog, listScenarios, getScenario, validateOnly, createScenario, updateScenario, setStatus,
  generateFromLesson, attachToLesson, createSession, startAttempt, updateAttempt, myAttempts, mySummary,
  pairStart, pairConfirm, pairPoll, sanitizeProgress,
};
