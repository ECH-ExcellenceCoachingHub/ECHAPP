using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using ECHLabs.Core;
using ECHLabs.Runtime.Equipment;
using ECHLabs.Runtime.UI;
using Newtonsoft.Json;
using UnityEngine;

namespace ECHLabs.Runtime.Demo
{
    /// <summary>
    /// "Watch how it's done": before the student's turn, a demonstrator performs the whole activity
    /// in the real 3D lab — the same first-person hands, pours and instruments the student will use —
    /// while Dr. ECH narrates every step. It runs in its own LabWorld with its own random values
    /// (so the numbers can't be copied), long waits are fast-forwarded, and the student can pause,
    /// change speed, go back a step, replay a step or skip at any time.
    /// </summary>
    public sealed class DemoDirector : MonoBehaviour
    {
        public LabSession session;

        public bool Running { get; private set; }
        public LabWorld World { get; private set; }
        public ScenarioRuntime Runtime { get; private set; }
        public event Action Finished;

        ScenarioDefinition def;
        readonly Dictionary<int, string> snapshots = new Dictionary<int, string>();
        readonly LabBot bot = new LabBot();
        Coroutine loop;
        bool paused, fastForward;
        float speed = 1f;
        int stepIndex;

        /// <summary>Roughly how long the demo takes at normal speed (for the offer screen).</summary>
        public static int EstimateMinutes(ScenarioDefinition d)
        {
            float s = 0;
            foreach (var step in d.Steps) s += 3.5f + (step.Instruction?.Length ?? 0) / 16f;
            return Mathf.CeilToInt(s / 60f);
        }

        public void Begin(ScenarioDefinition template, ScenarioDefinition studentDef)
        {
            def = template.Clone();
            // Different values from the student's own attempt (when the lab has any).
            var rng = new System.Random();
            string mine = Fingerprint(studentDef);
            for (int i = 0; i < 6; i++)
            {
                var candidate = template.Clone();
                Variants.ApplyRandom(candidate, rng);
                def = candidate;
                if (Fingerprint(candidate) != mine) break;
            }
            snapshots.Clear();
            Running = true;
            paused = false;
            speed = 1f;
            session.hud.SetDemoActive(true);
            session.hud.SetDemoState(false, speed);
            session.hud.DemoCommand += OnCommand;
            session.hud.Graph.ResetData();
            loop = StartCoroutine(IntroThenDemo());
        }

        Demonstrator amani;

        IEnumerator IntroThenDemo()
        {
            yield return Intro();
            loop = null;
            StartFrom(null);
        }

        // ─── Full-body intro: Amani walks in, greets, shows the equipment, then "enters" the first-person view ──

