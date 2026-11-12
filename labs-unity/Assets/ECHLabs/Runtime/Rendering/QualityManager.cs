using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ECHLabs.Runtime.Rendering
{
    public enum QualityTier { Low, Medium, Ultra }

    /// <summary>
    /// Picks Low / Medium / Ultra from the device (GPU, memory, cores) and keeps it honest with a
    /// frame-time watchdog that steps down if the lab can't hold its target frame rate.
    /// Quality levels "ECH Low/Medium/Ultra" (each with its own URP asset) are created by
    /// the editor ProjectSetup; post-processing lives on the room's global Volume.
    /// </summary>
    public sealed class QualityManager : MonoBehaviour
    {
        public Volume postVolume;
        public QualityTier Tier { get; private set; } = QualityTier.Medium;
        public float AvgFps { get; private set; } = 60;
        public float MinFps { get; private set; } = 999;

        float targetFps = 60;
        float sampleTime, worstWindow = 999;
        int frames;
        float lowFor;
        bool locked; // student chose explicitly

        public static QualityTier Detect()
        {
            if (Application.platform == RuntimePlatform.WebGLPlayer)
                return SystemInfo.systemMemorySize >= 8000 && SystemInfo.graphicsMemorySize >= 2000 ? QualityTier.Medium : QualityTier.Low;
            if (Application.isMobilePlatform)
            {
                if (Bridge.PlatformInfo.IsHeadset) return QualityTier.Medium;
                int mem = SystemInfo.systemMemorySize;
                string gpu = SystemInfo.graphicsDeviceName.ToLowerInvariant();
                bool strongGpu = gpu.Contains("adreno (tm) 7") || gpu.Contains("adreno (tm) 6") && mem >= 6000 || gpu.Contains("apple") || gpu.Contains("immortalis") || gpu.Contains("mali-g7");
                if (mem < 3500 || SystemInfo.processorCount < 6) return QualityTier.Low;
                return strongGpu && mem >= 6000 ? QualityTier.Medium : QualityTier.Low;
            }
            // Desktop
            return SystemInfo.graphicsMemorySize >= 3500 && SystemInfo.processorCount >= 6 ? QualityTier.Ultra : QualityTier.Medium;
        }

        public static QualityTier Parse(string s, QualityTier fallback)
        {
            switch ((s ?? "").ToLowerInvariant())
            {
                case "low": return QualityTier.Low;
                case "medium": return QualityTier.Medium;
                case "ultra": return QualityTier.Ultra;
                default: return fallback;
            }
        }

        public void Apply(QualityTier tier, bool byUser = false)
        {
            Tier = tier;
            locked |= byUser;
            string levelName = "ECH " + tier;
            for (int i = 0; i < QualitySettings.names.Length; i++)
                if (QualitySettings.names[i] == levelName) { QualitySettings.SetQualityLevel(i, true); break; }

            var urp = GraphicsSettings.currentRenderPipeline as UniversalRenderPipelineAsset;
            if (urp)
            {
                urp.renderScale = tier == QualityTier.Low ? (Application.isMobilePlatform ? 0.75f : 0.85f) : 1f;
                urp.msaaSampleCount = tier == QualityTier.Ultra ? 4 : tier == QualityTier.Medium ? 2 : 1;
            }
            if (postVolume)
            {
                postVolume.enabled = tier != QualityTier.Low;
                if (postVolume.profile)
                {
                    if (postVolume.profile.TryGet<Bloom>(out var bloom)) bloom.active = tier != QualityTier.Low;
                    if (postVolume.profile.TryGet<DepthOfField>(out var dof)) dof.active = false; // enabled only during inspect
                    if (postVolume.profile.TryGet<Vignette>(out var vig)) vig.active = tier == QualityTier.Ultra;
                }
            }
            foreach (var cam in Camera.allCameras)
            {
                var data = cam.GetUniversalAdditionalCameraData();
                if (!data) continue;
                data.renderPostProcessing = tier != QualityTier.Low;
                data.antialiasing = tier == QualityTier.Ultra ? AntialiasingMode.SubpixelMorphologicalAntiAliasing : tier == QualityTier.Medium ? AntialiasingMode.FastApproximateAntialiasing : AntialiasingMode.None;
            }
            targetFps = UnityEngine.XR.XRSettings.isDeviceActive ? 72 : Application.isMobilePlatform && tier == QualityTier.Low ? 30 : 60;
            Application.targetFrameRate = UnityEngine.XR.XRSettings.isDeviceActive ? -1 : (int)targetFps;
            Debug.Log($"[ECHLabs] Quality {tier} (target {targetFps} fps)");
        }

        /// <summary>Depth of field for close-up inspection (Ultra only).</summary>
        public void SetInspectFocus(bool on, float distance)
        {
            if (Tier != QualityTier.Ultra || !postVolume || !postVolume.profile || !postVolume.profile.TryGet<DepthOfField>(out var dof)) return;
            dof.active = on;
            dof.mode.Override(DepthOfFieldMode.Bokeh);
            dof.focusDistance.Override(distance);
        }

        void Update()
        {
            float dt = Time.unscaledDeltaTime;
            if (dt <= 0) return;
            frames++;
            sampleTime += dt;
            worstWindow = Mathf.Min(worstWindow, 1f / dt);
            if (sampleTime < 2f) return;
            float fps = frames / sampleTime;
            AvgFps = Mathf.Lerp(AvgFps, fps, 0.5f);
            MinFps = Mathf.Min(MinFps, worstWindow);
            frames = 0; sampleTime = 0; worstWindow = 999;

            // Step down after ~6 s well below target (never step up automatically: avoids flapping).
            if (!locked && fps < targetFps * 0.8f) lowFor += 2f; else lowFor = 0;
            if (lowFor >= 6f && Tier != QualityTier.Low)
            {
                lowFor = 0;
                Apply(Tier == QualityTier.Ultra ? QualityTier.Medium : QualityTier.Low);
            }
        }
    }
}
