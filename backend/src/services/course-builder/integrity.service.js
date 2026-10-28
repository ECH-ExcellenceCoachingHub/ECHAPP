const { tryEvaluate, approximatelyEqual } = require('../../utils/mathExpression');

/**
 * Deterministic content-integrity checks for generated lessons.
 *
 * - Arithmetic in worked examples / explanations ("1000/(1.1)^2 = 826.45")
 *   is recomputed; mismatches are reported, never silently "fixed".
 * - Formulas are checked for structural problems (unbalanced brackets, empty
 *   side of an equation, listed variables that never appear).
 * - Calculation questions: the final result in the explanation must match the
 *   option marked correct.
 * - Science safety: hazards in the lesson are detected so experiment videos
 *   get mandatory human review.
 */

const NUMERIC_CHARS = '[\\d.,%()+\\-*/×÷^−·\\s]';
const TRAILING_NUMERIC = new RegExp(`(${NUMERIC_CHARS}+)$`);
const LEADING_NUMERIC = new RegExp(`^\\s*[$£€]?\\s*(${NUMERIC_CHARS}+)`);
const HAS_OPERATOR = /\d\s*[+\-*/×÷^−·]\s*[\d(]|\)\s*[\^*/]|\d\s*%\s*[*×]/;

/** Extract numeric "a op b = c" chains from free text and verify each link. */
function checkArithmetic(text) {
  const issues = [];
  let checked = 0;
  for (const rawLine of String(text || '').split(/\n|(?<=[.;])\s+(?=[A-Z])/)) {
    // Strip markdown emphasis / code ticks / LaTeX-ish commands that wrap numbers
    const line = rawLine.replace(/[*`_$£€]/g, '').replace(/\\times/g, '×').replace(/\\div/g, '÷');
    if (!line.includes('=')) continue;
    const parts = line.split(/(?<![<>!=])=(?!=)/);
    for (let i = 0; i < parts.length - 1; i++) {
      const leftM = TRAILING_NUMERIC.exec(parts[i]);
      const rightM = LEADING_NUMERIC.exec(parts[i + 1]);
      if (!leftM || !rightM) continue;
      const leftRaw = leftM[1];
      const left = leftRaw.trim();
      const right = rightM[1].trim().replace(/[+\-*/×÷^−·\s(.,]+$/, '');
      if (!/\d/.test(left) || !/\d/.test(right)) continue;
      // The numeric run must be a whole expression. If it continues a symbolic
      // term ("4x - 2 + 5 = 9", "2x+3 = 7") skip it rather than mis-evaluate.
      const before = parts[i].slice(0, parts[i].length - leftRaw.length);
      if (before.trim() && /^[+\-*/×÷^−·]/.test(left)) continue;
      if (/[A-Za-z0-9)]$/.test(before) && !/^\s/.test(leftRaw)) continue;
      if (!HAS_OPERATOR.test(left) && !HAS_OPERATOR.test(right)) continue;
      const l = tryEvaluate(left);
      if (l == null) continue;
      checked++;
      let ok;
      if (HAS_OPERATOR.test(right)) {
        const r = tryEvaluate(right);
        if (r == null) continue;
        ok = Math.abs(l - r) <= Math.max(1e-9, Math.abs(r) * 1e-4, 0.005);
      } else {
        ok = approximatelyEqual(l, right);
      }
      if (ok === false) {
        issues.push({ expression: `${left} = ${right}`, computed: round(l), stated: right });
      }
    }
  }
  return { checked, issues };
}

function round(n) {
  return Math.round(n * 1e6) / 1e6;
}

function balanced(s) {
  let depth = 0;
  for (const ch of s) {
    if (ch === '(' || ch === '[' || ch === '{') depth++;
    else if (ch === ')' || ch === ']' || ch === '}') depth--;
    if (depth < 0) return false;
  }
  return depth === 0;
}

function checkFormulas(formulas = []) {
  const issues = [];
  for (const f of formulas) {
    const expr = String(f.expression || '');
    if (!balanced(expr)) issues.push({ formula: f.name || expr, problem: 'unbalanced brackets' });
    if (expr.includes('=')) {
      const [lhs, ...rest] = expr.split('=');
      if (!lhs.trim() || !rest.join('=').trim()) issues.push({ formula: f.name || expr, problem: 'one side of the equation is empty' });
    }
    for (const v of f.variables || []) {
      const sym = String(v.symbol || '').trim();
      if (sym && !expr.includes(sym)) {
        issues.push({ formula: f.name || expr, problem: `variable "${sym}" is explained but not used in the formula` });
      }
    }
  }
  return issues;
}

function numericValue(text) {
  const m = /[-−]?\s*[$£€]?\s*\d[\d,]*(?:\.\d+)?/.exec(String(text || ''));
  if (!m) return null;
  return { value: tryEvaluate(m[0].replace(/[$£€\s]/g, '')), text: m[0].replace(/[$£€\s]/g, '') };
}

function checkCalculationQuestions(questions = []) {
  const issues = [];
  questions.forEach((q, index) => {
    const explanation = String(q.explanation || '');
    const arithmetic = checkArithmetic(explanation);
    for (const a of arithmetic.issues) issues.push({ index, question: q.question, problem: `arithmetic: ${a.expression} (computed ${a.computed})` });

    if (q.type !== 'calculation' || q.correctIndex == null || !q.options?.length) return;
    const marked = numericValue(q.options[q.correctIndex]);
    if (!marked || marked.value == null) return;
    // Final "= number" in the explanation is the worked result.
    const finals = [...explanation.matchAll(/=\s*[$£€]?\s*([-−]?\d[\d,]*(?:\.\d+)?)/g)];
    if (!finals.length) return;
    const lastText = finals[finals.length - 1][1];
    const last = tryEvaluate(lastText);
    if (last == null) return;
    if (approximatelyEqual(last, marked.text) === false && approximatelyEqual(marked.value, lastText) === false) {
      issues.push({ index, question: q.question, problem: `worked result ${lastText} does not match the marked answer ${q.options[q.correctIndex]}` });
    }
  });
  return issues;
}

const HAZARDS = {
  chemical: /\b(acid|alkali|corrosive|concentrated|toxic|poison|flammable|ethanol|methanol|sodium hydroxide|potassium hydroxide|hydrochloric|sulfuric|sulphuric|nitric|ammonia|chlorine|bromine|mercury|lead nitrate|hydrogen peroxide|irritant)\b/gi,
  heat: /\b(bunsen|flame|burner|heat strongly|boiling|hot plate|ignite|combustion|burn(?:ing)? magnesium|molten)\b/gi,
  electrical: /\b(mains|high voltage|electric shock|230 ?v|240 ?v|110 ?v|live wire|short circuit)\b/gi,
  biological: /\b(bacteria|microorganisms?|microbes?|culture plates?|agar|blood|saliva|dissect(?:ion)?|pathogens?|cheek cells?)\b/gi,
  radiation: /\b(radioactive|radiation source|x-rays?|laser|ultraviolet|uv lamp)\b/gi,
  sharp: /\b(scalpel|blade|broken glass|glass tubing|needle)\b/gi,
  pressure: /\b(pressure cooker|compressed gas|gas cylinder|explosi(?:ve|on))\b/gi,
};

function detectHazards(text) {
  const found = [];
  const s = String(text || '');
  for (const [category, re] of Object.entries(HAZARDS)) {
    const terms = [...new Set((s.match(re) || []).map(t => t.toLowerCase()))];
    if (terms.length) found.push({ category, terms: terms.slice(0, 8) });
  }
  return found;
}

function contentText(content) {
  if (!content) return '';
  return [
    content.notes,
    ...(content.examples || []).map(e => `${e.title}\n${e.body}`),
    ...(content.keyPoints || []),
  ].filter(Boolean).join('\n');
}

/**
 * Run every check on a lesson draft.
 * @returns {{integrity: object, warnings: string[]}}
 */
function checkContent(content, questions = []) {
  const examplesText = (content?.examples || []).map(e => e.body).join('\n');
  const arithmetic = checkArithmetic(`${examplesText}\n${content?.notes || ''}`);
  const formulaIssues = checkFormulas(content?.formulas || []);
  const questionIssues = checkCalculationQuestions(questions);
  const hazards = detectHazards(contentText(content));

  const warnings = [];
  if (arithmetic.issues.length) warnings.push(`${arithmetic.issues.length} calculation(s) in the notes/examples do not add up — check: ${arithmetic.issues.slice(0, 2).map(i => i.expression).join('; ')}`);
  if (formulaIssues.length) warnings.push(`${formulaIssues.length} formula problem(s): ${formulaIssues.slice(0, 2).map(i => `${i.formula} (${i.problem})`).join('; ')}`);
  if (questionIssues.length) warnings.push(`${questionIssues.length} calculation question(s) have answers that don't match their worked solution.`);

  return {
    integrity: {
      arithmeticChecked: arithmetic.checked,
      arithmeticIssues: arithmetic.issues,
      formulaIssues,
      questionIssues,
      hazards,
      checkedAt: new Date(),
    },
    warnings,
  };
}

module.exports = { checkArithmetic, checkFormulas, checkCalculationQuestions, detectHazards, checkContent, contentText };
