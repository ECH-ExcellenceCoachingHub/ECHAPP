// A scripted "bot student" plays the built-in labs end to end through Intents,
// exactly as the desktop / touch / Cardboard / XR rigs would deliver them.
using System;
using System.IO;
using System.Linq;
using ECHLabs.Core;
using Xunit;

public class ScenarioBotTests
{
    static ScenarioDefinition Load(string id)
        => ScenarioDefinition.FromJson(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "scenarios", id + ".json")));

    static (ScenarioRuntime rt, LabWorld w) Start(string id, int seed = 42)
    {
        var def = Load(id);
        var w = new LabWorld(def, seed);
        var rt = new ScenarioRuntime(def, w, "bot-" + Guid.NewGuid().ToString("N").Substring(0, 8));
        rt.Start();
        return (rt, w);
    }

    /// <summary>Advances simulated time in 1/60 s frames until the condition holds.</summary>
    static void RunUntil(ScenarioRuntime rt, Func<bool> condition, double maxSeconds = 600)
    {
        double t = 0;
        while (!condition())
        {
            rt.Tick(1.0 / 60);
            t += 1.0 / 60;
            Assert.True(t < maxSeconds, "timed out at step " + rt.Current?.Id);
        }
    }

    /// <summary>Reads an instrument like a careful student: the true value rounded to the scale.</summary>
    static double Read(ScenarioRuntime rt, double resolution)
    {
        double truth = Expr.Number(rt.Current.Record.Truth, rt.World);
        return Math.Round(truth / resolution) * resolution;
    }

    static void Do(ScenarioRuntime rt, IntentType type, string target, string into = null, double? value = null)
    {
        var fb = rt.Handle(Intent.Of(type, target, into, value));
        Assert.True(fb.Kind != FeedbackKind.WrongAction && fb.Kind != FeedbackKind.Impossible, $"{type} {target}: {fb.Message}");
    }

    [Fact]
    public void Titration_perfect_run_scores_100()
    {
        var (rt, w) = Start("chem-titration-hcl-naoh");
        ScoreBreakdown final = null;
        rt.Completed += s => final = s;

        Do(rt, IntentType.Grab, "goggles1");
        Do(rt, IntentType.Grab, "coat1");
        Do(rt, IntentType.Grab, "funnel1");
        Assert.Equal("rinse", rt.Current.Id);
        Do(rt, IntentType.Pour, "naoh", "burette1");
        Assert.Equal("fill", rt.Current.Id);
        Do(rt, IntentType.Pour, "naoh", "burette1");
        Assert.Equal("read0", rt.Current.Id);
        double initial = Read(rt, 0.05);
        Assert.InRange(initial, 0.1, 0.9);
        Assert.Equal(FeedbackKind.Correct, rt.SubmitReading(initial).Kind);
        Do(rt, IntentType.Pour, "phth", "flask1");
        Do(rt, IntentType.Grab, "flask1", "tile1");
        Assert.Equal("titrate", rt.Current.Id);

        // Fast flow first, then drop-wise near the end point — like a real chemist.
        Do(rt, IntentType.Rotate, "burette1", value: 1.0);
        RunUntil(rt, () => w.Num("burette1", "dispensedMl") >= 18.5);
        Do(rt, IntentType.Rotate, "burette1", value: 0.08);
        RunUntil(rt, () => rt.Current.Id != "titrate");
        Do(rt, IntentType.Rotate, "burette1", value: 0); // close the tap
        Assert.InRange(w.Num("burette1", "dispensedMl"), 19.95, 20.1);
        Assert.InRange(w.Var("titr", "pH"), 8.2, 11);

        double final_ = Read(rt, 0.05);
        Assert.Equal(FeedbackKind.Correct, rt.SubmitReading(final_).Kind);
        Assert.Equal(FeedbackKind.Correct, rt.SubmitReading(Math.Round((final_ - initial) * 100) / 100).Kind);
        Assert.Equal(FeedbackKind.Correct, rt.AnswerCheckpoint(0).Kind);
        Assert.Equal(FeedbackKind.Correct, rt.SubmitReading(Read(rt, 0.0001)).Kind);

        Assert.True(rt.IsComplete);
        Assert.NotNull(final);
        Assert.Equal(100, final.Safety);
        Assert.Equal(100, final.Procedure);
        Assert.Equal(100, final.Accuracy);
        Assert.True(final.Passed);
        Assert.Empty(rt.Progress.HazardsTriggered);
        Assert.Equal(rt.Def.Steps.Select(s => s.Id), rt.Progress.CompletedSteps);
    }

    [Fact]
    public void Titration_mistakes_hazards_and_readings_are_judged()
    {
        var (rt, w) = Start("chem-titration-hcl-naoh");
        // Skips the goggles and goes straight for the alkali → wrong action + hazard.
        var fb = rt.Handle(Intent.Of(IntentType.Pour, "naoh", "burette1"));
        Assert.Equal(FeedbackKind.WrongAction, fb.Kind);
        rt.Tick(0.1);
        Assert.Contains(rt.Progress.HazardsTriggered, h => h.Id == "noGoggles");
        Assert.Equal(1, w.Mistakes);

        Do(rt, IntentType.Grab, "goggles1");
        Do(rt, IntentType.Grab, "coat1");
        Do(rt, IntentType.Grab, "funnel1");
        Assert.Equal("rinse", rt.Current.Id); // the earlier pour already rinsed it, but the step needs the action
        Do(rt, IntentType.Pour, "naoh", "burette1");
        Do(rt, IntentType.Pour, "naoh", "burette1");
        Assert.Equal("read0", rt.Current.Id);

        // A careless reading is rejected twice, then accepted with the correct value shown.
        Assert.Equal(FeedbackKind.ReadingWrong, rt.SubmitReading(5).Kind);
        Assert.Equal(FeedbackKind.ReadingWrong, rt.SubmitReading(5).Kind);
        var accepted = rt.SubmitReading(5);
        Assert.Equal(FeedbackKind.ReadingAccepted, accepted.Kind);
        Assert.Contains("correct value", accepted.Message);

        // Overshoot the end point with the tap wide open.
        Do(rt, IntentType.Pour, "phth", "flask1");
        Do(rt, IntentType.Grab, "flask1", "tile1");
        Do(rt, IntentType.Rotate, "burette1", value: 1.0);
        RunUntil(rt, () => rt.Progress.HazardsTriggered.Any(h => h.Id == "overshoot"), 60);
        var score = rt.LiveScore;
        Assert.Equal(75, score.Safety); // noGoggles 15 + overshoot 10
        Assert.True(score.Procedure < 100);
    }

    [Fact]
    public void Burette_without_a_flask_underneath_spills()
    {
        var (rt, w) = Start("chem-titration-hcl-naoh");
        string spilled = null;
        w.OnEvent += e => { if (e.Type == "spill") spilled = e.Source; };
        w.Apply(Intent.Of(IntentType.Pour, "naoh", "burette1")); // rinse
        w.Apply(Intent.Of(IntentType.Pour, "naoh", "burette1")); // fill
        w.Apply(Intent.Of(IntentType.Rotate, "burette1", value: 0.5));
        rt.Tick(0.5);
        Assert.Equal("burette1", spilled);
        Assert.Equal(0, w.Num("flask1", "baseAddedMl"));
    }

    [Fact]
    public void Ohms_law_perfect_run()
    {
        var (rt, w) = Start("phys-ohms-law");
        Do(rt, IntentType.Connect, "r1", "board");
        Do(rt, IntentType.Connect, "amm", "board");
        Do(rt, IntentType.Connect, "volt", "board");
        Do(rt, IntentType.Toggle, "psu");
        Do(rt, IntentType.Rotate, "psu", value: 6.0);
        rt.Tick(1.0 / 60);
        Assert.Equal("readV", rt.Current.Id);
        Assert.Equal(FeedbackKind.Correct, rt.SubmitReading(w.Num("volt", "reading")).Kind);
        double i = w.Num("amm", "reading");
        Assert.Equal(0.128, i, 3);
        Assert.Equal(FeedbackKind.Correct, rt.SubmitReading(i).Kind);
        Assert.Equal(FeedbackKind.Correct, rt.SubmitReading(Math.Round(6.0 / i, 1)).Kind);
        Assert.Equal(FeedbackKind.Correct, rt.AnswerCheckpoint(0).Kind);
        Assert.True(rt.IsComplete);
        var s = rt.LiveScore;
        Assert.True(s.Passed);
        Assert.Equal(100, s.Total);
    }

    [Fact]
    public void Ohms_law_short_circuit_is_a_hazard()
    {
        var (rt, w) = Start("phys-ohms-law");
        w.Apply(Intent.Of(IntentType.Connect, "amm", "board"));
        w.Apply(Intent.Of(IntentType.Toggle, "psu"));
        w.Apply(Intent.Of(IntentType.Rotate, "psu", value: 3));
        rt.Tick(1.0 / 60);
        Assert.True(w.Bool("board", "shortCircuit"));
        Assert.Contains(rt.Progress.HazardsTriggered, h => h.Id == "short");
    }

    [Fact]
    public void Pendulum_measures_g_from_timed_oscillations()
    {
        var (rt, w) = Start("phys-pendulum");
        Assert.Equal(FeedbackKind.Correct, rt.SubmitReading(0.800).Kind);
        Do(rt, IntentType.Release, "pend", value: 6);
        rt.Tick(1.0 / 60);
        Assert.Equal("time20", rt.Current.Id);
        Do(rt, IntentType.Toggle, "watch");
        RunUntil(rt, () => w.Num("pend", "oscillations") >= 20);
        Do(rt, IntentType.Toggle, "watch");
        rt.Tick(1.0 / 60);
        Assert.Equal("period", rt.Current.Id);
        double T = Math.Round(w.Num("watch", "elapsedS") / 20, 3);
        Assert.InRange(T, 1.78, 1.81);
        Assert.Equal(FeedbackKind.Correct, rt.SubmitReading(T).Kind);
        double g = 4 * 9.8696 * 0.8 / (T * T);
        Assert.Equal(FeedbackKind.Correct, rt.SubmitReading(Math.Round(g, 2)).Kind);
        rt.AnswerCheckpoint(0);
        var s = rt.LiveScore;
        Assert.True(s.Passed, $"total {s.Total}, accuracy {s.Accuracy}");
        Assert.True(s.Accuracy >= 90);
    }

    static void TypeCmd(ScenarioRuntime rt, string target, string text)
    {
        var fb = rt.Handle(new Intent { Type = IntentType.Type, Target = target, Text = text });
        Assert.True(fb.Kind != FeedbackKind.WrongAction && fb.Kind != FeedbackKind.Impossible, $"{text}: {fb.Message}");
        rt.Tick(1.0 / 60);
    }

    [Fact]
    public void Cyber_firewall_perfect_run_and_risky_rule_hazard()
    {
        var (rt, w) = Start("cyber-firewall-basics");
        TypeCmd(rt, "ws", "login");
        TypeCmd(rt, "ws", "show alerts");
        Assert.Equal("q1", rt.Current.Id);
        rt.AnswerCheckpoint(0);
        TypeCmd(rt, "fw", "deny 23 telnet");
        TypeCmd(rt, "fw", "deny 3389 rdp");
        TypeCmd(rt, "fw", "deny 3389 rdp"); // repeating a rule must not count twice
        TypeCmd(rt, "fw", "deny malicious-ip 203.0.113.66");
        TypeCmd(rt, "fw", "allow 443 https");
        TypeCmd(rt, "fw", "apply");
        Assert.Equal("count", rt.Current.Id);
        Assert.Equal(FeedbackKind.Correct, rt.SubmitReading(3).Kind);
        rt.AnswerCheckpoint(0);
        Assert.True(rt.IsComplete);
        var s = rt.LiveScore;
        Assert.Equal(100, s.Total);
        Assert.Empty(rt.Progress.HazardsTriggered);

        var (rt2, w2) = Start("cyber-firewall-basics");
        TypeCmd(rt2, "ws", "login");
        rt2.Handle(new Intent { Type = IntentType.Type, Target = "fw", Text = "allow 3389 rdp" });
        rt2.Tick(1.0 / 60);
        Assert.Contains(rt2.Progress.HazardsTriggered, h => h.Id == "openedRisky");
        Assert.Equal(75, rt2.LiveScore.Safety); // 25-point penalty
    }

    [Fact]
    public void Resume_continues_where_the_student_left_off()
    {
        var (rt, w) = Start("chem-titration-hcl-naoh");
        Do(rt, IntentType.Grab, "goggles1");
        Do(rt, IntentType.Grab, "coat1");
        Do(rt, IntentType.Grab, "funnel1");
        Do(rt, IntentType.Pour, "naoh", "burette1");
        Do(rt, IntentType.Pour, "naoh", "burette1");
        var json = Newtonsoft.Json.JsonConvert.SerializeObject(rt.Snapshot(includeWorld: true));

        var saved = Newtonsoft.Json.JsonConvert.DeserializeObject<AttemptProgress>(json);
        var def = Load("chem-titration-hcl-naoh");
        var w2 = new LabWorld(def, 7);
        var rt2 = new ScenarioRuntime(def, w2);
        rt2.Resume(saved);
        Assert.Equal("read0", rt2.Current.Id);
        Assert.Equal(w.Num("burette1", "volumeMl"), w2.Num("burette1", "volumeMl"), 6);
        Assert.True(w2.Bool("goggles1", "worn"));
        Assert.Equal(saved.ClientId, rt2.Progress.ClientId);
    }

    [Fact]
    public void Localization_applies_kinyarwanda()
    {
        var def = Load("chem-titration-hcl-naoh");
        def.Localize("rw");
        Assert.Equal("Ambara amadarubindi y'umutekano.", def.FindStep("ppe1").Instruction);
        Assert.StartsWith("Titrasiyo", def.Title);
    }
}
