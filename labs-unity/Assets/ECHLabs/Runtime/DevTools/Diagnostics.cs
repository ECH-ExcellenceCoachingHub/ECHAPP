using System.Collections;
using System.IO;
using UnityEngine;

namespace ECHLabs.Runtime.DevTools
{
    /// <summary>
    /// On-device health log for the first minute of a lab: frames, fps, screen, cameras,
    /// useful when diagnosing a device (adb logcat -s Unity).
    /// </summary>
    public sealed class Diagnostics : MonoBehaviour
    {
        IEnumerator Start()
        {
            float t0 = Time.realtimeSinceStartup;
            int lastFrames = Time.frameCount;
            // Every 3 s for the first minute, then every 15 s for the rest of the session.
            for (int i = 0; ; i++)
            {
                float every = i < 20 ? 3f : 15f;
                yield return new WaitForSecondsRealtime(every);
                int frames = Time.frameCount;
                int activeCams = 0;
                foreach (var c in Camera.allCameras) if (c.isActiveAndEnabled) activeCams++;
                Debug.Log($"[ECHLabs] diag t={Time.realtimeSinceStartup - t0:0}s frames={frames} fps={(frames - lastFrames) / every:0.0} screen={Screen.width}x{Screen.height} cams={activeCams} gfx={SystemInfo.graphicsDeviceType} {SystemInfo.graphicsDeviceName} quality={QualitySettings.names[QualitySettings.GetQualityLevel()]}");
                lastFrames = frames;
            }
        }
    }
}
