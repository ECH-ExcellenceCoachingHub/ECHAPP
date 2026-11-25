// ECH Labs — general solution chemistry for any container (beaker, test tube, cylinder, dish…).
// Pure C# (no Unity): what is in the container, its pH, temperature, colour, precipitates,
// gases and the reactions between them. Used by student-designed experiments as well as by
// built-in labs. Science is simplified but directionally right and quantitative where school
// experiments measure something (pH, temperature rise, gas, rates, food tests, enzymes, osmosis).
//
// Bookkeeping: strong ions are tracked as ions (Na+, Cl-, Cu2+…); H+ and OH- are NOT tracked —
// they follow from charge balance. Weak acid/base systems (ethanoic acid, ammonia, carbonate,
// fatty acids) are tracked as totals and speciated from pH. Big biological molecules (starch,
// protein, lipid) are tracked in grams; everything else in mol.
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;

namespace ECHLabs.Sim
{
    public enum SpeciesKind { Ion, Weak, Molecule, Grams, Solid, Precipitate, Enzyme, Indicator }

    public sealed class Species
    {
        public string Id, Name;
        public SpeciesKind Kind;
        public int Charge;           // strong ions
        public double MolarMass;     // g/mol (Grams kind: 1)
        public bool StaysBehind;     // large solids that do not pour out with the liquid
        public double DensityGcm3;   // solids: for volume displacement
        public Species(string id, string name, SpeciesKind kind, double molarMass, int charge = 0, bool stays = false, double density = 2.5)
        { Id = id; Name = name; Kind = kind; MolarMass = molarMass; Charge = charge; StaysBehind = stays; DensityGcm3 = density; }
    }

    /// <summary>What a reagent bottle / dropper / sample jar adds: species per litre (solutions) or per gram (solids).</summary>
    public sealed class Recipe
    {
        public string Id, Name;
        public bool Solid;            // per gram added, else per litre at 1 M (scaled by conc)
        public double WaterMlPerUnit; // solids/samples that bring water (milk, juice…) per gram
        public double HeatJPerMol;    // heat released when dissolved (negative = gets colder)
        public Dictionary<string, double> Adds;
        public bool FixedStrength;    // reagents with a fixed recipe (Benedict's, 1% starch…): conc is ignored
        public Recipe(string id, string name, bool solid, Dictionary<string, double> adds, double waterMl = 0, double heat = 0, bool fixedStrength = false)
        { Id = id; Name = name; Solid = solid; Adds = adds; WaterMlPerUnit = waterMl; HeatJPerMol = heat; FixedStrength = fixedStrength; }
    }

    public static class Chem
    {
        public const double Kw = 1e-14, RoomC = 20, WaterCp = 4.18;

        static readonly Dictionary<string, Species> species = new Dictionary<string, Species>();
        static void S(Species s) => species[s.Id] = s;

        public static readonly Dictionary<string, Recipe> Recipes = new Dictionary<string, Recipe>();
        static void R(Recipe r) => Recipes[r.Id] = r;
        static Dictionary<string, double> D(params object[] kv) { var d = new Dictionary<string, double>(); for (int i = 0; i < kv.Length; i += 2) d[(string)kv[i]] = Convert.ToDouble(kv[i + 1], CultureInfo.InvariantCulture); return d; }

