/**
 * Pure unit tests (no database): expression parser, integrity checks,
 * storyboard validation, captions, subject/experiment detection, figure
 * selection validation, cost rules.
 */
require('./helpers/setup');
const test = require('node:test');
const assert = require('node:assert/strict');

const m = require('../src/utils/mathExpression');
const integrity = require('../src/services/course-builder/integrity.service');
const { validateStoryboard, latexOk } = require('../src/services/video/storyboard.service');
const { buildCaptions } = require('../src/services/video/captions');
const { detectSubject } = require('../src/services/video/subjects');
const { assessExperiment } = require('../src/services/video/experiment');
const { validateSelection } = require('../src/services/course-builder/figure-selection.service');
const cost = require('../src/services/video/cost.service');
const { framesFor, plotSvg } = require('../src/services/video/render/scene-html');

test('expression parser: arithmetic, implicit multiplication, functions, variables', () => {
  assert.equal(m.evaluate('2 + 3 * 4'), 14);
  assert.equal(m.evaluate('(2 + 3) * 4'), 20);
  assert.equal(m.evaluate('2^3^2'), 512);
  assert.equal(m.evaluate('-2^2'), -4);
  assert.equal(m.evaluate('1,000 × 5%'), 50);
  assert.equal(m.evaluate('√(16) + 2(3 + 1)'), 12);
  assert.equal(m.evaluate('2x^2 - 4', { x: 3 }), 14);
  assert.ok(Math.abs(m.evaluate('sin(pi/2)') - 1) < 1e-12);
  assert.throws(() => m.evaluate('2 +'), m.ExpressionError);
  assert.throws(() => m.evaluate('process.exit()'), m.ExpressionError);
  assert.throws(() => m.evaluate('y + 1'), /Unknown variable/);
  assert.equal(m.approximatelyEqual(826.446, '826.45'), true);
  assert.equal(m.approximatelyEqual(826.446, '826.40'), false);
});

test('integrity: arithmetic chains verified, symbolic algebra skipped, errors reported', () => {
  const r = integrity.checkArithmetic('PV = 1000 / (1 + 0.1)^2 = 1000 / 1.21 = 826.45\nSo 5 × 3 = 16. Solve 2x + 3 = 7. Then 4x - 2 + 5 = 9. Total = $1,200 + $300 = $1,500');
  assert.equal(r.issues.length, 1);
  assert.equal(r.issues[0].expression, '5 × 3 = 16');
  assert.equal(r.issues[0].computed, 15);
  assert.ok(r.checked >= 4);
});

test('integrity: formulas, calculation answers and hazards', () => {
  const f = integrity.checkFormulas([
    { name: 'PV', expression: 'PV = FV / (1 + r)^n', variables: [{ symbol: 'r' }, { symbol: 'n' }] },
    { name: 'Broken', expression: 'A = (b + c', variables: [{ symbol: 'z' }] },
  ]);
  assert.equal(f.length, 2);
  assert.match(f[0].problem, /unbalanced/);
  assert.match(f[1].problem, /"z"/);
  const q = integrity.checkCalculationQuestions([
    { type: 'calculation', question: 'PV?', options: ['826.45', '900', '1000', '1210'], correctIndex: 1, explanation: 'PV = 1000/1.21 = 826.45' },
    { type: 'calculation', question: 'ok?', options: ['826.45', '900'], correctIndex: 0, explanation: 'PV = 1000/1.21 = 826.45' },
  ]);
  assert.equal(q.length, 1);
  assert.equal(q[0].index, 0);
  const h = integrity.detectHazards('Heat dilute hydrochloric acid gently with a Bunsen burner. Wear goggles.');
  assert.deepEqual(h.map(x => x.category).sort(), ['chemical', 'heat']);
});

