// ECH Labs — the simulated lab: equipment state + behaviour, engine-independent.
// Unity components (ECHLabs.Runtime) render this state; they never own the science.
using System;
using System.Collections.Generic;
using System.Globalization;

namespace ECHLabs.Core
{
    public enum IntentType { Select, Grab, Release, Pour, Rotate, Inspect, Toggle, Connect, Type }

    /// <summary>
    /// Everything a student can do, independent of input device: a mouse click, a tap,
    /// a 1.2 s gaze dwell in Cardboard and an XR controller trigger all become Intents.
    /// </summary>
    public struct Intent
    {
        public IntentType Type;
        public string Target;  // equipment acted on
        public string Into;    // receiver (pour into, place onto, connect to)
        public double? Value;  // knob/tap position, amount in mL, angle…
        public string Text;    // typed command (terminals)

        public static Intent Of(IntentType type, string target, string into = null, double? value = null, string text = null)
            => new Intent { Type = type, Target = target, Into = into, Value = value, Text = text };

        public override string ToString()
            => $"{Type} {Target}{(Into != null ? " → " + Into : "")}{(Value.HasValue ? " = " + Value.Value.ToString("0.###", CultureInfo.InvariantCulture) : "")}";
    }

    public sealed class WorldEvent
    {
        public string Type;    // spill, overflow, reaction, shortCircuit…
        public string Source;
        public string Message;
    }

    public interface IEquipmentLogic
    {
        void Init(EquipmentSpec spec, LabWorld world);
        /// <summary>Applies an intent targeting this equipment. Returns false if the action is impossible.</summary>
        bool Apply(Intent intent, LabWorld world);
        void Tick(double dt, LabWorld world);
    }

    /// <summary>Equipment that can receive liquid (burette, flask, beaker…).</summary>
    public interface ILiquidReceiver
    {
        void Receive(LabWorld world, string solution, double conc, double volumeMl);
    }

    public sealed class LabWorld : IExprScope
    {
        public readonly ScenarioDefinition Definition;
        public readonly Dictionary<string, Dictionary<string, object>> Equipment = new Dictionary<string, Dictionary<string, object>>();
        public readonly Dictionary<string, Dictionary<string, object>> Variables = new Dictionary<string, Dictionary<string, object>>();
        public readonly Dictionary<string, double> Records = new Dictionary<string, double>();
        public readonly HashSet<string> Done = new HashSet<string>();
        public readonly Dictionary<string, IEquipmentLogic> Logic = new Dictionary<string, IEquipmentLogic>();
        /// <summary>Simulated contents of containers (beakers, tubes, flasks…), keyed by equipment id.</summary>
        public readonly Dictionary<string, ECHLabs.Sim.Mixture> Mixtures = new Dictionary<string, ECHLabs.Sim.Mixture>();
        public readonly Random Rng;
        public double Time;
        public int Mistakes;
        public int HintsUsed;

        public event Action<WorldEvent> OnEvent;

        public LabWorld(ScenarioDefinition def, int seed = 0)
        {
            Definition = def;
            Rng = new Random(seed == 0 ? Environment.TickCount : seed);
            foreach (var eq in def.Equipment)
            {
                var state = new Dictionary<string, object>();
                if (eq.Init != null)
                    foreach (var kv in eq.Init)
                        state[kv.Key] = kv.Value.Type == Newtonsoft.Json.Linq.JTokenType.String ? (object)kv.Value.ToString()
                                      : kv.Value.Type == Newtonsoft.Json.Linq.JTokenType.Boolean ? (object)kv.Value.ToObject<bool>()
                                      : kv.Value.Type == Newtonsoft.Json.Linq.JTokenType.Array ? (object)kv.Value.ToString()
                                      : kv.Value.ToObject<double>();
                Equipment[eq.Id] = state;
            }
            foreach (var eq in def.Equipment)
            {
                var logic = EquipmentLogics.Create(eq.Type);
                Logic[eq.Id] = logic;
                logic.Init(eq, this);
            }
            foreach (var kv in def.Variables) Variables[kv.Key] = new Dictionary<string, object>();
            VariableModels.UpdateAll(this);
        }

        // ─── State access ────────────────────────────────────────────────────

        public double Num(string eq, string key, double fallback = 0)
            => Equipment.TryGetValue(eq, out var s) && s.TryGetValue(key, out var v) && v != null ? Expr.Num(v) : fallback;
        public bool Bool(string eq, string key)
            => Equipment.TryGetValue(eq, out var s) && s.TryGetValue(key, out var v) && Expr.Truthy(v);
        public string Str(string eq, string key)
            => Equipment.TryGetValue(eq, out var s) && s.TryGetValue(key, out var v) ? v as string : null;
        public void Set(string eq, string key, object value)
        {
            if (!Equipment.TryGetValue(eq, out var s)) Equipment[eq] = s = new Dictionary<string, object>();
            s[key] = value;
        }
        public double Var(string name, string output)
            => Variables.TryGetValue(name, out var v) && v.TryGetValue(output, out var o) ? Expr.Num(o) : 0;

