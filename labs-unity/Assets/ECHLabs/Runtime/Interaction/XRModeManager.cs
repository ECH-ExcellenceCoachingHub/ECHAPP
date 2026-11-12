using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR.Management;

namespace ECHLabs.Runtime.Interaction
{
    /// <summary>
    /// Starts/stops XR at runtime (XR is NOT initialised on startup, so the normal 3D modes never pay
    /// for it). On Android both loaders are configured: Cardboard for phones, OpenXR for Quest/Pico.
    /// </summary>
    public static class XRModeManager
    {
        public enum StereoKind { Cardboard, OpenXR }
        public static bool Running { get; private set; }

        public static bool StartStereo(StereoKind kind)
        {
            if (Running) return true;
            var settings = XRGeneralSettings.Instance;
            var manager = settings ? settings.Manager : null;
            if (manager == null) { Debug.Log("[ECHLabs] XR not configured; using fallback stereo."); return false; }

            var wanted = new List<XRLoader>();
            foreach (var loader in manager.activeLoaders)
            {
                string n = loader.GetType().Name.ToLowerInvariant();
                bool isCardboard = n.Contains("cardboard");
                if (kind == StereoKind.Cardboard ? isCardboard : !isCardboard) wanted.Add(loader);
            }
            if (wanted.Count == 0) { Debug.Log($"[ECHLabs] No {kind} XR loader in this build."); return false; }
            if (!manager.TrySetLoaders(wanted)) return false;

            manager.InitializeLoaderSync();
            if (manager.activeLoader == null) { Debug.LogWarning("[ECHLabs] XR loader failed to initialise."); return false; }
            manager.StartSubsystems();
            Running = true;
            return true;
        }

        public static void StopStereo()
        {
            if (!Running) return;
            var manager = XRGeneralSettings.Instance ? XRGeneralSettings.Instance.Manager : null;
            if (manager != null && manager.isInitializationComplete)
            {
                manager.StopSubsystems();
                manager.DeinitializeLoader();
            }
            Running = false;
        }

        /// <summary>Does this device look like a standalone headset or have an XR device attached?</summary>
        public static bool HeadsetLikely => Bridge.PlatformInfo.IsHeadset;
    }
}