        static Chem()
        {
            // Strong ions
            S(new Species("Na+", "sodium ions", SpeciesKind.Ion, 23, 1)); S(new Species("K+", "potassium ions", SpeciesKind.Ion, 39, 1));
            S(new Species("Ag+", "silver ions", SpeciesKind.Ion, 108, 1)); S(new Species("Ba2+", "barium ions", SpeciesKind.Ion, 137, 2));
            S(new Species("Cu2+", "copper(II) ions", SpeciesKind.Ion, 63.5, 2)); S(new Species("Fe2+", "iron(II) ions", SpeciesKind.Ion, 56, 2));
            S(new Species("Fe3+", "iron(III) ions", SpeciesKind.Ion, 56, 3)); S(new Species("Mg2+", "magnesium ions", SpeciesKind.Ion, 24, 2));
            S(new Species("Zn2+", "zinc ions", SpeciesKind.Ion, 65, 2)); S(new Species("Ca2+", "calcium ions", SpeciesKind.Ion, 40, 2));
            S(new Species("Cl-", "chloride ions", SpeciesKind.Ion, 35.5, -1)); S(new Species("NO3-", "nitrate ions", SpeciesKind.Ion, 62, -1));
            S(new Species("SO4", "sulfate ions", SpeciesKind.Ion, 96, -2)); S(new Species("I-", "iodide ions", SpeciesKind.Ion, 127, -1));
            S(new Species("S2O3", "thiosulfate ions", SpeciesKind.Ion, 112, -2));
            // Weak systems (totals)
            S(new Species("CH3COOH", "ethanoic acid", SpeciesKind.Weak, 60)); S(new Species("NH3", "ammonia", SpeciesKind.Weak, 17));
            S(new Species("CO3", "carbonate", SpeciesKind.Weak, 60)); S(new Species("fattyAcid", "fatty acids", SpeciesKind.Weak, 280));
            // Molecules
            S(new Species("H2O2", "hydrogen peroxide", SpeciesKind.Molecule, 34)); S(new Species("glucose", "glucose", SpeciesKind.Molecule, 180));
            S(new Species("maltose", "maltose", SpeciesKind.Molecule, 342)); S(new Species("sucrose", "sucrose", SpeciesKind.Molecule, 342));
            S(new Species("lactose", "lactose", SpeciesKind.Molecule, 342)); S(new Species("ethanol", "ethanol", SpeciesKind.Molecule, 46));
            S(new Species("I2", "iodine", SpeciesKind.Molecule, 254)); S(new Species("benedict", "Benedict's reagent", SpeciesKind.Molecule, 160));
            S(new Species("biuret", "biuret reagent", SpeciesKind.Molecule, 160)); S(new Species("aminoAcids", "amino acids", SpeciesKind.Molecule, 110));
            // Big molecules in grams
            S(new Species("starch", "starch", SpeciesKind.Grams, 1)); S(new Species("protein", "protein", SpeciesKind.Grams, 1)); S(new Species("lipid", "fat/oil", SpeciesKind.Grams, 1));
            // Enzymes (activity units)
            S(new Species("amylase", "amylase", SpeciesKind.Enzyme, 1)); S(new Species("catalase", "catalase", SpeciesKind.Enzyme, 1));
            S(new Species("lipase", "lipase", SpeciesKind.Enzyme, 1)); S(new Species("pepsin", "pepsin", SpeciesKind.Enzyme, 1));
            // Solids that react (stay behind when pouring)
            S(new Species("Mg", "magnesium", SpeciesKind.Solid, 24.3, 0, true, 1.74)); S(new Species("Zn", "zinc", SpeciesKind.Solid, 65.4, 0, true, 7.14));
            S(new Species("Fe", "iron", SpeciesKind.Solid, 55.8, 0, true, 7.87)); S(new Species("Cu", "copper", SpeciesKind.Solid, 63.5, 0, true, 8.96));
            S(new Species("CaCO3", "calcium carbonate (marble chips)", SpeciesKind.Solid, 100, 0, true, 2.71));
            S(new Species("CuO", "copper(II) oxide", SpeciesKind.Solid, 79.5, 0, false, 6.3)); S(new Species("MnO2", "manganese(IV) oxide", SpeciesKind.Solid, 87, 0, true, 5.0));
            S(new Species("NaCl_s", "salt crystals", SpeciesKind.Solid, 58.5, 0, true, 2.16)); S(new Species("CuSO4_s", "blue copper sulfate crystals", SpeciesKind.Solid, 249.7, 0, true, 2.28));
            // Precipitates (pour out with the liquid)
            S(new Species("AgCl", "white precipitate (silver chloride)", SpeciesKind.Precipitate, 143.4)); S(new Species("AgI", "yellow precipitate (silver iodide)", SpeciesKind.Precipitate, 234.8));
            S(new Species("BaSO4", "white precipitate (barium sulfate)", SpeciesKind.Precipitate, 233.4)); S(new Species("CuOH2", "blue precipitate (copper(II) hydroxide)", SpeciesKind.Precipitate, 97.6));
            S(new Species("FeOH2", "green precipitate (iron(II) hydroxide)", SpeciesKind.Precipitate, 89.9)); S(new Species("FeOH3", "orange-brown precipitate (iron(III) hydroxide)", SpeciesKind.Precipitate, 106.9));
            S(new Species("MgOH2", "white precipitate (magnesium hydroxide)", SpeciesKind.Precipitate, 58.3)); S(new Species("CaCO3_ppt", "white precipitate (calcium carbonate)", SpeciesKind.Precipitate, 100));
            S(new Species("S", "pale yellow cloudiness (sulfur)", SpeciesKind.Precipitate, 32)); S(new Species("Cu2O", "brick-red precipitate (copper(I) oxide)", SpeciesKind.Precipitate, 143));
            S(new Species("Ag", "grey crystals (silver)", SpeciesKind.Precipitate, 108)); S(new Species("Cu_dep", "pink-brown copper coating", SpeciesKind.Precipitate, 63.5));
            // Indicators (tiny amounts; colour only)
            foreach (var ind in new[] { "universal", "phenolphthalein", "methyl_orange", "bromothymol_blue", "litmus" })
                S(new Species("ind:" + ind, ind.Replace('_', ' ') + " indicator", SpeciesKind.Indicator, 300));

            // ── Solutions (per litre at 1 mol/dm³; the bottle's conc scales them) ──
            R(new Recipe("water", "Distilled water", false, D()));
            R(new Recipe("HCl", "Hydrochloric acid", false, D("Cl-", 1)));
            R(new Recipe("HNO3", "Nitric acid", false, D("NO3-", 1)));
            R(new Recipe("H2SO4", "Sulfuric acid", false, D("SO4", 1)));
            R(new Recipe("CH3COOH", "Ethanoic acid (vinegar)", false, D("CH3COOH", 1)));
            R(new Recipe("NaOH", "Sodium hydroxide", false, D("Na+", 1)));
            R(new Recipe("KOH", "Potassium hydroxide", false, D("K+", 1)));
            R(new Recipe("NH3", "Ammonia solution", false, D("NH3", 1)));
            R(new Recipe("CaOH2", "Limewater (calcium hydroxide)", false, D("Ca2+", 0.02), fixedStrength: true));
            R(new Recipe("NaCl", "Sodium chloride", false, D("Na+", 1, "Cl-", 1)));
            R(new Recipe("KI", "Potassium iodide", false, D("K+", 1, "I-", 1)));
            R(new Recipe("AgNO3", "Silver nitrate", false, D("Ag+", 1, "NO3-", 1)));
            R(new Recipe("BaCl2", "Barium chloride", false, D("Ba2+", 1, "Cl-", 2)));
            R(new Recipe("CuSO4", "Copper(II) sulfate", false, D("Cu2+", 1, "SO4", 1)));
            R(new Recipe("FeSO4", "Iron(II) sulfate", false, D("Fe2+", 1, "SO4", 1)));
            R(new Recipe("FeCl3", "Iron(III) chloride", false, D("Fe3+", 1, "Cl-", 3)));
            R(new Recipe("MgSO4", "Magnesium sulfate", false, D("Mg2+", 1, "SO4", 1)));
            R(new Recipe("ZnSO4", "Zinc sulfate", false, D("Zn2+", 1, "SO4", 1)));
            R(new Recipe("Na2CO3", "Sodium carbonate", false, D("Na+", 2, "CO3", 1)));
            R(new Recipe("Na2S2O3", "Sodium thiosulfate", false, D("Na+", 2, "S2O3", 1)));
            R(new Recipe("H2O2", "Hydrogen peroxide", false, D("H2O2", 1)));
            R(new Recipe("glucose_sol", "Glucose solution", false, D("glucose", 1)));
            R(new Recipe("sucrose_sol", "Sucrose solution", false, D("sucrose", 1)));
            R(new Recipe("starch_sol", "Starch solution (1%)", false, D("starch", 10), fixedStrength: true));
            R(new Recipe("ethanol", "Ethanol", false, D("ethanol", 17), fixedStrength: true));
            // Reagents (droppers; fixed strength)
            R(new Recipe("benedicts", "Benedict's reagent", false, D("benedict", 0.1, "Na+", 0.2, "CO3", 0.1), fixedStrength: true));
            R(new Recipe("biuret", "Biuret reagent", false, D("biuret", 0.05, "Na+", 0.5), fixedStrength: true));
            R(new Recipe("iodine", "Iodine solution", false, D("I2", 0.01, "K+", 0.02, "I-", 0.02), fixedStrength: true));
            R(new Recipe("universal", "Universal indicator", false, D("ind:universal", 0.001), fixedStrength: true));
            R(new Recipe("phenolphthalein", "Phenolphthalein", false, D("ind:phenolphthalein", 0.001), fixedStrength: true));
            R(new Recipe("methyl_orange", "Methyl orange", false, D("ind:methyl_orange", 0.001), fixedStrength: true));
            R(new Recipe("bromothymol_blue", "Bromothymol blue", false, D("ind:bromothymol_blue", 0.001), fixedStrength: true));
            R(new Recipe("litmus", "Litmus solution", false, D("ind:litmus", 0.001), fixedStrength: true));
            R(new Recipe("amylase", "Amylase solution (1%)", false, D("amylase", 10), fixedStrength: true));
            R(new Recipe("lipase", "Lipase solution", false, D("lipase", 10), fixedStrength: true));
            R(new Recipe("pepsin", "Pepsin solution", false, D("pepsin", 10), fixedStrength: true));
            R(new Recipe("catalase_sol", "Catalase solution", false, D("catalase", 20), fixedStrength: true));

            // ── Solids and food samples (per gram) ──
            R(new Recipe("Mg", "Magnesium ribbon", true, D("Mg", 1 / 24.3)));
            R(new Recipe("Zn", "Zinc granules", true, D("Zn", 1 / 65.4)));
            R(new Recipe("Fe", "Iron filings", true, D("Fe", 1 / 55.8)));
            R(new Recipe("Cu", "Copper turnings", true, D("Cu", 1 / 63.5)));
            R(new Recipe("CaCO3", "Marble chips (calcium carbonate)", true, D("CaCO3", 1 / 100.0)));
            R(new Recipe("CuO", "Copper(II) oxide powder", true, D("CuO", 1 / 79.5)));
            R(new Recipe("MnO2", "Manganese(IV) oxide powder", true, D("MnO2", 1 / 87.0)));
            R(new Recipe("NaCl_s", "Salt (sodium chloride)", true, D("Na+", 1 / 58.5, "Cl-", 1 / 58.5), heat: 3900));
            R(new Recipe("CuSO4_s", "Copper sulfate crystals", true, D("Cu2+", 1 / 249.7, "SO4", 1 / 249.7), heat: -11500));
            R(new Recipe("NaHCO3", "Sodium hydrogencarbonate", true, D("Na+", 1 / 84.0, "CO3", 1 / 84.0), heat: 18700));
            R(new Recipe("Na2CO3_s", "Sodium carbonate powder", true, D("Na+", 2 / 106.0, "CO3", 1 / 106.0), heat: -26700));
            R(new Recipe("NH4NO3", "Ammonium nitrate", true, D("NH3", 1 / 80.0, "NO3-", 1 / 80.0), heat: 25700));
            R(new Recipe("glucose", "Glucose powder", true, D("glucose", 1 / 180.0)));
            R(new Recipe("sucrose", "Sugar (sucrose)", true, D("sucrose", 1 / 342.0)));
            R(new Recipe("starch", "Starch powder", true, D("starch", 1)));
            R(new Recipe("milk", "Milk", true, D("protein", 0.034, "lipid", 0.036, "lactose", 0.048 / 342), waterMl: 0.87));
            R(new Recipe("egg_white", "Egg white", true, D("protein", 0.11), waterMl: 0.88));
            R(new Recipe("bread", "Bread", true, D("starch", 0.45, "protein", 0.09, "lipid", 0.03, "glucose", 0.02 / 180)));
            R(new Recipe("apple_juice", "Apple juice", true, D("glucose", 0.1 / 180), waterMl: 0.88));
            R(new Recipe("honey", "Honey", true, D("glucose", 0.8 / 180), waterMl: 0.17));
            R(new Recipe("vegetable_oil", "Vegetable oil", true, D("lipid", 1)));
            R(new Recipe("potato", "Potato (chopped)", true, D("starch", 0.15, "catalase", 0.4), waterMl: 0.8));
            R(new Recipe("liver", "Liver (chopped)", true, D("catalase", 5, "protein", 0.2), waterMl: 0.7));
        }

