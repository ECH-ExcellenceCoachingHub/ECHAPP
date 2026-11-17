using System;
using System.Collections;
using System.IO;
using ECHLabs.Core;
using ECHLabs.Runtime.Demo;
using UnityEngine;

namespace ECHLabs.Runtime.DevTools
{
    /// <summary>
    /// End-to-end smoke test inside a real player build:
    ///   ECHLabs.exe --scenario=chem-titration-hcl-naoh --autoplay=D:\out [--demo]
    /// A bot student performs every step through the real runtime (HUD, views, hands, scoring),
    /// saves a screenshot at each step and at the results screen, writes a summary, then quits.
    /// With --demo it first watches the narrated demo (screenshots every few seconds).
    /// </summary>
    public sealed class AutoPlay : MonoBehaviour
    {
        public static bool Active { get; private set; }
        public static bool WantsDemo { get; private set; }
        static bool introOnly;

        public string outDir;
        LabSession session;
        int shot;
        readonly LabBot bot = new LabBot();

        public static void AttachIfRequested(LabSession s)
        {
            var args = Environment.GetCommandLineArgs();
            foreach (var a in args) if (a == "--demo") WantsDemo = true;
            foreach (var a in args) if (a == "--intro-only") { WantsDemo = true; introOnly = true; }
            foreach (var a in args)
                if (a.StartsWith("--autoplay="))
                {
                    Active = true;
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
            if (WantsDemo) StartCoroutine(DemoShots());
            if (introOnly)
            {
                // Character QA: screenshots through the intro only, then quit.
                float t = 0;
                while (t < 38f) { t += Time.unscaledDeltaTime; yield return null; }
                Application.Quit();
                yield break;
            }
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
                $"scenario={rt.Def.Id}\ncomplete={rt.IsComplete}\ntotal={s.Total}\naccuracy={s.Accuracy}\nprocedure={s.Procedure}\nsafety={s.Safety}\npassed={s.Passed}\nhazards={rt.Progress.HazardsTriggered.Count}\nmistakes={rt.Progress.Mistakes}\nfps={session.quality.AvgFps:0}\ndemo={WantsDemo}\n");
            Application.Quit();
        }

        /// <summary>Acts through the same path as a student (so the hands and pours are in the screenshots).</summary>
        IEnumerator Act(ScenarioRuntime rt, StepSpec step)
        {
            var first = bot.First(rt, step);
            if (first != null)
            {
                session.interaction.PerformScripted(first.Value, rt.Handle);
                yield return new WaitForSeconds(0.9f);
                yield return Shot(step.Id + "_hands");
            }
            float t = 0;
            string id = step.Id;
            while (!rt.IsComplete && rt.Current != null && rt.Current.Id == id && t < 150f)
            {
                var move = bot.Adjust(rt, step, Time.deltaTime);
                if (move.HasValue) session.interaction.PerformScripted(move.Value.Intent, rt.Handle, move.Value.Animate);
                t += Time.deltaTime;
                yield return null;
            }
            var after = bot.After(rt, step);
            if (after != null) session.interaction.PerformScripted(after.Value, rt.Handle, false);
        }

        IEnumerator DemoShots()
        {
            int n = 0;
            float wait = 0;
            while (session.Runtime == null || session.Runtime.Current == null)
            {
                wait += Time.unscaledDeltaTime;
                if (wait > 2.5f) { wait = 0; yield return Shot($"demo_{n++:000}"); }
                yield return null;
            }
        }

        IEnumerator Shot(string name)
        {
            yield return new WaitForEndOfFrame();
            ScreenCapture.CaptureScreenshot(Path.Combine(outDir, $"{shot++:000}_{name}.png"));
            yield return null;
        }
    }
}
