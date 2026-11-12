// ECH Labs — live scoring for the HUD. Same rules as backend scoring.service.js,
// which recomputes the official score on completion.
using System;
using System.Collections.Generic;
using System.Linq;

namespace ECHLabs.Core
{
    public sealed class ScoreBreakdown
    {
        public int Accuracy, Procedure, Safety, Total;
        public bool Passed, AllStepsDone, FailedSafety;
        public List<ResultGrade> Results = new List<ResultGrade>();
    }

    public sealed class ResultGrade
    {
        public string Key, Label, Unit;
        public double? Actual;
        public double Expected;
        public int Grade;
    }

    public static class Scoring
    {
        const int HintPenalty = 2, HintPenaltyMax = 20, MistakePenalty = 1, MistakePenaltyMax = 15;

        static int Clamp(double v) => (int)Math.Min(Math.Max(v, 0), 100);
        static int JsRound(double v) => (int)Math.Floor(v + 0.5);

        /// <summary>100 inside tolerance, falling linearly to 0 at 3× the tolerance.</summary>
        public static int GradeResult(double? actual, double expected, double tolerancePct)
        {
            if (!actual.HasValue || double.IsNaN(actual.Value) || double.IsInfinity(actual.Value)) return 0;
            if (expected == 0) return Math.Abs(actual.Value) < 1e-9 ? 100 : 0;
            double errPct = Math.Abs(actual.Value - expected) / Math.Abs(expected) * 100;
            double tol = Math.Max(tolerancePct, 0.01);
            if (errPct <= tol) return 100;
            if (errPct >= 3 * tol) return 0;
            return JsRound(100 * (1 - (errPct - tol) / (2 * tol)));
        }

        public static ScoreBreakdown Score(ScenarioDefinition def, AttemptProgress a)
        {
            var completed = new HashSet<string>(a.CompletedSteps);
            var answers = a.Checkpoints.ToDictionary(c => c.StepId, c => c);

            double earned = 0, possible = 0;
            foreach (var s in def.Steps)
            {
                possible += s.Points;
                if (!completed.Contains(s.Id)) continue;
                if (s.Kind == StepKind.Checkpoint) { if (answers.TryGetValue(s.Id, out var ans) && ans.Correct) earned += s.Points; }
                else earned += s.Points;
            }
            int procedure = Clamp(JsRound((possible > 0 ? earned / possible * 100 : 100)
                - Math.Min(a.HintsUsed * HintPenalty, HintPenaltyMax) - Math.Min(a.Mistakes * MistakePenalty, MistakePenaltyMax)));

            var result = new ScoreBreakdown();
            var recordScope = new RecordScope(a.Records);
            foreach (var r in def.Results)
            {
                double? actual = null;
                try { var v = Expr.Evaluate(r.Source, recordScope); if (v != null) actual = Expr.Num(v); } catch (ExprException) { }
                result.Results.Add(new ResultGrade { Key = r.Key, Label = r.Label, Unit = r.Unit, Actual = actual, Expected = r.Expected, Grade = GradeResult(actual, r.Expected, r.TolerancePct) });
            }
            int accuracy = result.Results.Count > 0 ? JsRound(result.Results.Average(g => (double)g.Grade)) : 100;

            var hazards = def.Hazards.ToDictionary(h => h.Id, h => h);
            var triggered = a.HazardsTriggered.Select(h => h.Id).Distinct().Where(hazards.ContainsKey).ToList();
            int safety = Clamp(100 - triggered.Sum(id => hazards[id].Penalty));
            bool failedSafety = triggered.Any(id => hazards[id].Severity == "fail");

            var w = def.Scoring;
            result.Accuracy = accuracy;
            result.Procedure = procedure;
            result.Safety = safety;
            result.Total = JsRound((accuracy * w.Accuracy + procedure * w.Procedure + safety * w.Safety) / 100.0);
            result.AllStepsDone = def.Steps.All(s => completed.Contains(s.Id));
            result.FailedSafety = failedSafety;
            result.Passed = result.AllStepsDone && !failedSafety && result.Total >= def.PassScore;
            return result;
        }

        sealed class RecordScope : IExprScope
        {
            readonly Dictionary<string, double> records;
            public RecordScope(Dictionary<string, double> r) { records = r; }
            public object Resolve(IReadOnlyList<string> path)
                => path.Count == 2 && path[0] == "record" && records.TryGetValue(path[1], out var v) ? (object)v : null;
            public bool IsDone(string stepId) => false;
        }
    }
}
