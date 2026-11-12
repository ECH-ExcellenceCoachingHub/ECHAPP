using ECHLabs.Core;
using UnityEngine;

namespace ECHLabs.Runtime.Equipment
{
    /// <summary>Goggles / lab coat / gloves: hidden from the rack once worn (shown as a HUD badge instead).</summary>
    public sealed class WearableView : EquipmentView
    {
        public GameObject visual;
        public override string ActionLabel(IntentType t) => t == IntentType.Grab ? (Bool("worn") ? "Wearing" : "Put on") : t == IntentType.Release ? "Take off" : base.ActionLabel(t);

        protected override void OnBound(EquipmentSpec spec)
        {
            if (!visual) visual = transform.childCount > 0 ? transform.GetChild(0).gameObject : gameObject;
        }

        public override void Render(float dt)
        {
            base.Render(dt);
            bool worn = Bool("worn");
            var s = Mathf.MoveTowards(visual.transform.localScale.x, worn ? 0f : 1f, dt * 5f);
            visual.transform.localScale = Vector3.one * s;
            if (visual != gameObject) visual.SetActive(s > 0.001f);
        }
    }
}
