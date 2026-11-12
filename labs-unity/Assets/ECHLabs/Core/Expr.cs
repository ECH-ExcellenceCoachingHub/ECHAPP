// ECH Labs — safe expression language for scenario conditions.
// 1:1 port of backend/src/services/labs/expression.js (same grammar, same semantics).
using System;
using System.Collections.Generic;
using System.Globalization;

namespace ECHLabs.Core
{
    public sealed class ExprException : Exception
    {
        public int Position { get; }
        public ExprException(string message, int pos = -1) : base(pos < 0 ? message : $"{message} (at {pos})") { Position = pos; }
    }

    /// <summary>Resolves dotted paths (e.g. "burette1.volumeMl") and done('id') for evaluation.</summary>
    public interface IExprScope
    {
        object Resolve(IReadOnlyList<string> path);
        bool IsDone(string stepId);
    }

    public abstract class ExprNode { }
    public sealed class LitNode : ExprNode { public object Value; }
    public sealed class PathNode : ExprNode { public string[] Parts; public string Joined; }
    public sealed class UnaryNode : ExprNode { public string Op; public ExprNode A; }
    public sealed class BinNode : ExprNode { public string Op; public ExprNode A, B; }
    public sealed class CallNode : ExprNode { public string Fn; public ExprNode[] Args; }

    public static class Expr
    {
        public const int MaxLength = 400;
        const int MaxDepth = 32;

        static readonly Dictionary<string, (int min, int max)> Functions = new Dictionary<string, (int, int)>
        {
            { "abs", (1, 1) }, { "min", (1, 8) }, { "max", (1, 8) }, { "round", (1, 2) },
            { "clamp", (3, 3) }, { "between", (3, 3) }, { "done", (1, 1) },
        };

        static readonly string[] Operators = { "&&", "||", "==", "!=", "<=", ">=", "<", ">", "+", "-", "*", "/", "%", "!", "(", ")", ",", "." };

        // ─── Values ──────────────────────────────────────────────────────────

        public static double Num(object v)
        {
            switch (v)
            {
                case null: return 0;
                case double d: return d;
                case float f: return f;
                case int i: return i;
                case long l: return l;
                case bool b: return b ? 1 : 0;
                case string s: return double.TryParse(s, NumberStyles.Float, CultureInfo.InvariantCulture, out var r) && !double.IsInfinity(r) && !double.IsNaN(r) ? r : 0;
                default:
                    try { var c = Convert.ToDouble(v, CultureInfo.InvariantCulture); return double.IsNaN(c) || double.IsInfinity(c) ? 0 : c; }
                    catch { return 0; }
            }
        }

        public static bool Truthy(object v)
        {
            switch (v)
            {
                case null: return false;
                case bool b: return b;
                case string s: return s.Length > 0;
                case double d: return d != 0;
                case float f: return f != 0;
                case int i: return i != 0;
                case long l: return l != 0;
                default: return true;
            }
        }

        // ─── Tokenizer ───────────────────────────────────────────────────────

        struct Tok { public char T; public object V; public int Pos; } // T: n=num s=str b=bool i=id o=op e=eof

        static List<Tok> Tokenize(string src)
        {
            var tokens = new List<Tok>();
            int i = 0;
            while (i < src.Length)
            {
                char c = src[i];
                if (c == ' ' || c == '\t' || c == '\n' || c == '\r') { i++; continue; }
                if (char.IsDigit(c) || (c == '.' && i + 1 < src.Length && char.IsDigit(src[i + 1])))
                {
                    int j = i, dots = 0;
                    while (j < src.Length && (char.IsDigit(src[j]) || src[j] == '.')) { if (src[j] == '.') dots++; j++; }
                    string text = src.Substring(i, j - i);
                    if (dots > 1) throw new ExprException($"Bad number \"{text}\"", i);
                    tokens.Add(new Tok { T = 'n', V = double.Parse(text, CultureInfo.InvariantCulture), Pos = i });
                    i = j; continue;
                }
                if (char.IsLetter(c) || c == '_' || c == '$')
                {
                    int j = i;
                    while (j < src.Length && (char.IsLetterOrDigit(src[j]) || src[j] == '_')) j++;
                    string word = src.Substring(i, j - i);
                    if (word == "true" || word == "false") tokens.Add(new Tok { T = 'b', V = word == "true", Pos = i });
                    else tokens.Add(new Tok { T = 'i', V = word, Pos = i });
                    i = j; continue;
                }
                if (c == '"' || c == '\'')
                {
                    int j = i + 1;
                    while (j < src.Length && src[j] != c) j++;
                    if (j >= src.Length) throw new ExprException("Unterminated string", i);
                    tokens.Add(new Tok { T = 's', V = src.Substring(i + 1, j - i - 1), Pos = i });
                    i = j + 1; continue;
                }
                string op = null;
                foreach (var o in Operators) if (string.CompareOrdinal(src, i, o, 0, o.Length) == 0) { op = o; break; }
                if (op == null) throw new ExprException($"Unexpected character \"{c}\"", i);
                tokens.Add(new Tok { T = 'o', V = op, Pos = i });
                i += op.Length;
            }
            tokens.Add(new Tok { T = 'e', Pos = src.Length });
            return tokens;
        }

