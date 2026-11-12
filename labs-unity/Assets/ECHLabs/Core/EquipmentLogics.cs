// ECH Labs — behaviour of each equipment type (pure C#).
// State keys match backend/src/services/labs/catalog.json "state".
using System;
using System.Linq;
using ECHLabs.Sim;

namespace ECHLabs.Core
{
    public static class EquipmentLogics
    {
        public static IEquipmentLogic Create(string type)
        {
            switch (type)
            {
                case "goggles": case "labcoat": case "gloves": return new WearableLogic();
                case "reagent_bottle": case "beaker": case "pipette": return new ContainerLogic();
                case "burette": return new BuretteLogic();
                case "conical_flask": return new FlaskLogic();
                case "indicator": case "stain": return new DropperLogic();
                case "funnel": return new FunnelLogic();
                case "power_supply": return new PowerSupplyLogic();
                case "resistor": case "ammeter": case "voltmeter": case "patch_cable": return new ConnectableLogic();
                case "breadboard": return new CircuitBoardLogic();
                case "pendulum": return new PendulumLogic();
                case "stopwatch": return new StopwatchLogic();
                case "microscope": return new MicroscopeLogic();
                case "slide": return new SlideLogic();
                case "bunsen_burner": return new BunsenLogic();
                case "workstation": case "firewall": return new TerminalLogic();
                default: return new StaticLogic(); // retort stand, tile, rule, displays, racks…
            }
        }
    }

    public class StaticLogic : IEquipmentLogic
    {
        protected string Id;
        public virtual void Init(EquipmentSpec spec, LabWorld w) { Id = spec.Id; }
        public virtual bool Apply(Intent i, LabWorld w)
        {
            switch (i.Type)
            {
                case IntentType.Grab: w.Set(Id, "held", true); return true;
                case IntentType.Release: w.Set(Id, "held", false); return true;
                case IntentType.Toggle: w.Set(Id, "on", !w.Bool(Id, "on")); return true;
                case IntentType.Connect: w.Set(Id, "connected", true); return true;
                default: return i.Type == IntentType.Select || i.Type == IntentType.Inspect;
            }
        }
        public virtual void Tick(double dt, LabWorld w) { }
    }

