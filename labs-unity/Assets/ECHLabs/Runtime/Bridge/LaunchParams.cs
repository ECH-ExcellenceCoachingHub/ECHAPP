using System;
using System.Collections.Generic;
using UnityEngine;

namespace ECHLabs.Runtime.Bridge
{
    /// <summary>
    /// How the lab was opened. Filled from (in priority order):
    ///   Android/iOS: launch message from Flutter (HostBridge.OnHostMessage)
    ///   Windows:     command line  --token=… --scenario=… --lesson=… --api=… --lang=…
    ///   WebGL:       URL fragment  #token=…&scenario=…   (never sent to servers or logs)
    ///   Headset:     pairing (PairingFlow) when no token is present
    ///   Editor:      environment variables ECH_LAB_TOKEN / ECH_LAB_SCENARIO / ECH_LAB_API
    /// With no token the lab runs in practice mode from the bundled scenarios (nothing is saved).
    /// </summary>
    [Serializable]
    public sealed class LaunchParams
    {
        public const string DefaultApi = "https://echappbackend.onrender.com/api/labs";

        public string Token;
        public string Scenario;
        public string Lesson;
        public string Api = DefaultApi;
        public string Lang = "en";
        public string Mode;      // desktop | touch | cardboard | xr (optional override)
        public string Quality;   // low | medium | ultra (optional override)
        public string ResumeClientId;

        public bool HasToken => !string.IsNullOrEmpty(Token);
        public bool IsPractice => !HasToken;

        public static LaunchParams FromCommandLine(string[] args)
        {
            var p = new LaunchParams();
            foreach (var a in args)
            {
                if (!a.StartsWith("--")) continue;
                int eq = a.IndexOf('=');
                if (eq < 0) continue;
                p.Set(a.Substring(2, eq - 2), a.Substring(eq + 1));
            }
            return p;
        }

        public static LaunchParams FromQuery(string query)
        {
            var p = new LaunchParams();
            if (string.IsNullOrEmpty(query)) return p;
            foreach (var kv in ParseQuery(query.TrimStart('#', '?'))) p.Set(kv.Key, kv.Value);
            return p;
        }

        public static LaunchParams FromEnvironment()
        {
            var p = new LaunchParams();
            p.Set("token", Environment.GetEnvironmentVariable("ECH_LAB_TOKEN"));
            p.Set("scenario", Environment.GetEnvironmentVariable("ECH_LAB_SCENARIO"));
            p.Set("api", Environment.GetEnvironmentVariable("ECH_LAB_API"));
            p.Set("lang", Environment.GetEnvironmentVariable("ECH_LAB_LANG"));
            return p;
        }

        public void Set(string key, string value)
        {
            if (string.IsNullOrEmpty(value)) return;
            switch (key)
            {
                case "token": Token = value; break;
                case "scenario": Scenario = value; break;
                case "lesson": Lesson = value; break;
                case "api": if (value.StartsWith("https://") || value.StartsWith("http://localhost") || value.StartsWith("http://127.0.0.1") || value.StartsWith("http://10.0.2.2")) Api = value.TrimEnd('/'); break;
                case "lang": Lang = value; break;
                case "mode": Mode = value; break;
                case "quality": Quality = value; break;
                case "resume": ResumeClientId = value; break;
            }
        }

        /// <summary>Fills empty fields from another source.</summary>
        public LaunchParams Merge(LaunchParams other)
        {
            if (other == null) return this;
            if (!HasToken) Token = other.Token;
            Scenario ??= other.Scenario;
            Lesson ??= other.Lesson;
            if (Api == DefaultApi && other.Api != DefaultApi) Api = other.Api;
            if (Lang == "en" && other.Lang != "en") Lang = other.Lang;
            Mode ??= other.Mode;
            Quality ??= other.Quality;
            ResumeClientId ??= other.ResumeClientId;
            return this;
        }

        static IEnumerable<KeyValuePair<string, string>> ParseQuery(string q)
        {
            foreach (var part in q.Split('&'))
            {
                if (part.Length == 0) continue;
                int eq = part.IndexOf('=');
                string k = Uri.UnescapeDataString((eq < 0 ? part : part.Substring(0, eq)).Replace('+', ' '));
                string v = eq < 0 ? "" : Uri.UnescapeDataString(part.Substring(eq + 1).Replace('+', ' '));
                yield return new KeyValuePair<string, string>(k, v);
            }
        }

        public override string ToString() => $"scenario={Scenario} lesson={Lesson} api={Api} lang={Lang} token={(HasToken ? "yes" : "no")}";
    }

    public static class PlatformInfo
    {
        /// <summary>Backend "platform" value for LabAttempt.</summary>
        public static string Platform
        {
            get
            {
#if UNITY_WEBGL
                return "web";
#elif UNITY_ANDROID
                return IsHeadset ? "quest" : "android";
#elif UNITY_IOS
                return "ios";
#elif UNITY_STANDALONE_WIN
                return UnityEngine.XR.XRSettings.isDeviceActive ? "pcvr" : "windows";
#else
                return "other";
#endif
            }
        }

        /// <summary>Standalone Android headsets (Quest, Pico) report their model name.</summary>
        public static bool IsHeadset
        {
            get
            {
                var model = SystemInfo.deviceModel.ToLowerInvariant();
                return model.Contains("quest") || model.Contains("oculus") || model.Contains("pico");
            }
        }
    }
}