        // ─── Parser ──────────────────────────────────────────────────────────

        sealed class Parser
        {
            readonly List<Tok> t; int p; int depth;
            public Parser(List<Tok> tokens) { t = tokens; }
            Tok Peek => t[p];
            bool IsOp(string v) => Peek.T == 'o' && (string)Peek.V == v;
            bool IsOpAny(params string[] vs) { if (Peek.T != 'o') return false; var s = (string)Peek.V; foreach (var v in vs) if (s == v) return true; return false; }
            void ExpectOp(string v) { if (!IsOp(v)) throw new ExprException($"Expected \"{v}\"", Peek.Pos); p++; }
            void Enter() { if (++depth > MaxDepth) throw new ExprException("Expression nested too deeply"); }

            public ExprNode ParseAll()
            {
                var ast = Or();
                if (Peek.T != 'e') throw new ExprException($"Unexpected \"{Peek.V}\"", Peek.Pos);
                return ast;
            }

            ExprNode Or() { var l = And(); while (IsOp("||")) { p++; l = new BinNode { Op = "||", A = l, B = And() }; } return l; }
            ExprNode And() { var l = Cmp(); while (IsOp("&&")) { p++; l = new BinNode { Op = "&&", A = l, B = Cmp() }; } return l; }
            ExprNode Cmp()
            {
                var l = Add();
                if (IsOpAny("==", "!=", "<", "<=", ">", ">=")) { var op = (string)t[p++].V; return new BinNode { Op = op, A = l, B = Add() }; }
                return l;
            }
            ExprNode Add() { var l = Mul(); while (IsOpAny("+", "-")) { var op = (string)t[p++].V; l = new BinNode { Op = op, A = l, B = Mul() }; } return l; }
            ExprNode Mul() { var l = Unary(); while (IsOpAny("*", "/", "%")) { var op = (string)t[p++].V; l = new BinNode { Op = op, A = l, B = Unary() }; } return l; }
            ExprNode Unary()
            {
                Enter();
                ExprNode node;
                if (IsOpAny("!", "-")) { var op = (string)t[p++].V; node = new UnaryNode { Op = op, A = Unary() }; }
                else node = Primary();
                depth--;
                return node;
            }
            ExprNode Primary()
            {
                var tok = Peek;
                switch (tok.T)
                {
                    case 'n': case 's': case 'b': p++; return new LitNode { Value = tok.V };
                    case 'o' when (string)tok.V == "(":
                        p++; Enter(); var inner = Or(); depth--; ExpectOp(")"); return inner;
                    case 'i':
                        p++;
                        var name = (string)tok.V;
                        if (IsOp("("))
                        {
                            if (!Functions.TryGetValue(name, out var arity)) throw new ExprException($"Unknown function \"{name}\"", tok.Pos);
                            p++;
                            var args = new List<ExprNode>();
                            if (!IsOp(")")) { args.Add(Or()); while (IsOp(",")) { p++; args.Add(Or()); } }
                            ExpectOp(")");
                            if (args.Count < arity.min || args.Count > arity.max)
                                throw new ExprException($"{name}() takes {(arity.min == arity.max ? arity.min.ToString() : arity.min + "-" + arity.max)} argument(s)", tok.Pos);
                            if (name == "done" && !(args[0] is LitNode)) throw new ExprException("done() needs a step id in quotes, e.g. done('s2')", tok.Pos);
                            return new CallNode { Fn = name, Args = args.ToArray() };
                        }
                        var parts = new List<string> { name };
                        while (IsOp("."))
                        {
                            p++;
                            if (Peek.T != 'i') throw new ExprException("Expected a name after \".\"", Peek.Pos);
                            parts.Add((string)Peek.V); p++;
                        }
                        return new PathNode { Parts = parts.ToArray(), Joined = string.Join(".", parts) };
                    case 'e': throw new ExprException("Unexpected end of expression", tok.Pos);
                    default: throw new ExprException($"Unexpected \"{tok.V}\"", tok.Pos);
                }
            }
        }

        static readonly Dictionary<string, ExprNode> Cache = new Dictionary<string, ExprNode>();

