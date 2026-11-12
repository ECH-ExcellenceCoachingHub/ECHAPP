// ECH Labs — scenario DSL data model. Matches backend/src/services/labs/validator.js.
using System.Collections.Generic;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace ECHLabs.Core
{
    public sealed class ScenarioDefinition
    {
        [JsonProperty("id")] public string Id;
        [JsonProperty("version")] public int Version = 1;
        [JsonProperty("title")] public string Title;
        [JsonProperty("summary")] public string Summary;
        [JsonProperty("subject")] public string Subject;
        [JsonProperty("level")] public string Level;
        [JsonProperty("environment")] public string Environment;
        [JsonProperty("durationMin")] public int DurationMin = 20;
        [JsonProperty("objectives")] public List<string> Objectives = new List<string>();
        [JsonProperty("equipment")] public List<EquipmentSpec> Equipment = new List<EquipmentSpec>();
        [JsonProperty("variables")] public Dictionary<string, VariableSpec> Variables = new Dictionary<string, VariableSpec>();
        [JsonProperty("steps")] public List<StepSpec> Steps = new List<StepSpec>();
        [JsonProperty("hazards")] public List<HazardSpec> Hazards = new List<HazardSpec>();
        [JsonProperty("results")] public List<ResultSpec> Results = new List<ResultSpec>();
        [JsonProperty("scoring")] public ScoringSpec Scoring = new ScoringSpec();
        [JsonProperty("passScore")] public double PassScore = 60;
        [JsonProperty("xp")] public int Xp = 100;
        [JsonProperty("i18n")] public Dictionary<string, JObject> I18n = new Dictionary<string, JObject>();

        public static ScenarioDefinition FromJson(string json) => JsonConvert.DeserializeObject<ScenarioDefinition>(json);

        public EquipmentSpec FindEquipment(string id) => Equipment.Find(e => e.Id == id);
        public StepSpec FindStep(string id) => Steps.Find(s => s.Id == id);

        /// <summary>Applies a translation ("rw", "fr") over titles, instructions, hints and narration.</summary>
        public void Localize(string lang)
        {
            if (string.IsNullOrEmpty(lang) || I18n == null || !I18n.TryGetValue(lang, out var tr) || tr == null) return;
            if (tr["title"] is JValue t) Title = (string)t;
            if (tr["summary"] is JValue su) Summary = (string)su;
            if (tr["steps"] is JObject steps)
                foreach (var step in Steps)
                {
                    if (!(steps[step.Id] is JObject s)) continue;
                    if (s["title"] is JValue ti) step.Title = (string)ti;
                    if (s["instruction"] is JValue ins) step.Instruction = (string)ins;
                    if (s["say"] is JValue say) step.Say = (string)say;
                    if (s["success"] is JValue suc) step.Success = (string)suc;
                    if (s["hints"] is JArray h) step.Hints = h.ToObject<List<string>>();
                }
        }
    }

    public sealed class EquipmentSpec
    {
        [JsonProperty("id")] public string Id;
        [JsonProperty("type")] public string Type;
        [JsonProperty("slot")] public string Slot;
        [JsonProperty("label")] public string Label;
        [JsonProperty("init")] public Dictionary<string, JToken> Init = new Dictionary<string, JToken>();

        public double InitNumber(string key, double fallback = 0)
            => Init != null && Init.TryGetValue(key, out var v) && v != null && (v.Type == JTokenType.Float || v.Type == JTokenType.Integer) ? v.Value<double>() : fallback;
        public string InitString(string key, string fallback = null)
            => Init != null && Init.TryGetValue(key, out var v) && v != null && v.Type == JTokenType.String ? v.Value<string>() : fallback;
    }

    public sealed class VariableSpec
    {
        [JsonProperty("model")] public string Model;
        [JsonProperty("inputs")] public Dictionary<string, string> Inputs = new Dictionary<string, string>();
        [JsonProperty("params")] public Dictionary<string, JToken> Params = new Dictionary<string, JToken>();
        public string ParamString(string key, string fallback = null)
            => Params != null && Params.TryGetValue(key, out var v) && v != null && v.Type == JTokenType.String ? v.Value<string>() : fallback;
        public double ParamNumber(string key, double fallback = 0)
            => Params != null && Params.TryGetValue(key, out var v) && v != null && (v.Type == JTokenType.Float || v.Type == JTokenType.Integer) ? v.Value<double>() : fallback;
    }

    public static class StepKind
    {
        public const string Action = "action", Measure = "measure", Checkpoint = "checkpoint", Info = "info";
    }

    public sealed class StepSpec
    {
        [JsonProperty("id")] public string Id;
        [JsonProperty("kind")] public string Kind = StepKind.Action;
        [JsonProperty("title")] public string Title;
        [JsonProperty("instruction")] public string Instruction;
        [JsonProperty("say")] public string Say;
        [JsonProperty("success")] public string Success;
        [JsonProperty("hints")] public List<string> Hints = new List<string>();
        [JsonProperty("focus")] public string Focus;
        [JsonProperty("points")] public int Points = 10;
        [JsonProperty("expect")] public ExpectSpec Expect;
        [JsonProperty("until")] public string Until;
        [JsonProperty("record")] public RecordSpec Record;
        [JsonProperty("checkpoint")] public CheckpointSpec Checkpoint;
    }

    public sealed class ExpectSpec
    {
        [JsonProperty("intent")] public string Intent;
        [JsonProperty("target")] public string Target;
        [JsonProperty("into")] public string Into;
        [JsonProperty("value")] public RangeSpec Value;
    }

    public sealed class RangeSpec
    {
        [JsonProperty("min")] public double? Min;
        [JsonProperty("max")] public double? Max;
        public bool Contains(double v) => (!Min.HasValue || v >= Min.Value) && (!Max.HasValue || v <= Max.Value);
    }

    public sealed class RecordSpec
    {
        [JsonProperty("key")] public string Key;
        [JsonProperty("label")] public string Label;
        [JsonProperty("unit")] public string Unit;
        [JsonProperty("truth")] public string Truth;
        [JsonProperty("tolerance")] public double Tolerance;
    }

    public sealed class CheckpointSpec
    {
        [JsonProperty("questionRef")] public string QuestionRef;
        [JsonProperty("question")] public QuestionSpec Question;
    }

    public sealed class QuestionSpec
    {
        [JsonProperty("prompt")] public string Prompt;
        [JsonProperty("choices")] public List<string> Choices = new List<string>();
        [JsonProperty("answerIndex")] public int AnswerIndex;
        [JsonProperty("explanation")] public string Explanation;
    }

    public sealed class HazardSpec
    {
        [JsonProperty("id")] public string Id;
        [JsonProperty("when")] public string When;
        [JsonProperty("message")] public string Message;
        [JsonProperty("severity")] public string Severity = "warn";
        [JsonProperty("penalty")] public int Penalty = 5;
    }

    public sealed class ResultSpec
    {
        [JsonProperty("key")] public string Key;
        [JsonProperty("label")] public string Label;
        [JsonProperty("unit")] public string Unit;
        [JsonProperty("expected")] public double Expected;
        [JsonProperty("tolerancePct")] public double TolerancePct = 5;
        [JsonProperty("source")] public string Source;
    }

    public sealed class ScoringSpec
    {
        [JsonProperty("accuracy")] public double Accuracy = 40;
        [JsonProperty("procedure")] public double Procedure = 40;
        [JsonProperty("safety")] public double Safety = 20;
    }
}
