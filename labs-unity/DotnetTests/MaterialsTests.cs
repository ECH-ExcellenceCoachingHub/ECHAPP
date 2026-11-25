// The general lab materials students use in their own experiments: real contents in every
// container (pH, heat, gases, precipitates, food tests, enzymes, rates), heaters, probes,
// balance, and the extended physics kit (cells, switches, bulbs, LEDs, parallel circuits,
// springs, ramps + light gates, lenses).
using System;
using System.Linq;
using ECHLabs.Core;
using ECHLabs.Sim;
using Newtonsoft.Json;
using Xunit;

public class MaterialsTests
{
    /// <summary>A world with the given equipment: (id, type, init as anonymous object).</summary>
    static LabWorld World(params (string id, string type, object init)[] items)
    {
        var def = new
        {
            id = "materials-test", version = 1, title = "t", summary = "t", subject = "chemistry", environment = "ChemLab",
            objectives = new[] { "t" },
            equipment = items.Select(i => new { id = i.id, type = i.type, slot = "benchA.center", init = i.init ?? new { } }).ToArray(),
            variables = new { },
            steps = new[] { new { id = "s1", kind = "info", instruction = "x" } },
        };
        return new LabWorld(ScenarioDefinition.FromJson(JsonConvert.SerializeObject(def)), 7);
    }

    static void Run(LabWorld w, double seconds) { for (double t = 0; t < seconds; t += 0.1) w.Tick(0.1); }
    static void Do(LabWorld w, IntentType t, string target, string into = null, double? value = null) => Assert.True(w.Apply(Intent.Of(t, target, into, value)), $"{t} {target}→{into} failed");

    [Fact]
    public void Neutralisation_warms_the_mixture_and_reaches_pH_7()
    {
        var w = World(("acid", "beaker", new { solution = "HCl", conc = 1.0, volume = 50 }), ("alkali", "beaker", new { solution = "NaOH", conc = 1.0, volume = 50 }), ("thermo", "thermometer", null), ("ph", "ph_meter", null));
        Assert.InRange(w.Num("acid", "pH"), -0.1, 0.1);
        Assert.InRange(w.Num("alkali", "pH"), 13.9, 14.1);
        Do(w, IntentType.Pour, "alkali", "acid", 50);
        // 0.05 mol water formed × 57.1 kJ/mol over ~100 g of solution → about +6.8 °C
        Assert.InRange(w.Num("acid", "temperatureC"), 26, 28);
        Assert.InRange(w.Num("acid", "pH"), 6.5, 7.5);
        Do(w, IntentType.Connect, "thermo", "acid");
        Do(w, IntentType.Connect, "ph", "acid");
        Run(w, 10);
        Assert.InRange(w.Num("thermo", "reading"), 25, 28);
        Assert.InRange(w.Num("ph", "reading"), 6.5, 7.5);
    }

    [Fact]
    public void Ethanoic_acid_is_weak_and_ammonia_is_alkaline()
    {
        var w = World(("vinegar", "beaker", new { solution = "CH3COOH", conc = 0.1, volume = 50 }), ("nh3", "beaker", new { solution = "NH3", conc = 0.1, volume = 50 }));
        Assert.InRange(w.Num("vinegar", "pH"), 2.7, 3.0);
        Assert.InRange(w.Num("nh3", "pH"), 11.0, 11.3);
    }

    [Fact]
    public void Magnesium_fizzes_in_acid_and_the_gas_gives_a_squeaky_pop()
    {
        var w = World(("tube", "test_tube", new { solution = "HCl", conc = 1.0, volume = 10 }), ("mg", "solid_jar", new { substance = "Mg" }), ("splint", "splint", new { mode = "lit" }));
        Do(w, IntentType.Pour, "mg", "tube");
        Run(w, 2);
        Assert.True(w.Bool("tube", "fizzing"));
        Assert.Equal("H2", w.Str("tube", "gas"));
        Assert.True(w.Num("tube", "temperatureC") > 21);
        Do(w, IntentType.Grab, "splint", "tube");
        Assert.Contains("squeaky pop", w.Str("splint", "result"));
        Run(w, 120);
        Assert.False(w.Bool("tube", "fizzing"));             // all the magnesium has reacted
        Assert.True(w.Num("tube", "pH") > 0.1);               // some acid was used up
        Assert.InRange(w.Num("tube", "gasVolumeMl"), 90, 110); // 0.1 g Mg → 4.1 mmol H2 ≈ 99 mL
    }