        public static ExprNode Parse(string src)
        {
            if (string.IsNullOrWhiteSpace(src)) throw new ExprException("Empty expression");
            if (src.Length > MaxLength) throw new ExprException($"Expression longer than {MaxLength} characters");
            lock (Cache)
            {
                if (Cache.TryGetValue(src, out var hit)) return hit;
                var ast = new Parser(Tokenize(src)).ParseAll();
                Cache[src] = ast;
                return ast;
            }
        }

        // ─── Evaluation ──────────────────────────────────────────────────────

        public static object Evaluate(string src, IExprScope scope) => Eval(Parse(src), scope);
        public static bool Test(string src, IExprScope scope) => Truthy(Evaluate(src, scope));
        public static double Number(string src, IExprScope scope) => Num(Evaluate(src, scope));

        public static object Eval(ExprNode node, IExprScope scope)
        {
            switch (node)
            {
                case LitNode lit: return lit.Value;
                case PathNode path: return scope?.Resolve(path.Parts);
                case UnaryNode un:
                    { var v = Eval(un.A, scope); return un.Op == "!" ? (object)!Truthy(v) : -Num(v); }
                case CallNode call: return Call(call, scope);
                case BinNode bin:
                    {
                        if (bin.Op == "&&") return Truthy(Eval(bin.A, scope)) && Truthy(Eval(bin.B, scope));
                        if (bin.Op == "||") return Truthy(Eval(bin.A, scope)) || Truthy(Eval(bin.B, scope));
                        var a = Eval(bin.A, scope);
                        var b = Eval(bin.B, scope);
                        bool str = a is string || b is string;
                        switch (bin.Op)
                        {
                            case "==": return str ? ToStr(a) == ToStr(b) : Num(a) == Num(b);
                            case "!=": return str ? ToStr(a) != ToStr(b) : Num(a) != Num(b);
                            case "<": return Num(a) < Num(b);
                            case "<=": return Num(a) <= Num(b);
                            case ">": return Num(a) > Num(b);
                            case ">=": return Num(a) >= Num(b);
                            case "+": return Num(a) + Num(b);
                            case "-": return Num(a) - Num(b);
                            case "*": return Num(a) * Num(b);
                            case "/": return Num(b) == 0 ? 0.0 : Num(a) / Num(b);
                            case "%": return Num(b) == 0 ? 0.0 : Num(a) % Num(b);
                        }
                        throw new ExprException("Unknown operator " + bin.Op);
                    }
            }
            throw new ExprException("Unknown node");
        }

        static string ToStr(object v)
        {
            switch (v)
            {
                case null: return "undefined";
                case bool b: return b ? "true" : "false";
                case double d: return d.ToString("R", CultureInfo.InvariantCulture);
                default: return Convert.ToString(v, CultureInfo.InvariantCulture);
            }
        }

        static object Call(CallNode call, IExprScope scope)
        {
            if (call.Fn == "done") return scope != null && scope.IsDone(ToStr(((LitNode)call.Args[0]).Value));
            var a = new double[call.Args.Length];
            for (int i = 0; i < a.Length; i++) a[i] = Num(Eval(call.Args[i], scope));
            switch (call.Fn)
            {
                case "abs": return Math.Abs(a[0]);
                case "min": { double m = a[0]; for (int i = 1; i < a.Length; i++) m = Math.Min(m, a[i]); return m; }
                case "max": { double m = a[0]; for (int i = 1; i < a.Length; i++) m = Math.Max(m, a[i]); return m; }
                // JS Math.round semantics (half up) so both runtimes agree.
                case "round": { double pw = Math.Pow(10, a.Length > 1 ? a[1] : 0); return Math.Floor(a[0] * pw + 0.5) / pw; }
                case "clamp": return Math.Min(Math.Max(a[0], a[1]), a[2]);
                case "between": return a[0] >= a[1] && a[0] <= a[2];
            }
            throw new ExprException("Unknown function " + call.Fn);
        }

        /// <summary>All dotted paths and done('id') step references in an expression.</summary>
        public static (List<string> paths, List<string> steps) References(string src)
        {
            var paths = new List<string>(); var steps = new List<string>();
            void Walk(ExprNode n)
            {
                switch (n)
                {
                    case PathNode p: paths.Add(p.Joined); break;
                    case CallNode c when c.Fn == "done": steps.Add(ToStr(((LitNode)c.Args[0]).Value)); break;
                    case CallNode c: foreach (var a in c.Args) Walk(a); break;
                    case UnaryNode u: Walk(u.A); break;
                    case BinNode b: Walk(b.A); Walk(b.B); break;
                }
            }
            Walk(Parse(src));
            return (paths, steps);
        }
    }
}
