/**
 * Small, safe arithmetic expression parser (no eval).
 *
 * Supports: numbers (1,000.5  2.5e3  12%), + - * / ^, × · ÷ −, parentheses,
 * implicit multiplication (2x, 3(x+1), 2pi), unary minus, constants (pi, π, e)
 * and functions (sin cos tan asin acos atan sqrt √ abs ln log log10 exp floor
 * ceil round). Variables are looked up in the object passed to evaluate().
 *
 * Used for deterministic checks of worked examples and for plotting graphs in
 * lesson videos — never for anything that needs symbolic algebra.
 */

const FUNCS = {
  sin: Math.sin, cos: Math.cos, tan: Math.tan,
  asin: Math.asin, acos: Math.acos, atan: Math.atan,
  sqrt: Math.sqrt, abs: Math.abs, exp: Math.exp,
  ln: Math.log, log: Math.log10, log10: Math.log10,
  floor: Math.floor, ceil: Math.ceil, round: Math.round,
};
const CONSTS = { pi: Math.PI, 'π': Math.PI, e: Math.E };

class ExpressionError extends Error {}

function normalize(src) {
  return String(src)
    .replace(/[−–]/g, '-')
    .replace(/[×·∙]/g, '*')
    .replace(/÷/g, '/')
    .replace(/√/g, 'sqrt')
    .replace(/²/g, '^2')
    .replace(/³/g, '^3')
    .replace(/\*\*/g, '^')
    // thousands separators: 1,000,000 → 1000000 (only full groups of three)
    .replace(/(\d),(?=\d{3}(?!\d))/g, '$1');
}

function tokenize(src) {
  const s = normalize(src);
  const tokens = [];
  let i = 0;
  while (i < s.length) {
    const c = s[i];
    if (/\s/.test(c)) { i++; continue; }
    const num = /^(\d+\.?\d*|\.\d+)(e[+-]?\d+)?/i.exec(s.slice(i));
    if (num) {
      let value = parseFloat(num[0]);
      i += num[0].length;
      if (s[i] === '%') { value /= 100; i++; }
      tokens.push({ t: 'num', v: value });
      continue;
    }
    const id = /^[a-zA-Zπ_][a-zA-Z0-9_]*/.exec(s.slice(i));
    if (id) {
      tokens.push({ t: 'id', v: id[0] });
      i += id[0].length;
      continue;
    }
    if ('+-*/^(),'.includes(c)) {
      tokens.push({ t: 'op', v: c });
      i++;
      continue;
    }
    throw new ExpressionError(`Unexpected character "${c}"`);
  }
  return tokens;
}

/** Recursive-descent parser producing a closure tree. */
function parse(src) {
  const tokens = tokenize(src);
  let pos = 0;
  const peek = () => tokens[pos];
  const next = () => tokens[pos++];
  const isOp = (v) => peek() && peek().t === 'op' && peek().v === v;
  const startsPrimary = (tk) => tk && (tk.t === 'num' || tk.t === 'id' || (tk.t === 'op' && tk.v === '('));
  const variables = new Set();

  function expr() {
    let left = term();
    while (isOp('+') || isOp('-')) {
      const op = next().v;
      const right = term();
      const l = left;
      left = op === '+' ? (v) => l(v) + right(v) : (v) => l(v) - right(v);
    }
    return left;
  }
  function term() {
    let left = unary();
    for (;;) {
      if (isOp('*') || isOp('/')) {
        const op = next().v;
        const right = unary();
        const l = left;
        left = op === '*' ? (v) => l(v) * right(v) : (v) => l(v) / right(v);
      } else if (startsPrimary(peek())) {
        // implicit multiplication: 2x, 2(x+1), (a)(b)
        const right = power();
        const l = left;
        left = (v) => l(v) * right(v);
      } else {
        return left;
      }
    }
  }
  function unary() {
    if (isOp('-')) { next(); const u = unary(); return (v) => -u(v); }
    if (isOp('+')) { next(); return unary(); }
    return power();
  }
  function power() {
    const base = primary();
    if (isOp('^')) {
      next();
      const exp = unary(); // right-associative, allows 2^-1
      return (v) => Math.pow(base(v), exp(v));
    }
    return base;
  }
  function primary() {
    const tk = next();
    if (!tk) throw new ExpressionError('Unexpected end of expression');
    if (tk.t === 'num') { const n = tk.v; return () => n; }
    if (tk.t === 'op' && tk.v === '(') {
      const e = expr();
      if (!isOp(')')) throw new ExpressionError('Missing )');
      next();
      return e;
    }
    if (tk.t === 'id') {
      const name = tk.v;
      const lower = name.toLowerCase();
      if (FUNCS[lower] && (isOp('(') || startsPrimary(peek()))) {
        const fn = FUNCS[lower];
        let arg;
        if (isOp('(')) {
          next();
          arg = expr();
          if (!isOp(')')) throw new ExpressionError('Missing ) after function argument');
          next();
        } else {
          arg = power();
        }
        return (v) => fn(arg(v));
      }
      if (Object.prototype.hasOwnProperty.call(CONSTS, lower)) {
        const c = CONSTS[lower];
        return (v) => (v && Object.prototype.hasOwnProperty.call(v, name) ? v[name] : c);
      }
      variables.add(name);
      return (v) => {
        if (!v || !Object.prototype.hasOwnProperty.call(v, name)) throw new ExpressionError(`Unknown variable "${name}"`);
        return v[name];
      };
    }
    throw new ExpressionError(`Unexpected token "${tk.v}"`);
  }

  const fn = expr();
  if (pos < tokens.length) throw new ExpressionError(`Unexpected "${tokens[pos].v}"`);
  return { evaluate: (vars = {}) => fn(vars), variables: [...variables] };
}

function evaluate(src, vars) {
  return parse(src).evaluate(vars);
}

function tryEvaluate(src, vars) {
  try {
    const v = evaluate(src, vars);
    return Number.isFinite(v) ? v : null;
  } catch (_) {
    return null;
  }
}

/**
 * Compare a computed value with a stated one, allowing for the rounding the
 * author used (number of decimals shown) plus a small relative tolerance.
 */
function approximatelyEqual(computed, statedText) {
  const stated = parseFloat(normalize(statedText).replace(/[^0-9.eE+-]/g, ''));
  if (!Number.isFinite(stated) || !Number.isFinite(computed)) return null;
  const decimals = (String(statedText).split('.')[1] || '').replace(/[^0-9]/g, '').length;
  const roundingTol = decimals ? 0.5 * Math.pow(10, -decimals) : 0.5;
  const relTol = Math.abs(stated) * 1e-9; // floating-point noise only; precision comes from the decimals shown
  return Math.abs(computed - stated) <= Math.max(roundingTol, relTol, 1e-9);
}

module.exports = { parse, evaluate, tryEvaluate, approximatelyEqual, ExpressionError, normalize };
