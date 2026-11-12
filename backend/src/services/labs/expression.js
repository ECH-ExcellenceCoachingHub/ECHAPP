/**
 * Safe expression language used by lab scenarios (conditions, hazards, measured
 * values). Mirrored 1:1 by ECHLabs.Core.Expr (C#) in the Unity runtime, so the
 * backend can validate exactly what the lab will evaluate.
 *
 * Grammar (lowest → highest precedence):
 *   or      := and ( '||' and )*
 *   and     := cmp ( '&&' cmp )*
 *   cmp     := add ( ( '==' | '!=' | '<' | '<=' | '>' | '>=' ) add )?
 *   add     := mul ( ( '+' | '-' ) mul )*
 *   mul     := unary ( ( '*' | '/' | '%' ) unary )*
 *   unary   := ( '!' | '-' ) unary | primary
 *   primary := number | string | true | false | path | call | '(' or ')'
 *   path    := ident ( '.' ident )*            e.g. burette1.dispensedMl
 *   call    := ident '(' ( or ( ',' or )* )? ')'   whitelisted functions only
 *
 * No property access beyond dotted identifiers, no assignment, no eval.
 */

const FUNCTIONS = {
  abs: { arity: [1, 1], fn: (a) => Math.abs(num(a)) },
  min: { arity: [1, 8], fn: (...a) => Math.min(...a.map(num)) },
  max: { arity: [1, 8], fn: (...a) => Math.max(...a.map(num)) },
  round: { arity: [1, 2], fn: (a, d = 0) => { const p = 10 ** num(d); return Math.round(num(a) * p) / p; } },
  clamp: { arity: [3, 3], fn: (v, lo, hi) => Math.min(Math.max(num(v), num(lo)), num(hi)) },
  between: { arity: [3, 3], fn: (v, lo, hi) => num(v) >= num(lo) && num(v) <= num(hi) },
  // done('s2') → step s2 has been completed. Resolved through scope.$done.
  done: { arity: [1, 1], fn: null },
};

const MAX_LENGTH = 400;
const MAX_DEPTH = 32;

class ExprError extends Error {
  constructor(message, pos) {
    super(pos == null ? message : `${message} (at ${pos})`);
    this.name = 'ExprError';
    this.pos = pos;
  }
}

function num(v) {
  if (typeof v === 'number') return v;
  if (typeof v === 'boolean') return v ? 1 : 0;
  if (v == null) return 0;
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
}

function truthy(v) {
  if (typeof v === 'boolean') return v;
  if (typeof v === 'number') return v !== 0;
  if (typeof v === 'string') return v.length > 0;
  return v != null;
}

// ─── Tokenizer ────────────────────────────────────────────────────────────────

const OPERATORS = ['&&', '||', '==', '!=', '<=', '>=', '<', '>', '+', '-', '*', '/', '%', '!', '(', ')', ',', '.'];

function tokenize(src) {
  const tokens = [];
  let i = 0;
  while (i < src.length) {
    const c = src[i];
    if (c === ' ' || c === '\t' || c === '\n' || c === '\r') { i++; continue; }
    if (/[0-9]/.test(c) || (c === '.' && /[0-9]/.test(src[i + 1] || ''))) {
      let j = i;
      while (j < src.length && /[0-9.]/.test(src[j])) j++;
      const text = src.slice(i, j);
      if ((text.match(/\./g) || []).length > 1) throw new ExprError(`Bad number "${text}"`, i);
      tokens.push({ t: 'num', v: parseFloat(text), pos: i });
      i = j;
      continue;
    }
    if (/[A-Za-z_$]/.test(c)) {
      let j = i;
      while (j < src.length && /[A-Za-z0-9_]/.test(src[j])) j++;
      const word = src.slice(i, j);
      if (word === 'true' || word === 'false') tokens.push({ t: 'bool', v: word === 'true', pos: i });
      else tokens.push({ t: 'id', v: word, pos: i });
      i = j;
      continue;
    }
    if (c === '"' || c === "'") {
      let j = i + 1;
      while (j < src.length && src[j] !== c) j++;
      if (j >= src.length) throw new ExprError('Unterminated string', i);
      tokens.push({ t: 'str', v: src.slice(i + 1, j), pos: i });
      i = j + 1;
      continue;
    }
    const op = OPERATORS.find((o) => src.startsWith(o, i));
    if (!op) throw new ExprError(`Unexpected character "${c}"`, i);
    tokens.push({ t: 'op', v: op, pos: i });
    i += op.length;
  }
  tokens.push({ t: 'eof', pos: src.length });
  return tokens;
}

// ─── Parser (recursive descent → AST) ─────────────────────────────────────────

