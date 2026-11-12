using System;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using ECHLabs.Core;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using UnityEngine;
using UnityEngine.Networking;

namespace ECHLabs.Runtime.Net
{
    /// <summary>
    /// ECH backend client (/api/labs). Every write goes through OfflineQueue first, so a student
    /// who loses connection mid-practical loses nothing: payloads are retried until accepted.
    /// </summary>
    public sealed class LabApiClient
    {
        readonly string api;
        string token;
        public bool Online { get; private set; } = true;

        public LabApiClient(string apiBase, string labToken)
        {
            api = apiBase.TrimEnd('/');
            token = labToken;
        }

        public void SetToken(string labToken) => token = labToken;

        public sealed class ApiResult
        {
            public bool Ok;
            public long Status;
            public JToken Data;
            public string Message;
        }

        public async Task<ApiResult> Send(string method, string path, object body = null, int timeoutSec = 20)
        {
            using var req = new UnityWebRequest(api + path, method);
            req.downloadHandler = new DownloadHandlerBuffer();
            if (body != null)
            {
                var json = body is string s ? s : JsonConvert.SerializeObject(body, new JsonSerializerSettings { NullValueHandling = NullValueHandling.Ignore });
                req.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(json)) { contentType = "application/json" };
            }
            req.SetRequestHeader("Accept", "application/json");
            if (!string.IsNullOrEmpty(token)) req.SetRequestHeader("Authorization", "Bearer " + token);
            req.timeout = timeoutSec;
            await req.SendWebRequest();

            var result = new ApiResult { Status = req.responseCode };
            if (req.result == UnityWebRequest.Result.ConnectionError || req.result == UnityWebRequest.Result.DataProcessingError)
            {
                Online = false;
                result.Message = req.error;
                return result;
            }
            Online = true;
            try
            {
                var obj = JObject.Parse(req.downloadHandler.text);
                result.Ok = req.result == UnityWebRequest.Result.Success && obj.Value<bool?>("success") != false;
                result.Data = obj["data"];
                result.Message = obj.Value<string>("message");
            }
            catch (Exception e)
            {
                result.Message = "Bad response: " + e.Message;
            }
            return result;
        }

        public async Task<(ScenarioDefinition def, JToken card)> GetScenario(string idOrSlug)
        {
            var r = await Send("GET", "/scenarios/" + UnityWebRequest.EscapeURL(idOrSlug));
            if (!r.Ok || r.Data == null) throw new Exception(r.Message ?? "Could not download the lab");
            var def = r.Data["definition"].ToObject<ScenarioDefinition>();
            ScenarioCache.Save(def, r.Data["id"]?.ToString());
            return (def, r.Data);
        }

        public Task<ApiResult> StartAttempt(string clientId, string scenarioId, string lessonId, string platform, string mode, string tier, string lang)
            => Send("POST", "/attempts", new { clientId, scenarioId, lessonId, platform, mode, qualityTier = tier, lang, startedAt = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() });

        public Task<ApiResult> SaveProgress(AttemptProgress progress)
        {
            // World snapshots stay on the device.
            var world = progress.World;
            progress.World = null;
            var json = JsonConvert.SerializeObject(progress, new JsonSerializerSettings { NullValueHandling = NullValueHandling.Ignore });
            progress.World = world;
            OfflineQueue.Put(progress.ClientId, json);
            return FlushOne(progress.ClientId);
        }

        public async Task<ApiResult> FlushOne(string clientId)
        {
            var json = OfflineQueue.Get(clientId);
            if (json == null) return new ApiResult { Ok = true };
            var r = await Send("PATCH", "/attempts/" + clientId, json);
            // 4xx (other than 401/408/429) will never succeed: drop instead of retrying forever.
            if (r.Ok || (r.Status >= 400 && r.Status < 500 && r.Status != 401 && r.Status != 408 && r.Status != 429)) OfflineQueue.Remove(clientId);
            return r;
        }

        public async Task FlushAll()
        {
            foreach (var id in OfflineQueue.Pending())
            {
                var r = await FlushOne(id);
                if (!Online) return;
            }
        }

