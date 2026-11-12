// ECH Labs — scenario "variables": science models computed from equipment state each tick.
// Model names/outputs match catalog.json "models".
using System;
using System.Collections.Generic;
using ECHLabs.Sim;

namespace ECHLabs.Core
{
    public static class VariableModels
    {
        public static void UpdateAll(LabWorld w)
        {
            foreach (var kv in w.Definition.Variables)
            {
                if (!w.Variables.TryGetValue(kv.Key, out var outputs)) w.Variables[kv.Key] = outputs = new Dictionary<string, object>();
                Update(kv.Value, outputs, w);
            }
        }

        static string In(VariableSpec v, string input) => v.Inputs != null && v.Inputs.TryGetValue(input, out var id) ? id : null;

        static void Update(VariableSpec v, Dictionary<string, object> o, LabWorld w)
        {
            switch (v.Model)
            {
                case "chem.titration":
                    {
                        string flask = In(v, "flask"), burette = In(v, "burette");
                        var spec = w.Spec(flask);
                        string acid = spec?.InitString("solution") ?? "HCl";
                        double acidConc = spec?.InitNumber("conc", 0.1) ?? 0.1;
                        double acidVol = spec?.InitNumber("volume", 25) ?? 25;
                        double baseConc = w.Spec(burette)?.InitNumber("conc", 0.1) ?? 0.1;
                        // baseMol is exact even if the burette concentration were changed mid-run.
                        double baseMol = w.Num(flask, "baseMol");
                        double baseAddedMl = w.Num(flask, "baseAddedMl");
                        double pH;
                        if (Chemistry.Acids.TryGetValue(acid, out var info))
                            pH = Chemistry.MixturePH(acidConc * acidVol / 1000.0, info.Ka, baseMol, (acidVol + baseAddedMl) / 1000.0);
                        else pH = 7;
                        string indicator = w.Bool(flask, "hasIndicator") ? (w.Str(flask, "indicator") ?? v.ParamString("indicator", "phenolphthalein")) : null;
                        o["pH"] = pH;
                        o["colorIndex"] = indicator == null ? 0.0 : Chemistry.IndicatorColorIndex(indicator, pH);
                        o["equivalenceVolumeMl"] = baseConc > 0 ? acidConc * acidVol / baseConc : double.PositiveInfinity;
                        o["indicator"] = indicator;
                        break;
                    }
                case "phys.circuit":
                    {
                        string board = In(v, "circuit");
                        o["currentA"] = w.Num(board, "currentA");
                        o["voltageV"] = w.Num(board, "voltageV");
                        o["powerW"] = w.Num(board, "powerW");
                        break;
                    }
                case "phys.pendulum":
                    {
                        string p = In(v, "pendulum");
                        double L = w.Num(p, "lengthM", 1), amp = w.Num(p, "amplitudeDeg");
                        o["periodS"] = Physics.PendulumPeriod(L, amp);
                        o["theoreticalPeriodS"] = Physics.PendulumTheoreticalPeriod(L);
                        break;
                    }
                case "bio.microscope":
                    {
                        string m = In(v, "microscope");
                        double objective = w.Num(m, "objective", 4);
                        bool visible = w.Bool(m, "lightOn") && w.Bool(m, "slideLoaded");
                        o["magnification"] = Biology.TotalMagnification(objective);
                        o["focusQuality"] = visible ? Biology.FocusQuality(w.Num(m, "focus"), v.ParamNumber("idealFocus", 0.62), objective) : 0.0;
                        break;
                    }
                case "net.firewall":
                    {
                        string f = In(v, "firewall");
                        var rules = (w.Str(f, "rules") ?? "").Split('\n');
                        int blocked = 0, allowedLegit = 0, risky = 0;
                        foreach (var r in rules)
                        {
                            var t = r.Trim().ToLowerInvariant();
                            if (t.StartsWith("deny ") && (t.Contains("23") || t.Contains("telnet") || t.Contains("3389") || t.Contains("malicious"))) blocked++;
                            if (t.StartsWith("allow ") && (t.Contains("443") || t.Contains("https") || t.Contains(" 80"))) allowedLegit++;
                            if (t.StartsWith("allow ") && (t.Contains("23") || t.Contains("telnet") || t.Contains("3389") || t.Contains("rdp"))) risky++;
                        }
                        o["blockedThreats"] = (double)blocked;
                        o["allowedLegit"] = (double)allowedLegit;
                        o["riskyAllowed"] = (double)risky;
                        o["score"] = (double)(blocked * 10 + allowedLegit * 5 - risky * 10);
                        break;
                    }
            }
        }
    }
}