    /// <summary>Goggles, lab coat, gloves: Grab = put on, Release = take off.</summary>
    public sealed class WearableLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w) { base.Init(spec, w); w.Set(Id, "worn", false); }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Grab) { w.Set(Id, "worn", true); return true; }
            if (i.Type == IntentType.Release) { w.Set(Id, "worn", false); return true; }
            return base.Apply(i, w);
        }
    }

    /// <summary>Reagent bottle / beaker / pipette: pours its solution into a receiver.</summary>
    public class ContainerLogic : StaticLogic, ILiquidReceiver
    {
        public const double DefaultPourMl = 10;
        public override void Init(EquipmentSpec spec, LabWorld w)
        {
            base.Init(spec, w);
            w.Set(Id, "volumeMl", spec.InitNumber("volume", 0));
            w.Set(Id, "poured", false);
            w.Set(Id, "filled", spec.InitNumber("volume", 0) > 0);
        }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type != IntentType.Pour) return base.Apply(i, w);
            double available = w.Num(Id, "volumeMl");
            if (available <= 0) { w.Emit("empty", Id, "This container is empty."); return false; }
            // Receivers that know how much they want (e.g. a burette being filled) are given it.
            double amount = Math.Min(available, i.Value ?? Wanted(i.Into, w));
            if (!w.Transfer(i.Into, w.Str(Id, "solution"), w.Num(Id, "conc"), amount, Id)) { w.Set(Id, "volumeMl", available - amount); w.Set(Id, "poured", true); return false; }
            w.Set(Id, "volumeMl", available - amount);
            w.Set(Id, "poured", true);
            return true;
        }
        static double Wanted(string into, LabWorld w)
            => into != null && w.Logic.TryGetValue(into, out var l) && l is BuretteLogic b ? b.WantedMl(w) : DefaultPourMl;

        public void Receive(LabWorld w, string solution, double conc, double volumeMl)
        {
            double v = w.Num(Id, "volumeMl");
            double total = v + volumeMl;
            // Mixing the same solution: concentration-weighted.
            if (w.Str(Id, "solution") == null || w.Str(Id, "solution") == solution)
            {
                w.Set(Id, "solution", solution);
                w.Set(Id, "conc", total > 0 ? (w.Num(Id, "conc") * v + conc * volumeMl) / total : conc);
            }
            w.Set(Id, "volumeMl", total);
            w.Set(Id, "filled", true);
        }
    }

    /// <summary>
    /// 50 mL burette. Graduations read from the top (0.00) to the bottom (50.00):
    /// reading = capacity − volume. The first pour into an empty, un-rinsed burette is a rinse.
    /// Rotate sets the tap opening 0…1 (quadratic: fine drop-wise control near closed).
    /// </summary>
    public sealed class BuretteLogic : StaticLogic, ILiquidReceiver
    {
        public const double Capacity = 50;
        public const double RinseMl = 5;
        public const double MaxFlowMlPerS = 2.5;
        double fillTarget;

        public override void Init(EquipmentSpec spec, LabWorld w)
        {
            base.Init(spec, w);
            w.Set(Id, "volumeMl", 0.0);
            w.Set(Id, "dispensedMl", 0.0);
            w.Set(Id, "filled", false);
            w.Set(Id, "rinsed", false);
            w.Set(Id, "tapOpen", 0.0);
            w.Set(Id, "reading", Capacity);
            // Students fill "to just above zero, then run down": the start reading is never exactly 0.00.
            fillTarget = Capacity - Math.Round((0.1 + w.Rng.NextDouble() * 0.8) * 20) / 20; // 0.10…0.90 in 0.05 steps
        }

        public double WantedMl(LabWorld w)
            => !w.Bool(Id, "rinsed") && w.Num(Id, "volumeMl") <= 0 ? RinseMl : Math.Max(fillTarget - w.Num(Id, "volumeMl"), 0.5);

        public void Receive(LabWorld w, string solution, double conc, double volumeMl)
        {
            if (!w.Bool(Id, "rinsed") && w.Num(Id, "volumeMl") <= 0)
            {
                w.Set(Id, "rinsed", true); // rinse portion drained to waste
                w.Emit("rinse", Id, "Burette rinsed with " + solution + ".");
                return;
            }
            double v = Math.Min(w.Num(Id, "volumeMl") + volumeMl, Capacity);
            if (w.Num(Id, "volumeMl") + volumeMl > Capacity + 0.01) w.Emit("overflow", Id, "The burette overflowed.");
            w.Set(Id, "solution", solution);
            w.Set(Id, "conc", conc);
            w.Set(Id, "volumeMl", v);
            w.Set(Id, "filled", v >= 45);
            w.Set(Id, "reading", Capacity - v);
        }

        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Rotate)
            {
                double open = i.Value.HasValue ? Math.Min(Math.Max(i.Value.Value, 0), 1) : (w.Num(Id, "tapOpen") > 0 ? 0 : 0.3);
                w.Set(Id, "tapOpen", open);
                return true;
            }
            return base.Apply(i, w);
        }

        public override void Tick(double dt, LabWorld w)
        {
            double open = w.Num(Id, "tapOpen");
            double v = w.Num(Id, "volumeMl");
            if (open <= 0 || v <= 0) return;
            double flow = Math.Min(MaxFlowMlPerS * open * open * dt, v);
            v -= flow;
            w.Set(Id, "volumeMl", v);
            w.Set(Id, "reading", Capacity - v);
            w.Set(Id, "dispensedMl", w.Num(Id, "dispensedMl") + flow);
            var receiver = w.Definition.Equipment.FirstOrDefault(e => w.Bool(e.Id, "underBurette"));
            w.Transfer(receiver?.Id, w.Str(Id, "solution"), w.Num(Id, "conc"), flow, Id);
            if (v <= 0) { w.Set(Id, "tapOpen", 0.0); w.Emit("empty", Id, "The burette is empty."); }
        }
    }

    /// <summary>Conical flask holding the analyte; tracks base added from the burette.</summary>
    public sealed class FlaskLogic : StaticLogic, ILiquidReceiver
    {
        public override void Init(EquipmentSpec spec, LabWorld w)
        {
            base.Init(spec, w);
            w.Set(Id, "volumeMl", spec.InitNumber("volume", 0));
            w.Set(Id, "baseAddedMl", 0.0);
            w.Set(Id, "hasIndicator", false);
            w.Set(Id, "swirled", false);
            w.Set(Id, "underBurette", false);
        }

        public void Receive(LabWorld w, string solution, double conc, double volumeMl)
        {
            w.Set(Id, "volumeMl", w.Num(Id, "volumeMl") + volumeMl);
            if (solution != null && Chemistry.StrongBases.Contains(solution))
            {
                // Track moles of base as an equivalent volume at the burette concentration.
                w.Set(Id, "baseMol", w.Num(Id, "baseMol") + conc * volumeMl / 1000.0);
                w.Set(Id, "baseAddedMl", w.Num(Id, "baseAddedMl") + volumeMl);
            }
            if (w.Num(Id, "volumeMl") > 250) w.Emit("overflow", Id, "The flask overflowed.");
        }

        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Grab)
            {
                // Placing it on the white tile puts it under the burette.
                bool onTile = i.Into != null && w.Spec(i.Into)?.Type == "white_tile";
                w.Set(Id, "underBurette", onTile);
                w.Set(Id, "swirled", true);
                return true;
            }
            if (i.Type == IntentType.Rotate) { w.Set(Id, "swirled", true); return true; }
            return base.Apply(i, w);
        }
    }

    /// <summary>Indicator / stain dropper: pours drops into a flask or onto a slide.</summary>
    public sealed class DropperLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w) { base.Init(spec, w); w.Set(Id, "dropsAdded", 0.0); }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type != IntentType.Pour) return base.Apply(i, w);
            if (i.Into == null || !w.Equipment.ContainsKey(i.Into)) { w.Emit("spill", Id, "The drops fell on the bench."); return false; }
            double drops = i.Value ?? 3;
            w.Set(Id, "dropsAdded", w.Num(Id, "dropsAdded") + drops);
            var type = w.Spec(i.Into).Type;
            if (type == "slide") w.Set(i.Into, "stained", true);
            else
            {
                w.Set(i.Into, "hasIndicator", true);
                w.Set(i.Into, "indicator", w.Str(Id, "name"));
            }
            return true;
        }
    }

    public sealed class FunnelLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w) { base.Init(spec, w); w.Set(Id, "inPlace", false); }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Grab) { w.Set(Id, "inPlace", !w.Bool(Id, "inPlace")); return true; }
            if (i.Type == IntentType.Release) { w.Set(Id, "inPlace", false); return true; }
            return base.Apply(i, w);
        }
    }

    public sealed class PowerSupplyLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w)
        {
            base.Init(spec, w);
            w.Set(Id, "on", false);
            w.Set(Id, "voltageV", 0.0);
            w.Set(Id, "maxVoltage", spec.InitNumber("maxVoltage", 12));
        }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Rotate)
            {
                double v = i.Value ?? w.Num(Id, "voltageV") + 0.5;
                w.Set(Id, "voltageV", Math.Round(Math.Min(Math.Max(v, 0), w.Num(Id, "maxVoltage")) * 10) / 10);
                return true;
            }
            return base.Apply(i, w);
        }
    }

    public sealed class ConnectableLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w)
        {
            base.Init(spec, w);
            w.Set(Id, "connected", false);
            w.Set(Id, "reading", 0.0);
        }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Connect) { w.Set(Id, "connected", i.Into != null); return true; }
            if (i.Type == IntentType.Release) { w.Set(Id, "connected", false); return true; }
            return base.Apply(i, w);
        }
    }

    /// <summary>
    /// Series circuit on the board: supply → ammeter → resistors, voltmeter across the resistors.
    /// An ammeter connected with no load is a short circuit across the supply.
    /// </summary>
    public sealed class CircuitBoardLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w)
        {
            base.Init(spec, w);
            w.Set(Id, "closed", false);
            w.Set(Id, "shortCircuit", false);
            w.Set(Id, "currentA", 0.0);
            w.Set(Id, "voltageV", 0.0);
            w.Set(Id, "powerW", 0.0);
        }

        public override void Tick(double dt, LabWorld w)
        {
            var psu = w.OfType("power_supply").FirstOrDefault();
            var ammeter = w.OfType("ammeter").FirstOrDefault();
            var voltmeter = w.OfType("voltmeter").FirstOrDefault();
            var resistors = w.OfType("resistor").Where(r => w.Bool(r.Id, "connected")).Select(r => r.InitNumber("ohms", 10)).ToList();
            bool on = psu != null && w.Bool(psu.Id, "on");
            double supply = psu != null ? w.Num(psu.Id, "voltageV") : 0;
            bool ammeterIn = ammeter == null || w.Bool(ammeter.Id, "connected");
            bool closed = resistors.Count > 0 && ammeterIn;
            bool shortCircuit = on && supply > 0 && ammeter != null && w.Bool(ammeter.Id, "connected") && resistors.Count == 0;
            double current = 0, load = 0;
            if (on && closed)
            {
                var r = Physics.SeriesCircuit(supply, resistors, internalOhm: 0);
                current = r.CurrentA;
                load = r.LoadVoltageV;
            }
            w.Set(Id, "closed", closed);
            if (shortCircuit && !w.Bool(Id, "shortCircuit")) w.Emit("shortCircuit", Id, "Short circuit!");
            w.Set(Id, "shortCircuit", shortCircuit);
            w.Set(Id, "currentA", current);
            w.Set(Id, "voltageV", load);
            w.Set(Id, "powerW", current * load);
            if (ammeter != null) w.Set(ammeter.Id, "reading", w.Bool(ammeter.Id, "connected") ? Math.Round(current * 1000) / 1000 : 0.0);
            if (voltmeter != null) w.Set(voltmeter.Id, "reading", w.Bool(voltmeter.Id, "connected") ? Math.Round(load * 100) / 100 : 0.0);
        }
    }

    public sealed class PendulumLogic : StaticLogic
    {
        double swingTime;
        public override void Init(EquipmentSpec spec, LabWorld w)
        {
            base.Init(spec, w);
            w.Set(Id, "lengthM", spec.InitNumber("lengthM", 1));
            w.Set(Id, "amplitudeDeg", 0.0);
            w.Set(Id, "swinging", false);
            w.Set(Id, "oscillations", 0.0);
            w.Set(Id, "angleDeg", 0.0);
        }
        public override bool Apply(Intent i, LabWorld w)
        {
            switch (i.Type)
            {
                case IntentType.Grab: w.Set(Id, "swinging", false); w.Set(Id, "held", true); return true;
                case IntentType.Rotate: w.Set(Id, "amplitudeDeg", Math.Min(Math.Max(i.Value ?? 8, 0), 60)); return true;
                case IntentType.Release:
                    if (i.Value.HasValue) w.Set(Id, "amplitudeDeg", Math.Min(Math.Max(i.Value.Value, 0), 60));
                    if (w.Num(Id, "amplitudeDeg") <= 0) w.Set(Id, "amplitudeDeg", 8.0);
                    w.Set(Id, "held", false);
                    w.Set(Id, "swinging", true);
                    w.Set(Id, "oscillations", 0.0);
                    swingTime = 0;
                    return true;
            }
            return base.Apply(i, w);
        }
        public override void Tick(double dt, LabWorld w)
        {
            if (!w.Bool(Id, "swinging")) return;
            swingTime += dt;
            double L = w.Num(Id, "lengthM"), amp = w.Num(Id, "amplitudeDeg");
            w.Set(Id, "oscillations", Math.Floor(swingTime / Physics.PendulumPeriod(L, amp)));
            w.Set(Id, "angleDeg", Physics.PendulumAngleDeg(L, amp, swingTime));
        }
    }

    public sealed class StopwatchLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w) { base.Init(spec, w); w.Set(Id, "running", false); w.Set(Id, "elapsedS", 0.0); }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Toggle) { w.Set(Id, "running", !w.Bool(Id, "running")); return true; }
            if (i.Type == IntentType.Select && !w.Bool(Id, "running")) { w.Set(Id, "elapsedS", 0.0); return true; } // reset
            return base.Apply(i, w);
        }
        public override void Tick(double dt, LabWorld w) { if (w.Bool(Id, "running")) w.Set(Id, "elapsedS", w.Num(Id, "elapsedS") + dt); }
    }

    /// <summary>Rotate value ≤ 1 = focus knob; value in {4,10,40,100} = objective turret.</summary>
    public sealed class MicroscopeLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w)
        {
            base.Init(spec, w);
            w.Set(Id, "objective", 4.0);
            w.Set(Id, "focus", 0.0);
            w.Set(Id, "lightOn", false);
            w.Set(Id, "slideLoaded", false);
            w.Set(Id, "lastCommand", "");
        }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Toggle) { w.Set(Id, "lightOn", !w.Bool(Id, "lightOn")); return true; }
            if (i.Type == IntentType.Type && !string.IsNullOrEmpty(i.Text))
            {
                // Turret: "4x", "10x", "40x", "100x"
                var t = i.Text.Trim().ToLowerInvariant().TrimEnd('x', '×');
                if (!double.TryParse(t, System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out var obj) || obj <= 1) return false;
                w.Set(Id, "objective", obj);
                w.Set(Id, "lastCommand", i.Text.Trim());
                return true;
            }
            if (i.Type == IntentType.Rotate && i.Value.HasValue)
            {
                if (i.Value.Value > 1) w.Set(Id, "objective", i.Value.Value);
                else w.Set(Id, "focus", Math.Max(i.Value.Value, 0));
                return true;
            }
            return base.Apply(i, w);
        }
    }

    public sealed class SlideLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w) { base.Init(spec, w); w.Set(Id, "stained", false); w.Set(Id, "coverslip", false); w.Set(Id, "onStage", false); }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Grab && i.Into != null && w.Spec(i.Into)?.Type == "microscope")
            {
                w.Set(Id, "onStage", true);
                w.Set(i.Into, "slideLoaded", true);
                return true;
            }
            if (i.Type == IntentType.Select && w.Bool(Id, "stained")) { w.Set(Id, "coverslip", true); return true; }
            return base.Apply(i, w);
        }
    }

    public sealed class BunsenLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w) { base.Init(spec, w); w.Set(Id, "lit", false); w.Set(Id, "airHole", 0.0); }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Toggle) { w.Set(Id, "lit", !w.Bool(Id, "lit")); return true; }
            if (i.Type == IntentType.Rotate) { w.Set(Id, "airHole", Math.Min(Math.Max(i.Value ?? 1, 0), 1)); return true; }
            return base.Apply(i, w);
        }
    }

    /// <summary>Workstation / firewall: typed commands are counted; rules appended (scripted scenarios read them).</summary>
    public sealed class TerminalLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w)
        {
            base.Init(spec, w);
            w.Set(Id, "loggedIn", false);
            w.Set(Id, "commandsRun", 0.0);
            w.Set(Id, "rules", "");
            w.Set(Id, "applied", false);
            w.Set(Id, "lastCommand", "");
        }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type != IntentType.Type) return base.Apply(i, w);
            var cmd = (i.Text ?? "").Trim();
            if (cmd.Length == 0) return false;
            w.Set(Id, "commandsRun", w.Num(Id, "commandsRun") + 1);
            w.Set(Id, "lastCommand", cmd);
            if (cmd == "login") w.Set(Id, "loggedIn", true);
            else if (cmd == "apply") w.Set(Id, "applied", true);
            else if (cmd.StartsWith("allow ") || cmd.StartsWith("deny "))
            {
                // A repeated rule is not a new rule.
                var existing = (w.Str(Id, "rules") ?? "").Split('\n');
                if (Array.IndexOf(existing, cmd) < 0) w.Set(Id, "rules", (w.Str(Id, "rules") + "\n" + cmd).Trim());
            }
            return true;
        }
    }
}