        public EquipmentSpec Spec(string id) => Definition.FindEquipment(id);
        public ECHLabs.Sim.Mixture MixtureOf(string id) => id != null && Mixtures.TryGetValue(id, out var m) ? m : null;
        /// <summary>Human name of a piece of equipment (its label, or its type).</summary>
        public string Label(string id)
        {
            var s = Spec(id);
            if (s == null) return id ?? "";
            return !string.IsNullOrEmpty(s.Label) ? s.Label : s.Type.Replace('_', ' ');
        }
        public IEnumerable<EquipmentSpec> OfType(string type)
        {
            foreach (var e in Definition.Equipment) if (e.Type == type) yield return e;
        }

        public void Emit(string type, string source, string message) => OnEvent?.Invoke(new WorldEvent { Type = type, Source = source, Message = message });

        // ─── IExprScope ──────────────────────────────────────────────────────

        public object Resolve(IReadOnlyList<string> path)
        {
            if (path.Count == 0) return null;
            string head = path[0];
            if (path.Count == 1)
            {
                switch (head)
                {
                    case "time": return Time;
                    case "mistakes": return (double)Mistakes;
                    case "hintsUsed": return (double)HintsUsed;
                }
                return null;
            }
            if (path.Count != 2) return null;
            if (head == "record") return Records.TryGetValue(path[1], out var r) ? (object)r : null;
            if (Equipment.TryGetValue(head, out var eq)) return eq.TryGetValue(path[1], out var v) ? v : null;
            if (Variables.TryGetValue(head, out var vars)) return vars.TryGetValue(path[1], out var o) ? o : null;
            return null;
        }

        public bool IsDone(string stepId) => Done.Contains(stepId);

        // ─── Simulation ──────────────────────────────────────────────────────

        /// <summary>Executes an intent physically (sandbox: anything possible happens, right or wrong).</summary>
        public bool Apply(Intent intent)
        {
            if (intent.Target == null || !Logic.TryGetValue(intent.Target, out var logic)) return false;
            bool ok = logic.Apply(intent, this);
            VariableModels.UpdateAll(this);
            return ok;
        }

        public void Tick(double dt)
        {
            Time += dt;
            foreach (var kv in Logic) kv.Value.Tick(dt, this);
            Materials.Tick(this, dt);
            VariableModels.UpdateAll(this);
        }

        /// <summary>
        /// Moves liquid from a container into a receiver. The contents (Sim.Mixture) move with it,
        /// so reactions happen in the receiver; legacy receivers (burette, flask) also get Receive().
        /// </summary>
        public bool Transfer(string intoId, string solution, double conc, double volumeMl, string fromId)
        {
            if (volumeMl <= 0) return false;
            ILiquidReceiver receiver = intoId != null && Logic.TryGetValue(intoId, out var target) ? target as ILiquidReceiver : null;
            var src = MixtureOf(fromId);
            var dst = receiver != null ? MixtureOf(intoId) : null;
            if (src != null && src.LiquidMl > 1e-9)
                src.PourInto(dst ?? new ECHLabs.Sim.Mixture(), Math.Min(1, volumeMl / src.LiquidMl));
            else if (dst != null)
                dst.AddRecipe(solution, conc, volumeMl);
            if (receiver != null)
            {
                receiver.Receive(this, solution, conc, volumeMl);
                Materials.Sync(this, fromId);
                Materials.Sync(this, intoId);
                return true;
            }
            Materials.Sync(this, fromId);
            Emit("spill", fromId, "Liquid spilled on the bench.");
            return false;
        }

        // ─── Save / resume ───────────────────────────────────────────────────

        static ECHLabs.Sim.Mixture MixtureFrom(object value)
        {
            IDictionary<string, object> d = value as IDictionary<string, object>;
            if (d == null && value is Newtonsoft.Json.Linq.JObject jo)
            {
                d = new Dictionary<string, object>();
                foreach (var p in jo.Properties())
                    d[p.Name] = p.Value is Newtonsoft.Json.Linq.JObject inner ? inner.ToObject<Dictionary<string, double>>() : (object)p.Value.ToObject<double>();
            }
            return d != null ? ECHLabs.Sim.Mixture.FromSnapshot(d) : null;
        }

        public Dictionary<string, Dictionary<string, object>> SnapshotEquipment()
        {
            var copy = new Dictionary<string, Dictionary<string, object>>();
            foreach (var kv in Equipment) copy[kv.Key] = new Dictionary<string, object>(kv.Value);
            foreach (var kv in Mixtures) if (copy.TryGetValue(kv.Key, out var st)) st["_mix"] = kv.Value.Snapshot();
            return copy;
        }

        public void RestoreEquipment(Dictionary<string, Dictionary<string, object>> snapshot)
        {
            if (snapshot == null) return;
            foreach (var kv in snapshot)
            {
                if (!Equipment.ContainsKey(kv.Key)) continue;
                foreach (var s in kv.Value)
                {
                    if (s.Key == "_mix") { var mix = MixtureFrom(s.Value); if (mix != null) Mixtures[kv.Key] = mix; continue; }
                    Equipment[kv.Key][s.Key] = s.Value is long l ? (double)l : s.Value;
                }
            }
            VariableModels.UpdateAll(this);
        }
    }
}
