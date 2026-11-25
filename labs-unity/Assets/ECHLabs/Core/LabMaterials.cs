// ECH Labs — the general-purpose materials students use in their own experiments:
// containers with real contents (Sim.Mixture), heaters, probes, balance, gas tests,
// biology samples, and the extra physics kit (cells, switches, bulbs, LEDs, rheostats,
// springs, ramps, light gates, lenses). Engine-independent (pure C#).
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using ECHLabs.Sim;

namespace ECHLabs.Core
{
    /// <summary>World-level behaviour of mixtures: heating, placement, displacement, syncing state keys.</summary>
    public static class Materials
    {
        /// <summary>Types whose contents are simulated.</summary>
        public static readonly HashSet<string> MixtureTypes = new HashSet<string>
        { "reagent_bottle", "beaker", "pipette", "burette", "conical_flask", "test_tube", "measuring_cylinder", "evaporating_dish" };

        public static readonly Dictionary<string, double> CapacityMl = new Dictionary<string, double>
        {
            { "reagent_bottle", 1000 }, { "beaker", 250 }, { "pipette", 25 }, { "burette", 50 }, { "conical_flask", 250 },
            { "test_tube", 20 }, { "measuring_cylinder", 100 }, { "evaporating_dish", 60 },
        };

        /// <summary>Empty mass (g) of each item, for the balance.</summary>
        public static readonly Dictionary<string, double> EmptyMassG = new Dictionary<string, double>
        {
            { "beaker", 98.6 }, { "test_tube", 14.2 }, { "measuring_cylinder", 121.4 }, { "evaporating_dish", 58.9 }, { "conical_flask", 117.3 },
            { "pondweed", 1.8 }, { "slide", 4.6 },
        };

        static double Cooling(string type) => type switch { "test_tube" => 0.012, "evaporating_dish" => 0.01, "reagent_bottle" => 0.002, "measuring_cylinder" => 0.005, _ => 0.004 };

        /// <summary>Creates the contents of a container from its scenario init (solution, conc, volume).</summary>
        public static void InitMixture(EquipmentSpec spec, LabWorld w, double volumeMl)
        {
            var m = new Mixture();
            if (volumeMl > 0) m.AddRecipe(spec.InitString("solution", "water"), spec.InitNumber("conc", 0.1), volumeMl);
            double t = spec.InitNumber("temperature", Chem.RoomC);
            if (Math.Abs(t - Chem.RoomC) > 0.01) m.TemperatureC = t;
            w.Mixtures[spec.Id] = m;
            Sync(w, spec.Id);
        }

        public static void Tick(LabWorld w, double dt)
        {
            if (w.Mixtures.Count == 0) return;
            foreach (var kv in w.Mixtures)
            {
                string id = kv.Key;
                var m = kv.Value;
                var spec = w.Spec(id);
                string type = spec?.Type ?? "";
                // Heat sources this container sits in/on.
                double heatW = 0;
                double? bath = null;
                string on = w.Str(id, "placedIn");
                if (on != null)
                {
                    var heater = w.Spec(on)?.Type;
                    if (heater == "hot_plate" && w.Bool(on, "on")) heatW += w.Num(on, "powerW") * 0.7;
                    if (heater == "bunsen_burner" && w.Bool(on, "lit")) heatW += 120 + 260 * w.Num(on, "airHole");
                    if (heater == "water_bath" && w.Bool(on, "on")) bath = w.Num(on, "temperatureC", Chem.RoomC);
                    if (heater == "water_bath" && !w.Bool(on, "on")) bath = w.Num(on, "temperatureC", Chem.RoomC);
                }
                // Objects immersed in a measuring cylinder push the level up.
                if (type == "measuring_cylinder")
                {
                    double displaced = 0;
                    foreach (var e in w.Definition.Equipment)
                        if (w.Str(e.Id, "placedIn") == id && e.Type == "metal_block") displaced += w.Num(e.Id, "displacedCm3");
                    m.ExtraVolumeMl = m.LiquidMl > 0 ? displaced : 0;
                }
                m.Step(dt, heatW, Cooling(type), bath);
                // Overflow.
                if (CapacityMl.TryGetValue(type, out var cap) && m.LiquidMl > cap * 1.02 && type != "burette")
                {
                    m.PourInto(new Mixture(), (m.LiquidMl - cap) / m.LiquidMl);
                    w.Emit("overflow", id, $"The {w.Label(id)} overflowed!");
                }
                if (!string.IsNullOrEmpty(m.LastReaction))
                {
                    if (w.Str(id, "lastReaction") != m.LastReaction) w.Emit("observe", id, $"{w.Label(id)}: {m.LastReaction}.");
                    w.Set(id, "lastReaction", m.LastReaction);
                    m.LastReaction = null;
                }
                Sync(w, id);
            }
            DeliveryTubes(w, dt);
        }

