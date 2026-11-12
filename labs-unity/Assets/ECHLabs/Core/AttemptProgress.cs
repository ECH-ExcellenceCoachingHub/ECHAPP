// ECH Labs — attempt payload synced to PATCH /api/labs/attempts/:clientId.
using System.Collections.Generic;
using Newtonsoft.Json;

namespace ECHLabs.Core
{
    public sealed class AttemptProgress
    {
        [JsonProperty("clientId")] public string ClientId;
        [JsonProperty("scenarioId")] public string ScenarioId;
        [JsonProperty("currentStepId")] public string CurrentStepId;
        [JsonProperty("completedSteps")] public List<string> CompletedSteps = new List<string>();
        [JsonProperty("records")] public Dictionary<string, double> Records = new Dictionary<string, double>();
        [JsonProperty("checkpoints")] public List<CheckpointAnswer> Checkpoints = new List<CheckpointAnswer>();
        [JsonProperty("hazardsTriggered")] public List<HazardHit> HazardsTriggered = new List<HazardHit>();
        [JsonProperty("hintsUsed")] public int HintsUsed;
        [JsonProperty("mistakes")] public int Mistakes;
        [JsonProperty("durationSec")] public double DurationSec;
        [JsonProperty("log")] public List<LogEntry> Log = new List<LogEntry>();
        [JsonProperty("complete", NullValueHandling = NullValueHandling.Ignore)] public bool? Complete;
        /// <summary>Local only (resume on this device): equipment state snapshot. Not sent to the server.</summary>
        [JsonProperty("world", NullValueHandling = NullValueHandling.Ignore)] public Dictionary<string, Dictionary<string, object>> World;
    }

    public sealed class CheckpointAnswer
    {
        [JsonProperty("stepId")] public string StepId;
        [JsonProperty("choice")] public int Choice;
        [JsonProperty("correct")] public bool Correct;
    }

    public sealed class HazardHit
    {
        [JsonProperty("id")] public string Id;
        [JsonProperty("t")] public double T;
    }

    public sealed class LogEntry
    {
        [JsonProperty("t")] public double T;
        [JsonProperty("type")] public string Type;
        [JsonProperty("stepId", NullValueHandling = NullValueHandling.Ignore)] public string StepId;
        [JsonProperty("data", NullValueHandling = NullValueHandling.Ignore)] public object Data;
    }
}
