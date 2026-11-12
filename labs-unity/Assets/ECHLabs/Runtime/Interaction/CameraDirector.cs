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

        void LateUpdate()
        {
            if (t >= 1f || !cameraTransform) return;
            t = Mathf.Min(1f, t + Time.deltaTime / glideTime);
            float e = t * t * (3f - 2f * t); // smoothstep
            cameraTransform.SetPositionAndRotation(Vector3.Lerp(fromPos, toPos, e), Quaternion.Slerp(fromRot, toRot, e));
        }
    }
}
