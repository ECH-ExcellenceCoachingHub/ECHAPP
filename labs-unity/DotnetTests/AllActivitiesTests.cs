// Every built-in activity must be finishable and passable by a careful student.
// A generic bot plays each one through Intents only (exactly what the rigs send).
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using ECHLabs.Core;
using Newtonsoft.Json.Linq;
using Xunit;

public class AllActivitiesTests
{
    public static IEnumerable<object[]> Activities()
        => Directory.GetFiles(Path.Combine(AppContext.BaseDirectory, "scenarios"), "*.json")
            .Select(f => new object[] { Path.GetFileNameWithoutExtension(f) }).OrderBy(x => (string)x[0]);

    static readonly Regex CommandUntil = new Regex(@"lastCommand == '(.+)'");

    [Theory]
    [MemberData(nameof(Activities))]
    public void Activity_can_be_completed_and_passed(string id)
    {
        var def = Load(id);
        Variants.Apply(def, null); // default values, templates rendered
        Play(id, def);
    }

    public static IEnumerable<object[]> RandomizedActivities()
        => Activities().Where(a => Load((string)a[0]).Randomize.Count > 0);

    /// <summary>"New values every try": whatever values are picked, a careful student can still pass with full accuracy.</summary>
    [Theory]
    [MemberData(nameof(RandomizedActivities))]
    public void Randomized_activity_passes_with_any_values(string id)
    {
        var seen = new HashSet<string>();
        for (int seed = 1; seed <= 6; seed++)
        {
            var def = Load(id);
            Assert.True(Variants.ApplyRandom(def, new Random(seed)));
            seen.Add(string.Join(",", def.Randomize.Select(r => def.FindEquipment(r.Path.Split('.')[0]).InitNumber(r.Path.Split('.')[1]))));
            var score = Play(id, def);
            Assert.True(def.Results.Count == 0 || score.Accuracy == 100, $"{id} seed {seed}: accuracy {score.Accuracy}");
        }
        Assert.True(seen.Count >= 2, $"{id}: values never changed");
    }

    [Fact]
    public void Variants_match_the_backend_rules()
    {
        var def = Load("phys-ohms-law-two-readings");
        Variants.Apply(def, new Dictionary<string, Dictionary<string, double>> { ["r1"] = new Dictionary<string, double> { ["ohms"] = 47 } });
        Assert.Equal("Resistor 47 Ω", def.FindEquipment("r1").Label);
        Assert.Equal(47, def.Results.Single(r => r.Key == "resistance").Expected);
        // Out-of-rule values are ignored; re-applying uses the preserved template.
        Variants.Apply(def, new Dictionary<string, Dictionary<string, double>> { ["r1"] = new Dictionary<string, double> { ["ohms"] = 5 } });
        Assert.Equal(47, def.FindEquipment("r1").InitNumber("ohms"));
        var t = Load("chem-titration-hcl-naoh");
        Variants.Apply(t, new Dictionary<string, Dictionary<string, double>> { ["flask1"] = new Dictionary<string, double> { ["conc"] = 0.09 } });
        Assert.Equal(18.0, t.Results.Single(r => r.Key == "titre").Expected, 6);
        Assert.Equal(0.09, t.Results.Single(r => r.Key == "hclConc").Expected, 6);
    }