        public static Species Get(string id) => species.TryGetValue(id, out var s) ? s : null;
        public static IEnumerable<string> SolutionIds => Recipes.Values.Where(r => !r.Solid).Select(r => r.Id);
        public static IEnumerable<string> SolidIds => Recipes.Values.Where(r => r.Solid).Select(r => r.Id);
        public static string NameOf(string recipe) => Recipes.TryGetValue(recipe ?? "", out var r) ? r.Name : recipe;

        // ─── pH ──────────────────────────────────────────────────────────────

        public const double KaAcetic = 1.8e-5, KaAmmonium = 5.6e-10, Ka1Carbonic = 4.5e-7, Ka2Carbonic = 4.7e-11, KaFatty = 1.6e-5;

        /// <summary>pH from charge balance, by bisection. Concentrations in mol/L.</summary>
        public static double PH(double netStrong, double acetic, double ammonia, double carbonate, double fatty)
        {
            double lo = -1.5, hi = 15.5;
            for (int i = 0; i < 70; i++)
            {
                double mid = (lo + hi) / 2, h = Math.Pow(10, -mid);
                double f = netStrong + h - Kw / h
                         - acetic * KaAcetic / (KaAcetic + h)
                         - fatty * KaFatty / (KaFatty + h)
                         + ammonia * h / (h + KaAmmonium)
                         - carbonate * (Ka1Carbonic * h + 2 * Ka1Carbonic * Ka2Carbonic) / (h * h + Ka1Carbonic * h + Ka1Carbonic * Ka2Carbonic);
                if (f > 0) lo = mid; else hi = mid; // f decreases with pH
            }
            return (lo + hi) / 2;
        }

        /// <summary>Colour of an indicator at a pH (linear RGBA).</summary>
        public static float[] IndicatorColor(string ind, double pH)
        {
            switch (ind)
            {
                case "universal":
                    {
                        // red (1) → orange → yellow → green (7) → blue → indigo → violet (14)
                        var stops = new[] { (1.0, new[] { 0.85f, 0.08f, 0.08f }), (4.0, new[] { 0.98f, 0.55f, 0.1f }), (6.0, new[] { 0.95f, 0.88f, 0.12f }), (7.0, new[] { 0.2f, 0.72f, 0.2f }), (9.0, new[] { 0.12f, 0.45f, 0.85f }), (11.0, new[] { 0.25f, 0.18f, 0.7f }), (13.0, new[] { 0.45f, 0.12f, 0.6f }) };
                        if (pH <= stops[0].Item1) return Rgba(stops[0].Item2, 0.8f);
                        for (int i = 1; i < stops.Length; i++)
                            if (pH <= stops[i].Item1) { float t = (float)((pH - stops[i - 1].Item1) / (stops[i].Item1 - stops[i - 1].Item1)); return Rgba(Lerp(stops[i - 1].Item2, stops[i].Item2, t), 0.8f); }
                        return Rgba(stops[stops.Length - 1].Item2, 0.8f);
                    }
                case "litmus": return pH < 4.5 ? new[] { 0.85f, 0.15f, 0.2f, 0.75f } : pH > 8.3 ? new[] { 0.2f, 0.3f, 0.85f, 0.75f } : new[] { 0.55f, 0.2f, 0.6f, 0.75f };
                default:
                    if (Chemistry.Indicators.TryGetValue(ind, out var info))
                    {
                        float t = (float)Chemistry.IndicatorColorIndex(ind, pH);
                        var c = new float[4];
                        for (int k = 0; k < 4; k++) c[k] = info.FromRgba[k] + (info.ToRgba[k] - info.FromRgba[k]) * t;
                        return c;
                    }
                    return new[] { 0.9f, 0.95f, 1f, 0.15f };
            }
        }

