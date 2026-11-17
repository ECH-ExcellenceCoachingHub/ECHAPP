/**
 * "New values every try": a scenario may declare `randomize` rules, e.g.
 *
 *   "randomize": [{ "path": "flask1.conc", "min": 0.08, "max": 0.12, "decimals": 3 },
 *                 { "path": "r1.ohms", "choices": [47, 68, 100, 150] }]
 *
 * A variant is the set of values picked for one attempt, stored nested
 * ({ flask1: { conc: 0.094 } }) so it is a valid Mongo document and a valid
 * expression scope. Applying a variant:
 *   • overrides the equipment `init` values,
 *   • renders label templates ("Resistor {r1.ohms} Ω"),
 *   • recomputes results that have `expectedExpr` (e.g. "flask1.conc * 25 / 0.125").
 * Mirrored by ECHLabs.Core.Variants (C#) for offline practice and the demo.
 */
const expr = require('./expression');

const round = (v, d) => { const p = 10 ** d; return Math.round(v * p) / p; };
const fmt = (x) => (typeof x === 'number' ? String(+x.toFixed(4)) : String(x));

function pickVariant(def, rng = Math.random) {
  const out = {};
  for (const r of (def && def.randomize) || []) {
    const [id, key] = r.path.split('.');
    let v;
    if (Array.isArray(r.choices) && r.choices.length) v = r.choices[Math.floor(rng() * r.choices.length) % r.choices.length];
    else v = round(r.min + (r.max - r.min) * rng(), r.decimals ?? 3);
    (out[id] = out[id] || {})[key] = v;
  }
  return Object.keys(out).length ? out : null;
}

/** Only values the scenario allows to vary, inside their declared range. */
function isAllowed(rule, v) {
  if (typeof v !== 'number' || !Number.isFinite(v)) return false;
  if (Array.isArray(rule.choices) && rule.choices.length) return rule.choices.includes(v);
  return v >= rule.min - 1e-9 && v <= rule.max + 1e-9;
}

function initScope(def) {
  const scope = {};
  for (const eq of def.equipment || []) scope[eq.id] = { ...(eq.init || {}) };
  return scope;
}

function applyVariant(def, variant) {
  const d = JSON.parse(JSON.stringify(def));
  const rules = new Map((d.randomize || []).map((r) => [r.path, r]));
  for (const eq of d.equipment || []) {
    const values = variant && variant[eq.id];
    if (!values || typeof values !== 'object') continue;
    for (const [k, v] of Object.entries(values)) {
      const rule = rules.get(`${eq.id}.${k}`);
      if (rule && isAllowed(rule, v)) eq.init = { ...(eq.init || {}), [k]: v };
    }
  }
  const scope = initScope(d);
  for (const eq of d.equipment || []) {
    const tpl = eq.labelTemplate || (eq.label && eq.label.includes('{') ? eq.label : null);
    if (!tpl) continue;
    eq.labelTemplate = tpl;
    eq.label = tpl.replace(/\{([A-Za-z][A-Za-z0-9_]*)\.([A-Za-z][A-Za-z0-9_]*)\}/g, (m, id, k) => (scope[id] && scope[id][k] != null ? fmt(scope[id][k]) : m));
  }
  for (const r of d.results || []) {
    if (!r.expectedExpr) continue;
    try {
      const v = Number(expr.evaluate(r.expectedExpr, scope));
      if (Number.isFinite(v)) r.expected = round(v, 4);
    } catch (_) { /* validator reports bad expressions */ }
  }
  return d;
}

/** The two extreme variants (all minimums / all maximums) — used to validate the science. */
function extremeVariants(def) {
  const lo = {}; const hi = {};
  for (const r of def.randomize || []) {
    const [id, key] = r.path.split('.');
    const vals = Array.isArray(r.choices) && r.choices.length ? r.choices : [r.min, r.max];
    (lo[id] = lo[id] || {})[key] = Math.min(...vals);
    (hi[id] = hi[id] || {})[key] = Math.max(...vals);
  }
  return [lo, hi];
}

module.exports = { pickVariant, applyVariant, extremeVariants, initScope };