    static ScenarioDefinition Load(string id) => ScenarioDefinition.FromJson(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "scenarios", id + ".json")));

    static ScoreBreakdown Play(string id, ScenarioDefinition def)
    {
        var w = new LabWorld(def, 11);
        var rt = new ScenarioRuntime(def, w);
        rt.Start();
        var cycle = new Dictionary<string, int>();

        int guard = 0;
        while (!rt.IsComplete)
        {
            Assert.True(guard++ < 500, $"{id}: stuck");
            var step = rt.Current;
            switch (step.Kind)
            {
                case StepKind.Measure:
                    rt.SubmitReading(Expr.Number(step.Record.Truth, w));
                    continue;
                case StepKind.Checkpoint:
                    rt.AnswerCheckpoint(step.Checkpoint.Question.AnswerIndex);
                    continue;
                case StepKind.Info:
                    rt.Continue();
                    continue;
            }

            var e = step.Expect;
            Assert.NotNull(e);
            var type = (IntentType)Enum.Parse(typeof(IntentType), e.Intent);
            double sim = 0;
            bool sent = false;
            while (rt.Current == step && !rt.IsComplete)
            {
                Assert.True(sim < 300, $"{id}: step '{step.Id}' never completed");
                if (type == IntentType.Type)
                {
                    var m = step.Until != null ? CommandUntil.Match(step.Until) : Match.Empty;
                    string text = m.Success ? m.Groups[1].Value : NextCommand(w, e.Target, cycle);
                    rt.Handle(new Intent { Type = type, Target = e.Target, Into = e.Into, Text = text });
                }
                else if (!sent)
                {
                    double? value = e.Value != null ? (e.Value.Min + e.Value.Max) / 2 : type == IntentType.Rotate ? 1.0 : (double?)null;
                    rt.Handle(new Intent { Type = type, Target = e.Target, Into = e.Into, Value = value });
                    sent = true;
                }
                // Burette: drop-wise near the end point, close the tap afterwards.
                if (type == IntentType.Rotate && w.Spec(e.Target)?.Type == "burette"
                    && w.Var("titr", "equivalenceVolumeMl") - w.Num(e.Target, "dispensedMl") < 0.6)
                    rt.Handle(Intent.Of(IntentType.Rotate, e.Target, null, 0.25));
                // Stopwatch: stop after 20 oscillations.
                if (type == IntentType.Toggle && w.Spec(e.Target)?.Type == "stopwatch" && w.Bool(e.Target, "running")
                    && w.OfType("pendulum").Any(p => w.Num(p.Id, "oscillations") >= 20))
                    rt.Handle(Intent.Of(IntentType.Toggle, e.Target));
                rt.Tick(1.0 / 30);
                sim += 1.0 / 30;
            }
            if (type == IntentType.Rotate && w.Spec(e.Target)?.Type == "burette") rt.Handle(Intent.Of(IntentType.Rotate, e.Target, null, 0));
        }

        var score = Scoring.Score(def, rt.Progress);
        Assert.True(score.Passed, $"{id}: total {score.Total} (acc {score.Accuracy}, proc {score.Procedure}, safety {score.Safety})");
        Assert.True(score.Safety == 100, $"{id}: a careful run triggered hazards: {string.Join(",", rt.Progress.HazardsTriggered.Select(h => h.Id))}");
        Assert.Equal(0, rt.Progress.Mistakes);
        return score;
    }

    // Terminals without an explicit command (e.g. firewall rules): walk the offered commands, skipping risky ones.
    static string NextCommand(LabWorld w, string target, Dictionary<string, int> cycle)
    {
        var spec = w.Spec(target);
        if (spec?.Init == null || !spec.Init.TryGetValue("commands", out var tok) || !(tok is JArray arr) || arr.Count == 0) return "login";
        cycle.TryGetValue(target, out int i);
        for (int k = 0; k < arr.Count; k++)
        {
            var c = arr[(i + k) % arr.Count].ToString();
            if (c.StartsWith("allow") && (c.Contains("23") || c.Contains("3389"))) continue;
            cycle[target] = (i + k + 1) % arr.Count;
            return c;
        }
        return "apply";
    }

    [Fact]
    public void Every_room_has_a_path_from_beginner_to_expert()
    {
        var defs = Directory.GetFiles(Path.Combine(AppContext.BaseDirectory, "scenarios"), "*.json")
            .Select(f => JObject.Parse(File.ReadAllText(f))).ToList();
        foreach (var room in defs.GroupBy(d => (string)d["environment"]))
        {
            var levels = room.Select(d => (int?)d["difficulty"] ?? 2).Distinct().OrderBy(x => x).ToList();
            Assert.True(levels.SequenceEqual(new[] { 1, 2, 3, 4, 5 }), $"{room.Key}: levels {string.Join(",", levels)}");
            Assert.True(room.Count() >= 5, room.Key);
        }
    }
}