test('storyboard validation: invented figures removed, LaTeX fallback, bad graphs rejected', () => {
  const figures = [{ id: 'fig1', labels: ['burette', 'flask'], usage: ['video_reference', 'animate'] }];
  const raw = {
    title: 'T',
    scenes: [
      { type: 'figure', figureId: 'fig1', highlightLabels: ['burette', 'not-a-label'], narration: 'Look at the burette.' },
      { type: 'figure', figureId: 'made-up-99', narration: 'An invented figure.' },
      { type: 'formula', steps: [{ latex: '\\frac{a}{b', text: 'a/b' }, { latex: 'x = \\pm 2', text: 'x = ±2' }], narration: 'Formula time.' },
      { type: 'graph', graph: { functions: [{ expression: 'x^2 + y' }] }, narration: 'A graph with an unknown variable.' },
      { type: 'graph', graph: { functions: [{ expression: 'y = 2x + 1' }], xMin: 5, xMax: -5 }, narration: 'A line.' },
      { type: 'video_clip', narration: 'Unsupported scene type.' },
      { type: 'bullets', bullets: ['a'] },
    ],
  };
  const { storyboard, warnings, inventedFigureIds } = validateStoryboard(raw, {
    allowedTypes: ['title', 'figure', 'formula', 'graph', 'bullets', 'summary'], figures, lessonTitle: 'Titration',
  });
  const s = storyboard.scenes;
  assert.equal(s[0].type, 'title'); // injected
  assert.equal(s[1].type, 'figure');
  assert.deepEqual(s[1].highlightLabels, ['burette']);
  assert.equal(s[1].animate, true);
  assert.equal(s[2].type, 'bullets'); // invented figure → bullets, narration kept
  assert.deepEqual(inventedFigureIds, ['made-up-99']);
  assert.equal(s[3].steps[0].latex, null);
  assert.equal(s[3].steps[0].text, 'a/b');
  assert.equal(s[3].steps[1].latex, 'x = \\pm 2');
  assert.equal(s[4].type, 'bullets'); // graph with variable y rejected
  assert.equal(s[5].type, 'graph');
  assert.deepEqual([s[5].graph.xMin, s[5].graph.xMax], [-10, 10]); // invalid range replaced
  assert.equal(s[6].type, 'bullets'); // unsupported type
  assert.equal(s.length, 7); // narration-less scene dropped
  assert.ok(warnings.some(w => /unknown figure/.test(w)));
  assert.ok(latexOk('\\sqrt{x}'));
});

test('storyboard validation: experiment observations cannot contain invented numbers; safety + disclosure added', () => {
  const raw = {
    scenes: [
      { type: 'title', heading: 'Titration', narration: 'A titration.' },
      { type: 'experiment', phase: 'observation', items: ['The indicator turns pink', 'The end point is reached at 23.4 cm3', 'About 25 cm3 of acid is used'], narration: 'Watch the colour.' },
      { type: 'summary', bullets: ['done'], narration: 'Done.' },
    ],
  };
  const { storyboard, warnings } = validateStoryboard(raw, {
    allowedTypes: ['title', 'experiment', 'figure', 'formula', 'summary'],
    variant: 'experiment',
    lessonText: 'Pipette 25 cm3 of acid into the flask. The indicator turns pink at the end point.',
    hazards: [{ category: 'chemical', terms: ['acid'] }],
  });
  const obs = storyboard.scenes.find(s => s.phase === 'observation');
  assert.deepEqual(obs.items, ['The indicator turns pink', 'About 25 cm3 of acid is used']);
  assert.ok(storyboard.scenes.some(s => s.phase === 'safety'));
  assert.ok(storyboard.scenes.every(s => /Simulated demonstration/.test(s.disclosure)));
  assert.ok(warnings.some(w => /numbers not found/.test(w)));
});

test('storyboard validation: unbalanced ledgers are flagged', () => {
  const cols = ['Date', 'Account', 'Debit', 'Credit'];
  const ok = validateStoryboard({ scenes: [{ type: 'ledger', heading: 'OK', columns: cols, rows: [['1 Jan', 'Cash', '5,000', ''], ['1 Jan', 'Capital', '', '5,000']], narration: 'Balanced.' }] }, { allowedTypes: ['title', 'ledger'] });
  assert.ok(!ok.warnings.some(w => /does not balance/.test(w)));
  const bad = validateStoryboard({ scenes: [{ type: 'ledger', heading: 'Bad', columns: cols, rows: [['1 Jan', 'Cash', '5,000', ''], ['1 Jan', 'Capital', '', '4,000']], narration: 'Unbalanced.' }] }, { allowedTypes: ['title', 'ledger'] });
  assert.ok(bad.warnings.some(w => /debits 5000 ≠ credits 4000/.test(w)));
});