    [Fact]
    public void Marble_chips_give_carbon_dioxide_that_turns_limewater_milky()
    {
        var w = World(("flask", "test_tube", new { solution = "HCl", conc = 1.0, volume = 15 }), ("chips", "solid_jar", new { substance = "CaCO3" }),
                      ("lime", "test_tube", new { solution = "CaOH2", volume = 10 }), ("tube", "delivery_tube", null));
        Assert.Equal("colourless", w.Str("lime", "colour"));
        Do(w, IntentType.Pour, "chips", "flask");
        Do(w, IntentType.Grab, "tube", "flask");
        Do(w, IntentType.Connect, "tube", "lime");
        Run(w, 20);
        Assert.Equal("CO2", w.Str("flask", "gas"));
        Assert.Equal("CaCO3_ppt", w.Str("lime", "precipitate"));
        Assert.True(w.Num("lime", "cloudiness") > 0.3);
    }

    [Theory]
    [InlineData("AgNO3", "NaCl", "AgCl", "white")]
    [InlineData("AgNO3", "KI", "AgI", "yellow")]
    [InlineData("BaCl2", "H2SO4", "BaSO4", "white")]
    [InlineData("CuSO4", "NaOH", "CuOH2", "blue")]
    [InlineData("FeCl3", "NaOH", "FeOH3", "orange")]
    [InlineData("FeSO4", "NaOH", "FeOH2", "green")]
    public void Precipitation_tests(string a, string b, string ppt, string colour)
    {
        var w = World(("t", "test_tube", new { solution = a, conc = 0.1, volume = 5 }), ("r", "beaker", new { solution = b, conc = 0.5, volume = 50 }));
        Do(w, IntentType.Pour, "r", "t", 3);
        Assert.Equal(ppt, w.Str("t", "precipitate"));
        Assert.Contains(colour, w.Str("t", "observation"));
    }

    [Fact]
    public void Disappearing_cross_is_faster_when_hotter()
    {
        double TimeToHide(double tempC)
        {
            var w = World(("flask", "conical_flask", new { solution = "Na2S2O3", conc = 0.15, volume = 50, temperature = tempC }), ("acid", "beaker", new { solution = "HCl", conc = 2.0, volume = 50 }));
            Do(w, IntentType.Pour, "acid", "flask", 5);
            double t = 0;
            while (!w.Bool("flask", "crossHidden")) { w.Tick(0.1); t += 0.1; Assert.True(t < 900, "cross never disappeared at " + tempC); }
            return t;
        }
        double cold = TimeToHide(20), hot = TimeToHide(40);
        Assert.InRange(cold, 15, 240);
        Assert.True(hot < cold * 0.5, $"40 °C {hot:0}s should be much faster than 20 °C {cold:0}s");
    }

