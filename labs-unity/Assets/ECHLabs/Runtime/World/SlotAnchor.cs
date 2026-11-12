using UnityEngine;

namespace ECHLabs.Runtime.World
{
    /// <summary>
    /// A named place in a room where scenario equipment is spawned ("benchA.center", "shelf.1"…).
    /// Created by the SceneBuilder from Layouts/&lt;Room&gt;.json. Multi-item slots (shelves, PPE rack)
    /// spread items along their local X axis.
    /// </summary>
    public sealed class SlotAnchor : MonoBehaviour
    {
        public string slotId;
        [Tooltip("Spacing between items when several share this slot (m)")] public float spacing = 0.22f;
        [Tooltip("Camera viewpoint for this station (optional)")] public Transform viewpoint;
        int used;

        public Pose NextPose()
        {
            int i = used++;
            // 0, +1, -1, +2, -2 … centred around the anchor.
            int k = (i + 1) / 2 * (i % 2 == 0 ? -1 : 1);
            if (i == 0) k = 0;
            var pos = transform.TransformPoint(new Vector3(k * spacing, 0, 0));
            return new Pose(pos, transform.rotation);
        }

        public void ResetUsage() => used = 0;

        void OnDrawGizmos()
        {
            Gizmos.color = new Color(0.06f, 0.72f, 0.5f, 0.8f);
            Gizmos.DrawWireCube(transform.position + Vector3.up * 0.05f, new Vector3(0.2f, 0.1f, 0.2f));
        }
    }
}
