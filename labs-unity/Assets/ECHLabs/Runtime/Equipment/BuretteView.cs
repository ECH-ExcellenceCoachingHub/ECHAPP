using ECHLabs.Core;
using UnityEngine;

namespace ECHLabs.Runtime.Equipment
{
    /// <summary>
    /// Burette: liquid column, rotating stopcock, drips/stream from the tip. The scale texture on the
    /// tube is graduated 0.00 (top) → 50.00 (bottom) so the student reads it like the real thing.
    /// </summary>
    public sealed class BuretteView : EquipmentView
    {
        public LiquidVolume liquid;
        public Transform stopcock;
        public ParticleSystem drips;
        public Transform tip;
        [Tooltip("Top opening (funnel goes here)")] public Transform topPoint;
        public Color liquidColor = new Color(0.72f, 0.86f, 1f, 0.42f);

        float shownVolume;

        protected override void OnBound(EquipmentSpec spec)
        {
            if (!liquid) liquid = GetComponentInChildren<LiquidVolume>();
            if (liquid) liquid.capacityMl = (float)BuretteLogic.Capacity;
        }

        public override bool TryGetValueRange(IntentType t, out ValueRange range)
        {
            if (t == IntentType.Rotate)
            {
                range = new ValueRange { Min = 0, Max = 1, Step = 0.01f, Default = 0.3f, Unit = "", Label = "Tap opening (left = closed · right = fully open)", Live = true };
                return true;
            }
            return base.TryGetValueRange(t, out range);
        }

        public override string ActionLabel(IntentType t) => t == IntentType.Rotate ? "Turn the tap" : t == IntentType.Inspect ? "Read the scale" : base.ActionLabel(t);

        public override void Render(float dt)
        {
            base.Render(dt);
            float target = (float)Num("volumeMl");
            // Fast but not instant, so filling looks continuous.
            shownVolume = Mathf.MoveTowards(shownVolume, target, Mathf.Max(30f * dt, Mathf.Abs(target - shownVolume) * dt * 4f));
            if (liquid) liquid.Set(shownVolume, liquidColor);

            float open = (float)Num("tapOpen");
            if (stopcock) stopcock.localRotation = Quaternion.Euler(0, 0, Mathf.Lerp(90f, 0f, open));
            if (drips)
            {
                var em = drips.emission;
                bool flowing = open > 0 && target > 0;
                // Drop-wise below ~0.15 opening, a thin stream above.
                em.rateOverTime = flowing ? Mathf.Lerp(1.5f, 60f, Mathf.InverseLerp(0.02f, 0.5f, open)) : 0f;
                var main = drips.main;
                main.startSize = open > 0.15f ? 0.004f : 0.006f;
                if (flowing && !drips.isPlaying) drips.Play();
            }
        }
    }
}