        // ─── Headset pairing ─────────────────────────────────────────────────

        public Task<ApiResult> PairStart(string deviceName) => Send("POST", "/pair/start", new { deviceName });
        public Task<ApiResult> PairPoll(string deviceSecret) => Send("POST", "/pair/poll", new { deviceSecret });
    }

    /// <summary>Pending attempt payloads on disk (one file per attempt; newest payload wins).</summary>
    public static class OfflineQueue
    {
        static string Dir
        {
            get
            {
                var d = Path.Combine(Application.persistentDataPath, "ech-labs", "pending");
                Directory.CreateDirectory(d);
                return d;
            }
        }

        static string FileFor(string clientId) => Path.Combine(Dir, Sanitize(clientId) + ".json");
        static string Sanitize(string s) { var sb = new StringBuilder(); foreach (var c in s) if (char.IsLetterOrDigit(c) || c == '-') sb.Append(c); return sb.ToString(); }

        public static void Put(string clientId, string json) { try { File.WriteAllText(FileFor(clientId), json); } catch (Exception e) { Debug.LogWarning("[ECHLabs] queue write failed: " + e.Message); } }
        public static string Get(string clientId) { var f = FileFor(clientId); return File.Exists(f) ? File.ReadAllText(f) : null; }
        public static void Remove(string clientId) { var f = FileFor(clientId); if (File.Exists(f)) File.Delete(f); }
        public static string[] Pending()
        {
            var files = Directory.GetFiles(Dir, "*.json");
            for (int i = 0; i < files.Length; i++) files[i] = Path.GetFileNameWithoutExtension(files[i]);
            return files;
        }
    }

    /// <summary>Downloaded scenarios + local resume snapshots, for offline replay.</summary>
    public static class ScenarioCache
    {
        static string Dir
        {
            get
            {
                var d = Path.Combine(Application.persistentDataPath, "ech-labs", "scenarios");
                Directory.CreateDirectory(d);
                return d;
            }
        }

        public static void Save(ScenarioDefinition def, string serverId)
        {
            try
            {
                var json = JsonConvert.SerializeObject(def);
                File.WriteAllText(Path.Combine(Dir, def.Id + ".json"), json);
                if (!string.IsNullOrEmpty(serverId)) File.WriteAllText(Path.Combine(Dir, serverId + ".json"), json);
            }
            catch (Exception e) { Debug.LogWarning("[ECHLabs] cache write failed: " + e.Message); }
        }

        /// <summary>Cached download, else a scenario bundled in Resources/Scenarios (practice mode).</summary>
        public static ScenarioDefinition Load(string idOrSlug)
        {
            if (string.IsNullOrEmpty(idOrSlug)) return null;
            var f = Path.Combine(Dir, idOrSlug + ".json");
            if (File.Exists(f)) return ScenarioDefinition.FromJson(File.ReadAllText(f));
            var bundled = Resources.Load<TextAsset>("Scenarios/" + idOrSlug);
            return bundled ? ScenarioDefinition.FromJson(bundled.text) : null;
        }

        public static void SaveResume(AttemptProgress p)
        {
            try { File.WriteAllText(Path.Combine(Dir, "resume-" + p.ScenarioId + ".json"), JsonConvert.SerializeObject(p)); } catch { }
        }

        public static AttemptProgress LoadResume(string scenarioId)
        {
            var f = Path.Combine(Dir, "resume-" + scenarioId + ".json");
            if (!File.Exists(f)) return null;
            try { return JsonConvert.DeserializeObject<AttemptProgress>(File.ReadAllText(f)); } catch { return null; }
        }

        public static void ClearAllResumes()
        {
            foreach (var f in Directory.GetFiles(Dir, "resume-*.json")) File.Delete(f);
        }

        public static void ClearResume(string scenarioId)
        {
            var f = Path.Combine(Dir, "resume-" + scenarioId + ".json");
            if (File.Exists(f)) File.Delete(f);
        }
    }
}
