using System.Runtime.InteropServices;
using UnityEngine;

namespace ECHLabs.Runtime.UI
{
    /// <summary>
    /// Dr. ECH's voice, using each platform's built-in TTS (no downloads, works offline):
    /// Android TextToSpeech, browser speechSynthesis (WebGL). Elsewhere subtitles only.
    /// English and Kinyarwanda (falls back to subtitles if the device has no rw voice).
    /// </summary>
    public static class Speech
    {
        public static bool Enabled = true;

#if UNITY_WEBGL && !UNITY_EDITOR
        [DllImport("__Internal")] static extern void ECHLabs_Speak(string text, string lang);
        [DllImport("__Internal")] static extern void ECHLabs_StopSpeaking();
#endif

#if UNITY_ANDROID && !UNITY_EDITOR
        static AndroidJavaObject tts;
        static bool ready;
        sealed class InitListener : AndroidJavaProxy
        {
            public InitListener() : base("android.speech.tts.TextToSpeech$OnInitListener") { }
            public void onInit(int status) { ready = status == 0; }
        }
#endif

        public static void Init(string lang)
        {
#if UNITY_ANDROID && !UNITY_EDITOR
            if (tts != null) return;
            try
            {
                using var unity = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
                var activity = unity.GetStatic<AndroidJavaObject>("currentActivity");
                tts = new AndroidJavaObject("android.speech.tts.TextToSpeech", activity, new InitListener());
            }
            catch (System.Exception e) { Debug.LogWarning("[ECHLabs] TTS unavailable: " + e.Message); }
#endif
        }

        public static void Say(string text, string lang)
        {
            if (!Enabled || string.IsNullOrEmpty(text)) return;
#if UNITY_WEBGL && !UNITY_EDITOR
            ECHLabs_Speak(text, lang == "rw" ? "rw-RW" : "en-GB");
#elif UNITY_ANDROID && !UNITY_EDITOR
            if (tts == null || !ready) return;
            try
            {
                using var locale = new AndroidJavaObject("java.util.Locale", lang == "rw" ? "rw" : "en", lang == "rw" ? "RW" : "GB");
                int res = tts.Call<int>("setLanguage", locale);
                if (res < 0 && lang == "rw") return; // no Kinyarwanda voice: subtitles only
                tts.Call<int>("speak", text, 0 /* QUEUE_FLUSH */, null, "ech");
            }
            catch (System.Exception e) { Debug.LogWarning("[ECHLabs] TTS failed: " + e.Message); }
#endif
        }

        public static void Stop()
        {
#if UNITY_WEBGL && !UNITY_EDITOR
            ECHLabs_StopSpeaking();
#elif UNITY_ANDROID && !UNITY_EDITOR
            try { tts?.Call<int>("stop"); } catch { }
#endif
        }
    }
}