        /// <summary>Gas from one container bubbles into another (limewater test, collecting gas).</summary>
        static void DeliveryTubes(LabWorld w, double dt)
        {
            foreach (var e in w.OfType("delivery_tube"))
            {
                string from = w.Str(e.Id, "from"), to = w.Str(e.Id, "to");
                var src = w.MixtureOf(from);
                var dst = w.MixtureOf(to);
                if (src == null) continue;
                foreach (var g in src.GasRate)
                {
                    double n = g.Value * dt;
                    w.Set(e.Id, "gasPassedMl", w.Num(e.Id, "gasPassedMl") + n * 24000);
                    if (dst == null) continue;
                    if (g.Key == "CO2") { dst.Add("CO3", n); dst.LastReaction = dst.Get("Ca2+") > 0 ? "Bubbles of gas — the limewater goes milky" : "Bubbles of gas pass through"; }
                    else dst.LastReaction = "Bubbles of gas pass through";
                    dst.RecentGas[g.Key] = (dst.RecentGas.TryGetValue(g.Key, out var r) ? r : 0) + n;
                    dst.Equilibrate();
                }
            }
        }

        /// <summary>Publishes what the student can observe/measure as plain state keys (usable in scenario expressions).</summary>
        public static void Sync(LabWorld w, string id)
        {
            var m = w.MixtureOf(id);
            if (m == null) return;
            var type = w.Spec(id)?.Type;
            if (type != "burette") w.Set(id, "volumeMl", Math.Round(m.VolumeMl, 3));
            w.Set(id, "pH", Math.Round(m.PHValue, 2));
            w.Set(id, "temperatureC", Math.Round(m.TemperatureC, 1));
            w.Set(id, "colour", m.ColourName());
            var c = m.Color();
            w.Set(id, "colorRGBA", string.Join(",", c.Select(x => x.ToString("0.###", CultureInfo.InvariantCulture))));
            w.Set(id, "cloudiness", Math.Round(m.Cloudiness, 3));
            w.Set(id, "precipitate", m.MainPrecipitate);
            w.Set(id, "gas", m.MainGas);
            w.Set(id, "fizzing", m.Fizzing);
            w.Set(id, "gasVolumeMl", Math.Round(m.TotalGasMl, 1));
            w.Set(id, "observation", m.Observation());
            w.Set(id, "crossHidden", m.Cloudiness >= 0.85);
            w.Set(id, "starch", m.StarchPresent);
            w.Set(id, "massG", Math.Round(m.MassG, 2));
            if (type == "measuring_cylinder") w.Set(id, "reading", Math.Round(m.VolumeMl, 1)); // graduated scale
        }

        public static string Num3(double v) => v.ToString("0.###", CultureInfo.InvariantCulture);
    }

    // ─── Containers ──────────────────────────────────────────────────────────

