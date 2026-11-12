using ECHLabs.Core;
using UnityEngine;

namespace ECHLabs.Runtime.Equipment
{
    /// <summary>Reagent bottle, beaker, pipette: liquid level + tilt animation while pouring.</summary>
    public class ContainerView : EquipmentView
    {
        public LiquidVolume liquid;
        public Color liquidColor = new Color(0.78f, 0.89f, 1f, 0.35f);
        [Tooltip("Pivot rotated to show pouring")] public Transform tiltPivot;
        float pourAnim;
        Quaternion restRotation;

        protected override void OnBound(EquipmentSpec spec)
        {
            if (!liquid) liquid = GetComponentInChildren<LiquidVolume>();
            if (!tiltPivot) tiltPivot = transform;
            restRotation = tiltPivot.localRotation;
        }

        /// <summary>Plays a short tilt-and-return animation (the logic transfer is instant).</summary>
        public void PlayPour() => pourAnim = 1.2f;

        public override void Render(float dt)
        {
            base.Render(dt);
            if (liquid) liquid.Set((float)Num("volumeMl"), liquidColor);
            if (pourAnim > 0)
            {
                pourAnim -= dt;
                float t = Mathf.Sin(Mathf.Clamp01(pourAnim / 1.2f) * Mathf.PI); // 0→1→0
                tiltPivot.localRotation = restRotation * Quaternion.Euler(0, 0, -95f * t);
            }
            else tiltPivot.localRotation = Quaternion.Slerp(tiltPivot.localRotation, restRotation, dt * 8f);
        }
    }
}