        IEnumerator Intro()
        {
            amani = Demonstrator.Spawn();
            if (!amani) yield break;
            var cam = session.interaction.Rig != null ? session.interaction.Rig.Camera : null;
            bool flat = session.interaction.Rig != null && !session.interaction.Rig.WorldSpaceUI && session.director.cameraTransform;
            session.hud.SetDemoCaption("Meet " + Demonstrator.Name + ", your lab demonstrator", def.Title, def.Summary);

            // Where the work happens (benches / desks), and which side the student stands on.
            var views = session.Views;
            var work = new List<EquipmentView>();
            foreach (var e in def.Equipment)
                if (views.TryGetValue(e.Id, out var v) && !(e.Slot ?? "").StartsWith("ppe") && !(e.Slot ?? "").StartsWith("shelf")) work.Add(v);
            if (work.Count == 0) work.AddRange(views.Values);
            if (work.Count == 0) yield break;
            var area = EquipmentGeometry.BoundsOf(work[0]);
            var front = Vector3.zero;
            foreach (var v in work) { area.Encapsulate(EquipmentGeometry.BoundsOf(v)); front += -v.transform.forward; }
            front.y = 0;
            front = front.sqrMagnitude < 1e-4f ? Vector3.back : front.normalized;
            var side = Vector3.Cross(Vector3.up, front).normalized;
            float halfWidth = Mathf.Abs(Vector3.Dot(area.extents, new Vector3(Mathf.Abs(side.x), 0, Mathf.Abs(side.z))));
            var stand = Floor(area.center + side * Mathf.Clamp(halfWidth * 0.5f, 0.3f, 0.9f) + front * (Mathf.Max(area.extents.x, area.extents.z) * 0.35f + 0.55f));
            var mid = Vector3.Lerp(stand, new Vector3(area.center.x, stand.y, area.center.z), 0.4f);
            var camPos = mid + front * 2.5f + Vector3.up * 1.55f - side * 0.3f;
            var lookAt = mid + Vector3.up * 1.05f;
            if (flat) session.director.GlideTo(camPos, Quaternion.LookRotation(lookAt - camPos));
            Vector3 Viewer() => cam ? cam.transform.position : camPos;

            // Walk in from the side.
            var start = Floor(stand + side * 2.2f);
            amani.transform.SetPositionAndRotation(start, Quaternion.LookRotation(stand - start));
            amani.Play("Walk", 0f);
            float walk = Vector3.Distance(start, stand) / 1.15f, t = 0;
            while (t < walk)
            {
                t += Time.deltaTime;
                amani.transform.position = Vector3.Lerp(start, stand, Mathf.SmoothStep(0, 1, t / walk));
                yield return null;
            }
            amani.Play("Idle");
            amani.LookAt(Viewer());
            yield return Facing(Viewer, 0.6f);

            Narrate($"Hello! I'm {Demonstrator.Name}, your lab demonstrator. Today's experiment: {def.Title}.");
            amani.Play("Wave", 0.2f);
            yield return Facing(Viewer, Mathf.Max(amani.Length("Wave"), 3.2f));
            amani.Play("Idle");
            if (!string.IsNullOrEmpty(def.Summary))
            {
                Narrate(def.Summary);
                yield return Facing(Viewer, Mathf.Clamp(def.Summary.Length / 16f, 2.5f, 8f));
            }

            // Show the key equipment, in the order it will be used.
            bool ppe = false;
            var shown = new HashSet<string>();
            foreach (var step in def.Steps)
            {
                if (step.Expect == null || shown.Count >= 4) continue;
                foreach (var id in new[] { step.Expect.Target, step.Expect.Into })
                {
                    if (id == null || shown.Contains(id) || shown.Count >= 4 || !views.TryGetValue(id, out var v)) continue;
                    var spec = def.FindEquipment(id);
                    bool isPpe = spec != null && (spec.Slot ?? "").StartsWith("ppe");
                    if (isPpe && ppe) continue;
                    shown.Add(id);
                    var target = EquipmentGeometry.BoundsOf(v).center;
                    session.guideArrowPublic?.Point(v, IntentType.Inspect);
                    amani.PointAt(target);
                    amani.LookAt(target);
                    if (isPpe) { ppe = true; Narrate("Safety first: we always put on our goggles and lab coat before we start."); }
                    else
                    {
                        string kind = Catalog.Title(v.Type).ToLowerInvariant();
                        Narrate(string.Equals(v.Label, Catalog.Title(v.Type), StringComparison.OrdinalIgnoreCase) ? $"This is the {kind}." : $"This is the {kind}: {v.Label}.");
                    }
                    yield return Facing(() => target, 2.6f, 2.5f);
                }
            }
            session.guideArrowPublic?.Hide();
            amani.PointAt(null);
            amani.LookAt(Viewer());
            Narrate("Now watch closely. I'll do every step, and you'll see it through my own eyes!");
            yield return Facing(Viewer, 3.4f);

            // Glide into her eyes, then switch to the first-person demo.
            if (flat && amani.Head)
            {
                var eye = amani.Head.position + Vector3.up * 0.06f + amani.transform.forward * 0.1f;
                var focus = new Vector3(area.center.x, area.max.y - 0.05f, area.center.z);
                amani.Face(focus, 1f, 100f);
                session.director.GlideTo(eye, Quaternion.LookRotation(focus - eye));
                yield return Wait(0.8f);
                amani.SetVisible(false);
                yield return Wait(0.4f);
            }
            DestroyAmani();
        }

