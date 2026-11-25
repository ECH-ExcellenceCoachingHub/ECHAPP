/**
 * Student "My experiments" (/api/labs/projects): students design their own
 * experiment in a lab room and run it in the 3D lab. Projects are private to their
 * author until they send one to a teacher (status "review"); staff can publish a
 * good one for everybody (it then appears in its room like any other activity).
 */
const mongoose = require('mongoose');
const LabScenario = require('../models/LabScenario');
const LabAttempt = require('../models/LabAttempt');
const { builderKit, compileProject, specFromScenario, MAX_PROJECTS } = require('../services/labs/project.service');
const { generateScenario, SUBJECT_TO_ENV } = require('../services/labs/generator.service');
const { sendSuccess, sendError, sendNotFound, sendForbidden } = require('../utils/response.utils');

const AI_PER_DAY = Number(process.env.LAB_PROJECT_AI_PER_DAY || 8);
const aiUse = new Map(); // userId → { day, count }

function projectCard(s, best) {
  return {
    ...s.toCard(),
    aim: s.project?.aim || '',
    hypothesis: s.project?.hypothesis || '',
    conclusion: s.project?.conclusion || '',
    updatedAt: s.updatedAt,
    best: best || null,
  };
}

async function ownProject(req) {
  if (!mongoose.isValidObjectId(req.params.id)) return null;
  const s = await LabScenario.findOne({ _id: req.params.id, source: 'student' });
  if (!s) return null;
  if (String(s.createdBy) !== String(req.user._id) && req.user.role !== 'admin') return false;
  return s;
}

async function uniqueSlug(base) {
  let slug = base;
  for (let i = 2; await LabScenario.exists({ slug }); i++) slug = `${base}-${i}`.slice(0, 80);
  return slug;
}

const meta = (body, spec) => ({
  aim: String(spec.aim || '').slice(0, 400),
  hypothesis: String(spec.hypothesis || '').slice(0, 400),
  conclusion: String(body.conclusion ?? spec.conclusion ?? '').slice(0, 2000),
  spec,
});

const cardFields = (def) => ({ title: def.title, summary: def.summary, subject: def.subject, environment: def.environment, level: def.level, difficulty: def.difficulty, tags: def.tags, durationMin: def.durationMin, xp: def.xp });

const kit = (req, res) => sendSuccess(res, builderKit());

/** Compile without saving: the builder's "Check" button. */
const check = (req, res) => {
  const out = compileProject(req.body.spec || req.body);
  return sendSuccess(res, { ok: out.ok, errors: out.errors, stepCount: out.ok ? out.scenario.steps.length : 0, hazards: out.ok ? out.scenario.hazards.map((h) => h.message) : [] });
};

const mine = async (req, res) => {
  try {
    const projects = await LabScenario.find({ createdBy: req.user._id, source: 'student', status: { $ne: 'archived' } }).sort({ updatedAt: -1 }).limit(100);
    const best = await LabAttempt.aggregate([
      { $match: { userId: req.user._id, scenarioId: { $in: projects.map((p) => p._id) }, status: 'completed' } },
      { $group: { _id: '$scenarioId', best: { $max: '$score.total' }, passed: { $max: { $cond: ['$passed', 1, 0] } }, attempts: { $sum: 1 } } },
    ]);
    const byId = new Map(best.map((b) => [String(b._id), { best: b.best, passed: b.passed === 1, attempts: b.attempts }]));
    return sendSuccess(res, projects.map((p) => projectCard(p, byId.get(String(p._id)))));
  } catch (err) {
    return sendError(res, 'Could not load your experiments', 500, err.message);
  }
};

const getOne = async (req, res) => {
  try {
    const s = await ownProject(req);
    if (s === false) return sendForbidden(res, 'This is not your experiment');
    if (!s) return sendNotFound(res, 'Experiment not found');
    return sendSuccess(res, { ...projectCard(s), spec: s.project?.spec || specFromScenario(s.definition) });
  } catch (err) {
    return sendError(res, 'Could not load the experiment', 500, err.message);
  }
};

const create = async (req, res) => {
  try {
    const count = await LabScenario.countDocuments({ createdBy: req.user._id, source: 'student', status: { $ne: 'archived' } });
    if (count >= MAX_PROJECTS) return sendError(res, `You can keep up to ${MAX_PROJECTS} experiments. Delete one to make room.`, 409);
    const spec = req.body.spec || {};
    const out = compileProject(spec);
    if (!out.ok) return sendError(res, 'Your experiment needs a few fixes', 422, out.errors);
    const slug = await uniqueSlug(out.scenario.id);
    out.scenario.id = slug;
    let remixOf = null;
    if (mongoose.isValidObjectId(req.body.remixOf)) remixOf = req.body.remixOf;
    const s = await LabScenario.create({
      slug, ...cardFields(out.scenario), definition: out.scenario, version: 1,
      status: 'draft', source: 'student', createdBy: req.user._id, project: meta(req.body, spec), remixOf,
    });
    return sendSuccess(res, { ...projectCard(s), spec }, 'Experiment saved', 201);
  } catch (err) {
    return sendError(res, 'Could not save the experiment', 500, err.message);
  }
};

