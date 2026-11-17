using UnityEngine;

namespace ECHLabs.Runtime.Interaction
{
    /// <summary>
    /// Cinematic camera moves for flat-screen modes: glides to each step's focus equipment,
    /// close-up "inspect" shots at eye level (e.g. reading a burette meniscus without parallax).
    /// The student can always take over (look/orbit); the director yields until the next step.
    /// </summary>
    public sealed class CameraDirector : MonoBehaviour
    {
        public Transform cameraTransform;
        public float glideTime = 1.1f;
        public float defaultDistance = 0.9f;
        public float minHeight = 0.9f, maxHeight = 2.2f;

        Vector3 fromPos, toPos;
        Quaternion fromRot, toRot;
        float t = 1f;
        public Vector3 OrbitCenter { get; private set; } = new Vector3(0, 1f, 0);

        /// <summary>Temporary lean toward far equipment (requested by the hands each frame).</summary>
        public Vector3 LeanRequest;
        public Vector3 Lean { get; private set; }
        Transform leanedCamera;
        public bool Busy => t < 1f;

        public void FocusOn(Vector3 target, float distance = -1f, bool eyeLevel = false, Vector3? front = null)
        {
            if (!cameraTransform) return;
            if (distance <= 0) distance = defaultDistance;
            OrbitCenter = target;
            Vector3 flatDir = front ?? (cameraTransform.position - target);
            flatDir.y = 0;
            if (flatDir.sqrMagnitude < 0.01f) flatDir = -Vector3.forward;
            flatDir.Normalize();
            float height = eyeLevel ? 0f : distance * 0.45f;
            Vector3 pos = target + flatDir * distance + Vector3.up * height;
            pos.y = Mathf.Clamp(pos.y, eyeLevel ? target.y : minHeight, maxHeight);
            GlideTo(pos, Quaternion.LookRotation(target - pos, Vector3.up));
        }

        public void GlideTo(Vector3 pos, Quaternion rot)
        {
            fromPos = cameraTransform.position;
            fromRot = cameraTransform.rotation;
            toPos = pos;
            toRot = rot;
            t = 0f;
        }

        public void Cancel() => t = 1f;

        /// <summary>Walking moves the point the student orbits around along with them.</summary>
        public void ShiftOrbit(Vector3 delta) => OrbitCenter += delta;

        /// <summary>Frame a whole station (several pieces of equipment) from a given side.</summary>
        public void FocusOnArea(Bounds area, Vector3 front)
        {
            float size = Mathf.Max(area.extents.x, area.extents.z, 0.25f);
            FocusOn(area.center, Mathf.Clamp(size * 2.1f + 0.35f, 0.7f, 2.6f), false, front);
        }

        void LateUpdate()
        {
            // The lean is additive: take last frame's off, run the glide, then put the new one on.
            if (leanedCamera) leanedCamera.position -= Lean;
            if (leanedCamera != cameraTransform) { Lean = Vector3.zero; leanedCamera = cameraTransform; }
            if (!cameraTransform) return;
            if (t < 1f)
            {
                t = Mathf.Min(1f, t + Time.deltaTime / glideTime);
                float e = t * t * (3f - 2f * t); // smoothstep
                cameraTransform.SetPositionAndRotation(Vector3.Lerp(fromPos, toPos, e), Quaternion.Slerp(fromRot, toRot, e));
            }
            Lean = Vector3.Lerp(Lean, LeanRequest, 1f - Mathf.Exp(-Time.deltaTime * 4f));
            if (Lean.sqrMagnitude < 1e-8f && LeanRequest.sqrMagnitude < 1e-8f) Lean = Vector3.zero;
            cameraTransform.position += Lean;
        }
    }
}