        static float[] Rgba(float[] rgb, float a) => new[] { rgb[0], rgb[1], rgb[2], a };
        static float[] Lerp(float[] a, float[] b, float t) => new[] { a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t };

        /// <summary>Rate multiplier for a chemical reaction (rate doubles every 10 °C).</summary>
        public static double Q10(double tC, double refC = 20) => Math.Pow(2, (tC - refC) / 10);

        /// <summary>Enzyme activity vs temperature (optimum ~37–40 °C, falls off above; denaturation handled separately).</summary>
        public static double EnzymeTemp(double tC) => tC <= 40 ? Math.Pow(2, (tC - 37) / 10) : Math.Pow(2, 0.3) * Math.Exp(-Math.Pow((tC - 40) / 9, 2));
        public static double EnzymePH(double pH, double optimum) => Math.Exp(-Math.Pow((pH - optimum) / 1.6, 2));
    }

    /// <summary>The contents of one container.</summary>
    public sealed class Mixture
    {
        public double WaterMl;
        public double TemperatureC = Chem.RoomC;
        public readonly Dictionary<string, double> Amount = new Dictionary<string, double>();
        /// <summary>Gas produced recently (mol, decays) — what a splint or limewater would detect.</summary>
        public readonly Dictionary<string, double> RecentGas = new Dictionary<string, double>();
        /// <summary>Gas produced in the last tick (mol/s) — fizzing, bubbles, delivery tubes.</summary>
        public readonly Dictionary<string, double> GasRate = new Dictionary<string, double>();
        public double TotalGasMl; // cumulative, at room conditions (24 dm³/mol) — gas syringes
        /// <summary>Fraction of each enzyme still working (0 = fully denatured).</summary>
        public readonly Dictionary<string, double> EnzymeAlive = new Dictionary<string, double>();
        public double PHValue = 7;
        public double ExtraVolumeMl; // immersed objects (measuring cylinder displacement)
        public string LastReaction;  // short description of the most recent change (for toasts)

        public double Get(string id) => Amount.TryGetValue(id, out var v) ? v : 0;
        public void Add(string id, double v) { var n = Get(id) + v; if (n <= 1e-15) Amount.Remove(id); else Amount[id] = n; }
        double L => Math.Max(LiquidMl, 1e-6) / 1000.0;
        public double Conc(string id) => LiquidMl > 0.01 ? Get(id) / L : 0;

        public double LiquidMl => Math.Max(0, WaterMl + Get("ethanol") * 58.4 + Get("lipid") / 0.92);
        public double VolumeMl => LiquidMl + SolidVolumeMl + ExtraVolumeMl;
        double SolidVolumeMl
        {
            get
            {
                double v = 0;
                foreach (var kv in Amount)
                {
                    var s = Chem.Get(kv.Key);
                    if (s != null && (s.Kind == SpeciesKind.Solid)) v += kv.Value * s.MolarMass / s.DensityGcm3;
                }
                return v;
            }
        }

        public double MassG
        {
            get
            {
                double m = WaterMl;
                foreach (var kv in Amount) { var s = Chem.Get(kv.Key); if (s != null) m += kv.Value * s.MolarMass; }
                return m;
            }
        }

        public double HeatCapacityJPerK => Math.Max(WaterMl, 0.5) * Chem.WaterCp + 5;

        // ─── Adding things ───────────────────────────────────────────────────

        /// <summary>Adds a solution (recipe at conc mol/dm³) or a solid/sample (grams).</summary>
        public void AddRecipe(string recipeId, double conc, double amount, double tempC = Chem.RoomC, bool solidAmount = false)
        {
            if (recipeId == null || !Chem.Recipes.TryGetValue(recipeId, out var r))
            {
                if (recipeId != null && Chemistry.Indicators.ContainsKey(recipeId)) { Add("ind:" + recipeId, 0.001 * amount / 1000); return; }
                r = Chem.Recipes["water"];
            }
            double heatBefore = HeatCapacityJPerK;
            double tBefore = TemperatureC;
            if (r.Solid && conc > 0 && r.WaterMlPerUnit == 0 && amount > 0 && !solidAmount)
            {
                // A solid named as a solution ("NaHCO3, 0.1 M"): dissolve conc mol/dm³ of it in that much water.
                double molarMass = 1 / Math.Max(r.Adds.Values.Max(), 1e-9);
                double grams = conc * amount / 1000 * molarMass;
                double cAdd = amount * Chem.WaterCp;
                TemperatureC = WaterMl + amount > 0 ? (tBefore * heatBefore + tempC * cAdd) / (heatBefore + cAdd) : tempC;
                WaterMl += amount;
                foreach (var kv in r.Adds) Add(kv.Key, kv.Value * grams);
            }
            else if (r.Solid)
            {
                foreach (var kv in r.Adds) Add(kv.Key, kv.Value * amount);
                double water = r.WaterMlPerUnit * amount;
                WaterMl += water;
                if (r.HeatJPerMol != 0 && WaterMl > 0)
                {
                    double mol = r.Adds.Values.Max() * amount;
                    TemperatureC -= r.HeatJPerMol * mol / HeatCapacityJPerK;
                }
                LastReaction = $"Added {amount:0.##} g of {r.Name.ToLowerInvariant()}";
            }
            else
            {
                double scale = r.FixedStrength ? 1 : conc;
                double litres = amount / 1000.0;
                // Neutralisation heat: strong/weak acid meets strong/weak base.
                double acidHere = AcidCapacity(), baseHere = BaseCapacity();
                double addAcid = 0, addBase = 0;
                double addNet = 0;
                foreach (var kv in r.Adds)
                {
                    var s = Chem.Get(kv.Key);
                    double n = kv.Value * scale * litres;
                    if (s != null && s.Kind == SpeciesKind.Ion) addNet += s.Charge * n;
                    if (kv.Key == "CH3COOH") addAcid += n;
                    if (kv.Key == "NH3") addBase += n;
                }
                if (addNet < 0) addAcid += -addNet; else addBase += addNet;
                double neutralised = Math.Min(acidHere, addBase) + Math.Min(addAcid, baseHere);
                // Mix temperatures, then add the reaction heat.
                double cAdded = amount * Chem.WaterCp;
                TemperatureC = WaterMl + amount > 0 ? (tBefore * heatBefore + tempC * cAdded) / (heatBefore + cAdded) : tempC;
                WaterMl += amount;
                foreach (var kv in r.Adds) Add(kv.Key, kv.Value * scale * litres);
                if (neutralised > 0)
                {
                    TemperatureC += 57100 * neutralised / HeatCapacityJPerK;
                    LastReaction = "Neutralisation — the mixture warms up";
                }
            }
            Equilibrate();
        }