        IEnumerator Facing(Func<Vector3> target, float seconds, float speed = 4f)
        {
            float t = 0;
            while (t < seconds) { t += Time.deltaTime; if (amani) amani.Face(target(), Time.deltaTime, speed); yield return null; }
        }

        static Vector3 Floor(Vector3 p)
        {
            float best = float.PositiveInfinity;
            foreach (var hit in Physics.RaycastAll(p + Vector3.up * 3f, Vector3.down, 8f, ~(1 << 8), QueryTriggerInteraction.Ignore))
                if (hit.normal.y > 0.7f && hit.point.y < best) best = hit.point.y;
            return new Vector3(p.x, float.IsInfinity(best) || best > 0.4f ? 0f : best, p.z);
        }

        void DestroyAmani()
        {
            if (amani) Destroy(amani.gameObject);
            amani = null;
        }

        static string Fingerprint(ScenarioDefinition d)
        {
            var parts = new List<string>();
            foreach (var r in d.Randomize ?? new List<RandomizeSpec>())
            {
                var p = r.Path.Split('.');
                parts.Add(d.FindEquipment(p[0])?.InitNumber(p[1]).ToString(CultureInfo.InvariantCulture));
            }
            return string.Join(",", parts);
        }

        /// <summary>Fresh demo world, optionally restored to the start of an earlier step.</summary>
        void StartFrom(string snapshotJson)
        {
            if (loop != null) StopCoroutine(loop);
            DestroyAmani();
            session.hands?.StopAll();
            session.hud.HideTaskPanels();
            World = new LabWorld(def);
            Runtime = new ScenarioRuntime(def, World);
            Runtime.StepStarted += (step, i) =>
            {
                stepIndex = i;
                session.hud.HideTaskPanels();
                session.hud.ShowStep(step, i, def.Steps.Count);
                session.hud.SetDemoStep(i, def.Steps.Count, step.Title ?? step.Instruction);
                session.FocusStepPublic(step);
            };
            Runtime.StepCompleted += _ => session.fx?.StepDone();
            Runtime.Say += text => session.hud.Say(text);
            session.BindViews(World);
            session.hud.Graph.ResetData();
            if (snapshotJson != null)
            {
                var saved = JsonConvert.DeserializeObject<AttemptProgress>(snapshotJson);
                Runtime.Resume(saved);
            }
            else Runtime.Start();
            ApplyTimeScale();
            loop = StartCoroutine(Play());
        }

        void OnCommand(string cmd)
        {
            switch (cmd)
            {
                case "pause": paused = !paused; break;
                case "speed": speed = speed >= 2f ? 1f : 2f; break;
                case "skip": Stop(); return;
                case "replay": Jump(stepIndex); return;
                case "prev": Jump(Mathf.Max(0, stepIndex - 1)); return;
            }
            ApplyTimeScale();
            session.hud.SetDemoState(paused, speed);
        }

        void Jump(int index)
        {
            // Snapshots exist for every step the demo has reached.
            while (index > 0 && !snapshots.ContainsKey(index)) index--;
            paused = false;
            session.hud.SetDemoState(false, speed);
            StartFrom(index > 0 && snapshots.TryGetValue(index, out var json) ? json : null);
        }

        void ApplyTimeScale() => Time.timeScale = paused ? 0f : speed * (fastForward ? 4f : 1f);

        public void Stop()
        {
            if (!Running) return;
            if (loop != null) StopCoroutine(loop);
            loop = null;
            DestroyAmani();
            Running = false;
            fastForward = false;
            paused = false;
            Time.timeScale = 1f;
            Speech.Stop();
            session.hands?.StopAll();
            session.hud.DemoCommand -= OnCommand;
            session.hud.SetDemoActive(false);
            Finished?.Invoke();
        }