    [Fact]
    public void Food_tests_starch_sugar_protein_fat()
    {
        var w = World(("bread", "test_tube", new { solution = "water", volume = 5 }), ("b", "solid_jar", new { substance = "bread" }), ("iod", "dropper_bottle", new { reagent = "iodine" }),
                      ("sugar", "test_tube", new { solution = "glucose_sol", conc = 0.05, volume = 5 }), ("ben", "dropper_bottle", new { reagent = "benedicts" }), ("bath", "water_bath", new { setpointC = 80 }),
                      ("egg", "test_tube", new { solution = "water", volume = 3 }), ("e", "solid_jar", new { substance = "egg_white" }), ("biu", "dropper_bottle", new { reagent = "biuret" }),
                      ("oil", "test_tube", new { solution = "ethanol", volume = 2 }), ("o", "solid_jar", new { substance = "vegetable_oil" }), ("water", "beaker", new { solution = "water", volume = 100 }));
        Do(w, IntentType.Pour, "b", "bread"); Do(w, IntentType.Pour, "iod", "bread");
        Assert.Equal("blue-black", w.Str("bread", "colour"));

        Do(w, IntentType.Pour, "ben", "sugar"); Do(w, IntentType.Pour, "ben", "sugar");
        Assert.Equal("blue", w.Str("sugar", "colour"));
        Do(w, IntentType.Toggle, "bath");
        Do(w, IntentType.Grab, "sugar", "bath");
        Run(w, 120);
        Assert.Equal("Cu2O", w.Str("sugar", "precipitate"));
        Assert.Contains(w.Str("sugar", "colour"), new[] { "orange", "red", "yellow" });

        Do(w, IntentType.Pour, "e", "egg"); Do(w, IntentType.Pour, "biu", "egg");
        Assert.Contains("purple", w.Str("egg", "observation"));

        Do(w, IntentType.Pour, "o", "oil"); Do(w, IntentType.Pour, "water", "oil", 5);
        Assert.Contains("emulsion", w.Str("oil", "observation"));
    }

    [Fact]
    public void Amylase_digests_starch_fastest_near_body_temperature()
    {
        double TimeToClear(double bathC)
        {
            var w = World(("t", "test_tube", new { solution = "starch_sol", volume = 5, temperature = bathC }), ("amy", "dropper_bottle", new { reagent = "amylase" }), ("iod", "dropper_bottle", new { reagent = "iodine" }), ("bath", "water_bath", new { setpointC = bathC }));
            Do(w, IntentType.Toggle, "bath");
            Do(w, IntentType.Grab, "t", "bath");
            Do(w, IntentType.Pour, "iod", "t", 0.2);
            Do(w, IntentType.Pour, "amy", "t");
            double time = 0;
            while (w.Bool("t", "starch")) { w.Tick(0.5); time += 0.5; if (time > 1500) return double.PositiveInfinity; }
            return time;
        }
        double t20 = TimeToClear(20), t37 = TimeToClear(37), t70 = TimeToClear(70);
        Assert.True(t37 < t20, $"37 °C ({t37}) should beat 20 °C ({t20})");
        Assert.True(double.IsPositiveInfinity(t70) || t70 > t37 * 3, $"70 °C denatures the enzyme ({t70})");
    }

    [Fact]
    public void Catalase_and_manganese_dioxide_release_oxygen()
    {
        var w = World(("t", "test_tube", new { solution = "H2O2", conc = 1.0, volume = 10 }), ("liver", "solid_jar", new { substance = "liver" }), ("s", "splint", new { mode = "glowing" }));
        Do(w, IntentType.Pour, "liver", "t");
        Run(w, 3);
        Assert.True(w.Bool("t", "fizzing"));
        Do(w, IntentType.Grab, "s", "t");
        Assert.Contains("relights", w.Str("s", "result"));
    }

    [Fact]
    public void Evaporating_salt_water_leaves_crystals_and_heating_follows_power()
    {
        var w = World(("dish", "evaporating_dish", new { solution = "NaCl", conc = 1.0, volume = 20 }), ("plate", "hot_plate", new { powerW = 400 }));
        Do(w, IntentType.Grab, "dish", "plate");
        Do(w, IntentType.Toggle, "plate");
        Run(w, 400);
        Assert.Contains("crystals", w.Str("dish", "observation"));
        Assert.True(w.Num("plate", "energyJ") > 100000);
    }

