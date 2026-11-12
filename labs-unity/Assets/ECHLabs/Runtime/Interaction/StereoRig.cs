using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.XR;

namespace ECHLabs.Runtime.Interaction
{
    /// <summary>
    /// Smartphone VR viewers (Cardboard-style). With the Google Cardboard XR plugin, Unity renders
    /// stereo with lens distortion and head tracking via XR. Without it (or if XR fails), this rig
    /// falls back to its own side-by-side stereo cameras + gyroscope head tracking.
    /// Selection: 1.2 s gaze dwell on equipment/buttons, or the viewer's button (screen tap).
    /// </summary>
    public sealed class StereoRig : MonoBehaviour, IPointerSource
    {
        public Camera cam;               // centre eye (head)
        public Transform head;           // cam.transform's parent pivot for gyro
        public GazeReticle reticle;
        public float dwellSeconds = 1.2f;
        public float ipd = 0.064f;

        bool active, xrStereo, fallbackStereo;
        Camera leftEye, rightEye;
        object hoverTarget;
        float dwell;
        bool selectThisFrame;
        Quaternion gyroOffset = Quaternion.identity;

        public LabMode Mode => LabMode.Cardboard;
        public Camera Camera => cam;
        public Transform Root => head ? head.parent ?? head : cam.transform;
        public bool WorldSpaceUI => true;
        public Vector2? ScreenPosition => null;
        public bool SelectPressed => active && selectThisFrame;

        public bool TryGetRay(out Ray ray)
        {
            ray = new Ray(cam.transform.position, cam.transform.forward);
            return active && cam;
        }

        public void Activate(bool on)
        {
            active = on;
            if (reticle) reticle.gameObject.SetActive(on);
            if (on)
            {
                xrStereo = XRModeManager.StartStereo(XRModeManager.StereoKind.Cardboard);
                if (!xrStereo) EnableFallbackStereo(true);
                Screen.sleepTimeout = SleepTimeout.NeverSleep;
                Screen.orientation = ScreenOrientation.LandscapeLeft;
            }
            else
            {
                if (xrStereo) XRModeManager.StopStereo();
                EnableFallbackStereo(false);
                xrStereo = false;
                Screen.orientation = ScreenOrientation.AutoRotation;
            }
        }

        public void SetHoverTarget(object target)
        {
            if (!Equals(target, hoverTarget)) { hoverTarget = target; dwell = 0; }
        }

        void EnableFallbackStereo(bool on)
        {
            fallbackStereo = on;
            if (on)
            {
                if (AttitudeSensor.current != null) InputSystem.EnableDevice(AttitudeSensor.current);
                if (!leftEye) leftEye = MakeEye("LeftEye", -ipd / 2, new Rect(0, 0, 0.5f, 1));
                if (!rightEye) rightEye = MakeEye("RightEye", ipd / 2, new Rect(0.5f, 0, 0.5f, 1));
                leftEye.gameObject.SetActive(true);
                rightEye.gameObject.SetActive(true);
                cam.enabled = false; // centre camera still drives rays/HUD position
            }
            else
            {
                if (leftEye) leftEye.gameObject.SetActive(false);
                if (rightEye) rightEye.gameObject.SetActive(false);
                if (cam) cam.enabled = true;
            }
        }

        Camera MakeEye(string n, float x, Rect rect)
        {
            var go = new GameObject(n);
            go.transform.SetParent(cam.transform, false);
            go.transform.localPosition = new Vector3(x, 0, 0);
            var c = go.AddComponent<Camera>();
            c.CopyFrom(cam);
            c.rect = rect;
            c.fieldOfView = 80;
            c.stereoTargetEye = StereoTargetEyeMask.None;
            return c;
        }

        void Update()
        {
            selectThisFrame = false;
            if (!active || !cam) return;

            if (fallbackStereo && AttitudeSensor.current != null)
            {
                // Device attitude (right-handed, z-up) → Unity camera (left-handed, y-up).
                var q = AttitudeSensor.current.attitude.ReadValue();
                var rot = Quaternion.Euler(90, 0, 0) * new Quaternion(q.x, q.y, -q.z, -q.w);
                (head ? head : cam.transform).localRotation = gyroOffset * rot;
            }

            // Viewer button = touch anywhere (Cardboard trigger), or Enter in the editor.
            bool trigger = (Touchscreen.current != null && Touchscreen.current.primaryTouch.press.wasPressedThisFrame)
                           || (Keyboard.current != null && Keyboard.current.enterKey.wasPressedThisFrame);
            if (trigger) { selectThisFrame = true; dwell = 0; }
            else if (hoverTarget != null)
            {
                dwell += Time.unscaledDeltaTime;
                if (dwell >= dwellSeconds) { selectThisFrame = true; dwell = -0.6f; } // short cooldown
            }
            else dwell = 0;
            if (reticle) reticle.SetProgress(hoverTarget != null ? Mathf.Clamp01(dwell / dwellSeconds) : 0, hoverTarget != null);
        }

        /// <summary>Re-centre: the current gaze direction becomes "forward".</summary>
        public void Recenter()
        {
            var t = head ? head : cam.transform;
            gyroOffset = Quaternion.Euler(0, -t.localEulerAngles.y, 0) * gyroOffset;
        }
    }
}