        /// <summary>Moves a fraction of the liquid (and what is dissolved/suspended in it) into another mixture.</summary>
        public void PourInto(Mixture target, double fraction)
        {
            fraction = Math.Min(Math.Max(fraction, 0), 1);
            if (fraction <= 0) return;
            double water = WaterMl * fraction;
            double heatT = target.HeatCapacityJPerK, heatS = water * Chem.WaterCp;
            double t = target.WaterMl + water > 0 ? (target.TemperatureC * heatT + TemperatureC * heatS) / (heatT + heatS) : TemperatureC;
            double acid = AcidCapacity() * fraction, bas = BaseCapacity() * fraction;
            double neutralised = Math.Min(target.AcidCapacity(), bas) + Math.Min(acid, target.BaseCapacity());
            WaterMl -= water;
            target.WaterMl += water;
            foreach (var kv in Amount.ToList())
            {
                var s = Chem.Get(kv.Key);
                if (s != null && s.StaysBehind) continue;
                double moved = kv.Value * fraction;
                Add(kv.Key, -moved);
                target.Add(kv.Key, moved);
            }
            foreach (var kv in EnzymeAlive) if (!target.EnzymeAlive.ContainsKey(kv.Key) || target.Get(kv.Key) <= 0) target.EnzymeAlive[kv.Key] = kv.Value;
            target.TemperatureC = t;
            if (neutralised > 0) { target.TemperatureC += 57100 * neutralised / target.HeatCapacityJPerK; target.LastReaction = "Neutralisation — the mixture warms up"; }
            target.Equilibrate();
            Equilibrate();
        }

        /// <summary>Strong-acid + weak-acid capacity (mol of H+ that a base could neutralise).</summary>
        public double AcidCapacity() => Math.Max(0, -NetStrongMol()) + Get("CH3COOH") * (PHValue < 7 ? 1 : 0) + Get("fattyAcid") * (PHValue < 7 ? 1 : 0);
        public double BaseCapacity() => Math.Max(0, NetStrongMol()) + Get("NH3") * (PHValue > 7 ? 1 : 0);

        public double NetStrongMol()
        {
            double net = 0;
            foreach (var kv in Amount) { var s = Chem.Get(kv.Key); if (s != null && s.Kind == SpeciesKind.Ion) net += s.Charge * kv.Value; }
            return net;
        }

        // ─── Equilibria (instant) ────────────────────────────────────────────

        public void Equilibrate()
        {
            if (LiquidMl < 0.01) { PHValue = 7; return; }
            for (int pass = 0; pass < 4; pass++)
            {
                bool changed = false;
                // Silver halides, barium sulfate: essentially complete.
                changed |= Precipitate("Ag+", "I-", 1, "AgI");
                changed |= Precipitate("Ag+", "Cl-", 1, "AgCl");
                changed |= Precipitate("Ba2+", "SO4", 1, "BaSO4");
                PHValue = ComputePH();
                // Hydroxides: precipitate while the solution is alkaline enough (excess strong base pays for OH-).
                changed |= Hydroxide("Fe3+", 3, 2.5, "FeOH3");
                changed |= Hydroxide("Cu2+", 2, 5.5, "CuOH2");
                changed |= Hydroxide("Fe2+", 2, 7.0, "FeOH2");
                changed |= Hydroxide("Mg2+", 2, 9.5, "MgOH2");
                // Limewater + carbon dioxide → calcium carbonate (milky) while alkaline.
                if (Get("Ca2+") > 0 && Get("CO3") > 0 && PHValue > 8.5)
                {
                    double n = Math.Min(Get("Ca2+"), Get("CO3"));
                    Add("Ca2+", -n); Add("CO3", -n); Add("CaCO3_ppt", n);
                    LastReaction = "The solution turns milky (calcium carbonate)";
                    changed = true;
                }
                if (!changed) break;
            }
            PHValue = ComputePH();
        }

        bool Precipitate(string cation, string anion, double ratio, string ppt)
        {
            double n = Math.Min(Get(cation), Get(anion) / ratio);
            if (n <= 1e-12) return false;
            Add(cation, -n); Add(anion, -n * ratio); Add(ppt, n);
            LastReaction = "A " + Chem.Get(ppt).Name + " forms";
            return true;
        }

        bool Hydroxide(string cation, int charge, double pHStart, string ppt)
        {
            if (Get(cation) <= 0) return false;
            if (ComputePH() < pHStart) return false;
            double excessBase = NetStrongMol();
            if (excessBase <= 1e-12) return false;
            double n = Math.Min(Get(cation), excessBase / charge);
            if (n <= 1e-12) return false;
            Add(cation, -n); Add(ppt, n);
            LastReaction = "A " + Chem.Get(ppt).Name + " forms";
            return true;
        }

        public double ComputePH()
        {
            if (LiquidMl < 0.01) return 7;
            double l = L;
            return Chem.PH(NetStrongMol() / l, Get("CH3COOH") / l, Get("NH3") / l, Get("CO3") / l, Get("fattyAcid") / l);
        }

        // ─── Kinetics (per tick) ─────────────────────────────────────────────

