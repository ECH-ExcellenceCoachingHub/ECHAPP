using System;
using System.Collections;
using System.IO;
using ECHLabs.Core;
using UnityEngine;

namespace ECHLabs.Runtime.DevTools
{
    /// <summary>
    /// End-to-end smoke test inside a real player build:
    ///   ECHLabs.exe --scenario=chem-titration-hcl-naoh --autoplay=D:\out
    /// A bot student performs every step through the real runtime (HUD, views, scoring),
    /// saves a screenshot at each step and at the results screen, writes a summary, then quits.
    /// </summary>
    public sealed class AutoPlay : MonoBehaviour
    {
        public string outDir;
        LabSession session;
        int shot;

        public static void AttachIfRequested(LabSession s)
        {
            foreach (var a in Environment.GetCommandLineArgs())
                if (a.StartsWith("--autoplay="))
                {
                    var ap = s.gameObject.AddComponent<AutoPlay>();
                    ap.outDir = a.Substring("--autoplay=".Length).Trim('"');
                    ap.session = s;
                    Directory.CreateDirectory(ap.outDir);
                    // Always a fresh, unattended run: no saved progress, no real mouse/keyboard input.
                    Net.ScenarioCache.ClearAllResumes();
                    if (s.interaction) s.interaction.enabled = false;
                }
        }

        IEnumerator Start()
        {
            while (session.Runtime == null || session.Runtime.Current == null) yield return null;
            var rt = session.Runtime;
            yield return new WaitForSeconds(2f);
            yield return Shot("start");

            int guard = 0;
            while (!rt.IsComplete && guard++ < 200)
            {
                var step = rt.Current;
                yield return new WaitForSeconds(0.8f);
                yield return Shot(step.Id);
                switch (step.Kind)
                {
                    case StepKind.Measure:
                        rt.SubmitReading(Expr.Number(step.Record.Truth, rt.World));
                        break;
                    case StepKind.Checkpoint:
                        rt.AnswerCheckpoint(step.Checkpoint?.Question?.AnswerIndex ?? 0, true);
                        yield return new WaitForSeconds(0.8f);
                        session.hud.CloseQuestion();
                        break;
                    case StepKind.Info:
                        rt.Continue();
                        break;
                    default:
                        yield return Act(rt, step);
                        break;
                }
                yield return null;
            }
            yield return new WaitForSeconds(2.5f); // results screen
            yield return Shot("results");
            var s = rt.LiveScore;
            File.WriteAllText(Path.Combine(outDir, "summary.txt"),
                $"scenario={rt.Def.Id}\ncomplete={rt.IsComplete}\ntotal={s.Total}\naccuracy={s.Accuracy}\nprocedure={s.Procedure}\nsafety={s.Safety}\npassed={s.Passed}\nhazards={rt.Progress.HazardsTriggered.Count}\nmistakes={rt.Progress.Mistakes}\nfps={session.quality.AvgFps:0}\n");
            Application.Quit();
        }

        IEnumerator Act(ScenarioRuntime rt, StepSpec step)
        {
            var e = step.Expect;
            if (e != null && Enum.TryParse<IntentType>(e.Intent, out var type))
            {
                double? value = e.Value != null ? (e.Value.Min + e.Value.Max) / 2 : type == IntentType.Rotate ? 1.0 : (double?)null;
                string text = type == IntentType.Type ? NextCommand(rt, step) : null;
                rt.Handle(new Intent { Type = type, Target = e.Target, Into = e.Into, Value = value, Text = text });
            }
            // Wait for the "until" condition; slow the burette near the end point like a student would.
            float t = 0;
            string id = step.Id;
            while (!rt.IsComplete && rt.Current != null && rt.Current.Id == id && t < 40f)
            {
                if (e != null && e.Intent == "Rotate" && rt.World.Spec(e.Target)?.Type == "burette")
                {
                    double nearEnd = rt.World.Var("titr", "equivalenceVolumeMl") - rt.World.Num(e.Target, "dispensedMl");
                    if (nearEnd < 0.6) rt.Handle(Intent.Of(IntentType.Rotate, e.Target, null, 0.25)); // ≈0.16 mL/s, drop-wise
                }
                // Stopwatch: stop it once the pendulum has completed 20 oscillations.
                if (e != null && e.Intent == "Toggle" && rt.World.Spec(e.Target)?.Type == "stopwatch" && rt.World.Bool(e.Target, "running"))
                    foreach (var p in rt.World.OfType("pendulum"))
                        if (rt.World.Num(p.Id, "oscillations") >= 20) rt.Handle(Intent.Of(IntentType.Toggle, e.Target));
                if (e != null && e.Intent == "Type" && (int)(t * 2) % 2 == 0 && t > 0.5f)
                    rt.Handle(new Intent { Type = IntentType.Type, Target = e.Target, Text = NextCommand(rt, step) });
                t += Time.deltaTime;
                yield return null;
            }
            if (e != null && e.Intent == "Rotate" && rt.World.Spec(e.Target)?.Type == "burette")
                rt.Handle(Intent.Of(IntentType.Rotate, e.Target, null, 0)); // close the tap
        }

        // Terminals: walk through the offered commands, never choosing a risky "allow" for 23/3389.
        int cmdIndex;
        static readonly System.Text.RegularExpressions.Regex CommandUntil = new System.Text.RegularExpressions.Regex(@"lastCommand == '(.+)'");

        string NextCommand(ScenarioRuntime rt, StepSpec step)
        {
            // Steps that ask for one exact command: type that command.
            if (step.Until != null) { var m = CommandUntil.Match(step.Until); if (m.Success) return m.Groups[1].Value; }
            var spec = rt.World.Spec(step.Expect.Target);
            if (spec?.Init == null || !spec.Init.TryGetValue("commands", out var tok) || !(tok is Newtonsoft.Json.Linq.JArray arr) || arr.Count == 0) return "login";
            for (int i = 0; i < arr.Count; i++)
            {
                var c = arr[(cmdIndex + i) % arr.Count].ToString();
                if (c.StartsWith("allow") && (c.Contains("23") || c.Contains("3389"))) continue;
                cmdIndex = (cmdIndex + i + 1) % arr.Count;
                return c;
            }
            return "apply";
        }

        IEnumerator Shot(string name)
        {
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(Path.Combine(outDir, $"{shot++:00}_{name}.png"));
            yield return null;
        }
    }
}