test('storyboard generation asks once for a fuller script when far below the target length', async () => {
  const { generateStoryboard } = require('../src/services/video/storyboard.service');
  const scene = (words) => ({ type: 'bullets', heading: 'h', bullets: ['a'], narration: Array(words).fill('word').join(' ') + '.' });
  const prompts = [];
  const answers = [
    { scenes: [{ type: 'title', narration: 'Hi.' }, scene(20)] },          // ~10 s
    { scenes: [{ type: 'title', narration: 'Hi.' }, ...Array(6).fill(0).map(() => scene(55))] }, // ~140 s
  ];
  const completeJson = async (p) => { prompts.push(p); return answers[prompts.length - 1]; };
  const input = { lesson: { title: 'L', content: { notes: 'n' } }, subject: 'general', figures: [], variant: 'explainer', lessonText: 'n', durationSec: [100, 180] };
  const r = await generateStoryboard(input, { completeJson });
  assert.equal(prompts.length, 2);
  assert.match(prompts[1], /only about \d+ seconds/);
  assert.ok(r.storyboard.plannedSeconds > 100);

  // If the second answer is not better, the first valid one is kept and flagged.
  const short = [answers[0], { scenes: [{ type: 'title', narration: 'Hi.' }] }];
  let n = 0;
  const r2 = await generateStoryboard(input, { completeJson: async () => short[n++] });
  assert.ok(r2.storyboard.plannedSeconds < 50);
  assert.ok(r2.warnings.some(w => /shorter than the target/.test(w)));
});

test('captions: cues cover every scene, timestamps ordered, valid WebVTT', () => {
  const scenes = [{ narration: 'First sentence. Second sentence here.' }, { narration: 'Another scene with a much longer sentence that will need to be split into more than one caption cue because it is long.' }];
  const { vtt, cues, transcript } = buildCaptions(scenes, [5, 8]);
  assert.ok(vtt.startsWith('WEBVTT'));
  assert.ok(cues.length >= 4);
  for (let i = 1; i < cues.length; i++) assert.ok(cues[i].start >= cues[i - 1].start);
  assert.ok(cues[cues.length - 1].end <= 13.0001);
  assert.match(vtt, /00:00:00\.200 --> /);
  assert.match(transcript, /First sentence/);
});

test('subjects and experiment detection', () => {
  assert.equal(detectSubject('Mathematics', 'Algebra Book').key, 'mathematics');
  assert.equal(detectSubject('CPA Financial Accounting').key, 'accounting');
  assert.equal(detectSubject('Senior 4 Chemistry').key, 'chemistry');
  assert.equal(detectSubject('Kinyarwanda grammar').key, 'languages');
  assert.equal(detectSubject('Something else').key, 'general');
  const chem = assessExperiment('chemistry', { notes: 'In this experiment use a burette and a conical flask. Procedure: titrate the hydrochloric acid. Observe the colour change of the indicator.', examples: [] });
  assert.equal(chem.experiment, true);
  assert.equal(chem.reviewRequired, true);
  assert.ok(chem.hazards.length > 0);
  const maths = assessExperiment('mathematics', { notes: 'experiment procedure apparatus observe', examples: [] });
  assert.equal(maths.experiment, false);
});

test('figure selection: only real candidate ids survive; missing ones get heuristic usage', () => {
  const candidates = [{ _id: 'a1', caption: 'Figure 1.1', quality: 'ok' }, { _id: 'a2', caption: null, quality: 'needs_review' }];
  const { selection, invented } = validateSelection([
    { id: 'a1', usage: ['notes', 'bogus'], reason: 'r' },
    { id: 'zzz', usage: ['notes'] },
  ], candidates);
  assert.equal(invented, 1);
  assert.deepEqual(selection.find(s => s.id === 'a1').usage, ['notes']);
  assert.deepEqual(selection.find(s => s.id === 'a2').usage, ['exclude']);
  assert.equal(selection.length, 2);
});

test('cost: paid TTS without a configured price is refused', () => {
  delete process.env.VIDEO_TTS_COST_PER_1K_CHARS;
  const paid = { name: 'elevenlabs', paid: true, costPer1kChars: () => null };
  assert.throws(() => cost.ttsCost(paid, 1000), (e) => e.code === 'BUDGET_RATE_MISSING' && e.retryable === false);
  assert.equal(cost.ttsCost({ paid: false }, 5000), 0);
  assert.equal(cost.ttsCost({ name: 'x', paid: true, costPer1kChars: () => 0.3 }, 2000), 0.6);
  assert.deepEqual(cost.limits({ options: { videoBudgetUsd: 5 } }).perCourse, 5);
});

test('renderer frame plans and deterministic graph SVG', () => {
  assert.equal(framesFor({ type: 'bullets', bullets: ['a', 'b', 'c'] }).length, 3);
  assert.equal(framesFor({ type: 'figure', highlightLabels: ['x', 'y'] }).length, 3);
  const a = plotSvg({ functions: [{ expression: 'x^2 - 4', label: 'y' }], points: [], xMin: -4, xMax: 4, yMin: null, yMax: null });
  const b = plotSvg({ functions: [{ expression: 'x^2 - 4', label: 'y' }], points: [], xMin: -4, xMax: 4, yMin: null, yMax: null });
  assert.equal(a.svg, b.svg); // same input → identical output
  assert.match(a.svg, /<path d="M/);
});
