/**
 * Lab scenario validation: structure (joi) + meaning (catalog, expressions,
 * step graph, scientific correctness of expected results). Used for teacher
 * edits, AI-generated drafts and the seed scenarios in CI.
 */
const Joi = require('joi');
const catalog = require('./catalog.json');
const expr = require('./expression');
const sim = require('./sim');

const ID = Joi.string().pattern(/^[A-Za-z][A-Za-z0-9_]{0,39}$/);
const SLUG = Joi.string().pattern(/^[a-z0-9][a-z0-9-]{2,79}$/);
const TEXT = (max) => Joi.string().trim().min(1).max(max);
const EXPR = Joi.string().trim().min(1).max(400);

const SUBJECTS = ['chemistry', 'physics', 'biology', 'cybersecurity', 'networking', 'coding'];
const LEVELS = ['primary', 'secondary', 'university', 'professional'];
const BUILTINS = ['time', 'mistakes', 'hintsUsed']; // provided by the runtime

const questionSchema = Joi.object({
  prompt: TEXT(400).required(),
  choices: Joi.array().items(TEXT(200)).min(2).max(6).required(),
  answerIndex: Joi.number().integer().min(0).required(),
  explanation: TEXT(600),
});

const stepSchema = Joi.object({
  id: ID.required(),
  kind: Joi.string().valid('action', 'measure', 'checkpoint', 'info').default('action'),
  title: TEXT(80),
  instruction: TEXT(400).required(),
  say: TEXT(600),
  success: TEXT(400),
  hints: Joi.array().items(TEXT(300)).max(5).default([]),
  focus: ID,
  points: Joi.number().integer().min(0).max(100).default(10),
  expect: Joi.object({
    intent: Joi.string().valid(...catalog.intents).required(),
    target: ID.required(),
    into: ID, // receiver of a Pour / Connect
    value: Joi.object({ min: Joi.number(), max: Joi.number() }),
  }),
  until: EXPR,
  record: Joi.object({
    key: ID.required(),
    label: TEXT(120).required(),
    unit: Joi.string().trim().allow('').max(20),
    truth: EXPR.required(), // value the student should read off the instrument
    tolerance: Joi.number().min(0).required(), // absolute, in `unit`
  }),
  checkpoint: Joi.object({
    questionRef: Joi.string().hex().length(24),
    question: questionSchema,
  }).xor('questionRef', 'question'),
});

const scenarioSchema = Joi.object({
  id: SLUG.required(),
  version: Joi.number().integer().min(1).default(1),
  title: TEXT(120).required(),
  summary: TEXT(600).required(),
  subject: Joi.string().valid(...SUBJECTS).required(),
  level: Joi.string().valid(...LEVELS).default('secondary'),
  // 1 Beginner · 2 Easy · 3 Intermediate · 4 Advanced · 5 Expert — orders activities inside a lab room.
  difficulty: Joi.number().integer().min(1).max(5).default(2),
  tags: Joi.array().items(Joi.string().trim().max(30)).max(8).default([]),
  environment: Joi.string().valid(...Object.keys(catalog.environments)).required(),
  durationMin: Joi.number().integer().min(1).max(180).default(20),
  objectives: Joi.array().items(TEXT(200)).min(1).max(8).required(),
  equipment: Joi.array().items(Joi.object({
    id: ID.required(),
    type: Joi.string().valid(...Object.keys(catalog.equipment)).required(),
    slot: Joi.string().required(),
    label: TEXT(60),
    init: Joi.object().pattern(Joi.string(), Joi.alternatives(Joi.number(), Joi.string(), Joi.boolean(), Joi.array().items(Joi.number()), Joi.array().items(Joi.string().max(80)).max(20))).default({}),
  })).min(1).max(40).required(),
  variables: Joi.object().pattern(ID, Joi.object({
    model: Joi.string().valid(...Object.keys(catalog.models)).required(),
    inputs: Joi.object().pattern(Joi.string(), ID).required(),
    params: Joi.object().default({}),
  })).default({}),
  steps: Joi.array().items(stepSchema).min(1).max(60).required(),
  hazards: Joi.array().items(Joi.object({
    id: ID.required(),
    when: EXPR.required(),
    message: TEXT(300).required(),
    severity: Joi.string().valid('warn', 'fail').default('warn'),
    penalty: Joi.number().integer().min(0).max(100).default(5),
  })).max(20).default([]),
  results: Joi.array().items(Joi.object({
    key: ID.required(),
    label: TEXT(120).required(),
    unit: Joi.string().trim().allow('').max(20),
    expected: Joi.number().required(),
    tolerancePct: Joi.number().min(0).max(100).default(5),
    source: EXPR.required(), // usually record.<key>
  })).max(10).default([]),
  scoring: Joi.object({
    accuracy: Joi.number().min(0).max(100).default(40),
    procedure: Joi.number().min(0).max(100).default(40),
    safety: Joi.number().min(0).max(100).default(20),
  }).default({ accuracy: 40, procedure: 40, safety: 20 }),
  passScore: Joi.number().min(0).max(100).default(60),
  xp: Joi.number().integer().min(0).max(1000).default(100),
  i18n: Joi.object().pattern(Joi.string().valid('rw', 'fr', 'en'), Joi.object()).default({}),
});