const update = async (req, res) => {
  try {
    const s = await ownProject(req);
    if (s === false) return sendForbidden(res, 'This is not your experiment');
    if (!s) return sendNotFound(res, 'Experiment not found');
    const spec = req.body.spec || s.project?.spec;
    const out = compileProject(spec, { slug: s.slug });
    if (!out.ok) return sendError(res, 'Your experiment needs a few fixes', 422, out.errors);
    out.scenario.version = (s.version || 1) + 1;
    Object.assign(s, cardFields(out.scenario), { definition: out.scenario, version: out.scenario.version, project: meta(req.body, spec) });
    // A published experiment that the student changes goes back to the teacher.
    if (s.status === 'published' && req.user.role !== 'admin') s.status = 'review';
    s.markModified('definition');
    s.markModified('project');
    await s.save();
    return sendSuccess(res, { ...projectCard(s), spec }, 'Experiment saved');
  } catch (err) {
    return sendError(res, 'Could not save the experiment', 500, err.message);
  }
};

/** Write-up only (conclusion after running it) — no recompile. */
const saveConclusion = async (req, res) => {
  try {
    const s = await ownProject(req);
    if (s === false) return sendForbidden(res, 'This is not your experiment');
    if (!s) return sendNotFound(res, 'Experiment not found');
    s.project = { ...(s.project || {}), conclusion: String(req.body.conclusion || '').slice(0, 2000) };
    s.markModified('project');
    await s.save();
    return sendSuccess(res, projectCard(s), 'Conclusion saved');
  } catch (err) {
    return sendError(res, 'Could not save', 500, err.message);
  }
};

const remove = async (req, res) => {
  try {
    const s = await ownProject(req);
    if (s === false) return sendForbidden(res, 'This is not your experiment');
    if (!s) return sendNotFound(res, 'Experiment not found');
    // Archive (attempts keep pointing at it); it disappears from lists.
    s.status = 'archived';
    await s.save();
    return sendSuccess(res, { id: s._id }, 'Experiment deleted');
  } catch (err) {
    return sendError(res, 'Could not delete', 500, err.message);
  }
};

/** Send to teachers for review (they may publish it for everyone), or take it back. */
const share = async (req, res) => {
  try {
    const s = await ownProject(req);
    if (s === false) return sendForbidden(res, 'This is not your experiment');
    if (!s) return sendNotFound(res, 'Experiment not found');
    if (s.status === 'published') return sendError(res, 'This experiment is already published', 409);
    s.status = req.body.share === false ? 'draft' : 'review';
    await s.save();
    return sendSuccess(res, projectCard(s), s.status === 'review' ? 'Sent to your teachers' : 'Experiment is private again');
  } catch (err) {
    return sendError(res, 'Could not share', 500, err.message);
  }
};

/** "Remix": any lab the student can open, as an editable project spec (not saved yet). */
const remixSpec = async (req, res) => {
  try {
    const ref = String(req.params.id);
    const s = mongoose.isValidObjectId(ref) ? await LabScenario.findById(ref) : await LabScenario.findOne({ slug: ref.toLowerCase() });
    const visible = s && (s.status === 'published' || String(s.createdBy) === String(req.user._id) || ['admin', 'instructor'].includes(req.user.role));
    if (!visible) return sendNotFound(res, 'Lab not found');
    const spec = specFromScenario(s.definition);
    spec.title = `My version of ${s.title}`.slice(0, 120);
    return sendSuccess(res, { spec, remixOf: s._id });
  } catch (err) {
    return sendError(res, 'Could not copy this lab', 500, err.message);
  }
};

/** AI turns the student's idea into a draft spec they then edit (not saved yet). */
const fromIdea = async (req, res) => {
  try {
    const idea = String(req.body.idea || '').trim().slice(0, 1500);
    const environment = String(req.body.environment || '');
    if (idea.length < 15) return sendError(res, 'Describe your idea in a sentence or two', 400);
    const subject = Object.entries(SUBJECT_TO_ENV).find(([, e]) => e === environment)?.[0];
    if (!subject) return sendError(res, 'Choose a lab room', 400);
    const key = String(req.user._id);
    const day = new Date().toISOString().slice(0, 10);
    const use = aiUse.get(key);
    const count = use && use.day === day ? use.count : 0;
    if (count >= AI_PER_DAY) return sendError(res, `You have used the AI helper ${AI_PER_DAY} times today. Build it yourself or try again tomorrow.`, 429);
    aiUse.set(key, { day, count: count + 1 });
    if (aiUse.size > 20000) for (const [k, v] of aiUse) if (v.day !== day) aiUse.delete(k);

    const out = await generateScenario({ title: idea.slice(0, 120), notes: `A student's own experiment idea. Design a short, safe experiment a secondary-school student can do that tests this idea:\n${idea}` }, { subject, maxRepairs: 2 });
    if (!out.ok || !out.scenario) return sendError(res, 'The AI could not turn that idea into an experiment. Try describing it differently, or build it step by step.', 422, out.errors);
    const spec = specFromScenario(out.scenario);
    spec.aim = spec.aim || idea.slice(0, 400);
    const check = compileProject(spec);
    return sendSuccess(res, { spec, ok: check.ok, errors: check.errors });
  } catch (err) {
    return sendError(res, err.message || 'The AI helper failed', 500);
  }
};

module.exports = { kit, check, mine, getOne, create, update, saveConclusion, remove, share, remixSpec, fromIdea };