        /// <summary>Advances reactions by dt seconds. heatInW = heater power reaching the contents.</summary>
        public void Step(double dt, double heatInW = 0, double coolingPerS = 0.004, double? bathC = null)
        {
            GasRate.Clear();
            foreach (var k in RecentGas.Keys.ToList()) { RecentGas[k] *= Math.Exp(-dt / 25); if (RecentGas[k] < 1e-7) RecentGas.Remove(k); }
            if (LiquidMl < 0.01 && heatInW <= 0) { TemperatureC += (Chem.RoomC - TemperatureC) * Math.Min(1, coolingPerS * dt); return; }

            double h = Math.Pow(10, -PHValue);
            double T = TemperatureC, q = Chem.Q10(T);
            double heatJ = 0;

            // Metals + acid → salt + hydrogen (fizzing, warming).
            heatJ += MetalAcid("Mg", 0.004, 467000, "Mg2+", h, q, dt);
            heatJ += MetalAcid("Zn", 0.0006, 153000, "Zn2+", h, q, dt);
            heatJ += MetalAcid("Fe", 0.0002, 89000, "Fe2+", h, q, dt);
            // Carbonates + acid → carbon dioxide.
            heatJ += SolidAcid("CaCO3", 0.004, 15000, "Ca2+", h, q, dt, "CO2");
            heatJ += SolidAcid("CaCO3_ppt", 2.0, 15000, "Ca2+", h, q, dt, "CO2");
            heatJ += SolidAcid("MgOH2", 3.0, 0, "Mg2+", h, q, dt, null);
            heatJ += SolidAcid("CuOH2", 3.0, 0, "Cu2+", h, q, dt, null);
            heatJ += SolidAcid("FeOH3", 1.0, 0, "Fe3+", h, q, dt, null, 3);
            // Copper(II) oxide dissolves in warm acid (blue solution).
            heatJ += SolidAcid("CuO", 0.004 * Math.Pow(2, (T - 20) / 8), 0, "Cu2+", h, 1, dt, null);
            // Dissolved carbonate in acid loses CO2.
            if (Get("CO3") > 0 && PHValue < 6.0)
            {
                double frac = h * h / (h * h + Chem.Ka1Carbonic * h + Chem.Ka1Carbonic * Chem.Ka2Carbonic);
                double n = Math.Min(Get("CO3"), Get("CO3") * frac * 0.15 * dt * q);
                if (n > 0) { Add("CO3", -n); Gas("CO2", n, dt); }
            }
            // Displacement: more reactive metal + copper(II)/silver ions.
            heatJ += Displace("Mg", "Cu2+", 0.3, 530000, "Mg2+", "Cu_dep", 1, q, dt);
            heatJ += Displace("Zn", "Cu2+", 0.06, 217000, "Zn2+", "Cu_dep", 1, q, dt);
            heatJ += Displace("Fe", "Cu2+", 0.03, 153000, "Fe2+", "Cu_dep", 1, q, dt);
            heatJ += Displace("Cu", "Ag+", 0.03, 147000, "Cu2+", "Ag", 2, q, dt);
            // Thiosulfate + acid → sulfur (the "disappearing cross").
            if (Get("S2O3") > 0 && h > 1e-5)
            {
                double rate = 0.025 * Conc("S2O3") * h * q * L;
                double n = Math.Min(Get("S2O3"), rate * dt);
                Add("S2O3", -n); Add("S", n); Gas("SO2", n, dt, false);
            }
            // Hydrogen peroxide decomposition (catalysed by MnO2 or catalase).
            if (Get("H2O2") > 0)
            {
                double k = 0.00002 * q;
                if (Get("MnO2") > 0) k += 0.05 * Math.Min(1, Get("MnO2") / 0.005) * q;
                k += Enzyme("catalase", 7.0, dt) * 0.004;
                double n = Math.Min(Get("H2O2"), Get("H2O2") * k * dt);
                if (n > 0) { Add("H2O2", -n); Gas("O2", n / 2, dt); heatJ += 98000 * n; }
            }
            // Amylase: starch → maltose.
            if (Get("starch") > 0 && Get("amylase") > 0)
            {
                double act = Enzyme("amylase", 7.0, dt);
                double s = Conc("starch"); // g/L
                double rate = 12.0 * act * s / (s + 2) * L; // g/s
                double n = Math.Min(Get("starch"), rate * dt);
                Add("starch", -n); Add("maltose", n / 342.0);
            }
            // Lipase: fat → fatty acids (pH falls).
            if (Get("lipid") > 0 && Get("lipase") > 0)
            {
                double act = Enzyme("lipase", 8.0, dt);
                double n = Math.Min(Get("lipid"), 0.0008 * act * dt);
                Add("lipid", -n); Add("fattyAcid", n * 3 / 880.0);
            }
            // Pepsin (works in acid): protein → amino acids.
            if (Get("protein") > 0 && Get("pepsin") > 0)
            {
                double act = Enzyme("pepsin", 2.0, dt);
                double n = Math.Min(Get("protein"), 0.0006 * act * dt);
                Add("protein", -n); Add("aminoAcids", n / 110.0);
            }
            // Acid + heat hydrolyses sucrose to glucose (why sucrose can test positive after boiling with acid).
            if (Get("sucrose") > 0 && h > 1e-3 && T > 70)
            {
                double n = Math.Min(Get("sucrose"), Get("sucrose") * 0.01 * q / Chem.Q10(70) * dt);
                Add("sucrose", -n); Add("glucose", 2 * n);
            }
            // Benedict's test: reducing sugars + hot Benedict's → copper(I) oxide.
            if (Get("benedict") > 0 && T > 60)
            {
                double sugar = Get("glucose") + Get("maltose") + Get("lactose");
                if (sugar > 0)
                {
                    double n = Math.Min(Math.Min(Get("benedict"), sugar), (Get("benedict") + sugar) * 0.03 * Chem.Q10(T, 80) * dt);
                    Add("benedict", -n); Add("Cu2O", n);
                    double g = Math.Min(Get("glucose"), n); Add("glucose", -g); n -= g;
                    double m = Math.Min(Get("maltose"), n); Add("maltose", -m); n -= m;
                    Add("lactose", -Math.Min(Get("lactose"), n));
                }
            }

            // Heat: chemistry, heater/bath, cooling, boiling.
            double cap = HeatCapacityJPerK;
            TemperatureC += heatJ / cap;
            if (bathC.HasValue) TemperatureC += (bathC.Value - TemperatureC) * Math.Min(1, 0.05 * dt);
            if (heatInW > 0) TemperatureC += heatInW * dt / cap;
            TemperatureC += (Chem.RoomC - TemperatureC) * Math.Min(1, coolingPerS * dt);
            if (TemperatureC > 100 && WaterMl > 0)
            {
                // Boiling: extra energy evaporates water (2257 J/g).
                double excessJ = (TemperatureC - 100) * cap;
                double evaporated = Math.Min(WaterMl, excessJ / 2257.0);
                WaterMl -= evaporated;
                TemperatureC = 100;
                Crystallise();
                if (WaterMl <= 0.01) { WaterMl = 0; LastReaction = "All the water has evaporated"; }
            }
            if (WaterMl <= 0 && heatInW > 0) TemperatureC = Math.Min(TemperatureC, 250);
            Equilibrate();
        }

        double Enzyme(string id, double optimumPH, double dt)
        {
            if (Get(id) <= 0) return 0;
            if (!EnzymeAlive.TryGetValue(id, out var alive)) alive = 1;
            // Denaturation above ~50 °C is permanent.
            if (TemperatureC > 50) alive *= Math.Exp(-0.02 * (TemperatureC - 50) * dt);
            EnzymeAlive[id] = alive;
            return Get(id) * alive * Chem.EnzymeTemp(TemperatureC) * Chem.EnzymePH(PHValue, optimumPH);
        }

