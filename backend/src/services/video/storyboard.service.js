const katex = require('katex');
const { parse: parseExpression } = require('../../utils/mathExpression');
const { SCENE_TYPES, subjectByKey } = require('./subjects');
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

const WORDS_PER_SECOND = 2.4;
const MAX_SCENES = 14;
const NOTES_CHARS = 7000;

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
    formula: '{ "type": "formula", "heading": "...", "steps": [ { "latex": "PV = \\\\frac{FV}{(1+r)^n}", "text": "PV = FV / (1 + r)^n", "explanation": "what changed in this step" } ], "highlight": ["r"], "narration": "..." }',
    graph: '{ "type": "graph", "heading": "...", "graph": { "functions": [ { "expression": "x^2 - 4", "label": "y = x^2 - 4" } ], "xMin": -5, "xMax": 5, "yMin": -6, "yMax": 10, "points": [ { "x": 2, "y": 0, "label": "root" } ] }, "narration": "..." }   // expression in x only, plain math syntax',
    figure: '{ "type": "figure", "heading": "...", "figureId": "<one of the AVAILABLE FIGURES ids>", "highlightLabels": ["exact label text from that figure"], "narration": "..." }',
    worked_example: '{ "type": "worked_example", "heading": "...", "problem": "...", "steps": [ { "text": "...", "latex": "optional" } ], "answer": "...", "narration": "..." }',
    table: '{ "type": "table", "heading": "...", "columns": ["..."], "rows": [["..."]], "narration": "..." }   // max 8 rows',
    ledger: '{ "type": "ledger", "heading": "Journal entry", "columns": ["Date","Account","Debit","Credit"], "rows": [["...","...","...","..."]], "narration": "..." }',
    timeline: '{ "type": "timeline", "heading": "...", "events": [ { "label": "1994", "detail": "..." } ], "narration": "..." }',
    flow: '{ "type": "flow", "heading": "...", "steps": [ { "label": "...", "detail": "..." } ], "narration": "..." }',
    dialogue: '{ "type": "dialogue", "heading": "...", "lines": [ { "speaker": "A", "text": "...", "translation": "optional" } ], "narration": "..." }',
    experiment: '{ "type": "experiment", "phase": "apparatus | safety | setup | procedure | observation | explanation | conclusion | questions", "heading": "...", "items": ["..."], "narration": "..." }',
    summary: '{ "type": "summary", "heading": "Key takeaways", "bullets": ["..."], "narration": "..." }',
  };
  return types.map(t => `  ${all[t]}`).join(',\n');
}

function buildPrompt({ lesson, subject, level, language, durationSec, figures, variant, experimentInfo }) {
  const s = subjectByKey(subject);
  const types = variant === 'experiment' ? ['title', 'experiment', 'figure', 'formula', 'summary'] : s.scenes;
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
- Start with a "title" scene and end with a "summary" scene.
- At most ${MAX_SCENES} scenes. Allowed scene types: ${types.join(', ')}.
- figure scenes may only use ids from AVAILABLE FIGURES; "highlightLabels" must be copied from that figure's labels.
- LaTeX: valid KaTeX syntax, escape backslashes for JSON. Always also give "text" (plain form).
- Every scene may also have "sourcePages": [page numbers from the lesson sources] and "transition": "fade" | "cut".

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

function cleanFormulaStep(step, warnings) {
  const latex = str(step?.latex, 300);
  const text = str(step?.text, 300);
  const ok = latexOk(latex);
  if (latex && !ok) warnings.push(`LaTeX did not compile, using plain text: ${latex.slice(0, 60)}`);
  if (!ok && !text) return null;
  return { latex: ok ? latex : null, text: text || latex, explanation: str(step?.explanation, 200) };
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
function validateStoryboard(raw, { allowedTypes, figures = [], variant = 'explainer', lessonText = '', lessonTitle = '', hazards = [] }) {
  const warnings = [];
  const inventedFigureIds = [];
  const figureById = new Map(figures.map(f => [String(f.id), f]));
  const allowed = new Set(allowedTypes || SCENE_TYPES);
  const lessonNumbers = numbersIn(lessonText);
  const scenes = [];

  for (const s of arr(raw?.scenes).slice(0, MAX_SCENES + 4)) {
    if (!s || typeof s !== 'object') continue;
    let type = SCENE_TYPES.includes(s.type) && allowed.has(s.type) ? s.type : null;
    const narration = str(s.narration, 900);
    if (!narration) { warnings.push(`Dropped a ${s.type || 'unknown'} scene without narration`); continue; }
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
        scene = { type, ...base, heading: base.heading || lessonTitle, subtitle: str(s.subtitle, 120) };
        break;
      case 'bullets':
      case 'summary': {
        const bullets = arr(s.bullets || s.items).map(b => str(b, 120)).filter(Boolean).slice(0, 5);
        scene = { type, ...base, bullets: bullets.length ? bullets : splitSentences(narration).slice(0, 3) };
        break;
      }
      case 'formula': {
        const steps = arr(s.steps).map(st => cleanFormulaStep(st, warnings)).filter(Boolean).slice(0, 5);
        scene = steps.length ? { type, ...base, steps, highlight: arr(s.highlight).map(h => str(h, 20)).slice(0, 4) } : null;
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
          const latex = str(st?.latex, 300);
          return { text: str(st?.text || st, 240), latex: latexOk(latex) ? latex : null };
        }).filter(st => st.text || st.latex).slice(0, 7);
        scene = steps.length ? { type, ...base, problem: str(s.problem, 400), steps, answer: str(s.answer, 160) } : null;
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
        scene = items.length ? { type, ...base, phase, items } : null;
        break;
      }
      default:
        scene = null;
    }
    if (!scene) {
      // Keep the narration — show it as points rather than losing the explanation.
      scene = { type: 'bullets', ...base, bullets: splitSentences(narration).slice(0, 3) };
    }
    scenes.push(scene);
  }

  if (!scenes.length) throw Object.assign(new Error('The storyboard had no usable scenes'), { retryable: true, code: 'EMPTY_STORYBOARD' });
  if (scenes[0].type !== 'title') {
    scenes.unshift({ type: 'title', heading: lessonTitle, subtitle: '', narration: `In this lesson: ${lessonTitle}.`, onScreenLabels: [], sourcePages: [], transition: 'fade' });
  }
  if (scenes[scenes.length - 1].type !== 'summary' && scenes.length > 2) {
    warnings.push('Storyboard had no summary scene');
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

  scenes.forEach((s, i) => { s.n = i + 1; s.plannedSec = Math.round(estimateSeconds(s.narration) * 10) / 10; });
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
  const allowedTypes = input.variant === 'experiment' ? ['title', 'experiment', 'figure', 'formula', 'summary'] : subject.scenes;
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

module.exports = { buildPrompt, validateStoryboard, generateStoryboard, estimateSeconds, splitSentences, latexOk, WORDS_PER_SECOND };
