/**
 * Server-side lab scoring. The lab client reports what the student did
 * (completed steps, typed readings, checkpoint answers, hazards); the score is
 * always recomputed here from the scenario definition. The Unity runtime uses
 * the same rules for the live HUD (ECHLabs.Core.Scoring).
 */
const expr = require('./expression');

const HINT_PENALTY = 2;
const HINT_PENALTY_MAX = 20;
const MISTAKE_PENALTY = 1;
const MISTAKE_PENALTY_MAX = 15;

const clamp = (v, lo = 0, hi = 100) => Math.min(Math.max(v, lo), hi);

/** 100 inside tolerance, falling linearly to 0 at 3× the tolerance. */
function gradeResult(actual, expected, tolerancePct) {
  if (typeof actual !== 'number' || !Number.isFinite(actual)) return 0;
  if (expected === 0) return Math.abs(actual) < 1e-9 ? 100 : 0;
  const errPct = Math.abs(actual - expected) / Math.abs(expected) * 100;
  const tol = Math.max(tolerancePct, 0.01);
  if (errPct <= tol) return 100;
  if (errPct >= 3 * tol) return 0;
  return Math.round(100 * (1 - (errPct - tol) / (2 * tol)));
}

/**
 * @param {object} def       validated scenario definition
 * @param {object} attempt   { completedSteps, records, checkpoints, hazardsTriggered, hintsUsed, mistakes }
 */
function scoreAttempt(def, attempt) {
  const completed = new Set(attempt.completedSteps || []);
  const records = attempt.records || {};
  const checkpoints = new Map((attempt.checkpoints || []).map((c) => [c.stepId, c]));

  // Procedure: points for completed steps; checkpoints only when answered correctly.
  let earned = 0;
  let possible = 0;
  for (const step of def.steps) {
    const pts = step.points ?? 10;
    possible += pts;
    if (!completed.has(step.id)) continue;
    if (step.kind === 'checkpoint') {
      const answer = checkpoints.get(step.id);
      if (answer && answer.correct) earned += pts;
    } else earned += pts;
  }
  const hintPenalty = Math.min((attempt.hintsUsed || 0) * HINT_PENALTY, HINT_PENALTY_MAX);
  const mistakePenalty = Math.min((attempt.mistakes || 0) * MISTAKE_PENALTY, MISTAKE_PENALTY_MAX);
  const procedure = clamp(Math.round((possible ? (earned / possible) * 100 : 100) - hintPenalty - mistakePenalty));

  // Accuracy: student's results against the scenario's expected values.
  const scope = { record: records };
  const grades = (def.results || []).map((r) => {
    let actual;
    try { actual = expr.evaluate(r.source, scope); } catch (_) { actual = undefined; }
    const grade = gradeResult(typeof actual === 'number' ? actual : Number(actual), r.expected, r.tolerancePct ?? 5);
    return { key: r.key, label: r.label, actual: Number.isFinite(Number(actual)) ? Number(actual) : null, expected: r.expected, unit: r.unit, grade };
  });
  const accuracy = grades.length ? Math.round(grades.reduce((s, g) => s + g.grade, 0) / grades.length) : 100;

  // Safety: each distinct hazard costs its penalty once; a "fail" hazard fails the lab.
  const hazardsById = new Map((def.hazards || []).map((h) => [h.id, h]));
  const triggered = [...new Set((attempt.hazardsTriggered || []).map((h) => h.id))].filter((id) => hazardsById.has(id));
  const safety = clamp(100 - triggered.reduce((s, id) => s + (hazardsById.get(id).penalty ?? 5), 0));
  const failedSafety = triggered.some((id) => hazardsById.get(id).severity === 'fail');

  const w = def.scoring || { accuracy: 40, procedure: 40, safety: 20 };
  const total = Math.round((accuracy * w.accuracy + procedure * w.procedure + safety * w.safety) / 100);
  const allStepsDone = def.steps.every((s) => completed.has(s.id));
  const passed = allStepsDone && !failedSafety && total >= (def.passScore ?? 60);

  return { score: { accuracy, procedure, safety, total }, passed, allStepsDone, failedSafety, results: grades, hazards: triggered };
}

/** Badges earned by this attempt, given the student's history. */
function badgesFor({ def, outcome, passedSubjects = {}, firstLab }) {
  const badges = [];
  if (!outcome.passed) return badges;
  if (firstLab) badges.push('first-experiment');
  if ((def.scoring?.safety ?? 0) > 0 && outcome.score.safety === 100) badges.push('safety-champion');
  if ((def.results || []).length && outcome.score.accuracy >= 95) badges.push('precision-scientist');
  if (outcome.score.total === 100) badges.push('flawless-lab');
  const count = (passedSubjects[def.subject] || 0) + 1;
  if (count >= 3) badges.push(`${def.subject}-explorer`);
  return badges;
}

module.exports = { scoreAttempt, gradeResult, badgesFor };
