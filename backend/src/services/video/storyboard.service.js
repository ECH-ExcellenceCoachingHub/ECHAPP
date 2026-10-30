const katex = require('katex');
const { parse: parseExpression } = require('../../utils/mathExpression');
const { SCENE_TYPES, EXPERIMENT_SCENES, HANDS_ON_PHASES, subjectByKey } = require('./subjects');
const { SIMULATION_DISCLOSURE } = require('./experiment');

/**
 * Teaching script + scene-by-scene storyboard for one lesson video.
 *
 * The planning model only *describes* scenes as structured JSON. Every visual
 * that must be exact (formulas, graphs, numbers, figures) is rendered later by
 * deterministic code, and this module validates the plan first:
 *   - LaTeX must compile with KaTeX (otherwise the plain-text form is used)
 *   - graph expressions must parse (otherwise the scene becomes bullets)
 *   - figure ids must be real FigureAsset ids offered to the planner
 *   - experiment observations may only quote numbers found in the lesson
 */

const WORDS_PER_SECOND = 2.0; // slow, beginner-friendly narration
const MAX_SCENES = 14;
const MAX_CHECKS = 3;
const MEDIA_SCENES_HINT = '3-5';
// Searched when no clip matches the scene's own phrase, so a step still shows real lab work.
const GENERIC_LAB = {
  apparatus: 'laboratory equipment glassware',
  setup: 'scientist preparing laboratory experiment',
  procedure: 'scientist doing laboratory experiment',
  observation: 'laboratory experiment reaction',
};
const CHECKS_HINT = '1-2';
const NOTES_CHARS = 7000;
const MAX_FORMULA_STEPS = 6;
const MAX_WORKED_STEPS = 7;

function wordCount(s) {
  return String(s || '').trim().split(/\s+/).filter(Boolean).length;
}

function estimateSeconds(narration) {
  return Math.max(3, wordCount(narration) / WORDS_PER_SECOND);
}

function sceneSpec(types) {
  const all = {
    title: '{ "type": "title", "heading": "lesson title", "subtitle": "one line hook", "narration": "..." }',
    bullets: '{ "type": "bullets", "heading": "...", "bullets": ["max 5 short points"], "narration": "..." }',
    formula: '{ "type": "formula", "heading": "...", "steps": [ { "latex": "PV = \\\\frac{FV}{(1+r)^n}", "text": "PV = FV / (1 + r)^n", "explanation": "what changed in this step", "say": "what the teacher says while THIS line appears (1-3 short sentences)" } ], "highlight": ["r"], "narration": "short introduction, said before the first line" }',
    graph: '{ "type": "graph", "heading": "...", "graph": { "functions": [ { "expression": "x^2 - 4", "label": "y = x^2 - 4" } ], "xMin": -5, "xMax": 5, "yMin": -6, "yMax": 10, "points": [ { "x": 2, "y": 0, "label": "root" } ] }, "narration": "..." }   // expression in x only, plain math syntax',
    figure: '{ "type": "figure", "heading": "...", "figureId": "<one of the AVAILABLE FIGURES ids>", "highlightLabels": ["exact label text from that figure"], "narration": "..." }',
    worked_example: '{ "type": "worked_example", "heading": "...", "problem": "...", "steps": [ { "text": "...", "latex": "optional", "say": "what the teacher says while THIS line appears (1-3 short sentences)" } ], "answer": "...", "answerSay": "one or two sentences stating the answer", "narration": "short introduction: read the problem aloud" }',
    table: '{ "type": "table", "heading": "...", "columns": ["..."], "rows": [["..."]], "narration": "..." }   // max 8 rows',
    ledger: '{ "type": "ledger", "heading": "Journal entry", "columns": ["Date","Account","Debit","Credit"], "rows": [["...","...","...","..."]], "narration": "..." }',
    timeline: '{ "type": "timeline", "heading": "...", "events": [ { "label": "1994", "detail": "..." } ], "narration": "..." }',
    flow: '{ "type": "flow", "heading": "...", "steps": [ { "label": "...", "detail": "..." } ], "narration": "..." }',
    dialogue: '{ "type": "dialogue", "heading": "...", "lines": [ { "speaker": "A", "text": "...", "translation": "optional" } ], "narration": "..." }',
    experiment: '{ "type": "experiment", "phase": "apparatus | safety | setup | procedure | observation | explanation | conclusion | questions", "heading": "...", "items": ["..."], "narration": "..." }',
    summary: '{ "type": "summary", "heading": "Key takeaways", "bullets": ["..."], "narration": "..." }',
    media: '{ "type": "media", "heading": "short title", "points": ["max 3 very short key points"], "media": { "query": "2-5 concrete words naming what is visible", "kind": "video | image", "alternatives": ["simpler search words"] }, "narration": "..." }',
    check: '{ "type": "check", "question": "...", "choices": ["2 to 4 short options"], "answerIndex": 0, "explanation": "why the answer is right, from the lesson", "narration": "asks the question and invites the learner to pause and think", "answerNarration": "reveals and explains the answer" }',
  };
  return types.map(t => `  ${all[t]}`).join(',\n');
}