    [Fact]
    public void Balance_measuring_cylinder_and_density()
    {
        var w = World(("cyl", "measuring_cylinder", new { solution = "water", volume = 50 }), ("block", "metal_block", new { material = "aluminium", volumeCm3 = 10 }), ("bal", "balance", null));
        Assert.Equal(50, w.Num("cyl", "reading"), 1);
        Do(w, IntentType.Grab, "block", "bal");
        Run(w, 0.2);
        Assert.Equal(27.0, w.Num("bal", "reading"), 1);
        Do(w, IntentType.Grab, "block", "cyl");
        Run(w, 0.2);
        Assert.Equal(60, w.Num("cyl", "reading"), 1);
        Assert.Equal(0, w.Num("bal", "reading"), 1);
    }

    [Fact]
    public void Potato_gains_mass_in_water_and_loses_it_in_strong_sugar()
    {
        var w = World(("water", "beaker", new { solution = "water", volume = 50 }), ("sugar", "beaker", new { solution = "sucrose_sol", conc = 0.8, volume = 50 }),
                      ("p1", "potato_cylinder", new { massG = 2.5 }), ("p2", "potato_cylinder", new { massG = 2.5 }));
        Do(w, IntentType.Grab, "p1", "water");
        Do(w, IntentType.Grab, "p2", "sugar");
        Run(w, 600);
        Assert.True(w.Num("p1", "changePct") > 15);
        Assert.True(w.Num("p2", "changePct") < -15);
    }

    [Fact]
    public void Pondweed_bubbles_faster_when_the_lamp_is_closer()
    {
        var w = World(("b", "beaker", new { solution = "NaHCO3", conc = 0.1, volume = 200 }), ("weed", "pondweed", null), ("lamp", "lamp", new { distanceCm = 40 }));
        Do(w, IntentType.Grab, "weed", "b");
        Do(w, IntentType.Toggle, "lamp");
        Run(w, 1);
        double far = w.Num("weed", "bubblesPerMin");
        Do(w, IntentType.Rotate, "lamp", null, 10);
        Run(w, 1);
        Assert.True(w.Num("weed", "bubblesPerMin") > far * 2);
    }

    [Fact]
    public void Circuits_cells_switches_parallel_bulbs_and_leds()
    {
        var w = World(("board", "breadboard", new { layout = "parallel" }), ("cell", "battery", new { voltage = 6 }), ("sw", "switch", null), ("amm", "ammeter", null), ("volt", "voltmeter", null),
                      ("r1", "resistor", new { ohms = 30 }), ("r2", "resistor", new { ohms = 60 }));
        foreach (var id in new[] { "cell", "sw", "amm", "volt", "r1", "r2" }) Do(w, IntentType.Connect, id, "board");
        Run(w, 0.2);
        Assert.Equal(0, w.Num("amm", "reading"), 3);           // switch open
        Do(w, IntentType.Toggle, "sw");
        Run(w, 0.2);
        Assert.Equal(0.3, w.Num("amm", "reading"), 3);         // 6 V across 20 Ω (30 ∥ 60)
        Assert.Equal(0.2, w.Num("r1", "currentA"), 3);
        Assert.Equal(6.0, w.Num("volt", "reading"), 2);

        // A filament bulb is non-ohmic: resistance rises as it gets brighter.
        var b = World(("board", "breadboard", null), ("psu", "power_supply", null), ("amm", "ammeter", null), ("lamp", "bulb", new { ratedVoltage = 6, ratedPower = 3 }));
        Do(b, IntentType.Connect, "amm", "board"); Do(b, IntentType.Connect, "lamp", "board"); Do(b, IntentType.Toggle, "psu");
        Do(b, IntentType.Rotate, "psu", null, 1); Run(b, 0.2); double r1 = 1 / b.Num("amm", "reading");
        Do(b, IntentType.Rotate, "psu", null, 6); Run(b, 0.2); double r6 = 6 / b.Num("amm", "reading");
        Assert.True(r6 > r1 * 2, $"bulb R at 6 V ({r6:0.0}) should be well above R at 1 V ({r1:0.0})");
        Assert.InRange(b.Num("amm", "reading"), 0.45, 0.55);   // rated 0.5 A at 6 V
        Assert.True(b.Bool("lamp", "lit"));

        // An LED needs its forward voltage before any current flows.
        var l = World(("board", "breadboard", null), ("psu", "power_supply", null), ("led", "led", new { colour = "red" }), ("r", "resistor", new { ohms = 220 }));
        Do(l, IntentType.Connect, "led", "board"); Do(l, IntentType.Connect, "r", "board"); Do(l, IntentType.Toggle, "psu");
        Do(l, IntentType.Rotate, "psu", null, 1.5); Run(l, 0.2);
        Assert.False(l.Bool("led", "lit"));
        Do(l, IntentType.Rotate, "psu", null, 5); Run(l, 0.2);
        Assert.True(l.Bool("led", "lit"));
    }

