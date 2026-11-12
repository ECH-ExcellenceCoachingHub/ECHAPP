// ECH Labs — plays a scenario: step state machine, intent judging, measurements,
// checkpoints, hints, hazards, logging and live scoring. Engine-independent.
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;

namespace ECHLabs.Core
{
    public enum FeedbackKind { Ok, StepProgress, WrongAction, Impossible, ReadingWrong, ReadingAccepted, Correct, Incorrect }

    public sealed class Feedback
    {
        public FeedbackKind Kind;
        public string Message;
        public string StepId;
        public bool Positive => Kind == FeedbackKind.Ok || Kind == FeedbackKind.StepProgress || Kind == FeedbackKind.Correct || Kind == FeedbackKind.ReadingAccepted;
    }

    public sealed class ScenarioRuntime
    {
        public const int MaxReadingAttempts = 3;

        public readonly ScenarioDefinition Def;
        public readonly LabWorld World;
        public readonly AttemptProgress Progress;

        int index = -1;
        bool expectMet;
        int hintIndex;
        StepSpec previousStep;
        int readingAttempts;
        readonly HashSet<string> activeHazards = new HashSet<string>();

        public event Action<StepSpec, int> StepStarted;   // step, index
        public event Action<StepSpec> StepCompleted;
        public event Action<HazardSpec> HazardTriggered;
        public event Action<string> Say;                   // assistant narration (TTS + subtitles)
        public event Action<Feedback> OnFeedback;
        public event Action<ScoreBreakdown> Completed;

        public StepSpec Current => index >= 0 && index < Def.Steps.Count ? Def.Steps[index] : null;
        public int StepIndex => index;
        public bool IsComplete { get; private set; }
        public ScoreBreakdown LiveScore => Scoring.Score(Def, Progress);

        public ScenarioRuntime(ScenarioDefinition def, LabWorld world, string clientId = null)
        {
            Def = def;
            World = world;
            Progress = new AttemptProgress { ClientId = clientId ?? Guid.NewGuid().ToString(), ScenarioId = def.Id };
            world.OnEvent += e => Log("event", Current?.Id, new Dictionary<string, object> { { "type", e.Type }, { "source", e.Source } });
        }

        // ─── Lifecycle ───────────────────────────────────────────────────────

        public void Start()
        {
            if (index >= 0) return;
            Log("start", null, null);
            Enter(0);
        }

        /// <summary>Resume from a saved attempt (same device: with world snapshot; other device: steps + records only).</summary>
        public void Resume(AttemptProgress saved)
        {
            Progress.ClientId = saved.ClientId ?? Progress.ClientId;
            foreach (var s in saved.CompletedSteps) if (Def.FindStep(s) != null && !Progress.CompletedSteps.Contains(s)) { Progress.CompletedSteps.Add(s); World.Done.Add(s); }
            foreach (var kv in saved.Records) { Progress.Records[kv.Key] = kv.Value; World.Records[kv.Key] = kv.Value; }
            Progress.Checkpoints.AddRange(saved.Checkpoints);
            Progress.HazardsTriggered.AddRange(saved.HazardsTriggered);
            Progress.HintsUsed = World.HintsUsed = saved.HintsUsed;
            Progress.Mistakes = World.Mistakes = saved.Mistakes;
            World.Time = saved.DurationSec;
            World.RestoreEquipment(saved.World);
            int next = Def.Steps.FindIndex(s => !World.Done.Contains(s.Id));
            Log("resume", null, null);
            if (next < 0) Finish(); else Enter(next);
        }

        void Enter(int i)
        {
            index = i;
            expectMet = false;
            hintIndex = 0;
            readingAttempts = 0;
            var step = Current;
            Progress.CurrentStepId = step.Id;
            Log("step", step.Id, null);
            StepStarted?.Invoke(step, i);
            if (!string.IsNullOrEmpty(step.Say)) Say?.Invoke(step.Say);
            // Conditions may already hold (e.g. resumed with world state).
            CheckCompletion();
        }

        void CompleteCurrent(string message = null)
        {
            var step = Current;
            if (step == null) return;
            previousStep = step;
            World.Done.Add(step.Id);
            if (!Progress.CompletedSteps.Contains(step.Id)) Progress.CompletedSteps.Add(step.Id);
            Log("done", step.Id, null);
            StepCompleted?.Invoke(step);
            var success = message ?? step.Success;
            if (!string.IsNullOrEmpty(success)) Say?.Invoke(success);
            if (index + 1 < Def.Steps.Count) Enter(index + 1);
            else Finish();
        }

