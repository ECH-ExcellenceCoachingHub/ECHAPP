using System;
using System.Runtime.InteropServices;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using UnityEngine;

namespace ECHLabs.Runtime.Bridge
{
    /// <summary>
    /// Messages between the lab and its host app.
    ///   Flutter (Android/iOS, flutter_embed_unity): host → GameObject "ECHLabsBridge".OnHostMessage(json);
    ///                                              lab → SendToFlutter.Send(json)  (resolved by reflection)
    ///   WebGL (iframe in Flutter web):              lab → window.parent.postMessage via ECHLabsBridge.jslib
    ///   Windows standalone:                         lab → localhost callback given in --callback=  (optional)
    /// Message shape: { "type": "launch" | "progress" | "completed" | "exit" | "ready" | "pause" | "resume", ... }
    /// </summary>
    public sealed class HostBridge : MonoBehaviour
    {
        public const string ObjectName = "ECHLabsBridge";
        static HostBridge instance;

        public static event Action<LaunchParams> LaunchReceived;
        public static event Action<string> CommandReceived; // pause / resume / exit

        public static HostBridge Ensure()
        {
            if (instance) return instance;
            var go = new GameObject(ObjectName);
            DontDestroyOnLoad(go);
            instance = go.AddComponent<HostBridge>();
            return instance;
        }

#if UNITY_WEBGL && !UNITY_EDITOR
        [DllImport("__Internal")] static extern string ECHLabs_GetFragment();
        [DllImport("__Internal")] static extern void ECHLabs_PostToHost(string json);
        [DllImport("__Internal")] static extern void ECHLabs_ClearFragment();
#endif

        /// <summary>Launch parameters available synchronously at startup (command line, URL, env).</summary>
        public static LaunchParams ReadStartupParams()
        {
            var p = new LaunchParams();
#if UNITY_WEBGL && !UNITY_EDITOR
            p = LaunchParams.FromQuery(ECHLabs_GetFragment());
            ECHLabs_ClearFragment(); // keep the token out of history/bookmarks
#elif UNITY_STANDALONE && !UNITY_EDITOR
            p = LaunchParams.FromCommandLine(Environment.GetCommandLineArgs());
#endif
#if UNITY_EDITOR
            p.Merge(LaunchParams.FromEnvironment());
#endif
            return p;
        }

        /// <summary>Called by Flutter through UnitySendMessage / flutter_embed_unity.</summary>
        public void OnHostMessage(string json)
        {
            JObject msg;
            try { msg = JObject.Parse(json); } catch { Debug.LogWarning("[ECHLabs] Bad host message"); return; }
            var type = (string)msg["type"];
            if (type == "launch")
            {
                var p = new LaunchParams();
                foreach (var prop in msg.Properties()) if (prop.Value.Type == JTokenType.String) p.Set(prop.Name, (string)prop.Value);
                LaunchReceived?.Invoke(p);
            }
            else if (!string.IsNullOrEmpty(type)) CommandReceived?.Invoke(type);
        }

        public static void Send(string type, object payload = null)
        {
            var obj = payload == null ? new JObject() : JObject.FromObject(payload);
            obj["type"] = type;
            string json = obj.ToString(Formatting.None);
#if UNITY_WEBGL && !UNITY_EDITOR
            ECHLabs_PostToHost(json);
#elif (UNITY_ANDROID || UNITY_IOS) && !UNITY_EDITOR
            SendToFlutter(json);
#else
            Debug.Log("[ECHLabs → host] " + json);
#endif
        }

        static Type sendToFlutterType;
        static void SendToFlutter(string json)
        {
            // flutter_embed_unity ships a "SendToFlutter" class into the Unity project; we avoid a hard
            // compile-time dependency so the same project builds for Windows/WebGL/Quest without it.
            sendToFlutterType ??= Type.GetType("SendToFlutter") ?? FindType("SendToFlutter");
            var method = sendToFlutterType?.GetMethod("Send", new[] { typeof(string) });
            if (method != null) method.Invoke(null, new object[] { json });
            else Debug.Log("[ECHLabs → host] (no Flutter bridge) " + json);
        }

        static Type FindType(string name)
        {
            foreach (var asm in AppDomain.CurrentDomain.GetAssemblies())
            {
                var t = asm.GetType(name);
                if (t != null) return t;
            }
            return null;
        }
    }
}
