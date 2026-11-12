using ECHLabs.Core;
using UnityEngine;

namespace ECHLabs.Runtime.Equipment
{
    /// <summary>Simple pendulum: string length from state, angle from the physics model (exact period).</summary>
    public sealed class PendulumView : EquipmentView
    {
        public Transform pivot;
        public Transform stringTransform; // unit-length cylinder scaled along Y
        public Transform bob;
        float shownAngle;

        public override bool TryGetValueRange(IntentType t, out ValueRange range)
        {
            if (t == IntentType.Release || t == IntentType.Rotate)
            {
                range = new ValueRange { Min = 2, Max = 30, Step = 1, Default = 8, Unit = "°", Label = "Release angle", Live = false };
                return true;
            }
            return base.TryGetValueRange(t, out range);
        }

        public override string ActionLabel(IntentType t) => t == IntentType.Release ? "Pull aside & release" : t == IntentType.Grab ? "Stop the bob" : base.ActionLabel(t);

        public override void Render(float dt)
        {
            base.Render(dt);
            float L = (float)Num("lengthM", 1);
            if (stringTransform) { stringTransform.localScale = new Vector3(stringTransform.localScale.x, L * 0.5f, stringTransform.localScale.z); stringTransform.localPosition = new Vector3(0, -L * 0.5f, 0); }
            if (bob) bob.localPosition = new Vector3(0, -L, 0);
            float target = Bool("swinging") ? (float)Num("angleDeg") : Bool("held") ? (float)Num("amplitudeDeg") : 0f;
            shownAngle = Bool("swinging") ? target : Mathf.Lerp(shownAngle, target, dt * 6f);
            if (pivot) pivot.localRotation = Quaternion.Euler(0, 0, shownAngle);
        }
    }
}