        double MetalAcid(string metal, double k, double dH, string ion, double h, double q, double dt)
        {
            double m = Get(metal);
            if (m <= 0 || h < 1e-6) return 0;
            // Rate ∝ surface (∝ amount^(2/3)) × [H+]; weak acids react slower (low [H+]).
            double rate = k * Math.Pow(m, 2.0 / 3) * Math.Min(h, 3) * q;
            double n = Math.Min(m, rate * dt);
            double maxByAcid = Math.Max(0, -NetStrongMol()) / 2 + Get("CH3COOH") * 0.5;
            n = Math.Min(n, Math.Max(maxByAcid, 0));
            if (n <= 0) return 0;
            Add(metal, -n); Add(ion, n);
            // Ethanoic acid gives up its H+ (it becomes ethanoate): handled by charge balance.
            Gas("H2", n, dt);
            LastReaction = "Fizzing — a colourless gas is given off";
            return dH * n;
        }

        double SolidAcid(string solid, double k, double dH, string ion, double h, double q, double dt, string gas, int charge = 2)
        {
            double m = Get(solid);
            if (m <= 0 || h < 1e-6) return 0;
            double rate = k * Math.Pow(m, 2.0 / 3) * Math.Min(h, 3) * q;
            double maxByAcid = (Math.Max(0, -NetStrongMol()) + Get("CH3COOH") * 0.5) / charge;
            double n = Math.Min(Math.Min(m, rate * dt), Math.Max(0, maxByAcid));
            if (n <= 0) return 0;
            Add(solid, -n); Add(ion, n);
            if (gas != null) { Gas(gas, n, dt); LastReaction = "Fizzing — a colourless gas is given off"; }
            return dH * n;
        }

        double Displace(string metal, string ion, double k, double dH, string newIon, string deposit, int ratio, double q, double dt)
        {
            double m = Get(metal), c = Get(ion);
            if (m <= 0 || c <= 0) return 0;
            double rate = k * Math.Pow(m, 2.0 / 3) * Conc(ion) * q;
            double n = Math.Min(Math.Min(m, c / ratio), rate * dt);
            if (n <= 0) return 0;
            Add(metal, -n); Add(ion, -n * ratio); Add(newIon, n); Add(deposit, n * ratio);
            LastReaction = deposit == "Ag" ? "Grey silver crystals grow on the copper" : "A brown copper coating forms; the blue colour fades";
            return dH * n;
        }

        void Gas(string gas, double mol, double dt, bool bubbles = true)
        {
            RecentGas[gas] = (RecentGas.TryGetValue(gas, out var r) ? r : 0) + mol;
            if (bubbles) GasRate[gas] = (GasRate.TryGetValue(gas, out var g) ? g : 0) + mol / Math.Max(dt, 1e-6);
            if (bubbles) TotalGasMl += mol * 24000;
        }

        void Crystallise()
        {
            if (WaterMl <= 0.5)
            {
                foreach (var (a, b, xtal, mm) in new[] { ("Na+", "Cl-", "NaCl_s", 58.5), ("Cu2+", "SO4", "CuSO4_s", 249.7) })
                {
                    double n = Math.Min(Get(a), Get(b));
                    if (n > 0) { Add(a, -n); Add(b, -n); Add(xtal, n); LastReaction = "Crystals form as the water evaporates"; }
                }
                return;
            }
            // Saturated solutions start to crystallise.
            foreach (var (a, b, xtal, sol) in new[] { ("Na+", "Cl-", "NaCl_s", 6.1), ("Cu2+", "SO4", "CuSO4_s", 1.4) })
            {
                double n = Math.Min(Get(a), Get(b));
                double max = sol * WaterMl / 1000;
                if (n > max) { Add(a, -(n - max)); Add(b, -(n - max)); Add(xtal, n - max); LastReaction = "Crystals start to form"; }
            }
        }

        // ─── What a student sees ─────────────────────────────────────────────

        public bool Fizzing => GasRate.Values.Sum() > 2e-6;
        public string MainGas => RecentGas.Count == 0 ? "" : RecentGas.OrderByDescending(k => k.Value).First().Key;

        /// <summary>0 clear … 1 opaque (precipitates, sulfur, emulsions).</summary>
        public double Cloudiness
        {
            get
            {
                if (LiquidMl < 0.01) return 0;
                double c = 0;
                foreach (var kv in Amount)
                {
                    var s = Chem.Get(kv.Key);
                    if (s != null && s.Kind == SpeciesKind.Precipitate) c += kv.Value / L * (kv.Key == "S" ? 25 : kv.Key == "CaCO3_ppt" ? 120 : 60);
                }
                if (Emulsion) c += 0.8;
                return Math.Min(1, c);
            }
        }

        public bool Emulsion => Get("lipid") > 0.005 && Get("ethanol") > 0 && WaterMl > Get("ethanol") * 58.4;
        public bool StarchPresent => LiquidMl > 0.01 && Conc("starch") > 0.05;
        public bool ProteinPresent => Get("protein") > 0.002;

        public string MainPrecipitate
        {
            get
            {
                string best = ""; double max = 1e-6;
                foreach (var kv in Amount) { var s = Chem.Get(kv.Key); if (s != null && s.Kind == SpeciesKind.Precipitate && kv.Value > max) { max = kv.Value; best = kv.Key; } }
                return best;
            }
        }

