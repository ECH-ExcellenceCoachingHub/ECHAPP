// ECH Labs — reference chemistry models.
// Mirrors backend/src/services/labs/sim.js; both test suites assert the same golden values.
using System;
using System.Collections.Generic;

namespace ECHLabs.Sim
{
    public sealed class AcidInfo
    {
        public string Name;
        /// <summary>Acid dissociation constant; null = strong acid (fully dissociated).</summary>
        public double? Ka;
        public AcidInfo(string name, double? ka) { Name = name; Ka = ka; }
    }

    public sealed class IndicatorInfo
    {
        public double Low, High;
        public string From, To;
        /// <summary>Linear RGB colours of the acid and base forms (for the liquid shader).</summary>
        public float[] FromRgba, ToRgba;
        public IndicatorInfo(double low, double high, string from, string to, float[] fromRgba, float[] toRgba)
        { Low = low; High = high; From = from; To = to; FromRgba = fromRgba; ToRgba = toRgba; }
    }

    public static class Chemistry
    {
        public const double Kw = 1e-14;

        public static readonly Dictionary<string, AcidInfo> Acids = new Dictionary<string, AcidInfo>
        {
            { "HCl", new AcidInfo("Hydrochloric acid", null) },
            { "HNO3", new AcidInfo("Nitric acid", null) },
            { "CH3COOH", new AcidInfo("Ethanoic (acetic) acid", 1.8e-5) },
        };

        public static readonly HashSet<string> StrongBases = new HashSet<string> { "NaOH", "KOH" };

        public static readonly Dictionary<string, IndicatorInfo> Indicators = new Dictionary<string, IndicatorInfo>
        {
            { "phenolphthalein", new IndicatorInfo(8.2, 10.0, "colourless", "pink", new[] { 0.95f, 0.97f, 1f, 0.08f }, new[] { 0.93f, 0.12f, 0.55f, 0.75f }) },
            { "methyl_orange", new IndicatorInfo(3.1, 4.4, "red", "yellow", new[] { 0.85f, 0.1f, 0.08f, 0.8f }, new[] { 0.98f, 0.8f, 0.1f, 0.8f }) },
            { "bromothymol_blue", new IndicatorInfo(6.0, 7.6, "yellow", "blue", new[] { 0.95f, 0.85f, 0.1f, 0.8f }, new[] { 0.1f, 0.3f, 0.85f, 0.8f }) },
            { "universal", new IndicatorInfo(3.0, 11.0, "red", "purple", new[] { 0.9f, 0.1f, 0.1f, 0.8f }, new[] { 0.45f, 0.1f, 0.7f, 0.8f }) },
        };

        /// <summary>
        /// pH of a mixture of an acid (Ka or strong) and a strong monoprotic base.
        /// Solves the charge balance [Na+] + [H+] = [OH-] + [A-] by bisection on pH,
        /// which stays exact through the equivalence point.
        /// </summary>
        public static double MixturePH(double acidMol, double? acidKa, double baseMol, double volumeL)
        {
            if (!(volumeL > 0)) return 7;
            double ca = Math.Max(acidMol, 0) / volumeL;
            double cb = Math.Max(baseMol, 0) / volumeL;
            double lo = -1, hi = 15;
            for (int i = 0; i < 100; i++)
            {
                double mid = (lo + hi) / 2;
                double h = Math.Pow(10, -mid);
                double oh = Kw / h;
                double a = acidKa.HasValue ? ca * acidKa.Value / (acidKa.Value + h) : ca;
                double balance = cb + h - oh - a; // decreasing in pH
                if (balance > 0) lo = mid; else hi = mid;
            }
            return (lo + hi) / 2;
        }

        public struct TitrationResult
        {
            public double PH;
            public double EquivalenceVolumeMl;
        }

        /// <summary>Acid in the flask titrated by a strong base from the burette.</summary>
        public static TitrationResult Titration(string acid, double acidConc, double acidVolumeMl, double baseConc, double baseAddedMl)
        {
            if (!Acids.TryGetValue(acid, out var def)) throw new ArgumentException("Unknown acid " + acid);
            double acidMol = acidConc * acidVolumeMl / 1000.0;
            double baseMol = baseConc * baseAddedMl / 1000.0;
            return new TitrationResult
            {
                PH = MixturePH(acidMol, def.Ka, baseMol, (acidVolumeMl + baseAddedMl) / 1000.0),
                EquivalenceVolumeMl = baseConc > 0 ? acidMol / baseConc * 1000.0 : double.PositiveInfinity,
            };
        }

        /// <summary>0 → indicator's low-pH colour, 1 → high-pH colour (smoothstep across its range).</summary>
        public static double IndicatorColorIndex(string indicator, double pH)
        {
            if (indicator == null || !Indicators.TryGetValue(indicator, out var def)) return 0;
            double t = Math.Min(Math.Max((pH - def.Low) / (def.High - def.Low), 0), 1);
            return t * t * (3 - 2 * t);
        }
    }
}
