using System;
using System.Collections.Generic;
using ECHLabs.Runtime.Equipment;
using UnityEngine;

namespace ECHLabs.Runtime.FX
{
    /// <summary>
    /// Lab sounds and phone vibration. Every sound is synthesised at start-up (glass clinks with
    /// real inharmonic partials, burette drips, a gurgling pour, the Bunsen roar, switch clicks,
    /// keyboard taps, chimes), so nothing has to be downloaded and it works offline on every platform.
    /// Sounds are positional, so a drip comes from the burette and the roar from the burner.
    /// </summary>
    public sealed class LabFx : MonoBehaviour
    {
        const int Rate = 22050;
        const string SoundKey = "ech_sound", HapticsKey = "ech_haptics";

        public static LabFx Instance { get; private set; }

        public static bool SoundOn
        {
            get => Pref(SoundKey, true);
            set { SetPref(SoundKey, value); AudioListener.volume = value ? 1f : 0f; }
        }

        public static bool HapticsOn { get => Pref(HapticsKey, true); set => SetPref(HapticsKey, value); }

        readonly Dictionary<string, AudioClip> clips = new Dictionary<string, AudioClip>();
        readonly List<AudioSource> pool = new List<AudioSource>();
        AudioSource ui, pourLoop, flameLoop, streamLoop;
        readonly List<BuretteView> burettes = new List<BuretteView>();
        readonly List<InstrumentView> burners = new List<InstrumentView>();
        readonly Dictionary<BuretteView, float> dripTimers = new Dictionary<BuretteView, float>();
        float lastHaptic;
        System.Random rng = new System.Random(7);

        public static LabFx Create()
        {
            if (Instance) return Instance;
            var go = new GameObject("Lab sound & haptics");
            DontDestroyOnLoad(go);
            return go.AddComponent<LabFx>();
        }

        void Awake()
        {
            Instance = this;
            AudioListener.volume = SoundOn ? 1f : 0f;
            Build();
            ui = gameObject.AddComponent<AudioSource>();
            ui.playOnAwake = false;
            ui.spatialBlend = 0;
            pourLoop = Loop("pour", 0.55f);
            streamLoop = Loop("pour", 0.25f);
            flameLoop = Loop("flame", 0.5f);
            for (int i = 0; i < 8; i++)
            {
                var s = new GameObject("fx").AddComponent<AudioSource>();
                s.transform.SetParent(transform, false);
                Spatial(s);
                pool.Add(s);
            }
            ContainerView.StreamChanged += OnStream;
        }

        void OnDestroy()
        {
            ContainerView.StreamChanged -= OnStream;
            if (Instance == this) Instance = null;
        }

        AudioSource Loop(string clip, float volume)
        {
            var s = new GameObject(clip + " loop").AddComponent<AudioSource>();
            s.transform.SetParent(transform, false);
            Spatial(s);
            s.clip = clips[clip];
            s.loop = true;
            s.volume = volume;
            s.playOnAwake = false;
            return s;
        }

        static void Spatial(AudioSource s)
        {
            s.playOnAwake = false;
            s.spatialBlend = 0.85f;
            s.rolloffMode = AudioRolloffMode.Logarithmic;
            s.minDistance = 0.6f;
            s.maxDistance = 12f;
            s.dopplerLevel = 0;
        }

        /// <summary>Equipment that makes continuous sound (dripping burettes, lit burners).</summary>
        public void Track(IEnumerable<EquipmentView> views)
        {
            burettes.Clear(); burners.Clear(); dripTimers.Clear();
            foreach (var v in views)
            {
                if (v is BuretteView b) burettes.Add(b);
                if (v is InstrumentView i && i.flame) burners.Add(i);
            }
        }

        // ─── Playback ────────────────────────────────────────────────────────