function scopeFor(scenario) {
  const known = new Set(BUILTINS);
  const prefixes = new Set(['record']); // record.<key> from measure steps
  for (const eq of scenario.equipment || []) {
    const def = catalog.equipment[eq.type];
    if (!def) continue;
    for (const k of [...def.state, ...def.init]) known.add(`${eq.id}.${k}`);
  }
  for (const [name, v] of Object.entries(scenario.variables || {})) {
    const model = catalog.models[v.model];
    if (model) for (const o of model.outputs) known.add(`${name}.${o}`);
  }
  for (const s of scenario.steps || []) if (s.record) known.add(`record.${s.record.key}`);
  return { known, prefixes };
}

/**
 * Check that expected results agree with the reference science models.
 * Today: acid–base titration equivalence volume.
 */
function checkScience(scenario, errors) {
  for (const [name, v] of Object.entries(scenario.variables || {})) {
    if (v.model !== 'chem.titration') continue;
    const flask = scenario.equipment.find((e) => e.id === v.inputs.flask);
    const burette = scenario.equipment.find((e) => e.id === v.inputs.burette);
    if (!flask || !burette) continue;
    const acid = flask.init.solution;
    if (!sim.ACIDS[acid]) { errors.push(`variables.${name}: flask solution "${acid}" is not a known acid (${Object.keys(sim.ACIDS).join(', ')})`); continue; }
    if (!sim.BASES[burette.init.solution]) { errors.push(`variables.${name}: burette solution "${burette.init.solution}" is not a known base (${Object.keys(sim.BASES).join(', ')})`); continue; }
    const ind = v.params && v.params.indicator;
    if (ind && !sim.INDICATORS[ind]) errors.push(`variables.${name}: unknown indicator "${ind}"`);
    const { equivalenceVolumeMl } = sim.titration({ acid, acidConc: Number(flask.init.conc), acidVolumeMl: Number(flask.init.volume), baseConc: Number(burette.init.conc), baseAddedMl: 0 });
    if (equivalenceVolumeMl > Number(burette.init.volume || 50)) {
      errors.push(`variables.${name}: the endpoint needs ${equivalenceVolumeMl.toFixed(2)} mL but the burette only holds ${burette.init.volume || 50} mL`);
    }
    for (const r of scenario.results || []) {
      if (!/titre|endpoint|equivalence/i.test(r.key)) continue;
      const diff = Math.abs(r.expected - equivalenceVolumeMl) / equivalenceVolumeMl * 100;
      if (diff > 1) errors.push(`results.${r.key}: expected ${r.expected} but the chemistry gives ${equivalenceVolumeMl.toFixed(2)} mL`);
    }
  }
}

/**
 * Validate and normalise a scenario.
 * @returns {{ ok: boolean, value?: object, errors: string[] }}
 */
