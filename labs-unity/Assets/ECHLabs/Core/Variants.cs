// ECH Labs — "new values every try". 1:1 port of backend/src/services/labs/variant.js.
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text.RegularExpressions;
using Newtonsoft.Json.Linq;

namespace ECHLabs.Core
{
    /// <summary>
    /// A variant is the set of values picked for one attempt ({ flask1: { conc: 0.094 } }).
    /// Applying it overrides equipment init values, renders label templates ("Resistor {r1.ohms} Ω")
    /// and recomputes results with an expectedExpr. Used offline/practice and for the demo run
    /// (which deliberately gets different values from the student's own attempt).
    /// </summary>
    public static class Variants
    {
        static readonly Regex Placeholder = new Regex(@"\{([A-Za-z][A-Za-z0-9_]*)\.([A-Za-z][A-Za-z0-9_]*)\}");

        public static Dictionary<string, Dictionary<string, double>> Pick(ScenarioDefinition def, Random rng)
        {
            var result = new Dictionary<string, Dictionary<string, double>>();
            foreach (var r in def.Randomize ?? new List<RandomizeSpec>())
            {
                var parts = r.Path.Split('.');
                if (parts.Length != 2) continue;
                double v;
                if (r.Choices != null && r.Choices.Count > 0) v = r.Choices[rng.Next(r.Choices.Count)];
                else if (r.Min.HasValue && r.Max.HasValue) v = Math.Round(r.Min.Value + (r.Max.Value - r.Min.Value) * rng.NextDouble(), r.Decimals);
                else continue;
                if (!result.TryGetValue(parts[0], out var d)) result[parts[0]] = d = new Dictionary<string, double>();
                d[parts[1]] = v;
            }
            return result;
        }

        static bool Allowed(RandomizeSpec r, double v)
        {
            if (double.IsNaN(v) || double.IsInfinity(v)) return false;
            if (r.Choices != null && r.Choices.Count > 0) return r.Choices.Contains(v);
            return r.Min.HasValue && r.Max.HasValue && v >= r.Min.Value - 1e-9 && v <= r.Max.Value + 1e-9;
        }

        /// <summary>Applies in place (call on a Clone() to keep the original).</summary>
        public static void Apply(ScenarioDefinition def, Dictionary<string, Dictionary<string, double>> variant)
        {
            var rules = new Dictionary<string, RandomizeSpec>();
            foreach (var r in def.Randomize ?? new List<RandomizeSpec>()) rules[r.Path] = r;
            if (variant != null)
                foreach (var eq in def.Equipment)
                {
                    if (!variant.TryGetValue(eq.Id, out var values)) continue;
                    foreach (var kv in values)
                        if (rules.TryGetValue(eq.Id + "." + kv.Key, out var rule) && Allowed(rule, kv.Value))
                        {
                            eq.Init ??= new Dictionary<string, JToken>();
                            eq.Init[kv.Key] = new JValue(kv.Value);
                        }
                }

            var scope = new InitScope(def);
            foreach (var eq in def.Equipment)
            {
                string tpl = eq.LabelTemplate ?? (eq.Label != null && eq.Label.Contains("{") ? eq.Label : null);
                if (tpl == null) continue;
                eq.LabelTemplate = tpl;
                eq.Label = Placeholder.Replace(tpl, m =>
                {
                    var v = scope.Resolve(new[] { m.Groups[1].Value, m.Groups[2].Value });
                    return v is double d ? Format(d) : v != null ? v.ToString() : m.Value;
                });
            }
            foreach (var r in def.Results)
            {
                if (string.IsNullOrEmpty(r.ExpectedExpr)) continue;
                try
                {
                    double v = Expr.Number(r.ExpectedExpr, scope);
                    if (!double.IsNaN(v) && !double.IsInfinity(v)) r.Expected = Math.Round(v, 4);
                }
                catch (ExprException) { }
            }
        }

        /// <summary>Practice/offline and the demo: pick fresh values unless the server already did.</summary>
        public static bool ApplyRandom(ScenarioDefinition def, Random rng)
        {
            if (def.Randomize == null || def.Randomize.Count == 0) { Apply(def, null); return false; }
            Apply(def, Pick(def, rng));
            return true;
        }

        static string Format(double d) => Math.Round(d, 4).ToString("0.####", CultureInfo.InvariantCulture);

        /// <summary>Equipment init values as an expression scope ("flask1.conc").</summary>
        sealed class InitScope : IExprScope
        {
            readonly ScenarioDefinition def;
            public InitScope(ScenarioDefinition d) { def = d; }
            public object Resolve(IReadOnlyList<string> path)
            {
                if (path.Count != 2) return null;
                var eq = def.FindEquipment(path[0]);
                if (eq?.Init == null || !eq.Init.TryGetValue(path[1], out var t) || t == null) return null;
                if (t.Type == JTokenType.Float || t.Type == JTokenType.Integer) return t.Value<double>();
                if (t.Type == JTokenType.String) return t.Value<string>();
                if (t.Type == JTokenType.Boolean) return t.Value<bool>();
                return null;
            }
            public bool IsDone(string stepId) => false;
        }
    }
}