        public void Play(string name, Vector3? at = null, float volume = 1f, float pitchJitter = 0.06f)
        {
            if (!SoundOn || !clips.TryGetValue(name, out var clip)) return;
            float pitch = 1f + ((float)rng.NextDouble() * 2 - 1) * pitchJitter;
            if (at == null) { ui.pitch = pitch; ui.PlayOneShot(clip, volume); return; }
            AudioSource src = null;
            foreach (var s in pool) if (!s.isPlaying) { src = s; break; }
            src ??= pool[0];
            src.transform.position = at.Value;
            src.pitch = pitch;
            src.clip = clip;
            src.volume = volume;
            src.Play();
        }

        /// <summary>Short vibration on phones (grab, connect, press, mistakes). Throttled.</summary>
        public void Haptic(int ms, int amplitude)
        {
            if (!HapticsOn || Time.unscaledTime - lastHaptic < 0.06f) return;
            lastHaptic = Time.unscaledTime;
            Haptics.Vibrate(ms, amplitude);
        }

        /// <summary>Hand cues from the first-person hands: sound + touch feedback at the right moment.</summary>
        public void OnHandCue(string cue, Vector3 at, EquipmentView near)
        {
            bool glass = near && (near is ContainerView || near is FlaskView || near is BuretteView || near.Type == "funnel" || near.Type == "indicator" || near.Type == "slide");
            switch (cue)
            {
                case "grip":
                    if (near is WearableView) Play("cloth", at, 0.8f);
                    else if (glass) Play("clink", at, 0.35f, 0.12f);
                    else Play("tap", at, 0.5f);
                    Haptic(18, 70);
                    break;
                case "release":
                    if (glass) Play("tap", at, 0.6f);
                    Haptic(12, 50);
                    break;
                case "press": Play("click", at, 0.8f); Haptic(25, 140); break;
                case "twist": Play("twist", at, 0.7f); Haptic(15, 60); break;
                case "key": Play("key", at, 0.5f, 0.15f); Haptic(8, 35); break;
            }
        }

        public void StepDone() { Play("success", null, 0.45f, 0); Haptic(35, 90); }
        public void Mistake() { Play("error", null, 0.5f, 0); Haptic(70, 170); }
        public void Hazard() { Play("alarm", null, 0.55f, 0); Haptic(220, 255); }
        public void Whoosh() => Play("whoosh", null, 0.25f, 0.1f);

        void OnStream(ContainerView c, bool on, Vector3 at)
        {
            if (!on) { pourLoop.Stop(); return; }
            if (!SoundOn) return;
            pourLoop.transform.position = at;
            pourLoop.pitch = 0.9f + (float)rng.NextDouble() * 0.2f;
            pourLoop.Play();
        }

        void Update()
        {
            if (!SoundOn) { if (flameLoop.isPlaying) flameLoop.Stop(); if (streamLoop.isPlaying) streamLoop.Stop(); return; }
            // Burette: individual drips, or a thin trickle when the tap is wide open.
            bool trickle = false;
            foreach (var b in burettes)
            {
                if (!b) continue;
                float rate = b.DropRate;
                if (rate <= 0) continue;
                var at = b.tip ? b.tip.position : b.transform.position;
                if (rate > 9f) { trickle = true; streamLoop.transform.position = at; continue; }
                dripTimers.TryGetValue(b, out float t);
                t -= Time.deltaTime;
                if (t <= 0) { Play("drip", at, 0.5f, 0.18f); t = 1f / Mathf.Max(rate, 0.5f); }
                dripTimers[b] = t;
            }
            if (trickle && !streamLoop.isPlaying) streamLoop.Play();
            if (!trickle && streamLoop.isPlaying) streamLoop.Stop();

            InstrumentView lit = null;
            foreach (var i in burners) if (i && i.Burning) { lit = i; break; }
            if (lit)
            {
                flameLoop.transform.position = lit.transform.position + Vector3.up * 0.15f;
                flameLoop.volume = Mathf.Lerp(0.25f, 0.6f, lit.AirHole);
                flameLoop.pitch = Mathf.Lerp(0.8f, 1.15f, lit.AirHole);
                if (!flameLoop.isPlaying) flameLoop.Play();
            }
            else if (flameLoop.isPlaying) flameLoop.Stop();
        }