function validateScenario(input) {
  const { error, value } = scenarioSchema.validate(input, { abortEarly: false, stripUnknown: true, convert: true });
  if (error) return { ok: false, errors: error.details.map((d) => d.message.replace(/"/g, "'")) };

  const errors = [];
  const env = catalog.environments[value.environment];
  const { known, prefixes } = scopeFor(value);

  // Equipment: unique ids, valid slots, no slot used twice, subject fits the room.
  const eqById = new Map();
  const slotsUsed = new Map();
  for (const eq of value.equipment) {
    if (eqById.has(eq.id)) errors.push(`equipment: duplicate id "${eq.id}"`);
    eqById.set(eq.id, eq);
    if (!env.slots.includes(eq.slot)) errors.push(`equipment.${eq.id}: slot "${eq.slot}" does not exist in ${value.environment} (${env.slots.join(', ')})`);
    else if (slotsUsed.has(eq.slot) && !eq.slot.startsWith('shelf') && eq.slot !== 'ppe.rack') errors.push(`equipment.${eq.id}: slot "${eq.slot}" already holds "${slotsUsed.get(eq.slot)}"`);
    slotsUsed.set(eq.slot, eq.id);
    const allowedInit = catalog.equipment[eq.type].init;
    for (const k of Object.keys(eq.init)) if (!allowedInit.includes(k)) errors.push(`equipment.${eq.id}: "${k}" is not a setting of ${eq.type} (${allowedInit.join(', ') || 'none'})`);
  }
  if (!env.subjects.includes(value.subject)) errors.push(`subject "${value.subject}" does not belong in ${value.environment}`);

  // Variables: model inputs reference equipment.
  for (const [name, v] of Object.entries(value.variables)) {
    const model = catalog.models[v.model];
    for (const input of model.inputs) {
      if (!v.inputs[input]) errors.push(`variables.${name}: missing input "${input}" for ${v.model}`);
      else if (!eqById.has(v.inputs[input])) errors.push(`variables.${name}: input ${input} → unknown equipment "${v.inputs[input]}"`);
    }
  }

  const checkExpr = (where, src, stepIndex, stepIds) => {
    let refs;
    try { refs = expr.references(src); } catch (e) { errors.push(`${where}: ${e.message}`); return; }
    for (const p of refs.paths) {
      if (known.has(p)) continue;
      const head = p.split('.')[0];
      if (prefixes.has(head) && p.split('.').length === 2) { errors.push(`${where}: "${p}" is never recorded by a measure step`); continue; }
      errors.push(`${where}: unknown value "${p}"`);
    }
    for (const s of refs.steps) {
      const idx = stepIds.indexOf(s);
      if (idx === -1) errors.push(`${where}: done('${s}') refers to an unknown step`);
      else if (stepIndex != null && idx >= stepIndex) errors.push(`${where}: done('${s}') must refer to an earlier step`);
    }
  };

  // Steps
  const stepIds = value.steps.map((s) => s.id);
  const seen = new Set();
  value.steps.forEach((s, i) => {
    const where = `steps.${s.id}`;
    if (seen.has(s.id)) errors.push(`${where}: duplicate step id`);
    seen.add(s.id);
    if (s.kind === 'action' && !s.expect && !s.until) errors.push(`${where}: an action step needs "expect" or "until"`);
    if (s.kind === 'measure' && !s.record) errors.push(`${where}: a measure step needs "record"`);
    if (s.kind === 'checkpoint' && !s.checkpoint) errors.push(`${where}: a checkpoint step needs "checkpoint"`);
    if (s.checkpoint && s.checkpoint.question && s.checkpoint.question.answerIndex >= s.checkpoint.question.choices.length) errors.push(`${where}: answerIndex is outside the choices`);
    if (s.focus && !eqById.has(s.focus)) errors.push(`${where}: focus → unknown equipment "${s.focus}"`);
    if (s.expect) {
      const target = eqById.get(s.expect.target);
      if (!target) errors.push(`${where}: target → unknown equipment "${s.expect.target}"`);
      else if (!catalog.equipment[target.type].intents.includes(s.expect.intent)) {
        errors.push(`${where}: ${target.type} does not support ${s.expect.intent} (${catalog.equipment[target.type].intents.join(', ')})`);
      }
      if (s.expect.into && !eqById.has(s.expect.into)) errors.push(`${where}: into → unknown equipment "${s.expect.into}"`);
    }
    if (s.until) checkExpr(`${where}.until`, s.until, i, stepIds);
    if (s.record) checkExpr(`${where}.record.truth`, s.record.truth, i, stepIds);
  });

  for (const h of value.hazards) checkExpr(`hazards.${h.id}`, h.when, null, stepIds);
  for (const r of value.results) checkExpr(`results.${r.key}`, r.source, null, stepIds);

  const weights = value.scoring.accuracy + value.scoring.procedure + value.scoring.safety;
  if (weights !== 100) errors.push(`scoring: accuracy + procedure + safety must add up to 100 (got ${weights})`);
  if (value.results.length === 0 && value.scoring.accuracy > 0) errors.push('scoring: accuracy is weighted but the scenario has no results to grade');

  checkScience(value, errors);

  return errors.length ? { ok: false, errors } : { ok: true, value, errors: [] };
}

module.exports = { validateScenario, scenarioSchema, SUBJECTS, LEVELS, BUILTINS };
