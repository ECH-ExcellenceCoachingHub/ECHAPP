using UnityEngine;

namespace ECHLabs.Runtime.Equipment
{
    /// <summary>Sagging test lead / patch cable from this equipment to whatever it is connected to.</summary>
    [RequireComponent(typeof(LineRenderer))]
    public sealed class CableRenderer : MonoBehaviour
    {
        public Transform plug;            // where the cable leaves this equipment
        public float sag = 0.08f;
        public int points = 20;
        Transform target;
        LineRenderer line;

        void Awake()
        {
            line = GetComponent<LineRenderer>();
            line.positionCount = 0;
            line.useWorldSpace = true;
        }

        public void ConnectTo(Transform t)
        {
            target = t;
            if (!t) line.positionCount = 0;
        }

        void LateUpdate()
        {
            if (!target) return;
            Vector3 a = plug ? plug.position : transform.position, b = target.position;
            line.positionCount = points;
            float drop = sag + Vector3.Distance(a, b) * 0.15f;
            for (int i = 0; i < points; i++)
            {
                float t = i / (points - 1f);
                var p = Vector3.Lerp(a, b, t);
                p.y -= Mathf.Sin(t * Mathf.PI) * drop; // catenary-like sag
                line.SetPosition(i, p);
            }
        }
    }
}