function buildPrompt({ lesson, subject, level, language, durationSec, figures, variant, experimentInfo }) {
  const s = subjectByKey(subject);
  const types = variant === 'experiment' ? EXPERIMENT_SCENES : s.scenes;
  const c = lesson.content || {};
  const figureList = figures.length
    ? figures.map(f => `- id: ${f.id} | page ${f.page} | ${f.caption || 'no caption'} | labels: ${(f.labels || []).slice(0, 15).join(', ') || '-'} | use: ${f.usage.join('/')}`).join('\n')
    : '(none — do not use "figure" scenes)';

  const experimentRules = variant === 'experiment' ? `
THIS IS AN EXPERIMENT DEMONSTRATION VIDEO (simulated, not real footage).
- Cover, in order: apparatus & materials, safety precautions, set-up, step-by-step procedure, observations, scientific explanation (with equations), conclusion, questions for learners.
- Use ONLY the procedure, apparatus and observations described in the LESSON. Never invent a procedure, quantities or measurements.
- Observations: describe what the lesson says will be observed. Do not state numeric results unless that exact number appears in the lesson.
- Safety: age-appropriate precautions for every hazard (${(experimentInfo?.hazards || []).map(h => h.category).join(', ') || 'none detected'}). Never suggest unsafe shortcuts.` : '';

  return `Plan a short TEACHING video for one lesson. It must teach — explain, show and check understanding — not just read slides.

SUBJECT: ${s.key}
LEVEL: ${level || 'general'}
LANGUAGE OF NARRATION AND ON-SCREEN TEXT: ${language || 'English'}
TARGET LENGTH: ${durationSec[0]}-${durationSec[1]} seconds in total (about ${Math.round(durationSec[0] * WORDS_PER_SECOND)}-${Math.round(durationSec[1] * WORDS_PER_SECOND)} spoken words). Fewer, richer scenes beat many thin ones.

SUBJECT GUIDANCE: ${s.guidance}
${experimentRules}

RULES:
- Use ONLY facts, numbers, formulas and examples from the LESSON below.
- "narration" is what the narrator says: natural spoken sentences, usually 3-6 per scene, that EXPLAIN (why, how, what to notice), not just read the screen. On-screen text is short.
- NARRATOR = a warm, experienced classroom teacher talking to one student. Signpost ("First…", "Now notice…", "So what does this tell us?"), ask a short rhetorical question before an important idea, link ideas to everyday life the student knows, and recap in one sentence at the end of a scene. Short sentences; commas and full stops where a teacher would pause. No filler, no "In this scene" or "As you can see on the screen".
- AUDIENCE: beginners, both in this topic and in English. Teach slowly, like a patient teacher at the board:
  * simple everyday English words; sentences of at most 15 words; one idea per sentence;
  * explain every new word the first time you use it;
  * in "formula" and "worked_example" scenes give EVERY step a "say": the teacher explains that line only (what we do, why, and the result) while it appears on the board;
  * after an important result, repeat it once in a short recap ("So, x squared is sixteen.");
  * never do two calculations in one sentence.
- Narration is read aloud by a voice engine: write numbers, units and symbols the way a teacher says them ("five plants per square metre", "x squared", "twenty-five divided by five"), never "m²", "x^2" or "25/5".
- Start with a "title" scene and end with a "summary" scene.
- At most ${MAX_SCENES} scenes. Allowed scene types: ${types.join(', ')}.
- At most ${MAX_FORMULA_STEPS} steps per "formula" scene and ${MAX_WORKED_STEPS} per "worked_example" scene. Continue longer working in the next scene instead of skipping lines.
- figure scenes may only use ids from AVAILABLE FIGURES; "highlightLabels" must be copied from that figure's labels.
- LaTeX: valid KaTeX syntax, escape backslashes for JSON. Always also give "text" (plain form).
- Every scene may also have "sourcePages": [page numbers from the lesson sources] and "transition": "fade" | "cut".
${types.includes('media') && s.mediaOptional ? `- REAL-WORLD MEDIA (OPTIONAL): a "media" scene shows a licensed photo or clip found from a short search phrase ("media": { "query": "2-5 concrete words", "kind": "image" }). Use one only when the LESSON itself describes a real-world situation or application; otherwise use no media at all. Never invent applications, and never use media for formulas, graphs, tables or numbers.` : ''}
${types.includes('media') && !s.mediaOptional ? `- REAL-WORLD MEDIA (REQUIRED): licensed photos and video clips are searched for you from a short phrase, so the video SHOWS what the narration talks about (organisms, places, apparatus, people doing the activity). You MUST include:
  1. a "media" field on the "title" scene;
  2. at least 2 scenes of type "media" (real-world context between the explanations);
  3. a "media" field on every "bullets" scene${variant === 'experiment' ? ' and on EVERY apparatus, set-up, procedure and observation "experiment" scene' : ''}.
  In total about ${variant === 'experiment' ? '5-8' : MEDIA_SCENES_HINT} scenes with media.${variant === 'experiment' ? `
  EXPERIMENT CLIPS: the apparatus, set-up, procedure and observation scenes are shown FULL SCREEN over a real video clip, with the steps on top. For each of them use "kind": "video" and a "media.query" naming the hands-on action or apparatus visible in that step ("burette dripping into flask", "heating test tube over flame", "leaf in beaker of boiling water"). Put the experiment's short name ("titration", "starch test", "osmosis") in "alternatives", plus one simpler action ("pouring liquid into beaker").` : ''}
  "media.query" = 2-5 concrete English words naming exactly what should be visible ("quadrat frame on grass", "lake shore wetland"), never abstract ideas ("population density"). "kind": "video" when motion helps, otherwise "image". Give 1-2 simpler "alternatives".
  Never use media for formulas, labelled diagrams, graphs, tables or numbers — those are drawn exactly by the renderer.` : ''}
${types.includes('check') ? `- INTERACTIVE CHECKS: add ${CHECKS_HINT} "check" scenes right after key ideas. The app pauses the video at each one and lets the learner answer. Exactly one choice must be correct, following directly from the lesson; the other choices are plausible misconceptions. Keep the question and choices short.` : ''}

SCENE FORMATS:
[
${sceneSpec(types)}
]

AVAILABLE FIGURES:
${figureList}

LESSON: ${lesson.title}
OBJECTIVES: ${(c.learningObjectives || []).join(' | ')}
SUMMARY: ${c.summary || ''}
KEY TERMS: ${(c.keyTerms || []).slice(0, 12).map(t => `${t.term}: ${t.definition}`).join(' | ')}
FORMULAS: ${(c.formulas || []).map(f => `${f.name}: ${f.expression}`).join(' | ') || '-'}
WORKED EXAMPLES:
${(c.examples || []).slice(0, 2).map(e => `### ${e.title}\n${e.body}`).join('\n\n') || '-'}
NOTES:
${String(c.notes || '').slice(0, NOTES_CHARS)}
SOURCE PAGES: ${[...new Set((c.sources || []).map(x => x.page).filter(Boolean))].join(', ') || '-'}

Return JSON: { "title": "...", "scenes": [ ... ] }`;
}

// ─── Spoken narration ────────────────────────────────────────────────────────

/**
 * The planner is told to write maths the way a teacher says it, but symbols
 * still slip through ("-4", "Δ", "2xy", "x²"). Voice engines read those
 * badly or skip them, so they are turned into words before recording.
 * English only; other languages keep the planner's text.
 */
const SPOKEN = [
  [/√\s*/g, 'the square root of '],
  [/±/g, ' plus or minus '],
  [/∓/g, ' minus or plus '],
  [/[Δ∆δ]/g, 'delta'], [/π/g, 'pi'], [/θ/g, 'theta'], [/α/g, 'alpha'], [/β/g, 'beta'], [/λ/g, 'lambda'], [/σ/g, 'sigma'],
  [/²/g, ' squared'], [/³/g, ' cubed'], [/\^\s*2\b/g, ' squared'], [/\^\s*3\b/g, ' cubed'], [/\^\s*\(?(-?\d+)\)?/g, ' to the power $1'],
  [/≤/g, ' is less than or equal to '], [/≥/g, ' is greater than or equal to '], [/≠/g, ' is not equal to '], [/≈/g, ' is approximately '],
  [/×/g, ' times '], [/÷/g, ' divided by '], [/[→⇒]/g, ' gives '], [/ℂ/g, 'the complex numbers'], [/ℝ/g, 'the real numbers'],
  [/(\d)\s*\/\s*(\d)/g, '$1 over $2'],
  [/\s+=\s+|(?<=[\w)])=(?=[\w(-])/g, ' equals '],
  // A minus sign before a number or a single-letter variable: "-4", "−b", "(−i)".
  [/[\u2010\u2011\u2012]/g, '-'], // hyphen variants the planner sometimes uses as a minus sign
  [/(^|[\s(\[,])[-−–](?=\d|[a-z]\b)/g, '$1minus '],
  [/\)\s*\/\s*(?=[\d(a-z])/g, ') over '],
  [/\s[−-]\s/g, ' minus '],
  [/\s\+\s/g, ' plus '],
  [/\bi([xyz])\b/g, 'i $1'], // "iz" → "i z"
  // A number written against variables: "2xy" → "2 x y", "8i" → "8 i".
  [/\b(\d+)([abcixyz])([abcixyz])?\b/g, (_, n, a, b) => [n, a, b].filter(Boolean).join(' ')],
];

function speakable(text) {
  let s = String(text || '');
  for (const [re, to] of SPOKEN) s = s.replace(re, to);
  return s.replace(/\s{2,}/g, ' ').replace(/\s+([,.;:!?])/g, '$1').trim();
}

// ─── Validation ──────────────────────────────────────────────────────────────

const str = (v, max = 400) => (v == null ? '' : String(v).trim().slice(0, max));
const arr = (v) => (Array.isArray(v) ? v : []);

function latexOk(latex) {
  if (!latex) return false;
  try {
    katex.renderToString(latex, { throwOnError: true, displayMode: true });
    return true;
  } catch (_) {
    return false;
  }
}

/**
 * The planner sometimes packs several equations into one step with only
 * spacing between them ("2x^2=32\;x^2=16\;x=\pm4"), which renders as one
 * confusing line. Separate them visibly with a comma and a gap.
 */
function separateEquations(latex) {
  if (!latex || (latex.match(/=/g) || []).length < 2) return latex;
  // "\," is left alone: it is also the thousands separator ("1\,000").
  return latex.replace(/\s*,?\s*(?:\\[;: ]\s*)+(?=[^=]*=)/g, ',\\quad ');
}

/** Split a list into consecutive groups of at most `size` items. */
function chunks(list, size) {
  const out = [];
  for (let i = 0; i < list.length; i += size) out.push(list.slice(i, i + size));
  return out;
}

function cleanFormulaStep(step, warnings) {
  const latex = separateEquations(str(step?.latex, 300));
  const text = str(step?.text, 300);
  const ok = latexOk(latex);
  if (latex && !ok) warnings.push(`LaTeX did not compile, using plain text: ${latex.slice(0, 60)}`);
  if (!ok && !text) return null;
  return { latex: ok ? latex : null, text: text || latex, explanation: str(step?.explanation, 200), say: str(step?.say, 400) };
}

function cleanGraph(g, warnings) {
  if (!g || typeof g !== 'object') return null;
  const functions = [];
  for (const f of arr(g.functions).slice(0, 3)) {
    const expression = str(f?.expression, 120).replace(/^y\s*=\s*/i, '');
    try {
      const parsed = parseExpression(expression);
      if (parsed.variables.some(v => v !== 'x')) throw new Error(`variables ${parsed.variables.join(',')}`);
      functions.push({ expression, label: str(f?.label, 60) || `y = ${expression}` });
    } catch (e) {
      warnings.push(`Graph expression rejected (${e.message}): ${expression}`);
    }
  }
  const points = arr(g.points).filter(p => Number.isFinite(Number(p?.x)) && Number.isFinite(Number(p?.y)))
    .slice(0, 6).map(p => ({ x: Number(p.x), y: Number(p.y), label: str(p.label, 30) }));
  if (!functions.length && !points.length) return null;
  let xMin = Number(g.xMin); let xMax = Number(g.xMax);
  if (!Number.isFinite(xMin) || !Number.isFinite(xMax) || xMin >= xMax || xMax - xMin > 1e6) { xMin = -10; xMax = 10; }
  let yMin = Number(g.yMin); let yMax = Number(g.yMax);
  if (!Number.isFinite(yMin) || !Number.isFinite(yMax) || yMin >= yMax || yMax - yMin > 1e7) { yMin = null; yMax = null; }
  return { functions, points, xMin, xMax, yMin, yMax };
}

function numbersIn(text) {
  return new Set((String(text || '').match(/\d+(?:[.,]\d+)?/g) || []).map(n => n.replace(',', '.')));
}

/** { query, kind, alternatives } or null. Queries are short concrete search phrases. */
function cleanMedia(m) {
  if (!m || typeof m !== 'object') return null;
  const words = (q) => str(q, 80).replace(/["<>]/g, '').split(/\s+/).filter(Boolean).slice(0, 8).join(' ');
  const query = words(m.query);
  if (!query) return null;
  return {
    query,
    kind: m.kind === 'video' ? 'video' : 'image',
    alternatives: arr(m.alternatives).map(words).filter(q => q && q.toLowerCase() !== query.toLowerCase()).slice(0, 2),
  };
}

function cleanCheck(s, warnings, lessonNumbers) {
  const question = str(s.question, 220);
  const seen = new Set();
  const choices = arr(s.choices).map(c => str(c, 100)).filter(c => c && !seen.has(c.toLowerCase()) && seen.add(c.toLowerCase())).slice(0, 4);
  const answerIndex = Number(s.answerIndex);
  if (!question || choices.length < 2 || !Number.isInteger(answerIndex) || answerIndex < 0 || answerIndex >= choices.length) {
    warnings.push(`Dropped an invalid check question: ${question.slice(0, 60) || '(no question)'}`);
    return null;
  }
  const unknown = [...numbersIn(choices[answerIndex])].filter(n => !lessonNumbers.has(n));
  if (unknown.length) warnings.push(`Check "${question.slice(0, 50)}": answer uses numbers not in the lesson (${unknown.join(', ')}) — review the answer key`);
  const explanation = str(s.explanation, 260);
  return {
    question,
    choices,
    answerIndex,
    explanation,
    answerNarration: str(s.answerNarration, 600) || `The answer is ${choices[answerIndex]}. ${explanation}`.trim(),
  };
}

function cleanTable(columns, rows, maxRows = 8) {
  const cols = arr(columns).map(c => str(c, 40)).slice(0, 6);
  if (cols.length < 2) return null;
  const body = arr(rows).filter(Array.isArray).slice(0, maxRows).map(r => cols.map((_, i) => str(r[i], 60)));
  return body.length ? { columns: cols, rows: body } : null;
}

/**
 * Validate and normalise a planner response.
 * @returns {{storyboard: object, warnings: string[], inventedFigureIds: string[]}}
 */
function validateStoryboard(raw, { allowedTypes, figures = [], variant = 'explainer', lessonText = '', lessonTitle = '', hazards = [], mediaOptional = false, language = 'English' }) {
  const warnings = [];
  const inventedFigureIds = [];
  const figureById = new Map(figures.map(f => [String(f.id), f]));
  const allowed = new Set(allowedTypes || SCENE_TYPES);
  const lessonNumbers = numbersIn(lessonText);
  const scenes = [];

  for (const s of arr(raw?.scenes).slice(0, MAX_SCENES + 4)) {
    if (!s || typeof s !== 'object') continue;
    let type = SCENE_TYPES.includes(s.type) && allowed.has(s.type) ? s.type : null;
    const stepSays = ['formula', 'worked_example'].includes(s.type) ? arr(s.steps).map(st => str(st?.say, 400)).filter(Boolean) : [];
    const narration = str(s.narration, 900);
    if (!narration && !stepSays.length) { warnings.push(`Dropped a ${s.type || 'unknown'} scene without narration`); continue; }
    const base = {
      heading: str(s.heading, 90),
      narration,
      onScreenLabels: arr(s.onScreenLabels).map(l => str(l, 60)).filter(Boolean).slice(0, 4),
      sourcePages: arr(s.sourcePages).map(Number).filter(Number.isFinite).slice(0, 6),
      transition: s.transition === 'cut' ? 'cut' : 'fade',
      visualDescription: str(s.visualDescription, 300),
    };
    let scene = null;

    if (!type) {
      warnings.push(`Scene type "${s.type}" not allowed here — shown as bullet points`);
      type = 'bullets';
    }
    switch (type) {
      case 'title':
        scene = { type, ...base, heading: base.heading || lessonTitle, subtitle: str(s.subtitle, 120), media: cleanMedia(s.media) };
        break;
      case 'bullets':
      case 'summary': {
        const bullets = arr(s.bullets || s.items).map(b => str(b, 120)).filter(Boolean).slice(0, 5);
        scene = { type, ...base, bullets: bullets.length ? bullets : splitSentences(narration).slice(0, 3) };
        if (type === 'bullets') scene.media = cleanMedia(s.media);
        break;
      }
      case 'media': {
        const media = cleanMedia(s.media);
        const points = arr(s.points || s.bullets).map(b => str(b, 80)).filter(Boolean).slice(0, 3);
        scene = media
          ? { type, ...base, points, media }
          : { type: 'bullets', ...base, bullets: points.length ? points : splitSentences(narration).slice(0, 3) };
        break;
      }
      case 'check': {
        const c = cleanCheck(s, warnings, lessonNumbers);
        if (c && scenes.filter(x => x.type === 'check').length >= MAX_CHECKS) {
          warnings.push('More than 3 check questions — extra ones removed');
          scene = 'skip';
        } else {
          scene = c ? { type, ...base, heading: base.heading || 'Quick check', ...c } : 'skip';
        }
        break;
      }
      case 'formula': {
        const all = arr(s.steps).map(st => cleanFormulaStep(st, warnings)).filter(Boolean);
        const spoken = all.length && all.every(st => st.say);
        const highlight = arr(s.highlight).map(h => str(h, 20)).slice(0, 4);
        // Long working continues on a new "board" rather than losing steps.
        scene = chunks(all, MAX_FORMULA_STEPS).map((steps, ci) => {
          const sc = { type, ...base, heading: ci ? `${base.heading} (continued)` : base.heading, steps, highlight };
          // One spoken part per revealed line (the intro goes with the first line).
          if (spoken) sc.parts = steps.map((st, i) => (i === 0 && ci === 0 ? [narration, st.say].filter(Boolean).join(' ') : st.say));
          else if (ci) sc.narration = '';
          return sc;
        });
        if (!scene.length) scene = null;
        break;
      }
      case 'graph': {
        const graph = cleanGraph(s.graph, warnings);
        scene = graph ? { type, ...base, graph } : null;
        break;
      }
      case 'figure': {
        const id = str(s.figureId, 40);
        const fig = figureById.get(id);
        if (!fig) {
          if (id) inventedFigureIds.push(id);
          warnings.push(`Figure scene referenced unknown figure "${id}" — removed`);
          scene = null;
        } else {
          const labels = new Set((fig.labels || []).map(l => l.toLowerCase()));
          const highlightLabels = arr(s.highlightLabels).map(l => str(l, 60)).filter(l => labels.has(l.toLowerCase())).slice(0, 6);
          scene = { type, ...base, figureId: id, highlightLabels, animate: fig.usage?.includes('animate') };
        }
        break;
      }
      case 'worked_example': {
        const steps = arr(s.steps).map(st => {
          const latex = separateEquations(str(st?.latex, 300));
          return { text: str(st?.text || st, 240), latex: latexOk(latex) ? latex : null, say: str(st?.say, 400) };
        }).filter(st => st.text || st.latex);
        const spoken = steps.length && steps.every(st => st.say);
        const problem = str(s.problem, 400);
        const answer = str(s.answer, 160);
        const groups = chunks(steps, MAX_WORKED_STEPS);
        scene = groups.map((part, ci) => {
          const last = ci === groups.length - 1;
          const sc = { type, ...base, heading: ci ? `${base.heading} (continued)` : base.heading, problem, steps: part, answer: last ? answer : '' };
          // Parts follow the reveals: problem, each step, then the answer.
          if (spoken) {
            sc.parts = [ci ? 'Let us continue.' : (narration || 'Let us read the problem carefully.'), ...part.map(st => st.say)];
            if (sc.answer) sc.parts.push(str(s.answerSay, 300) || `So the answer is ${sc.answer}.`);
          } else if (ci) sc.narration = '';
          return sc;
        });
        if (!scene.length) scene = null;
        break;
      }
      case 'table':
      case 'ledger': {
        const t = cleanTable(s.columns, s.rows);
        scene = t ? { type, ...base, ...t } : null;
        if (scene && type === 'ledger') {
          const balance = ledgerBalance(scene);
          if (balance && Math.abs(balance.debit - balance.credit) > 0.005) {
            warnings.push(`Ledger "${scene.heading}" does not balance: debits ${balance.debit} ≠ credits ${balance.credit}`);
          }
        }
        break;
      }
      case 'timeline': {
        const events = arr(s.events).filter(e => e?.label).map(e => ({ label: str(e.label, 30), detail: str(e.detail, 120) })).slice(0, 7);
        scene = events.length >= 2 ? { type, ...base, events } : null;
        break;
      }
      case 'flow': {
        const steps = arr(s.steps).filter(e => e?.label).map(e => ({ label: str(e.label, 40), detail: str(e.detail, 120) })).slice(0, 6);
        scene = steps.length >= 2 ? { type, ...base, steps } : null;
        break;
      }
      case 'dialogue': {
        const lines = arr(s.lines).filter(l => l?.text).map(l => ({ speaker: str(l.speaker, 20) || 'A', text: str(l.text, 160), translation: str(l.translation, 160) })).slice(0, 6);
        scene = lines.length ? { type, ...base, lines } : null;
        break;
      }
      case 'experiment': {
        const phases = ['apparatus', 'safety', 'setup', 'procedure', 'observation', 'explanation', 'conclusion', 'questions'];
        const phase = phases.includes(s.phase) ? s.phase : 'procedure';
        let items = arr(s.items).map(i => str(i, 160)).filter(Boolean).slice(0, 7);
        if (phase === 'observation') {
          // Never present invented measurements as observations.
          const kept = items.filter(i => [...numbersIn(i)].every(n => lessonNumbers.has(n)));
          if (kept.length < items.length) warnings.push(`Removed ${items.length - kept.length} observation(s) with numbers not found in the lesson`);
          items = kept;
          if (!items.length) items = ['Observe and record what happens, as described in your textbook.'];
        }
        const media = phase === 'safety' ? null : cleanMedia(s.media);
        if (media && variant === 'experiment' && HANDS_ON_PHASES.includes(phase)) {
          media.kind = 'video';
          media.generic = GENERIC_LAB[phase];
        }
        scene = items.length ? { type, ...base, phase, items, media } : null;
        break;
      }
      default:
        scene = null;
    }
    if (scene === 'skip') continue; // an unusable question is dropped, not turned into slides
    if (!scene) {
      // Keep the narration — show it as points rather than losing the explanation.
      scene = { type: 'bullets', ...base, bullets: splitSentences(narration).slice(0, 3) };
    }
    if (Array.isArray(scene)) {
      // A continued board without its own narration shares the first board's.
      scene.filter(sc => !sc.narration && !sc.parts).forEach(sc => { sc.narration = 'Let us continue.'; });
      scenes.push(...scene);
    } else scenes.push(scene);
  }

  if (!scenes.length) throw Object.assign(new Error('The storyboard had no usable scenes'), { retryable: true, code: 'EMPTY_STORYBOARD' });
  if (scenes[0].type !== 'title') {
    scenes.unshift({ type: 'title', heading: lessonTitle, subtitle: '', narration: `In this lesson: ${lessonTitle}.`, onScreenLabels: [], sourcePages: [], transition: 'fade' });
  }
  if (scenes[scenes.length - 1].type !== 'summary' && scenes.length > 2) {
    warnings.push('Storyboard had no summary scene');
  }

  // The planner sometimes forgets media. Fall back to the scene heading as the
  // search phrase for a few slides; the relevance gate in the media search
  // still rejects anything that does not match.
  // In an experiment video every hands-on step gets a clip (no minimum to stop at).
  if (allowed.has('media') && !mediaOptional) {
    const MIN_MEDIA = 3;
    const handsOn = (s) => variant === 'experiment' && s.type === 'experiment' && HANDS_ON_PHASES.includes(s.phase);
    let count = scenes.filter(s => s.media).length;
    for (const s of scenes) {
      if (count >= MIN_MEDIA && !handsOn(s)) continue;
      const eligible = (s.type === 'bullets' || (s.type === 'experiment' && ['apparatus', 'setup', 'procedure'].includes(s.phase)) || handsOn(s)) && !s.media;
      const words = (s.heading || '').replace(/[^\p{L}\p{N}\s-]/gu, ' ').split(/\s+/)
        .filter(w => w.length > 2 && !/^(the|and|for|why|how|what|use|using|steps?|key|quick|check|about|with|from|your|our)$/i.test(w));
      if (!eligible || (words.length < 2 && !handsOn(s))) continue;
      const query = words.slice(0, 4).join(' ').toLowerCase();
      s.media = handsOn(s)
        ? { query: query || GENERIC_LAB[s.phase], kind: 'video', alternatives: lessonTitle ? [lessonTitle.toLowerCase().slice(0, 60)] : [], generic: GENERIC_LAB[s.phase], auto: true }
        : { query, kind: 'image', alternatives: [], auto: true };
      count++;
    }
  }

  // Each check becomes two scenes: the question (the app pauses at its end
  // and asks the learner) and the answer reveal, each with its own narration.
  for (let i = scenes.length - 1; i >= 0; i--) {
    const s = scenes[i];
    if (s.type !== 'check') continue;
    const { answerNarration, ...question } = s;
    scenes[i] = question;
    scenes.splice(i + 1, 0, {
      type: 'check_answer', heading: s.heading, question: s.question, choices: s.choices, answerIndex: s.answerIndex,
      explanation: s.explanation, narration: answerNarration, onScreenLabels: [], sourcePages: s.sourcePages, transition: 'cut',
    });
  }

  if (variant === 'experiment') {
    if (hazards.length && !scenes.some(s => s.type === 'experiment' && s.phase === 'safety')) {
      scenes.splice(1, 0, {
        type: 'experiment', phase: 'safety', heading: 'Safety first',
        items: ['Only do this practical with your teacher present.', 'Wear eye protection and follow every instruction in your textbook.', `Hazards in this practical: ${hazards.map(h => h.category).join(', ')}.`],
        narration: 'Before we start, safety. Only carry out this practical with your teacher present, wear eye protection, and follow the precautions in your textbook.',
        onScreenLabels: [], sourcePages: [], transition: 'fade',
      });
      warnings.push('Added a safety scene because the lesson mentions hazards');
    }
    for (const s of scenes) s.disclosure = SIMULATION_DISCLOSURE;
  }

  const english = /^(en|english)\b/i.test(String(language || 'English'));
  for (const s of scenes) {
    if (s.parts) {
      if (english) s.parts = s.parts.map(speakable);
      s.narration = s.parts.join(' ');
    } else if (!s.narration && s.steps) {
      s.narration = s.steps.map(st => st.say).filter(Boolean).join(' ');
    }
    if (english) s.narration = speakable(s.narration);
  }
  scenes.forEach((s, i) => { s.n = i + 1; s.plannedSec = Math.round((estimateSeconds(s.narration) + (s.parts ? s.parts.length - 1 : 0)) * 10) / 10; });
  const totalSec = scenes.reduce((a, s) => a + s.plannedSec, 0);
  return {
    storyboard: { title: str(raw?.title, 120) || lessonTitle, variant, scenes, plannedSeconds: Math.round(totalSec) },
    warnings,
    inventedFigureIds,
  };
}

/** Sum of the Debit and Credit columns of a ledger scene (null if it has no such columns). */
function ledgerBalance(scene) {
  const di = scene.columns.findIndex(c => /^(dr|debit)/i.test(c.trim()));
  const ci = scene.columns.findIndex(c => /^(cr|credit)/i.test(c.trim()));
  if (di < 0 || ci < 0) return null;
  const amount = (v) => {
    const n = parseFloat(String(v || '').replace(/[,\s$£€]/g, '').replace(/^\((.*)\)$/, '-$1'));
    return Number.isFinite(n) ? n : 0;
  };
  const debit = scene.rows.reduce((a, r) => a + amount(r[di]), 0);
  const credit = scene.rows.reduce((a, r) => a + amount(r[ci]), 0);
  return { debit: Math.round(debit * 100) / 100, credit: Math.round(credit * 100) / 100 };
}

function splitSentences(text) {
  return String(text || '').split(/(?<=[.!?])\s+/).map(s => s.trim()).filter(Boolean);
}

/**
 * Ask the planner for a storyboard and validate it. One extra attempt is
 * made when the first answer is unusable.
 */
async function generateStoryboard(input, { completeJson, onUsage }) {
  const subject = subjectByKey(input.subject);
  const allowedTypes = input.variant === 'experiment' ? EXPERIMENT_SCENES : subject.scenes;
  const durationSec = input.durationSec || subject.durationSec;
  const prompt = buildPrompt({ ...input, durationSec });
  const ask = (extra) => completeJson(prompt + extra, {
    maxTokens: 7000,
    temperature: 0.35,
    onUsage,
    system: 'You are an expert teacher and educational video director. You only use facts from the lesson provided. You answer with one valid JSON object.',
  });
  const validate = (raw) => validateStoryboard(raw, {
    allowedTypes,
    figures: input.figures,
    variant: input.variant,
    lessonText: input.lessonText,
    lessonTitle: input.lesson.title,
    hazards: input.experimentInfo?.hazards || [],
    mediaOptional: !!subject.mediaOptional && input.variant !== 'experiment',
    language: input.language,
  });

  let result = null;
  let lastErr;
  for (let attempt = 1; attempt <= 2 && !result; attempt++) {
    try {
      result = validate(await ask(attempt > 1 ? `\n\nYour previous answer was unusable (${lastErr?.message}). Return the full JSON object.` : ''));
    } catch (err) {
      lastErr = err;
      if (err.retryable === false) throw err;
    }
  }
  if (!result) throw lastErr;

  // Much shorter than the target usually means thin explanations: ask once
  // for a fuller version and keep whichever is closer to the target length.
  const minSec = durationSec[0];
  if (result.storyboard.plannedSeconds < minSec * 0.7) {
    try {
      const longer = validate(await ask(`\n\nYour previous storyboard was only about ${result.storyboard.plannedSeconds} seconds of narration. The target is ${durationSec[0]}-${durationSec[1]} seconds. Explain each idea more fully (why it works, what to notice, a quick check question) using only the lesson content, and return the complete JSON again.`));
      const gap = (s) => Math.abs(s.storyboard.plannedSeconds - (durationSec[0] + durationSec[1]) / 2);
      if (gap(longer) < gap(result)) result = longer;
    } catch (_) { /* keep the first valid storyboard */ }
  }
  if (result.storyboard.plannedSeconds < minSec * 0.5) {
    result.warnings.push(`Video is shorter than the target (${result.storyboard.plannedSeconds}s planned, target ${durationSec[0]}-${durationSec[1]}s); the lesson may be thin.`);
  }
  return result;
}

module.exports = { buildPrompt, validateStoryboard, generateStoryboard, estimateSeconds, splitSentences, latexOk, speakable, separateEquations, WORDS_PER_SECOND };
