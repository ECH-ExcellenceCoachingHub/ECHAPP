using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.XR;

namespace ECHLabs.Runtime.Interaction
{
    /// <summary>
    /// Native VR headsets (Meta Quest, Pico, PC VR via OpenXR): head tracking, right-hand laser
    /// pointer with trigger = select, thumbstick snap-turn and teleport between stations.
    /// Uses Input System XR bindings directly (no extra rig prefab required).
    /// </summary>
    public sealed class XRRig : MonoBehaviour, IPointerSource
    {
        public Camera cam;
        public Transform origin;        // play-space root (teleport/turn moves this)
        public Transform rightHand;
        public LineRenderer laser;
        public float snapTurnDegrees = 30f;

        InputAction handPos, handRot, trigger, stick;
        bool active, turnLatched;
        bool select;

        public LabMode Mode => LabMode.XR;
        public Camera Camera => cam;
        public Transform Root => origin ? origin : transform;
        public bool WorldSpaceUI => true;
        public Vector2? ScreenPosition => null;
        public bool SelectPressed => active && select;

        void Awake()
        {
            handPos = new InputAction("handPos", binding: "<XRController>{RightHand}/devicePosition");
            handRot = new InputAction("handRot", binding: "<XRController>{RightHand}/deviceRotation");
            trigger = new InputAction("trigger", InputActionType.Button, "<XRController>{RightHand}/triggerPressed");
            trigger.AddBinding("<XRController>{RightHand}/{PrimaryButton}");
            stick = new InputAction("stick", binding: "<XRController>{RightHand}/{Primary2DAxis}");
        }

        public bool TryGetRay(out Ray ray)
        {
            var src = rightHand && rightHand.gameObject.activeInHierarchy ? rightHand : cam.transform;
            ray = new Ray(src.position, src.forward);
            return active;
        }

        public void Activate(bool on)
        {
            active = on;
            if (on)
            {
                XRModeManager.StartStereo(XRModeManager.StereoKind.OpenXR);
                if (cam && !cam.GetComponent<TrackedPoseDriver>())
                {
                    var tpd = cam.gameObject.AddComponent<TrackedPoseDriver>();
                    tpd.trackingType = TrackedPoseDriver.TrackingType.RotationAndPosition;
                }
                handPos.Enable(); handRot.Enable(); trigger.Enable(); stick.Enable();
            }
            else
            {
                handPos.Disable(); handRot.Disable(); trigger.Disable(); stick.Disable();
                XRModeManager.StopStereo();
            }
            if (laser) laser.enabled = on;
            if (rightHand) rightHand.gameObject.SetActive(on);
        }

        public void SetHoverTarget(object target) { }

        void Update()
        {
            select = false;
            if (!active) return;
            if (rightHand)
            {
                rightHand.localPosition = handPos.ReadValue<Vector3>();
                rightHand.localRotation = handRot.ReadValue<Quaternion>();
            }
            select = trigger.WasPressedThisFrame();

            var s = stick.ReadValue<Vector2>();
            if (Mathf.Abs(s.x) > 0.7f && !turnLatched && origin)
            {
                origin.RotateAround(cam.transform.position, Vector3.up, Mathf.Sign(s.x) * snapTurnDegrees);
                turnLatched = true;
            }
            else if (Mathf.Abs(s.x) < 0.3f) turnLatched = false;

            if (laser && TryGetRay(out var ray))
            {
                float len = Physics.Raycast(ray, out var hit, 8f) ? hit.distance : 3f;
                laser.SetPosition(0, ray.origin);
                laser.SetPosition(1, ray.origin + ray.direction * len);
            }
        }

        /// <summary>Teleport so the student stands in front of a station (comfort: instant, with fade).</summary>
        public void TeleportTo(Vector3 standPoint, Vector3 lookAt)
        {
            if (!origin || !cam) return;
            Vector3 headOffset = cam.transform.position - origin.position;
            headOffset.y = 0;
            origin.position = standPoint - headOffset;
            Vector3 dir = lookAt - standPoint; dir.y = 0;
            if (dir.sqrMagnitude > 0.001f)
            {
                float yaw = Vector3.SignedAngle(Vector3.ProjectOnPlane(cam.transform.forward, Vector3.up), dir, Vector3.up);
                origin.RotateAround(cam.transform.position, Vector3.up, yaw);
            }
        }
    }
}