        // ─── Synthesis ───────────────────────────────────────────────────────

        void Build()
        {
            // Glass: inharmonic partials with fast decays (a small beaker tapped against glass).
            clips["clink"] = Synth("clink", 0.6f, (t, n) => Partials(t, new[] { 2350f, 3720f, 5180f, 6900f }, new[] { 0.32f, 0.22f, 0.15f, 0.08f }, new[] { 0.5f, 0.3f, 0.22f, 0.15f }) * 0.5f);
            // Glass set down on the bench: low thud + a little ring.
            clips["tap"] = Synth("tap", 0.25f, (t, n) => (Mathf.Sin(2 * Mathf.PI * 180 * t) * Mathf.Exp(-t * 40) * 0.6f + n * Mathf.Exp(-t * 120) * 0.35f + Mathf.Sin(2 * Mathf.PI * 2900 * t) * Mathf.Exp(-t * 30) * 0.06f));
            // Switch: sharp transient + short body.
            clips["click"] = Synth("click", 0.08f, (t, n) => n * Mathf.Exp(-t * 900) * 0.8f + Mathf.Sin(2 * Mathf.PI * 3200 * t) * Mathf.Exp(-t * 160) * 0.35f + Mathf.Sin(2 * Mathf.PI * 900 * t) * Mathf.Exp(-t * 90) * 0.2f);
            clips["key"] = Synth("key", 0.05f, (t, n) => n * Mathf.Exp(-t * 500) * 0.55f + Mathf.Sin(2 * Mathf.PI * 1900 * t) * Mathf.Exp(-t * 300) * 0.2f);
            clips["twist"] = Synth("twist", 0.22f, Filtered(0.25f, (t, x) => x * Mathf.Sin(Mathf.PI * t / 0.22f) * 0.6f));
            // Drop: rising "plink" of a drop hitting liquid.
            clips["drip"] = Synth("drip", 0.12f, (t, n) => Mathf.Sin(2 * Mathf.PI * (650 * t + 5200 * t * t)) * Mathf.Exp(-t * 45) * 0.5f);
            // Pouring: low-passed noise with a gurgle.
            clips["pour"] = Synth("pour", 2f, Filtered(0.12f, (t, x) => x * (0.75f + 0.25f * Mathf.Sin(2 * Mathf.PI * 7.3f * t) * Mathf.Sin(2 * Mathf.PI * 2.1f * t)) * 1.6f));
            // Bunsen roar: deep rumbling noise.
            clips["flame"] = Synth("flame", 2f, Filtered(0.04f, (t, x) => x * (0.85f + 0.15f * Mathf.Sin(2 * Mathf.PI * 11f * t)) * 3.2f));
            clips["cloth"] = Synth("cloth", 0.4f, Filtered(0.35f, (t, x) => x * Mathf.Sin(Mathf.PI * t / 0.4f) * (0.6f + 0.4f * Mathf.Sin(2 * Mathf.PI * 18 * t)) * 0.5f));
            clips["whoosh"] = Synth("whoosh", 0.45f, Filtered(0.08f, (t, x) => x * Mathf.Sin(Mathf.PI * t / 0.45f) * 1.4f));
            clips["success"] = Synth("success", 0.75f, (t, n) => Bell(t, 1046.5f, 0) + Bell(t, 1318.5f, 0.11f) + Bell(t, 1568f, 0.22f));
            clips["error"] = Synth("error", 0.32f, (t, n) => Soft(t, 233f, 0, 0.13f) + Soft(t, 185f, 0.15f, 0.16f));
            clips["alarm"] = Synth("alarm", 0.7f, (t, n) => Soft(t, 880f, 0f, 0.15f) + Soft(t, 660f, 0.18f, 0.15f) + Soft(t, 880f, 0.36f, 0.15f) * 0.8f);
        }