function parse(src) {
  if (typeof src !== 'string' || !src.trim()) throw new ExprError('Empty expression');
  if (src.length > MAX_LENGTH) throw new ExprError(`Expression longer than ${MAX_LENGTH} characters`);
  const tokens = tokenize(src);
  let p = 0;
  let depth = 0;
  const peek = () => tokens[p];
  const isOp = (v) => peek().t === 'op' && peek().v === v;
  const expectOp = (v) => {
    if (!isOp(v)) throw new ExprError(`Expected "${v}"`, peek().pos);
    p++;
  };
  const enter = () => { if (++depth > MAX_DEPTH) throw new ExprError('Expression nested too deeply'); };

  function binaryLevel(next, ops) {
    return () => {
      let left = next();
      while (peek().t === 'op' && ops.includes(peek().v)) {
        const op = tokens[p++].v;
        left = { k: 'bin', op, a: left, b: next() };
      }
      return left;
    };
  }

  const unary = () => {
    enter();
    let node;
    if (isOp('!') || isOp('-')) {
      const op = tokens[p++].v;
      node = { k: 'un', op, a: unary() };
    } else node = primary();
    depth--;
    return node;
  };
  const mul = binaryLevel(unary, ['*', '/', '%']);
  const add = binaryLevel(mul, ['+', '-']);
  const cmp = () => {
    const left = add();
    if (peek().t === 'op' && ['==', '!=', '<', '<=', '>', '>='].includes(peek().v)) {
      const op = tokens[p++].v;
      return { k: 'bin', op, a: left, b: add() };
    }
    return left;
  };
  const and = binaryLevel(cmp, ['&&']);
  const or = binaryLevel(and, ['||']);

  function primary() {
    const tok = peek();
    if (tok.t === 'num') { p++; return { k: 'lit', v: tok.v }; }
    if (tok.t === 'str') { p++; return { k: 'lit', v: tok.v }; }
    if (tok.t === 'bool') { p++; return { k: 'lit', v: tok.v }; }
    if (tok.t === 'op' && tok.v === '(') {
      p++;
      enter();
      const inner = or();
      depth--;
      expectOp(')');
      return inner;
    }
    if (tok.t === 'id') {
      p++;
      if (isOp('(')) {
        const def = FUNCTIONS[tok.v];
        if (!def) throw new ExprError(`Unknown function "${tok.v}"`, tok.pos);
        p++;
        const args = [];
        if (!isOp(')')) {
          args.push(or());
          while (isOp(',')) { p++; args.push(or()); }
        }
        expectOp(')');
        if (args.length < def.arity[0] || args.length > def.arity[1]) {
          throw new ExprError(`${tok.v}() takes ${def.arity[0] === def.arity[1] ? def.arity[0] : `${def.arity[0]}-${def.arity[1]}`} argument(s)`, tok.pos);
        }
        if (tok.v === 'done' && args[0].k !== 'lit') throw new ExprError("done() needs a step id in quotes, e.g. done('s2')", tok.pos);
        return { k: 'call', fn: tok.v, args };
      }
      const parts = [tok.v];
      while (isOp('.')) {
        p++;
        const nxt = peek();
        if (nxt.t !== 'id') throw new ExprError('Expected a name after "."', nxt.pos);
        parts.push(nxt.v);
        p++;
      }
      return { k: 'path', parts };
    }
    throw new ExprError(tok.t === 'eof' ? 'Unexpected end of expression' : `Unexpected "${tok.v}"`, tok.pos);
  }

  const ast = or();
  if (peek().t !== 'eof') throw new ExprError(`Unexpected "${peek().v}"`, peek().pos);
  return ast;
}

// ─── Evaluation ───────────────────────────────────────────────────────────────

function resolvePath(scope, parts) {
  let cur = scope;
  for (const part of parts) {
    if (cur == null || typeof cur !== 'object' || !Object.prototype.hasOwnProperty.call(cur, part)) return undefined;
    cur = cur[part];
  }
  return cur;
}

function evaluateAst(node, scope) {
  switch (node.k) {
    case 'lit': return node.v;
    case 'path': return resolvePath(scope, node.parts);
    case 'un': {
      const v = evaluateAst(node.a, scope);
      return node.op === '!' ? !truthy(v) : -num(v);
    }
    case 'call': {
      if (node.fn === 'done') {
        const doneSet = scope && scope.$done;
        const id = node.args[0].v;
        return doneSet instanceof Set ? doneSet.has(id) : Array.isArray(doneSet) ? doneSet.includes(id) : false;
      }
      return FUNCTIONS[node.fn].fn(...node.args.map((a) => evaluateAst(a, scope)));
    }
    case 'bin': {
      if (node.op === '&&') return truthy(evaluateAst(node.a, scope)) && truthy(evaluateAst(node.b, scope));
      if (node.op === '||') return truthy(evaluateAst(node.a, scope)) || truthy(evaluateAst(node.b, scope));
      const a = evaluateAst(node.a, scope);
      const b = evaluateAst(node.b, scope);
      switch (node.op) {
        case '==': return (typeof a === 'string' || typeof b === 'string') ? String(a) === String(b) : num(a) === num(b);
        case '!=': return (typeof a === 'string' || typeof b === 'string') ? String(a) !== String(b) : num(a) !== num(b);
        case '<': return num(a) < num(b);
        case '<=': return num(a) <= num(b);
        case '>': return num(a) > num(b);
        case '>=': return num(a) >= num(b);
        case '+': return num(a) + num(b);
        case '-': return num(a) - num(b);
        case '*': return num(a) * num(b);
        case '/': return num(b) === 0 ? 0 : num(a) / num(b);
        case '%': return num(b) === 0 ? 0 : num(a) % num(b);
        default: throw new ExprError(`Unknown operator ${node.op}`);
      }
    }
    default: throw new ExprError(`Unknown node ${node.k}`);
  }
}

function evaluate(src, scope = {}) {
  return evaluateAst(typeof src === 'string' ? parse(src) : src, scope);
}

/** Every dotted path and every done('id') referenced by an expression. */
function references(src) {
  const ast = typeof src === 'string' ? parse(src) : src;
  const paths = [];
  const steps = [];
  (function walk(n) {
    if (n.k === 'path') paths.push(n.parts.join('.'));
    else if (n.k === 'call') {
      if (n.fn === 'done') steps.push(String(n.args[0].v));
      else n.args.forEach(walk);
    } else if (n.k === 'un') walk(n.a);
    else if (n.k === 'bin') { walk(n.a); walk(n.b); }
  })(ast);
  return { paths, steps };
}

module.exports = { parse, evaluate, references, truthy, ExprError, FUNCTIONS: Object.keys(FUNCTIONS) };