        void Finish()
        {
            if (IsComplete) return;
            IsComplete = true;
            index = Def.Steps.Count;
            Progress.CurrentStepId = null;
            Progress.Complete = true;
            Progress.DurationSec = World.Time;
            Log("finish", null, null);
            Completed?.Invoke(Scoring.Score(Def, Progress));
        }

        // ─── Per frame ───────────────────────────────────────────────────────

        public void Tick(double dt)
        {
            if (index < 0 || IsComplete) return;
            World.Tick(dt);
            Progress.DurationSec = World.Time;
            CheckHazards();
            CheckCompletion();
        }

        void CheckCompletion()
        {
            var step = Current;
            if (step == null || IsComplete) return;
            if (step.Kind != StepKind.Action) return;
            bool hasUntil = !string.IsNullOrEmpty(step.Until);
            if (step.Expect == null && !hasUntil) return;
            // expect + until: the expected action must have happened AND the condition must hold
            // (e.g. "open the burette tap" … "until the solution turns pink").
            bool expectOk = step.Expect == null || expectMet;
            bool untilOk = !hasUntil || SafeTest(step.Until);
            if (expectOk && untilOk) CompleteCurrent();
        }

        void CheckHazards()
        {
            foreach (var h in Def.Hazards)
            {
                bool on = SafeTest(h.When);
                if (on && activeHazards.Add(h.Id))
                {
                    Progress.HazardsTriggered.Add(new HazardHit { Id = h.Id, T = Math.Round(World.Time, 1) });
                    Log("hazard", Current?.Id, new Dictionary<string, object> { { "id", h.Id } });
                    HazardTriggered?.Invoke(h);
                    Say?.Invoke(h.Message);
                }
                else if (!on) activeHazards.Remove(h.Id);
            }
        }

        bool SafeTest(string expression)
        {
            try { return Expr.Test(expression, World); }
            catch (ExprException) { return false; }
        }

        // ─── Student actions ─────────────────────────────────────────────────

        static readonly HashSet<IntentType> Consequential = new HashSet<IntentType> { IntentType.Pour, IntentType.Rotate, IntentType.Toggle, IntentType.Connect, IntentType.Release, IntentType.Type };

        public Feedback Handle(Intent intent)
        {
            if (IsComplete) return Emit(FeedbackKind.Ok, null);
            bool possible = World.Apply(intent);
            Log("intent", Current?.Id, new Dictionary<string, object> { { "i", intent.ToString() } });
            var step = Current;
            if (step == null) return Emit(FeedbackKind.Ok, null);

            if (step.Kind == StepKind.Action && step.Expect != null && Matches(step.Expect, intent))
            {
                expectMet = true;
                if (!possible) return Emit(FeedbackKind.Impossible, "That didn't work — check the equipment and try again.");
                int before = index;
                CheckCompletion();
                return Emit(index != before || IsComplete ? FeedbackKind.Ok : FeedbackKind.StepProgress, null);
            }

            if (!possible) return Emit(FeedbackKind.Impossible, "That isn't possible right now.");
            if (Consequential.Contains(intent.Type) && !IsHarmless(step, intent) && !IsHarmless(previousStep, intent))
            {
                World.Mistakes++;
                Progress.Mistakes = World.Mistakes;
                Log("mistake", step.Id, new Dictionary<string, object> { { "i", intent.ToString() } });
                CheckCompletion();
                return Emit(FeedbackKind.WrongAction, "That's not the next step. " + step.Instruction);
            }
            CheckCompletion();
            return Emit(FeedbackKind.Ok, null);
        }

        static bool Matches(ExpectSpec e, Intent i)
        {
            if (!string.Equals(e.Intent, i.Type.ToString(), StringComparison.Ordinal)) return false;
            if (e.Target != i.Target) return false;
            if (e.Into != null && e.Into != i.Into) return false;
            if (e.Value != null && (!i.Value.HasValue || !e.Value.Contains(i.Value.Value))) return false;
            return true;
        }

        /// <summary>Adjusting the equipment the current step is about (e.g. closing the tap) is never a mistake.</summary>
        static bool IsHarmless(StepSpec step, Intent i)
            => step != null && step.Expect != null && (step.Expect.Target == i.Target || step.Expect.Into == i.Target)
               || step != null && step.Focus != null && step.Focus == i.Target;