        static float Partials(float t, float[] f, float[] a, float[] d)
        {
            float v = 0;
            for (int i = 0; i < f.Length; i++) v += Mathf.Sin(2 * Mathf.PI * f[i] * t) * a[i] * Mathf.Exp(-t / d[i] * 4f);
            return v * Mathf.Min(1, t * 2000);
        }

        static float Bell(float t, float f, float start)
        {
            float u = t - start;
            if (u < 0) return 0;
            return (Mathf.Sin(2 * Mathf.PI * f * u) + 0.3f * Mathf.Sin(2 * Mathf.PI * f * 2.01f * u)) * Mathf.Exp(-u * 7f) * 0.22f * Mathf.Min(1, u * 400);
        }

        static float Soft(float t, float f, float start, float len)
        {
            float u = t - start;
            if (u < 0 || u > len) return 0;
            float env = Mathf.Sin(Mathf.PI * u / len);
            // A few odd harmonics: a soft, rounded "square".
            return (Mathf.Sin(2 * Mathf.PI * f * u) + Mathf.Sin(2 * Mathf.PI * 3 * f * u) / 6f + Mathf.Sin(2 * Mathf.PI * 5 * f * u) / 14f) * env * 0.3f;
        }

        /// <summary>One-pole low-pass over white noise, then shaped.</summary>
        Func<float, float, float> Filtered(float alpha, Func<float, float, float> shape)
        {
            float y = 0;
            return (t, n) => { y += alpha * (n - y); return shape(t, y); };
        }

        AudioClip Synth(string name, float seconds, Func<float, float, float> f)
        {
            int count = Mathf.CeilToInt(seconds * Rate);
            var data = new float[count];
            for (int i = 0; i < count; i++)
            {
                float t = i / (float)Rate;
                float noise = (float)(rng.NextDouble() * 2 - 1);
                data[i] = Mathf.Clamp(f(t, noise), -1f, 1f);
            }
            // Tiny fade at both ends: no clicks.
            int fade = Mathf.Min(64, count / 4);
            for (int i = 0; i < fade; i++) { float k = i / (float)fade; data[i] *= k; data[count - 1 - i] *= k; }
            var clip = AudioClip.Create("ech_" + name, count, 1, Rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        static bool Pref(string key, bool fallback)
        {
            try { return PlayerPrefs.GetInt(key, fallback ? 1 : 0) == 1; } catch { return fallback; }
        }

        static void SetPref(string key, bool v)
        {
            try { PlayerPrefs.SetInt(key, v ? 1 : 0); PlayerPrefs.Save(); } catch { }
        }
    }

    /// <summary>Phone vibration with intensity (Android VibrationEffect); quietly does nothing elsewhere.</summary>
    public static class Haptics
    {
#if UNITY_ANDROID && !UNITY_EDITOR
        static AndroidJavaObject vibrator;
        static AndroidJavaClass effect;
        static bool tried;
#endif
        public static void Vibrate(int ms, int amplitude)
        {
#if UNITY_ANDROID && !UNITY_EDITOR
            try
            {
                if (!tried)
                {
                    tried = true;
                    using (var player = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
                    using (var activity = player.GetStatic<AndroidJavaObject>("currentActivity"))
                        vibrator = activity.Call<AndroidJavaObject>("getSystemService", "vibrator");
                    effect = new AndroidJavaClass("android.os.VibrationEffect");
                }
                if (vibrator == null) return;
                using (var e = effect.CallStatic<AndroidJavaObject>("createOneShot", (long)ms, Mathf.Clamp(amplitude, 1, 255)))
                    vibrator.Call("vibrate", e);
            }
            catch (Exception)
            {
                if (ms >= 60) Handheld.Vibrate(); // also makes Unity declare the VIBRATE permission
            }
#endif
        }
    }
}