        IEnumerator Play()
        {
            yield return Wait(0.8f);
            int guard = 0;
            while (!Runtime.IsComplete && guard++ < 300)
            {
                var step = Runtime.Current;
                int index = Runtime.StepIndex;
                if (!snapshots.ContainsKey(index)) snapshots[index] = JsonConvert.SerializeObject(Runtime.Snapshot(includeWorld: true));

                // Dr. ECH explains the step first.
                string say = string.IsNullOrEmpty(step.Say) ? step.Instruction : step.Instruction + " " + step.Say;
                Narrate(say);
                yield return Wait(Mathf.Clamp(say.Length / 17f, 2.2f, 7f));

                switch (step.Kind)
                {
                    case StepKind.Measure:
                        yield return Measure(step);
                        break;
                    case StepKind.Checkpoint:
                        Narrate("Then there's a quick question. You'll answer it yourself in your turn!");
                        yield return Wait(2.6f);
                        Runtime.AnswerCheckpoint(step.Checkpoint?.Question?.AnswerIndex ?? 0, true);
                        break;
                    case StepKind.Info:
                        yield return Wait(1f);
                        Runtime.Continue();
                        break;
                    default:
                        yield return Act(step);
                        break;
                }
                yield return Wait(0.9f);
            }
            Narrate("That's the whole experiment. Now it's your turn. Your values will be different, so watch your own instruments carefully!");
            yield return Wait(4f);
            Stop();
        }

        IEnumerator Act(StepSpec step)
        {
            var first = bot.First(Runtime, step);
            if (first != null)
            {
                session.interaction.PerformScripted(first.Value, i => Runtime.Handle(i));
                yield return WaitHands(4f);
            }
            float waited = 0;
            string id = step.Id;
            while (!Runtime.IsComplete && Runtime.Current != null && Runtime.Current.Id == id && waited < 120f)
            {
                var move = bot.Adjust(Runtime, step, Time.deltaTime);
                if (move.HasValue)
                {
                    session.interaction.PerformScripted(move.Value.Intent, i => Runtime.Handle(i), move.Value.Animate);
                    if (fastForward) { fastForward = false; ApplyTimeScale(); }
                    if (move.Value.Animate) yield return WaitHands(3f);
                }
                waited += Time.unscaledDeltaTime;
                // Long waits (filling a burette, 20 swings of a pendulum) are fast-forwarded.
                if (!fastForward && waited > 2.5f && !(session.hands && session.hands.Busy))
                {
                    fastForward = true;
                    ApplyTimeScale();
                    session.hud.Toast("Fast-forward…", true);
                }
                yield return null;
            }
            if (fastForward) { fastForward = false; ApplyTimeScale(); }
            var after = bot.After(Runtime, step);
            if (after != null) { session.interaction.PerformScripted(after.Value, i => Runtime.Handle(i)); yield return WaitHands(2f); }
        }

        IEnumerator Measure(StepSpec step)
        {
            var record = step.Record;
            double value;
            try { value = Expr.Number(record.Truth, World); }
            catch (ExprException) { value = 0; }
            bool calculation = record.Truth.Contains("record.");
            bool secret = calculation && (def.Randomize == null || def.Randomize.Count == 0);
            string text = secret ? "• • •" : Format(value, record.Tolerance);
            if (!calculation) Narrate($"Read it carefully: the {record.Label.ToLowerInvariant()} is {text} {record.Unit}.");
            else if (secret) Narrate("Now the calculation. Work this one out yourself in your turn. The demonstrator keeps the answer secret!");
            else Narrate($"Now the calculation: {record.Label.ToLowerInvariant()} = {text} {record.Unit}. With your own values the answer will be different.");
            session.hud.ShowDemoReading(record, text);
            yield return Wait(3.4f);
            Runtime.SubmitReading(value);
        }

        static string Format(double v, double tolerance)
        {
            int decimals = tolerance >= 1 ? 0 : tolerance >= 0.1 ? 1 : tolerance >= 0.01 ? 2 : 3;
            return v.ToString("F" + decimals, CultureInfo.InvariantCulture);
        }

        void Narrate(string text)
        {
            session.hud.Say(text);
            Speech.Say(text, session.Params.Lang);
        }

        IEnumerator WaitHands(float max)
        {
            float t = 0;
            yield return null;
            while (session.hands && session.hands.Busy && t < max) { t += Time.deltaTime; yield return null; }
        }

        static IEnumerator Wait(float seconds)
        {
            float t = 0;
            while (t < seconds) { t += Time.deltaTime; yield return null; }
        }

        void OnDisable()
        {
            if (Running) Time.timeScale = 1f;
        }
    }
}