    /// <summary>Test tube, measuring cylinder, evaporating dish: contents simulated, can be placed in/on things.</summary>
    public sealed class VesselLogic : ContainerLogic
    {
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Grab)
            {
                w.Set(Id, "placedIn", i.Into);
                if (i.Into != null) w.Emit("place", Id, $"{w.Label(Id)} placed in/on the {w.Label(i.Into)}.");
                return true;
            }
            if (i.Type == IntentType.Rotate) { w.Set(Id, "swirled", true); return true; } // shake / swirl
            return base.Apply(i, w);
        }
    }

    /// <summary>Solid / food sample jar: a spatula-full goes into a container.</summary>
    public sealed class SolidJarLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w)
        {
            base.Init(spec, w);
            w.Set(Id, "usedG", 0.0);
            w.Set(Id, "poured", false);
        }

        public static double DefaultGrams(string substance) => substance switch
        {
            "Mg" => 0.1, "Zn" => 1.0, "Fe" => 0.5, "Cu" => 1.0, "CaCO3" => 2.0, "CuO" => 0.5, "MnO2" => 0.2,
            "NaCl_s" => 2.0, "CuSO4_s" => 2.0, "NaHCO3" => 1.0, "Na2CO3_s" => 1.0, "NH4NO3" => 3.0,
            "glucose" => 1.0, "sucrose" => 1.0, "starch" => 0.5, "vegetable_oil" => 1.0, _ => 2.0,
        };

        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type != IntentType.Pour) return base.Apply(i, w);
            var m = w.MixtureOf(i.Into);
            if (m == null) { w.Emit("spill", Id, "The solid went on the bench — add it to a container."); return false; }
            string substance = w.Str(Id, "substance") ?? "NaCl_s";
            double g = i.Value ?? DefaultGrams(substance);
            m.AddRecipe(substance, 0, g, solidAmount: true);
            w.Set(Id, "usedG", w.Num(Id, "usedG") + g);
            w.Set(Id, "poured", true);
            Materials.Sync(w, i.Into);
            return true;
        }
    }

    /// <summary>Dropping bottle of a reagent: about 1 mL (20 drops) per use.</summary>
    public sealed class DropperBottleLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w) { base.Init(spec, w); w.Set(Id, "dropsAdded", 0.0); w.Set(Id, "poured", false); }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type != IntentType.Pour) return base.Apply(i, w);
            var m = w.MixtureOf(i.Into);
            if (m == null) { w.Emit("spill", Id, "The drops fell on the bench."); return false; }
            double ml = i.Value ?? 1.0;
            m.AddRecipe(w.Str(Id, "reagent") ?? "universal", 0.1, ml);
            w.Set(Id, "dropsAdded", w.Num(Id, "dropsAdded") + ml * 20);
            w.Set(Id, "poured", true);
            if (w.Spec(i.Into)?.Type == "conical_flask") { w.Set(i.Into, "hasIndicator", true); w.Set(i.Into, "indicator", w.Str(Id, "reagent")); }
            Materials.Sync(w, i.Into);
            return true;
        }
    }

    // ─── Heat ────────────────────────────────────────────────────────────────

    public sealed class HotPlateLogic : StaticLogic
    {
        public const double MaxW = 400;
        public override void Init(EquipmentSpec spec, LabWorld w)
        {
            base.Init(spec, w);
            w.Set(Id, "on", false);
            w.Set(Id, "powerW", spec.InitNumber("powerW", 200));
            w.Set(Id, "energyJ", 0.0);
            w.Set(Id, "surfaceC", Chem.RoomC);
        }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Toggle) { w.Set(Id, "on", !w.Bool(Id, "on")); return true; }
            if (i.Type == IntentType.Rotate) { w.Set(Id, "powerW", Math.Round(Math.Min(Math.Max(i.Value ?? 200, 0), MaxW))); return true; }
            return base.Apply(i, w);
        }
        public override void Tick(double dt, LabWorld w)
        {
            bool on = w.Bool(Id, "on");
            if (on) w.Set(Id, "energyJ", w.Num(Id, "energyJ") + w.Num(Id, "powerW") * dt); // joulemeter
            double target = on ? Chem.RoomC + w.Num(Id, "powerW") * 0.8 : Chem.RoomC;
            w.Set(Id, "surfaceC", w.Num(Id, "surfaceC") + (target - w.Num(Id, "surfaceC")) * Math.Min(1, 0.1 * dt));
        }
    }

    public sealed class WaterBathLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w)
        {
            base.Init(spec, w);
            w.Set(Id, "on", false);
            double set = spec.InitNumber("setpointC", 37);
            w.Set(Id, "setpointC", set);
            // Starts at its set temperature (pre-heated before the lesson) unless told otherwise.
            w.Set(Id, "temperatureC", spec.InitNumber("startC", set));
        }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Toggle) { w.Set(Id, "on", !w.Bool(Id, "on")); return true; }
            if (i.Type == IntentType.Rotate) { w.Set(Id, "setpointC", Math.Round(Math.Min(Math.Max(i.Value ?? 37, 5), 100))); w.Set(Id, "on", true); return true; }
            return base.Apply(i, w);
        }
        public override void Tick(double dt, LabWorld w)
        {
            double t = w.Num(Id, "temperatureC", Chem.RoomC);
            double target = w.Bool(Id, "on") ? w.Num(Id, "setpointC") : Chem.RoomC;
            double rate = w.Bool(Id, "on") ? 0.6 : 0.01; // °C/s heating, slow cooling
            double step = Math.Sign(target - t) * Math.Min(Math.Abs(target - t), rate * dt);
            w.Set(Id, "temperatureC", Math.Round(t + step, 2));
            w.Set(Id, "reading", Math.Round(t + step, 1));
        }
    }

    // ─── Probes and balance ──────────────────────────────────────────────────

    /// <summary>Thermometer / pH meter: dip into a container (Connect) to read it.</summary>
    public sealed class ProbeLogic : StaticLogic
    {
        readonly bool ph;
        public ProbeLogic(bool ph) { this.ph = ph; }
        public override void Init(EquipmentSpec spec, LabWorld w)
        {
            base.Init(spec, w);
            w.Set(Id, "connected", false);
            w.Set(Id, "in", null);
            w.Set(Id, "reading", ph ? 7.0 : Chem.RoomC);
        }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Connect || i.Type == IntentType.Grab && i.Into != null)
            {
                bool ok = i.Into != null && (w.MixtureOf(i.Into) != null || (!ph && w.Spec(i.Into)?.Type == "water_bath"));
                if (!ok) { w.Emit("info", Id, ph ? "Dip the pH probe into a liquid." : "Put the thermometer into a liquid."); return false; }
                w.Set(Id, "in", i.Into);
                w.Set(Id, "connected", true);
                return true;
            }
            if (i.Type == IntentType.Release) { w.Set(Id, "in", null); w.Set(Id, "connected", false); return true; }
            return base.Apply(i, w);
        }
        public override void Tick(double dt, LabWorld w)
        {
            string into = w.Str(Id, "in");
            double target;
            var m = w.MixtureOf(into);
            if (ph) target = m != null && m.LiquidMl > 0.5 ? m.PHValue : 7.0;
            else target = m != null ? m.TemperatureC : into != null ? w.Num(into, "temperatureC", Chem.RoomC) : Chem.RoomC;
            // Probes respond in a few seconds, like real ones.
            double r = w.Num(Id, "reading", target);
            r += (target - r) * Math.Min(1, (ph ? 0.8 : 0.5) * dt);
            w.Set(Id, "reading", Math.Round(r, ph ? 2 : 1));
        }
    }

    public sealed class BalanceLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w) { base.Init(spec, w); w.Set(Id, "tare", 0.0); w.Set(Id, "reading", 0.0); w.Set(Id, "grossG", 0.0); }

        public static double MassOf(LabWorld w, string id)
        {
            var spec = w.Spec(id);
            if (spec == null) return 0;
            double m = Materials.EmptyMassG.TryGetValue(spec.Type, out var e) ? e : 0;
            var mix = w.MixtureOf(id);
            if (mix != null) m += mix.MassG;
            if (spec.Type == "metal_block" || spec.Type == "potato_cylinder") m += w.Num(id, "massG");
            return m;
        }

        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Toggle || i.Type == IntentType.Select) { w.Set(Id, "tare", w.Num(Id, "grossG")); w.Emit("info", Id, "Balance zeroed (tare)."); return true; }
            return base.Apply(i, w);
        }
        public override void Tick(double dt, LabWorld w)
        {
            double gross = 0;
            foreach (var e in w.Definition.Equipment) if (w.Str(e.Id, "placedIn") == Id) gross += MassOf(w, e.Id);
            w.Set(Id, "grossG", gross);
            w.Set(Id, "reading", Math.Round(gross - w.Num(Id, "tare"), 2));
        }
    }

    // ─── Placeable objects ───────────────────────────────────────────────────

    /// <summary>Base for things you pick up and place in/on something (Grab → into).</summary>
    public class PlaceableLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w) { base.Init(spec, w); w.Set(Id, "placedIn", null); }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Grab) { w.Set(Id, "placedIn", i.Into); OnPlaced(i.Into, w); return true; }
            if (i.Type == IntentType.Release) { w.Set(Id, "placedIn", null); OnPlaced(null, w); return true; }
            return base.Apply(i, w);
        }
        protected virtual void OnPlaced(string into, LabWorld w) { }
    }

    /// <summary>Metal/wood block of known material: mass and volume (density practicals).</summary>
    public sealed class BlockLogic : PlaceableLogic
    {
        public static readonly Dictionary<string, double> Density = new Dictionary<string, double>
        { { "aluminium", 2.70 }, { "steel", 7.85 }, { "brass", 8.50 }, { "copper", 8.96 }, { "lead", 11.34 }, { "wood", 0.60 }, { "acrylic", 1.18 } };

        public override void Init(EquipmentSpec spec, LabWorld w)
        {
            base.Init(spec, w);
            string mat = spec.InitString("material", "aluminium");
            double v = spec.InitNumber("volumeCm3", 20);
            double rho = Density.TryGetValue(mat, out var d) ? d : 2.7;
            w.Set(Id, "densityGcm3", rho);
            w.Set(Id, "volumeCm3", v);
            w.Set(Id, "massG", Math.Round(rho * v, 1));
            // Floating objects displace their own mass of water; sinking ones their volume.
            w.Set(Id, "displacedCm3", rho < 1 ? rho * v : v);
            w.Set(Id, "floats", rho < 1);
        }
    }

    /// <summary>Potato cylinder for osmosis: gains or loses mass in sugar solutions.</summary>
    public sealed class PotatoLogic : PlaceableLogic
    {
        double pct; // exact; published rounded
        public override void Init(EquipmentSpec spec, LabWorld w)
        {
            base.Init(spec, w);
            double m0 = spec.InitNumber("massG", 2.50);
            w.Set(Id, "startMassG", m0);
            w.Set(Id, "massG", m0);
            w.Set(Id, "lengthMm", spec.InitNumber("lengthMm", 30));
            w.Set(Id, "startLengthMm", spec.InitNumber("lengthMm", 30));
            w.Set(Id, "changePct", 0.0);
        }
        public override void Tick(double dt, LabWorld w)
        {
            var m = w.MixtureOf(w.Str(Id, "placedIn"));
            if (m == null || m.LiquidMl < 1) return;
            // Equivalent sucrose concentration (each ion counts as a particle).
            double osm = m.Conc("sucrose") + m.Conc("glucose") + m.Conc("maltose") + 0.5 * (m.Conc("Na+") + m.Conc("Cl-") + m.Conc("K+"));
            double targetPct = BioModels.PotatoEquilibriumChangePct(osm);
            // Real osmosis takes hours; the lab runs it at ~1 "hour" per minute.
            pct += (targetPct - pct) * Math.Min(1, dt / 150.0);
            double pct_ = pct;
            w.Set(Id, "changePct", Math.Round(pct_, 2));
            w.Set(Id, "massG", Math.Round(w.Num(Id, "startMassG") * (1 + pct / 100), 2));
            w.Set(Id, "lengthMm", Math.Round(w.Num(Id, "startLengthMm") * (1 + pct / 300), 1));
        }
    }

    /// <summary>Pondweed (Elodea) in water: oxygen bubbles depend on light, CO2 and temperature.</summary>
    public sealed class PondweedLogic : PlaceableLogic
    {
        double carry;
        public override void Init(EquipmentSpec spec, LabWorld w) { base.Init(spec, w); w.Set(Id, "bubblesPerMin", 0.0); w.Set(Id, "bubbleCount", 0.0); }
        protected override void OnPlaced(string into, LabWorld w) { w.Set(Id, "bubbleCount", 0.0); carry = 0; }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Select || i.Type == IntentType.Toggle) { w.Set(Id, "bubbleCount", 0.0); carry = 0; return true; } // start counting again
            return base.Apply(i, w);
        }
        public override void Tick(double dt, LabWorld w)
        {
            var m = w.MixtureOf(w.Str(Id, "placedIn"));
            if (m == null || m.LiquidMl < 5) { w.Set(Id, "bubblesPerMin", 0.0); return; }
            var lamp = w.OfType("lamp").FirstOrDefault();
            bool lampOn = lamp != null && w.Bool(lamp.Id, "on");
            double d = lamp != null ? w.Num(lamp.Id, "distanceCm", 20) : 100;
            double rate = BioModels.PondweedBubblesPerMin(d, lampOn, m.Conc("CO3"), m.TemperatureC);
            w.Set(Id, "bubblesPerMin", Math.Round(rate, 1));
            carry += rate / 60 * dt;
            int whole = (int)carry;
            if (whole > 0) { carry -= whole; w.Set(Id, "bubbleCount", w.Num(Id, "bubbleCount") + whole); }
        }
    }

    /// <summary>Splint: glowing or lit; held at a container's mouth it tests the gas given off.</summary>
    public sealed class SplintLogic : PlaceableLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w) { base.Init(spec, w); w.Set(Id, "result", ""); w.Set(Id, "tested", false); w.Set(Id, "mode", spec.InitString("mode", "lit")); }
        protected override void OnPlaced(string into, LabWorld w)
        {
            if (into == null) return;
            var m = w.MixtureOf(into);
            string mode = w.Str(Id, "mode") ?? "lit";
            double Gas(string g) => m != null && m.RecentGas.TryGetValue(g, out var v) ? v : 0;
            string result;
            if (Gas("H2") > 2e-5) result = "squeaky pop — hydrogen";
            else if (Gas("O2") > 2e-5) result = mode == "glowing" ? "the glowing splint relights — oxygen" : "burns more brightly — oxygen";
            else if (Gas("CO2") > 2e-5) result = mode == "lit" ? "the flame goes out — could be carbon dioxide (test with limewater)" : "the splint goes out";
            else result = "no change — no gas detected";
            w.Set(Id, "result", result);
            w.Set(Id, "tested", true);
            w.Set(Id, "placedIn", null);
            w.Emit("observe", Id, "Splint test: " + result);
        }
    }

    /// <summary>Delivery tube: Grab into the reacting container, Connect into the receiving one.</summary>
    public sealed class DeliveryTubeLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w) { base.Init(spec, w); w.Set(Id, "from", null); w.Set(Id, "to", null); w.Set(Id, "connected", false); w.Set(Id, "gasPassedMl", 0.0); }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Grab) { w.Set(Id, "from", i.Into); w.Set(Id, "connected", i.Into != null && w.Str(Id, "to") != null); return true; }
            if (i.Type == IntentType.Connect) { w.Set(Id, "to", i.Into); w.Set(Id, "connected", i.Into != null && w.Str(Id, "from") != null); return true; }
            if (i.Type == IntentType.Release) { w.Set(Id, "from", null); w.Set(Id, "to", null); w.Set(Id, "connected", false); return true; }
            return base.Apply(i, w);
        }
    }

    /// <summary>Desk lamp: on/off and its distance from the experiment.</summary>
    public sealed class LampLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w) { base.Init(spec, w); w.Set(Id, "on", false); w.Set(Id, "distanceCm", spec.InitNumber("distanceCm", 20)); Update(w); }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Toggle) { w.Set(Id, "on", !w.Bool(Id, "on")); Update(w); return true; }
            if (i.Type == IntentType.Rotate) { w.Set(Id, "distanceCm", Math.Round(Math.Min(Math.Max(i.Value ?? 20, 5), 60))); Update(w); return true; }
            return base.Apply(i, w);
        }
        void Update(LabWorld w)
        {
            double d = w.Num(Id, "distanceCm", 20);
            w.Set(Id, "lightIntensity", w.Bool(Id, "on") ? Math.Round(10000 / (d * d), 2) : 0.0); // relative, 1/d²
        }
    }

    // ─── Physics kit ─────────────────────────────────────────────────────────

    /// <summary>Cell/battery, switch, variable resistor, bulb, LED: they connect to the circuit board.</summary>
    public sealed class ComponentLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w)
        {
            base.Init(spec, w);
            w.Set(Id, "connected", false);
            w.Set(Id, "currentA", 0.0);
            w.Set(Id, "voltageV", 0.0);
            switch (spec.Type)
            {
                case "battery": w.Set(Id, "emfV", spec.InitNumber("voltage", 3)); break;
                case "switch": w.Set(Id, "closed", false); break;
                case "variable_resistor": w.Set(Id, "maxOhms", spec.InitNumber("maxOhms", 100)); w.Set(Id, "ohms", spec.InitNumber("maxOhms", 100) / 2); break;
                case "bulb": w.Set(Id, "brightness", 0.0); w.Set(Id, "lit", false); break;
                case "led": w.Set(Id, "lit", false); w.Set(Id, "brightness", 0.0); break;
            }
        }
        public override bool Apply(Intent i, LabWorld w)
        {
            var type = w.Spec(Id).Type;
            if (i.Type == IntentType.Connect) { w.Set(Id, "connected", i.Into != null); return true; }
            if (i.Type == IntentType.Release) { w.Set(Id, "connected", false); return true; }
            if (i.Type == IntentType.Toggle && type == "switch") { w.Set(Id, "closed", !w.Bool(Id, "closed")); return true; }
            if (i.Type == IntentType.Rotate && type == "variable_resistor")
            {
                double max = w.Num(Id, "maxOhms", 100);
                w.Set(Id, "ohms", Math.Round(Math.Min(Math.Max(i.Value ?? max / 2, 0.5), max), 1));
                return true;
            }
            return base.Apply(i, w);
        }

        public static double LedForwardV(string colour) => colour switch { "red" => 1.8, "yellow" => 2.0, "green" => 2.1, "blue" => 3.0, "white" => 3.1, _ => 2.0 };
    }

    /// <summary>Spring + slotted masses (Hooke's law), with an elastic limit.</summary>
    public sealed class SpringLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w)
        {
            base.Init(spec, w);
            double k = spec.InitNumber("springConstant", 25);
            w.Set(Id, "springConstant", k);
            w.Set(Id, "naturalLengthCm", spec.InitNumber("naturalLengthCm", 10));
            w.Set(Id, "elasticLimitN", spec.InitNumber("elasticLimitN", k * 0.25));
            w.Set(Id, "massG", 0.0);
            Update(w);
        }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Rotate || i.Type == IntentType.Grab && i.Value.HasValue)
            {
                w.Set(Id, "massG", Math.Round(Math.Min(Math.Max(i.Value ?? 100, 0), 1500)));
                Update(w);
                return true;
            }
            if (i.Type == IntentType.Release) { w.Set(Id, "massG", 0.0); Update(w); return true; }
            return base.Apply(i, w);
        }
        void Update(LabWorld w)
        {
            double k = w.Num(Id, "springConstant", 25), f = w.Num(Id, "massG") / 1000 * Physics.G;
            double limit = w.Num(Id, "elasticLimitN");
            double ext = f / k;
            if (f > limit)
            {
                // Past the elastic limit it stretches more and does not fully return.
                ext = limit / k + (f - limit) / (k * 0.35);
                double set = (f - limit) / k * 0.6 * 100;
                if (set > w.Num(Id, "permanentSetCm")) { w.Set(Id, "permanentSetCm", Math.Round(set, 2)); w.Set(Id, "overstretched", true); w.Emit("observe", Id, "The spring has gone past its elastic limit — it will not return to its original length."); }
            }
            double natural = w.Num(Id, "naturalLengthCm", 10) + w.Num(Id, "permanentSetCm");
            w.Set(Id, "forceN", Math.Round(f, 3));
            w.Set(Id, "extensionCm", Math.Round(ext * 100 + w.Num(Id, "permanentSetCm"), 2));
            w.Set(Id, "lengthCm", Math.Round(natural + ext * 100, 2));
        }
    }

    /// <summary>Inclined ramp with a trolley: motion with friction; Rotate = angle, Release = let go, Grab = back to the top.</summary>
    public sealed class RampLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w)
        {
            base.Init(spec, w);
            w.Set(Id, "lengthM", spec.InitNumber("lengthM", 1.0));
            w.Set(Id, "frictionCoeff", spec.InitNumber("frictionCoeff", 0.04));
            w.Set(Id, "trolleyMassKg", spec.InitNumber("trolleyMassKg", 0.5));
            w.Set(Id, "angleDeg", spec.InitNumber("angleDeg", 10));
            Reset(w);
        }
        void Reset(LabWorld w)
        {
            w.Set(Id, "running", false); w.Set(Id, "distanceM", 0.0); w.Set(Id, "speed", 0.0); w.Set(Id, "timeS", 0.0);
            w.Set(Id, "atBottom", false);
            Accel(w);
        }
        void Accel(LabWorld w)
        {
            double th = w.Num(Id, "angleDeg") * Math.PI / 180, mu = w.Num(Id, "frictionCoeff");
            w.Set(Id, "accelerationMs2", Math.Round(Math.Max(0, Physics.G * (Math.Sin(th) - mu * Math.Cos(th))), 3));
        }
        public override bool Apply(Intent i, LabWorld w)
        {
            switch (i.Type)
            {
                case IntentType.Rotate:
                    if (w.Bool(Id, "running")) return false;
                    w.Set(Id, "angleDeg", Math.Round(Math.Min(Math.Max(i.Value ?? 10, 0), 40), 1)); Accel(w); return true;
                case IntentType.Release:
                    Reset(w);
                    if (w.Num(Id, "accelerationMs2") <= 0) { w.Emit("observe", Id, "The trolley does not move — friction is too large at this angle."); return true; }
                    w.Set(Id, "running", true); return true;
                case IntentType.Grab: Reset(w); return true;
            }
            return base.Apply(i, w);
        }
        public override void Tick(double dt, LabWorld w)
        {
            if (!w.Bool(Id, "running")) return;
            double a = w.Num(Id, "accelerationMs2"), L = w.Num(Id, "lengthM", 1);
            double t = w.Num(Id, "timeS") + dt;
            double s = 0.5 * a * t * t;
            if (s >= L)
            {
                t = Math.Sqrt(2 * L / a);
                s = L;
                w.Set(Id, "running", false);
                w.Set(Id, "atBottom", true);
                w.Set(Id, "finalSpeed", Math.Round(a * t, 3));
                w.Emit("observe", Id, "The trolley reached the bottom of the ramp.");
            }
            w.Set(Id, "timeS", Math.Round(t, 3));
            w.Set(Id, "distanceM", Math.Round(s, 3));
            w.Set(Id, "speed", Math.Round(a * t, 3));
        }
    }

    /// <summary>Light gate at the bottom of the ramp: times a 5.0 cm card → speed.</summary>
    public sealed class LightGateLogic : StaticLogic
    {
        public const double CardM = 0.05;
        public override void Init(EquipmentSpec spec, LabWorld w) { base.Init(spec, w); w.Set(Id, "connected", false); w.Set(Id, "gateTimeS", 0.0); w.Set(Id, "reading", 0.0); }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Connect) { w.Set(Id, "connected", i.Into != null); w.Set(Id, "ramp", i.Into); return true; }
            if (i.Type == IntentType.Toggle || i.Type == IntentType.Select) { w.Set(Id, "gateTimeS", 0.0); w.Set(Id, "reading", 0.0); return true; } // reset
            return base.Apply(i, w);
        }
        public override void Tick(double dt, LabWorld w)
        {
            if (!w.Bool(Id, "connected")) return;
            var ramp = w.Str(Id, "ramp") ?? w.OfType("ramp").FirstOrDefault()?.Id;
            if (ramp == null || !w.Bool(ramp, "atBottom")) return;
            double v = w.Num(ramp, "finalSpeed");
            if (v <= 0) return;
            w.Set(Id, "gateTimeS", Math.Round(CardM / v, 4));
            w.Set(Id, "reading", Math.Round(v, 3));
        }
    }

    /// <summary>Convex lens on the optical bench: Rotate = object distance u (cm).</summary>
    public sealed class LensLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w)
        {
            base.Init(spec, w);
            w.Set(Id, "focalLengthCm", spec.InitNumber("focalLengthCm", 15));
            w.Set(Id, "objectDistanceCm", spec.InitNumber("objectDistanceCm", 30));
            Update(w);
        }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Rotate) { w.Set(Id, "objectDistanceCm", Math.Round(Math.Min(Math.Max(i.Value ?? 30, 2), 100), 1)); Update(w); return true; }
            return base.Apply(i, w);
        }
        void Update(LabWorld w)
        {
            double f = w.Num(Id, "focalLengthCm", 15), u = w.Num(Id, "objectDistanceCm", 30);
            bool real = u > f + 1e-6;
            double v = real ? 1 / (1 / f - 1 / u) : -1;
            w.Set(Id, "realImage", real);
            w.Set(Id, "imageDistanceCm", real ? Math.Round(v, 2) : -1.0);
            w.Set(Id, "magnification", real ? Math.Round(v / u, 3) : Math.Round(f / (f - u), 3));
        }
    }

    /// <summary>White screen: Rotate = distance from the lens (cm). Sharp when at the image distance.</summary>
    public sealed class ScreenLogic : StaticLogic
    {
        public override void Init(EquipmentSpec spec, LabWorld w) { base.Init(spec, w); w.Set(Id, "distanceCm", spec.InitNumber("distanceCm", 40)); w.Set(Id, "sharpness", 0.0); w.Set(Id, "sharp", false); w.Set(Id, "imageHeightCm", 0.0); }
        public override bool Apply(Intent i, LabWorld w)
        {
            if (i.Type == IntentType.Rotate) { w.Set(Id, "distanceCm", Math.Round(Math.Min(Math.Max(i.Value ?? 40, 2), 200), 1)); return true; }
            return base.Apply(i, w);
        }
        public override void Tick(double dt, LabWorld w)
        {
            var lens = w.OfType("convex_lens").FirstOrDefault();
            var box = w.OfType("light_box").FirstOrDefault();
            bool lit = box == null || w.Bool(box.Id, "on");
            if (lens == null || !lit || !w.Bool(lens.Id, "realImage")) { w.Set(Id, "sharpness", 0.0); w.Set(Id, "sharp", false); w.Set(Id, "imageHeightCm", 0.0); return; }
            double vImg = w.Num(lens.Id, "imageDistanceCm"), d = w.Num(Id, "distanceCm");
            double width = 0.03 * vImg + 0.4;
            double sharp = Math.Exp(-Math.Pow((d - vImg) / width, 2));
            w.Set(Id, "sharpness", Math.Round(sharp, 3));
            w.Set(Id, "sharp", sharp >= 0.9);
            w.Set(Id, "imageHeightCm", Math.Round(2.0 * Math.Abs(w.Num(lens.Id, "magnification")), 2)); // 2 cm object
        }
    }
}