        /// <summary>Student submits a reading for a measure step.</summary>
        public Feedback SubmitReading(double value)
        {
            var step = Current;
            if (step == null || step.Kind != StepKind.Measure || step.Record == null) return Emit(FeedbackKind.Impossible, "Nothing to record right now.");
            double truth;
            try { truth = Expr.Number(step.Record.Truth, World); }
            catch (ExprException) { truth = double.NaN; }
            readingAttempts++;
            bool ok = !double.IsNaN(truth) && Math.Abs(value - truth) <= step.Record.Tolerance + 1e-9;
            Log("record", step.Id, new Dictionary<string, object> { { "value", value }, { "ok", ok } });
            if (!ok && readingAttempts < MaxReadingAttempts)
            {
                World.Mistakes++;
                Progress.Mistakes = World.Mistakes;
                return Emit(FeedbackKind.ReadingWrong, readingAttempts == 1 ? "Not quite — look again carefully." : HintOrDefault(step, "Check your units and read at eye level."));
            }
            World.Records[step.Record.Key] = value;
            Progress.Records[step.Record.Key] = value;
            var fb = Emit(ok ? FeedbackKind.Correct : FeedbackKind.ReadingAccepted,
                ok ? "Recorded." : $"Recorded. The correct value was {truth.ToString("0.###", CultureInfo.InvariantCulture)} {step.Record.Unit}.");
            CompleteCurrent();
            return fb;
        }

        /// <summary>Student answers the current checkpoint question.</summary>
        public Feedback AnswerCheckpoint(int choice, bool? externalCorrect = null)
        {
            var step = Current;
            if (step == null || step.Kind != StepKind.Checkpoint) return Emit(FeedbackKind.Impossible, "No question right now.");
            var q = step.Checkpoint?.Question;
            bool correct = q != null ? choice == q.AnswerIndex : externalCorrect ?? false;
            Progress.Checkpoints.RemoveAll(c => c.StepId == step.Id);
            Progress.Checkpoints.Add(new CheckpointAnswer { StepId = step.Id, Choice = choice, Correct = correct });
            Log("checkpoint", step.Id, new Dictionary<string, object> { { "choice", choice }, { "correct", correct } });
            var fb = Emit(correct ? FeedbackKind.Correct : FeedbackKind.Incorrect, (correct ? "Correct! " : "Not quite. ") + (q?.Explanation ?? ""));
            CompleteCurrent();
            return fb;
        }

        /// <summary>Info steps: student taps "Continue".</summary>
        public void Continue()
        {
            if (Current != null && Current.Kind == StepKind.Info) CompleteCurrent();
        }

        public string RequestHint()
        {
            var step = Current;
            if (step == null) return null;
            string hint = hintIndex < step.Hints.Count ? step.Hints[hintIndex] : step.Instruction;
            if (hintIndex < step.Hints.Count) hintIndex++;
            World.HintsUsed++;
            Progress.HintsUsed = World.HintsUsed;
            Log("hint", step.Id, null);
            Say?.Invoke(hint);
            return hint;
        }

        string HintOrDefault(StepSpec s, string fallback) => s.Hints.Count > 0 ? s.Hints[Math.Min(hintIndex, s.Hints.Count - 1)] : fallback;

        /// <summary>Snapshot for autosave (server) and local resume (with world state).</summary>
        public AttemptProgress Snapshot(bool includeWorld)
        {
            Progress.DurationSec = Math.Round(World.Time, 1);
            Progress.World = includeWorld ? World.SnapshotEquipment() : null;
            return Progress;
        }

        // ─── Helpers ─────────────────────────────────────────────────────────

        Feedback Emit(FeedbackKind kind, string message)
        {
            var fb = new Feedback { Kind = kind, Message = message, StepId = Current?.Id };
            if (message != null || kind != FeedbackKind.Ok) OnFeedback?.Invoke(fb);
            return fb;
        }

        void Log(string type, string stepId, object data)
        {
            if (Progress.Log.Count >= 2000) Progress.Log.RemoveAt(0);
            Progress.Log.Add(new LogEntry { T = Math.Round(World.Time, 2), Type = type, StepId = stepId, Data = data });
        }
    }
}