        /// <summary>Linear RGBA colour of the liquid.</summary>
        public float[] Color()
        {
            var c = new[] { 0.9f, 0.95f, 1f, 0.12f }; // water
            void Blend(float[] col, double strength) { float t = (float)Math.Min(1, Math.Max(0, strength)); for (int k = 0; k < 4; k++) c[k] += (col[k] - c[k]) * t; }
            if (LiquidMl < 0.01) return c;
            Blend(new[] { 0.15f, 0.45f, 0.95f, 0.6f }, Conc("Cu2+") * 4);              // copper(II): blue
            Blend(new[] { 0.6f, 0.82f, 0.5f, 0.5f }, Conc("Fe2+") * 4);                // iron(II): pale green
            Blend(new[] { 0.85f, 0.55f, 0.15f, 0.6f }, Conc("Fe3+") * 6);              // iron(III): yellow-brown
            Blend(new[] { 0.55f, 0.32f, 0.08f, 0.6f }, Conc("I2") * 120);              // iodine: brown
            Blend(new[] { 0.95f, 0.85f, 0.55f, 0.55f }, Get("lipid") > 0 && Get("ethanol") <= 0 ? 0.35 : 0); // oil layer
            Blend(new[] { 0.25f, 0.45f, 0.95f, 0.65f }, Conc("benedict") * 25);        // Benedict's: blue
            // Benedict's result: green → yellow → orange → brick red as more Cu2O forms.
            if (Get("Cu2O") > 0)
            {
                double frac = Get("Cu2O") / (Get("Cu2O") + Get("benedict") + 1e-9);
                var col = frac < 0.25 ? new[] { 0.35f, 0.65f, 0.25f, 0.75f } : frac < 0.5 ? new[] { 0.9f, 0.8f, 0.15f, 0.8f } : frac < 0.8 ? new[] { 0.95f, 0.5f, 0.1f, 0.85f } : new[] { 0.72f, 0.16f, 0.08f, 0.9f };
                Blend(col, Math.Min(1, frac * 4));
            }
            if (Get("biuret") > 0) Blend(ProteinPresent ? new[] { 0.5f, 0.15f, 0.65f, 0.8f } : new[] { 0.25f, 0.45f, 0.9f, 0.6f }, 0.9); // biuret: purple / blue
            if (Get("I2") > 0 && StarchPresent) Blend(new[] { 0.05f, 0.05f, 0.2f, 0.95f }, Math.Min(1, Conc("starch") * 0.8)); // blue-black
            foreach (var kv in Amount)
                if (kv.Key.StartsWith("ind:")) { Blend(Chem.IndicatorColor(kv.Key.Substring(4), PHValue), 0.9); break; }
            // Precipitates and cloudiness.
            string p = MainPrecipitate;
            float[] pc = p switch
            {
                "AgCl" => new[] { 0.95f, 0.95f, 0.95f, 0.9f }, "BaSO4" => new[] { 0.96f, 0.96f, 0.96f, 0.9f }, "CaCO3_ppt" => new[] { 0.94f, 0.94f, 0.92f, 0.85f },
                "MgOH2" => new[] { 0.93f, 0.93f, 0.93f, 0.85f }, "AgI" => new[] { 0.95f, 0.9f, 0.45f, 0.9f }, "CuOH2" => new[] { 0.3f, 0.55f, 0.9f, 0.9f },
                "FeOH2" => new[] { 0.35f, 0.5f, 0.3f, 0.9f }, "FeOH3" => new[] { 0.65f, 0.3f, 0.1f, 0.92f }, "S" => new[] { 0.95f, 0.93f, 0.7f, 0.92f },
                "Cu2O" => new[] { 0.72f, 0.16f, 0.08f, 0.9f }, _ => null,
            };
            if (pc != null) Blend(pc, Cloudiness);
            if (Emulsion) Blend(new[] { 0.97f, 0.97f, 0.95f, 0.9f }, 0.8);
            return c;
        }

        public string ColourName()
        {
            var c = Color();
            if (c[3] < 0.2f) return "colourless";
            float r = c[0], g = c[1], b = c[2];
            float max = Math.Max(r, Math.Max(g, b)), min = Math.Min(r, Math.Min(g, b));
            if (max < 0.25f) return "blue-black";
            if (max - min < 0.08f) return max > 0.8f ? (Cloudiness > 0.3 ? "white (cloudy)" : "colourless") : "grey";
            if (r >= g && r >= b) return g > 0.7f * r ? "yellow" : g > 0.4f * r ? "orange" : b > 0.5f * r ? "pink" : "red";
            if (g >= r && g >= b) return b > 0.8f * g ? "turquoise" : r > 0.8f * g ? "yellow-green" : "green";
            return r > 0.6f * b ? "purple" : "blue";
        }

        /// <summary>One line describing what you would notice.</summary>
        public string Observation()
        {
            if (LiquidMl < 0.01 && Amount.Count == 0) return "Empty";
            var parts = new List<string>();
            if (Fizzing) parts.Add("fizzing (bubbles of gas)");
            var p = MainPrecipitate;
            if (p != "" && Cloudiness > 0.05) parts.Add(Chem.Get(p).Name);
            if (Emulsion) parts.Add("cloudy white emulsion (fat present)");
            if (Get("I2") > 0) parts.Add(StarchPresent ? "blue-black (starch present)" : "orange-brown iodine (no starch)");
            if (Get("biuret") > 0) parts.Add(ProteinPresent ? "purple (protein present)" : "stays blue (no protein)");
            if (LiquidMl >= 0.01 && parts.Count == 0) parts.Add(ColourName() + " liquid");
            if (WaterMl <= 0 && (Get("NaCl_s") > 0 || Get("CuSO4_s") > 0)) parts.Add("crystals left in the dish");
            if (TemperatureC >= 99.5 && WaterMl > 0) parts.Add("boiling");
            return string.Join(", ", parts);
        }

        // ─── Save / restore ──────────────────────────────────────────────────

        public Dictionary<string, object> Snapshot() => new Dictionary<string, object>
        {
            { "w", WaterMl }, { "t", TemperatureC }, { "g", TotalGasMl }, { "x", ExtraVolumeMl },
            { "a", new Dictionary<string, double>(Amount) }, { "e", new Dictionary<string, double>(EnzymeAlive) },
        };

        public static Mixture FromSnapshot(IDictionary<string, object> s)
        {
            var m = new Mixture();
            double N(string k) => s.TryGetValue(k, out var v) && v != null ? Convert.ToDouble(v, CultureInfo.InvariantCulture) : 0;
            m.WaterMl = N("w"); m.TemperatureC = s.ContainsKey("t") ? N("t") : Chem.RoomC; m.TotalGasMl = N("g"); m.ExtraVolumeMl = N("x");
            void Fill(string key, Dictionary<string, double> into)
            {
                if (!s.TryGetValue(key, out var v) || v == null) return;
                if (v is IDictionary<string, double> d) { foreach (var kv in d) into[kv.Key] = kv.Value; return; }
                if (v is System.Collections.IDictionary any) foreach (System.Collections.DictionaryEntry kv in any) into[kv.Key.ToString()] = Convert.ToDouble(kv.Value, CultureInfo.InvariantCulture);
            }
            Fill("a", m.Amount);
            Fill("e", m.EnzymeAlive);
            m.Equilibrate();
            return m;
        }
    }

    /// <summary>Biology models that are not solution chemistry.</summary>
    public static class BioModels
    {
        /// <summary>
        /// Osmosis: % mass change of a potato cylinder at equilibrium in a sucrose solution
        /// (isotonic ≈ 0.3 mol/dm³; gains mass in weaker solutions, loses in stronger).
        /// </summary>
        public static double PotatoEquilibriumChangePct(double sucroseMolar) => 24 * Math.Tanh((0.3 - sucroseMolar) * 3.2);

        /// <summary>Oxygen bubbles per minute from pondweed: light (inverse square), CO2 and temperature limited.</summary>
        public static double PondweedBubblesPerMin(double lampDistanceCm, bool lampOn, double hydrogencarbonateMolar, double tempC)
        {
            double light = lampOn ? 2500.0 / Math.Max(lampDistanceCm * lampDistanceCm, 25) : 0.3; // inverse square; dim daylight when off
            double lightTerm = light / (light + 8);
            double co2Term = 0.2 + 0.8 * hydrogencarbonateMolar / (hydrogencarbonateMolar + 0.05);
            double tempTerm = Chem.EnzymeTemp(tempC) / Chem.EnzymeTemp(25);
            return Math.Max(0, 60 * lightTerm * co2Term * Math.Min(tempTerm, 1.5));
        }
    }
}
