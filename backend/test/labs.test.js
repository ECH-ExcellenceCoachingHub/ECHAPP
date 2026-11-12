/**
 * Virtual labs: expression language, science models (golden values shared with
 * the Unity C# tests), scenario validation, scoring, lab-token isolation,
 * the AI builder's repair loop and the full HTTP flow
 * (session → attempt → autosave → completion → lesson progress + XP).
 *
 * No network: Firebase token checks and the AI are stubbed.
 */
const { startDb, stopDb, oid, silenceLogs } = require('./helpers/setup');
const test = require('node:test');
const assert = require('node:assert/strict');

process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-jwt-secret';

// protect() tries Firebase first; make that fail fast and offline.
const admin = require('../src/config/firebase');
Object.defineProperty(admin, 'auth', { configurable: true, writable: true, value: () => ({ verifyIdToken: async () => { throw new Error('not a firebase token'); } }) });

const express = require('express');
const expr = require('../src/services/labs/expression');
const sim = require('../src/services/labs/sim');
const { validateScenario } = require('../src/services/labs/validator');
const { scoreAttempt, gradeResult } = require('../src/services/labs/scoring.service');
const { signLabToken, verifyLabToken } = require('../src/services/labs/token.service');
const { loadSeedDefinitions } = require('../src/services/labs/seed.service');
const generator = require('../src/services/labs/generator.service');
const ai = require('../src/services/course-builder/ai.service');
const { generateToken } = require('../src/utils/jwt.utils');
const User = require('../src/models/User');
const Course = require('../src/models/Course');
const Section = require('../src/models/Section');
const Lesson = require('../src/models/Lesson');
const Enrollment = require('../src/models/Enrollment');
const LabAttempt = require('../src/models/LabAttempt');

const titration = () => JSON.parse(JSON.stringify(require('../src/services/labs/scenarios/chem-titration-hcl-naoh.json')));
const close = (a, b, eps = 1e-3) => assert.ok(Math.abs(a - b) <= eps, `${a} ≉ ${b}`);

let restoreLogs;
let server;
let base;
const originalCompleteJson = ai.completeJson;

test.before(async () => {
  restoreLogs = silenceLogs();
  await startDb();
  const app = express();
  app.use(express.json());
  app.use('/api/labs', require('../src/routes/lab.routes'));
  await new Promise((resolve) => { server = app.listen(0, resolve); });
  base = `http://127.0.0.1:${server.address().port}/api/labs`;
});

test.after(async () => {
  ai.completeJson = originalCompleteJson;
  await new Promise((r) => server.close(r));
  await stopDb();
  restoreLogs();
});

