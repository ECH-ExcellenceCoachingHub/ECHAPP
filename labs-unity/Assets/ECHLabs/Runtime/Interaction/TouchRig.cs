using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.EnhancedTouch;
using Touch = UnityEngine.InputSystem.EnhancedTouch.Touch;

namespace ECHLabs.Runtime.Interaction
{
    /// <summary>
    /// Phones/tablets: tap to select, one-finger drag to orbit the current station, pinch to zoom.
    /// The CameraDirector flies to each step's equipment, so students rarely need to navigate.
    /// </summary>
    public sealed class TouchRig : MonoBehaviour, IPointerSource
    {
        public Camera cam;
        public CameraDirector director;
        public float orbitSpeed = 0.18f, tapMaxMove = 18f, tapMaxTime = 0.35f;

        bool active, tapped;
        Vector2 tapPos;
        float downTime;
        Vector2 downPos;
        bool dragging;
        float lastPinch = -1;

        public LabMode Mode => LabMode.Touch;
        public Camera Camera => cam;
        public Transform Root => cam ? cam.transform : transform;
        public bool WorldSpaceUI => false;
        public Vector2? ScreenPosition => tapPos;
        public bool SelectPressed => active && tapped;

        public bool TryGetRay(out Ray ray)
        {
            ray = default;
            if (!active || !cam) return false;
            ray = cam.ScreenPointToRay(tapPos);
            return true;
        }

        public void Activate(bool on)
        {
            active = on;
            if (on) EnhancedTouchSupport.Enable();
        }

        public void SetHoverTarget(object target) { }

        void Update()
        {
            tapped = false;
            if (!active || !cam) return;
            var touches = Touch.activeTouches;
            if (touches.Count == 1)
            {
                var t = touches[0];
                if (t.phase == UnityEngine.InputSystem.TouchPhase.Began) { downTime = Time.unscaledTime; downPos = t.screenPosition; dragging = false; }
                if ((t.screenPosition - downPos).magnitude > tapMaxMove) dragging = true;
                if (dragging && t.phase == UnityEngine.InputSystem.TouchPhase.Moved)
                {
                    director?.Cancel();
                    Orbit(t.delta);
                }
                if (t.phase == UnityEngine.InputSystem.TouchPhase.Ended && !dragging && Time.unscaledTime - downTime < tapMaxTime)
                {
                    tapped = true;
                    tapPos = t.screenPosition;
                }
                lastPinch = -1;
            }
            else if (touches.Count >= 2)
            {
                float d = Vector2.Distance(touches[0].screenPosition, touches[1].screenPosition);
                if (lastPinch > 0)
                {
                    director?.Cancel();
                    float delta = (d - lastPinch) / Screen.dpi * 0.25f;
                    var center = director ? director.OrbitCenter : cam.transform.position + cam.transform.forward;
                    float dist = Vector3.Distance(cam.transform.position, center);
                    float newDist = Mathf.Clamp(dist - delta, 0.25f, 3.5f);
                    cam.transform.position = center - cam.transform.forward * newDist;
                }
                lastPinch = d;
            }
            else lastPinch = -1;

            // Mouse fallback (Editor / Chromebooks) so the touch rig is testable on desktop.
            if (touches.Count == 0 && Mouse.current != null && Mouse.current.leftButton.wasReleasedThisFrame)
            {
                tapped = true;
                tapPos = Mouse.current.position.ReadValue();
            }
        }

        void Orbit(Vector2 delta)
        {
            var center = director ? director.OrbitCenter : cam.transform.position + cam.transform.forward;
            cam.transform.RotateAround(center, Vector3.up, delta.x * orbitSpeed);
            var right = cam.transform.right;
            float pitch = Vector3.SignedAngle(Vector3.ProjectOnPlane(cam.transform.forward, Vector3.up), cam.transform.forward, right);
            float dp = -delta.y * orbitSpeed;
            if (pitch + dp > -10 && pitch + dp < 70) cam.transform.RotateAround(center, right, dp);
            cam.transform.LookAt(center);
        }
    }
}
