using UnityEngine;
using UnityEngine.InputSystem;

namespace ECHLabs.Runtime.Interaction
{
    /// <summary>
    /// Desktop / web / Windows: mouse pointer + click; hold right mouse (or Alt) to look around;
    /// WASD/arrow keys to walk; mouse wheel to lean in. The CameraDirector frames each step.
    /// </summary>
    public sealed class DesktopRig : MonoBehaviour, IPointerSource
    {
        public Camera cam;
        public CameraDirector director;
        public float lookSpeed = 0.12f, moveSpeed = 1.6f, eyeHeight = 1.62f;
        public Bounds walkBounds = new Bounds(Vector3.zero, new Vector3(9, 4, 7));

        float yaw, pitch;
        bool active;

        public LabMode Mode => LabMode.Desktop;
        public Camera Camera => cam;
        public Transform Root => cam ? cam.transform : transform;
        public bool WorldSpaceUI => false;
        public Vector2? ScreenPosition => Mouse.current != null ? Mouse.current.position.ReadValue() : (Vector2?)null;
        public bool SelectPressed => active && Mouse.current != null && Mouse.current.leftButton.wasPressedThisFrame;

        public bool TryGetRay(out Ray ray)
        {
            ray = default;
            if (!active || !cam || Mouse.current == null) return false;
            ray = cam.ScreenPointToRay(Mouse.current.position.ReadValue());
            return true;
        }

        public void Activate(bool on)
        {
            active = on;
            if (on && cam)
            {
                var e = cam.transform.eulerAngles;
                yaw = e.y;
                pitch = e.x > 180 ? e.x - 360 : e.x;
            }
        }

        public void SetHoverTarget(object target) { }

        void Update()
        {
            if (!active || !cam) return;
            var mouse = Mouse.current;
            var kb = Keyboard.current;
            bool looking = mouse != null && (mouse.rightButton.isPressed || (kb != null && kb.leftAltKey.isPressed));
            if (looking)
            {
                director?.Cancel();
                var d = mouse.delta.ReadValue();
                yaw += d.x * lookSpeed;
                pitch = Mathf.Clamp(pitch - d.y * lookSpeed, -80, 80);
                cam.transform.rotation = Quaternion.Euler(pitch, yaw, 0);
            }
            else if (director && !director.Busy)
            {
                var e = cam.transform.eulerAngles;
                yaw = e.y;
                pitch = e.x > 180 ? e.x - 360 : e.x;
            }

            if (kb != null)
            {
                Vector3 move = Vector3.zero;
                if (kb.wKey.isPressed || kb.upArrowKey.isPressed) move += Vector3.forward;
                if (kb.sKey.isPressed || kb.downArrowKey.isPressed) move += Vector3.back;
                if (kb.aKey.isPressed || kb.leftArrowKey.isPressed) move += Vector3.left;
                if (kb.dKey.isPressed || kb.rightArrowKey.isPressed) move += Vector3.right;
                if (move != Vector3.zero)
                {
                    director?.Cancel();
                    var fwd = Quaternion.Euler(0, yaw, 0);
                    var p = cam.transform.position + fwd * move.normalized * moveSpeed * Time.deltaTime;
                    p.y = Mathf.MoveTowards(p.y, eyeHeight, Time.deltaTime * 1.5f);
                    cam.transform.position = ClampToBounds(p);
                }
            }

            if (mouse != null)
            {
                float scroll = mouse.scroll.ReadValue().y;
                if (Mathf.Abs(scroll) > 0.01f)
                {
                    director?.Cancel();
                    cam.transform.position = ClampToBounds(cam.transform.position + cam.transform.forward * Mathf.Sign(scroll) * 0.12f);
                }
            }
        }

        Vector3 ClampToBounds(Vector3 p)
        {
            var min = walkBounds.min; var max = walkBounds.max;
            return new Vector3(Mathf.Clamp(p.x, min.x, max.x), Mathf.Clamp(p.y, 0.6f, 2.4f), Mathf.Clamp(p.z, min.z, max.z));
        }
    }
}