async function api(method, path, { token, body } = {}) {
  const res = await fetch(base + path, {
    method,
    headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: res.status, body: await res.json() };
}

// ─── Expression language ──────────────────────────────────────────────────────

test('expressions: precedence, paths, functions, done()', () => {
  const scope = { burette1: { volumeMl: 49.5, filled: true }, titr: { pH: 8.4 }, record: { a: 20.1, b: 0.05 }, $done: new Set(['s1']) };
  assert.equal(expr.evaluate('1 + 2 * 3', scope), 7);
  assert.equal(expr.evaluate('(1 + 2) * 3', scope), 9);
  assert.equal(expr.evaluate('burette1.filled && burette1.volumeMl >= 49', scope), true);
  assert.equal(expr.evaluate('!burette1.filled || titr.pH < 8.2', scope), false);
  assert.equal(expr.evaluate('round(record.a - record.b, 2)', scope), 20.05);
  assert.equal(expr.evaluate('between(titr.pH, 8.2, 10)', scope), true);
  assert.equal(expr.evaluate("done('s1') && !done('s2')", scope), true);
  assert.equal(expr.evaluate('missing.value > 0', scope), false, 'unknown paths read as 0/undefined');
  assert.equal(expr.evaluate('5 / 0', scope), 0, 'no Infinity');
  assert.equal(expr.evaluate("'pink' == 'pink'", scope), true);
  assert.equal(expr.evaluate('-2 * -3', scope), 6);
});

test('expressions: rejects anything outside the grammar', () => {
  for (const bad of ['', 'a +', 'foo(1)', 'a = 1', 'a[0]', 'constructor.constructor("x")()', "done(x)", '1..2', 'a.', '"open', 'a ? b : c', 'x'.repeat(401)]) {
    assert.throws(() => expr.parse(bad), expr.ExprError, bad);
  }
  assert.deepEqual(expr.references("a.b > 1 && done('s3') || max(c.d, 2)"), { paths: ['a.b', 'c.d'], steps: ['s3'] });
  // No prototype access through paths.
  assert.equal(expr.evaluate('x.constructor', { x: {} }), undefined);
});

// ─── Science (golden values — keep identical to labs-unity Tests/SimTests.cs) ─

test('science: acid–base titration curve', () => {
  const t = (acid, v) => sim.titration({ acid, acidConc: 0.1, acidVolumeMl: 25, baseConc: 0.125, baseAddedMl: v });
  close(t('HCl', 0).pH, 1.000);
  close(t('HCl', 10).pH, 1.447);
  close(t('HCl', 20).pH, 7.000);
  close(t('HCl', 20.1).pH, 10.443);
  close(t('HCl', 25).pH, 12.097);
  close(t('HCl', 0).equivalenceVolumeMl, 20.0);
  close(t('CH3COOH', 0).pH, 2.875);
  close(t('CH3COOH', 10).pH, 4.745); // half-equivalence: pH = pKa
  close(t('CH3COOH', 20).pH, 8.745);
  assert.equal(sim.indicatorColorIndex('phenolphthalein', 7), 0);
  assert.equal(sim.indicatorColorIndex('phenolphthalein', 11), 1);
  close(sim.indicatorColorIndex('phenolphthalein', 9.1), 0.5);
});

test('science: pendulum and circuits', () => {
  close(sim.pendulumPeriod({ lengthM: 0.8 }).theoreticalPeriodS, 1.7946);
  close(sim.pendulumPeriod({ lengthM: 0.8, amplitudeDeg: 5 }).periodS, 1.7954);
  const c = sim.seriesCircuit({ voltageV: 6, resistorsOhm: [47] });
  close(c.currentA, 0.12766);
  close(c.powerW, 0.76596);
  close(sim.parallel([100, 100]), 50);
  assert.equal(sim.seriesCircuit({ voltageV: 6, resistorsOhm: [] }).shortCircuit, true);
});

// ─── Validation ───────────────────────────────────────────────────────────────

test('all built-in labs are valid', () => {
  const defs = loadSeedDefinitions();
  assert.ok(defs.length >= 3);
  for (const d of defs) assert.equal(validateScenario(d).ok, true, d.id);
});

test('validator catches broken labs with useful messages', () => {
  const s = titration();
  s.equipment.push({ id: 'burette1', type: 'burette', slot: 'nowhere' });
  s.steps[0].expect = { intent: 'Pour', target: 'goggles1' };
  s.steps[1].until = "flask1.colour == 'pink'";
  s.steps[2].until = "done('conc')";
  s.hazards.push({ id: 'h', when: 'burette1.volumeMl >', message: 'x' });
  s.results[0].expected = 25; // wrong chemistry: the titre is 20.00 cm³
  s.scoring.safety = 30;
  const { ok, errors } = validateScenario(s);
  assert.equal(ok, false);
  const has = (re) => assert.ok(errors.some((e) => re.test(e)), `missing ${re} in\n${errors.join('\n')}`);
  has(/duplicate id "burette1"/);
  has(/slot "nowhere" does not exist/);
  has(/goggles does not support Pour/);
  has(/unknown value "flask1.colour"/);
  has(/done\('conc'\) must refer to an earlier step/);
  has(/hazards.h: Unexpected end/);
  has(/expected 25 but the chemistry gives 20.00/);
  has(/must add up to 100/);
});

// ─── Scoring ──────────────────────────────────────────────────────────────────

test('scoring: perfect run, sloppy run, unsafe run', () => {
  const def = validateScenario(titration()).value;
  const all = def.steps.map((s) => s.id);
  const perfect = scoreAttempt(def, { completedSteps: all, records: { titre: 20.0, hclConc: 0.1 }, checkpoints: [{ stepId: 'why', correct: true }] });
  assert.deepEqual(perfect.score, { accuracy: 100, procedure: 100, safety: 100, total: 100 });
  assert.equal(perfect.passed, true);

  const sloppy = scoreAttempt(def, { completedSteps: all, records: { titre: 20.5, hclConc: 0.1025 }, checkpoints: [{ stepId: 'why', correct: false }], hintsUsed: 3 });
  assert.ok(sloppy.score.accuracy < 100 && sloppy.score.accuracy > 0);
  assert.equal(sloppy.score.procedure, Math.round(((def.steps.reduce((s, x) => s + x.points, 0) - 10) / def.steps.reduce((s, x) => s + x.points, 0)) * 100) - 6);

  const unsafe = scoreAttempt(def, { completedSteps: all, records: { titre: 20.0, hclConc: 0.1 }, checkpoints: [{ stepId: 'why', correct: true }], hazardsTriggered: [{ id: 'noGoggles' }, { id: 'noGoggles' }, { id: 'overshoot' }] });
  assert.equal(unsafe.score.safety, 75, 'each hazard counts once');

  const unfinished = scoreAttempt(def, { completedSteps: all.slice(0, 3) });
  assert.equal(unfinished.passed, false);
  assert.equal(gradeResult(20.3, 20, 1.5), 100);
  assert.equal(gradeResult(21, 20, 1.5), 0);
});

// ─── Tokens ───────────────────────────────────────────────────────────────────

test('lab tokens are not account logins (and vice versa)', () => {
  const lab = signLabToken({ userId: oid() });
  assert.equal(verifyLabToken(lab).scope, 'lab');
  const { verifyToken } = require('../src/utils/jwt.utils');
  assert.throws(() => verifyToken(lab), 'protect() must reject lab tokens');
  assert.throws(() => verifyLabToken(generateToken({ id: String(oid()) })));
});

// ─── AI builder ───────────────────────────────────────────────────────────────

test('AI builder: subject routing and repair loop', async () => {
  assert.equal(generator.labSubjectFor('Titration of hydrochloric acid with sodium hydroxide in chemistry'), 'chemistry');
  assert.equal(generator.labSubjectFor('Configuring firewall rules against phishing'), 'cybersecurity');
  assert.equal(generator.labSubjectFor('Subnetting an IP address'), 'networking');
  assert.equal(generator.labSubjectFor('The history of Rwanda'), null);

  const good = titration();
  const broken = { ...titration(), scoring: { accuracy: 50, procedure: 50, safety: 50 } };
  const prompts = [];
  ai.completeJson = async (prompt) => { prompts.push(prompt); return prompts.length === 1 ? broken : good; };
  const out = await generator.generateScenario({ title: 'Titration', notes: 'Chemistry titration of HCl with NaOH using a burette.' });
  assert.equal(out.ok, true, out.errors.join('\n'));
  assert.equal(out.rounds, 2);
  assert.match(prompts[1], /PREVIOUS ANSWER WAS INVALID[\s\S]*must add up to 100/);

  const none = await generator.generateScenario({ title: 'Poetry', notes: 'Rhymes and metre' });
  assert.equal(none.ok, false);
});

// ─── HTTP flow ────────────────────────────────────────────────────────────────

test('HTTP: student plays a lab from a lesson; teacher authoring is protected', async () => {
  const student = await User.create({ fullName: 'Aline Student', email: 'aline@test.rw', password: 'secret123', role: 'student', isActive: true });
  const teacher = await User.create({ fullName: 'Teacher', email: 't@test.rw', password: 'secret123', role: 'instructor', isActive: true });
  const sTok = generateToken({ id: String(student._id) });
  const tTok = generateToken({ id: String(teacher._id) });
  const course = await Course.create({ title: 'Chemistry S4', description: 'Chem', createdBy: teacher._id, price: 0, duration: 10, level: 'beginner' });
  const section = await Section.create({ courseId: course._id, title: 'Acids', order: 0 });
  const lesson = await Lesson.create({ courseId: course._id, sectionId: section._id, title: 'Titration', order: 0 });
  await Lesson.create({ courseId: course._id, sectionId: section._id, title: 'Salts', order: 1 });
  await Enrollment.create({ userId: student._id, courseId: course._id });

  // Catalog is public, scenarios need a login and get seeded on first list.
  assert.equal((await api('GET', '/catalog')).status, 200);
  assert.equal((await api('GET', '/scenarios')).status, 401);
  const list = await api('GET', '/scenarios', { token: sTok });
  assert.equal(list.status, 200);
  const card = list.body.data.find((s) => s.slug === 'chem-titration-hcl-naoh');
  assert.ok(card && card.stepCount === 13);

  // Students cannot author; teachers attach the lab to the lesson.
  assert.equal((await api('PUT', `/lessons/${lesson._id}/lab`, { token: sTok, body: { scenarioId: card.id } })).status, 403);
  assert.equal((await api('PUT', `/lessons/${lesson._id}/lab`, { token: tTok, body: { scenarioId: card.slug, required: true } })).status, 200);

  // Flutter asks for a session → lab token for Unity.
  const session = await api('POST', '/session', { token: sTok, body: { scenarioId: card.id, lessonId: String(lesson._id) } });
  assert.equal(session.status, 200);
  const labTok = session.body.data.labToken;
  assert.match(session.body.data.webUrl, /#token=/);
  assert.equal((await api('POST', '/session', { token: labTok, body: { scenarioId: card.id } })).status, 401, 'lab token cannot mint sessions');

  // Unity downloads the definition and starts an attempt with the lab token.
  const scenario = await api('GET', `/scenarios/${card.slug}`, { token: labTok });
  assert.equal(scenario.body.data.definition.steps[0].id, 'ppe1');
  const clientId = '8a6f1c2e-1111-4222-8333-123456789abc';
  const started = await api('POST', '/attempts', { token: labTok, body: { clientId, platform: 'android', mode: 'cardboard', qualityTier: 'low' } });
  assert.equal(started.status, 201);
  assert.equal(started.body.data.lessonId, String(lesson._id));
  assert.equal((await api('POST', '/attempts', { token: labTok, body: { clientId } })).status, 200, 'idempotent for offline retries');

  // Autosave with junk mixed in: unknown steps/records/hazards are dropped; correctness is decided server-side.
  const steps = scenario.body.data.definition.steps.map((s) => s.id);
  const saved = await api('PATCH', `/attempts/${clientId}`, { token: labTok, body: { completedSteps: [...steps.slice(0, 4), 'hacked'], records: { titre: 20.0, evil: 1 }, checkpoints: [{ stepId: 'why', choice: 2, correct: true }], hazardsTriggered: [{ id: 'nope' }] } });
  assert.equal(saved.status, 200);
  assert.deepEqual(saved.body.data.attempt.completedSteps, steps.slice(0, 4));
  assert.deepEqual(saved.body.data.attempt.records, { titre: 20.0 });
  assert.equal(saved.body.data.attempt.checkpoints[0].correct, false, 'client claim of correct is ignored');

  // Finish the lab.
  const done = await api('PATCH', `/attempts/${clientId}`, { token: labTok, body: { completedSteps: steps, records: { initialReading: 0.5, finalReading: 20.5, titre: 20.0, hclConc: 0.1 }, checkpoints: [{ stepId: 'why', choice: 0 }], durationSec: 900, complete: true } });
  assert.equal(done.status, 200);
  const outcome = done.body.data.outcome;
  assert.equal(outcome.passed, true);
  assert.equal(outcome.score.total, 100);
  assert.equal(outcome.xpAwarded, 150);
  assert.ok(outcome.newBadges.includes('first-experiment') && outcome.newBadges.includes('safety-champion'));
  assert.equal(outcome.lesson.updated, true);
  assert.equal(outcome.lesson.progress, 50);

  const enrollment = await Enrollment.findOne({ userId: student._id, courseId: course._id });
  assert.deepEqual(enrollment.completedLessons.map(String), [String(lesson._id)]);

  // A second pass gives no extra XP.
  const clientId2 = '8a6f1c2e-2222-4222-8333-123456789abc';
  await api('POST', '/attempts', { token: labTok, body: { clientId: clientId2 } });
  const again = await api('PATCH', `/attempts/${clientId2}`, { token: labTok, body: { completedSteps: steps, records: { titre: 20.0, hclConc: 0.1 }, checkpoints: [{ stepId: 'why', choice: 0 }], complete: true } });
  assert.equal(again.body.data.outcome.xpAwarded, 0);

  const summary = await api('GET', '/me/summary', { token: sTok });
  assert.equal(summary.body.data.xp, 150);
  assert.deepEqual(summary.body.data.scenarios[card.id], { best: 100, passed: true, attempts: 2 });

  // Rooms list their activities from Beginner to Expert, with hint counts for the UI.
  const room = await api('GET', '/scenarios?environment=ChemLab', { token: sTok });
  const levels = room.body.data.map((s) => s.difficulty);
  assert.deepEqual(levels, [...levels].sort((a, b) => a - b));
  assert.ok(levels[0] === 1 && levels[levels.length - 1] === 5);
  assert.ok(room.body.data.every((s) => s.environment === 'ChemLab' && s.hintCount >= 0 && Array.isArray(s.objectives)));
  assert.equal(summary.body.data.bySubject.chemistry.passed, 1);
  assert.equal(await LabAttempt.countDocuments({ userId: student._id }), 2);
});

test('HTTP: headset pairing hands over a lab token exactly once', async () => {
  const student = await User.create({ fullName: 'VR Student', email: 'vr@test.rw', password: 'secret123', role: 'student', isActive: true });
  const sTok = generateToken({ id: String(student._id) });
  const start = await api('POST', '/pair/start', { body: { deviceName: 'Meta Quest 3' } });
  assert.equal(start.status, 201);
  assert.match(start.body.data.code, /^\d{6}$/);
  const secret = start.body.data.deviceSecret;
  assert.equal((await api('POST', '/pair/poll', { body: { deviceSecret: secret } })).body.data.status, 'pending');
  assert.equal((await api('POST', '/pair/confirm', { token: sTok, body: { code: '000000x' } })).status, 404);
  assert.equal((await api('POST', '/pair/confirm', { token: sTok, body: { code: start.body.data.code, scenarioId: 'phys-pendulum' } })).status, 200);
  const paired = await api('POST', '/pair/poll', { body: { deviceSecret: secret } });
  assert.equal(paired.body.data.status, 'paired');
  assert.equal(verifyLabToken(paired.body.data.labToken).sub, String(student._id));
  assert.equal((await api('POST', '/pair/poll', { body: { deviceSecret: secret } })).status, 410);
});
