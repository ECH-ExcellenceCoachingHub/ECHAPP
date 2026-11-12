using UnityEngine;

namespace ECHLabs.Runtime.Interaction
{
    public enum LabMode { Desktop, Touch, Cardboard, XR, Fallback }

    /// <summary>
    /// One per interaction rig. The InteractionController only ever asks: where is the student
    /// pointing, and did they just "select"? That is what makes every lab work in every mode.
    /// </summary>
    public interface IPointerSource
    {
        LabMode Mode { get; }
        Camera Camera { get; }
        /// <summary>World ray of the pointer (mouse, finger, gaze, controller laser).</summary>
        bool TryGetRay(out Ray ray);
        /// <summary>Screen position of the pointer for flat-screen UI hit tests (null in stereo modes).</summary>
        Vector2? ScreenPosition { get; }
        /// <summary>True on the frame the student confirms (click, tap, dwell complete, trigger).</summary>
        bool SelectPressed { get; }
        /// <summary>Stereo/VR modes render the HUD on a world-space surface instead of the screen.</summary>
        bool WorldSpaceUI { get; }
        /// <summary>The rig's root (moved to teleport between stations in VR).</summary>
        Transform Root { get; }
        void Activate(bool on);
        /// <summary>Gaze-dwell rigs need to know what is hovered to run their timer.</summary>
        void SetHoverTarget(object target);
    }
}
