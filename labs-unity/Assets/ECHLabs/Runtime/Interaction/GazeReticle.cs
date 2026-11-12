using UnityEngine;

namespace ECHLabs.Runtime.Interaction
{
    /// <summary>Head-locked dot that grows into a filling ring while gazing at something selectable.</summary>
    public sealed class GazeReticle : MonoBehaviour
    {
        public Renderer ring;
        public float distance = 1.2f;
        static readonly int ProgressId = Shader.PropertyToID("_Progress");
        static readonly int ActiveId = Shader.PropertyToID("_Active");
        MaterialPropertyBlock mpb;

        public void SetProgress(float p, bool hovering)
        {
            if (!ring) return;
            mpb ??= new MaterialPropertyBlock();
            ring.GetPropertyBlock(mpb);
            mpb.SetFloat(ProgressId, p);
            mpb.SetFloat(ActiveId, hovering ? 1 : 0);
            ring.SetPropertyBlock(mpb);
            float s = hovering ? 0.05f : 0.018f;
            transform.localScale = Vector3.Lerp(transform.localScale, Vector3.one * s, Time.unscaledDeltaTime * 12f);
        }

        void LateUpdate() => transform.localPosition = new Vector3(0, 0, distance);
    }
}