    [Fact]
    public void Spring_obeys_Hookes_law_until_its_elastic_limit()
    {
        var w = World(("s", "spring", new { springConstant = 20, elasticLimitN = 8 }));
        Do(w, IntentType.Rotate, "s", null, 200);
        Assert.Equal(9.81, w.Num("s", "extensionCm"), 1);       // 1.962 N / 20 N/m = 9.81 cm
        Do(w, IntentType.Rotate, "s", null, 400);
        Assert.Equal(19.61, w.Num("s", "extensionCm"), 1);
        Do(w, IntentType.Rotate, "s", null, 1200);
        Assert.True(w.Bool("s", "overstretched"));
        Do(w, IntentType.Release, "s");
        Assert.True(w.Num("s", "extensionCm") > 0.5);             // permanent stretch
    }

    [Fact]
    public void Ramp_trolley_and_light_gate()
    {
        var w = World(("ramp", "ramp", new { lengthM = 1.0, frictionCoeff = 0.0 }), ("gate", "light_gate", null));
        Do(w, IntentType.Connect, "gate", "ramp");
        Do(w, IntentType.Rotate, "ramp", null, 30);
        Do(w, IntentType.Release, "ramp");
        Run(w, 3);
        double v = Math.Sqrt(2 * 9.80665 * 0.5);                  // a = g sin30, s = 1 m
        Assert.Equal(v, w.Num("gate", "reading"), 2);
        Assert.Equal(0.05 / v, w.Num("gate", "gateTimeS"), 3);
    }

    [Fact]
    public void Convex_lens_forms_a_sharp_image_at_the_lens_formula_distance()
    {
        var w = World(("box", "light_box", null), ("lens", "convex_lens", new { focalLengthCm = 10 }), ("scr", "screen", null));
        Do(w, IntentType.Toggle, "box");
        Do(w, IntentType.Rotate, "lens", null, 30);
        Assert.Equal(15, w.Num("lens", "imageDistanceCm"), 2);     // 1/10 = 1/30 + 1/v
        Do(w, IntentType.Rotate, "scr", null, 40); Run(w, 0.1);
        Assert.False(w.Bool("scr", "sharp"));
        Do(w, IntentType.Rotate, "scr", null, 15); Run(w, 0.1);
        Assert.True(w.Bool("scr", "sharp"));
        Assert.Equal(1.0, w.Num("scr", "imageHeightCm"), 2);       // magnification 0.5 × 2 cm
    }

    [Fact]
    public void Contents_survive_save_and_resume()
    {
        var w = World(("t", "test_tube", new { solution = "CuSO4", conc = 0.5, volume = 10 }), ("r", "beaker", new { solution = "NaOH", conc = 1.0, volume = 50 }));
        Do(w, IntentType.Pour, "r", "t", 2);
        var snap = JsonConvert.DeserializeObject<System.Collections.Generic.Dictionary<string, System.Collections.Generic.Dictionary<string, object>>>(JsonConvert.SerializeObject(w.SnapshotEquipment()));
        var w2 = World(("t", "test_tube", new { solution = "water", volume = 1 }), ("r", "beaker", new { solution = "NaOH", conc = 1.0, volume = 50 }));
        w2.RestoreEquipment(snap);
        Run(w2, 0.1);
        Assert.Equal("CuOH2", w2.Str("t", "precipitate"));
        Assert.Equal(12, w2.Num("t", "volumeMl"), 1);
    }
}
