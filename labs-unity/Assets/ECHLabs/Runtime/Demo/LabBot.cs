using System;
using System.Text.RegularExpressions;
using ECHLabs.Core;
using Newtonsoft.Json.Linq;

namespace ECHLabs.Runtime.Demo
{
    /// <summary>
    /// A careful "perfect student": what to do for each step, and the small corrections a real
    /// student makes while waiting (closing the burette tap to drop-wise near the end point,
    /// stopping the stopwatch after 20 swings, typing the next command). Used by the in-lab demo
    /// (with hands, slowly, narrated) and by the automated end-to-end player (AutoPlay).
    /// </summary>
    public sealed class LabBot
    {
        static readonly Regex CommandUntil = new Regex(@"lastCommand == '(.+)'");
        int cmdIndex;
        double lastTap = -1;
        float typeTimer;
        double oscAtStart, lastOsc;
        bool watchPending;

        public struct Move
        {
            public Intent Intent;
            public bool Animate; // hands act it out (false for tiny continuous corrections)
        }

        /// <summary>The main action of an action step.</summary>
        public Intent? First(ScenarioRuntime rt, StepSpec step)
        {
            var e = step.Expect;
            if (e == null || !Enum.TryParse<IntentType>(e.Intent, out var type)) return null;
            double? value = e.Value != null ? (e.Value.Min + e.Value.Max) / 2 : type == IntentType.Rotate ? 1.0 : (double?)null;
            lastTap = type == IntentType.Rotate ? value ?? -1 : -1;
            typeTimer = 0;
            // Stopwatch: like a careful student, start it as the bob passes the centre (Adjust does it).
            watchPending = false;
            if (type == IntentType.Toggle && rt.World.Spec(e.Target)?.Type == "stopwatch" && !rt.World.Bool(e.Target, "running") && rt.World.OfType("pendulum").GetEnumerator().MoveNext())
            {
                watchPending = true;
                lastOsc = Oscillations(rt.World);
                return null;
            }
            string text = type == IntentType.Type ? NextCommand(rt, step) : null;
            return new Intent { Type = type, Target = e.Target, Into = e.Into, Value = value, Text = text };
        }

        /// <summary>Called every frame while waiting for the step's condition; returns a correction or null.</summary>
        public Move? Adjust(ScenarioRuntime rt, StepSpec step, float dt)
        {
            var e = step.Expect;
            if (e == null) return null;
            var w = rt.World;
            if (e.Intent == "Rotate" && w.Spec(e.Target)?.Type == "burette")
            {
                double nearEnd = w.Var("titr", "equivalenceVolumeMl") - w.Num(e.Target, "dispensedMl");
                if (nearEnd < 0.6 && Math.Abs(lastTap - 0.25) > 1e-6)
                {
                    lastTap = 0.25; // ≈0.16 mL/s: drop by drop near the end point
                    return new Move { Intent = Intent.Of(IntentType.Rotate, e.Target, null, 0.25), Animate = true };
                }
            }
            if (watchPending && e.Intent == "Toggle")
            {
                double osc = Oscillations(w);
                if (osc != lastOsc)
                {
                    watchPending = false;
                    oscAtStart = osc;
                    return new Move { Intent = Intent.Of(IntentType.Toggle, e.Target), Animate = true };
                }
                return null;
            }
            if (e.Intent == "Toggle" && w.Spec(e.Target)?.Type == "stopwatch" && w.Bool(e.Target, "running")
                && Oscillations(w) - oscAtStart >= 20 && Oscillations(w) >= 20)
                return new Move { Intent = Intent.Of(IntentType.Toggle, e.Target), Animate = true };
            if (e.Intent == "Type")
            {
                typeTimer += dt;
                if (typeTimer > 1.6f)
                {
                    typeTimer = 0;
                    return new Move { Intent = new Intent { Type = IntentType.Type, Target = e.Target, Text = NextCommand(rt, step) }, Animate = true };
                }
            }
            return null;
        }

        static double Oscillations(LabWorld w)
        {
            double n = 0;
            foreach (var p in w.OfType("pendulum")) n = Math.Max(n, w.Num(p.Id, "oscillations"));
            return n;
        }

        /// <summary>Tidy-up after a step (close the burette tap).</summary>
        public Intent? After(ScenarioRuntime rt, StepSpec step)
        {
            var e = step.Expect;
            if (e != null && e.Intent == "Rotate" && rt.World.Spec(e.Target)?.Type == "burette") return Intent.Of(IntentType.Rotate, e.Target, null, 0);
            return null;
        }

        /// <summary>Terminals: the exact command a step asks for, else walk the offered ones (never allowing risky ports).</summary>
        public string NextCommand(ScenarioRuntime rt, StepSpec step)
        {
            if (step.Until != null) { var m = CommandUntil.Match(step.Until); if (m.Success) return m.Groups[1].Value; }
            var spec = rt.World.Spec(step.Expect.Target);
            if (spec?.Init == null || !spec.Init.TryGetValue("commands", out var tok) || !(tok is JArray arr) || arr.Count == 0) return "login";
            for (int i = 0; i < arr.Count; i++)
            {
                var c = arr[(cmdIndex + i) % arr.Count].ToString();
                if (c.StartsWith("allow") && (c.Contains("23") || c.Contains("3389"))) continue;
                cmdIndex = (cmdIndex + i + 1) % arr.Count;
                return c;
            }
            return "apply";
        }
    }
}
