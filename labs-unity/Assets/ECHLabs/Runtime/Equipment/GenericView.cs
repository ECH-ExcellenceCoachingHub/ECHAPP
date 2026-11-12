using ECHLabs.Core;
using UnityEngine;

namespace ECHLabs.Runtime.Equipment
{
    /// <summary>
    /// Equipment with no special animation (stands, tiles, rules, dropper bottles, connectables).
    /// Connectables snap to their receiver's attach point when connected.
    /// </summary>
    public sealed class GenericView : EquipmentView
    {
        public bool placesSomewhere;
        Vector3 restPos;
        Quaternion restRot;
        Transform connectedTo;

        public override bool GrabPlacesSomewhere => placesSomewhere;

        protected override void OnBound(EquipmentSpec spec)
        {
            restPos = transform.position;
            restRot = transform.rotation;
        }

        public void ConnectTo(Transform anchor) => connectedTo = anchor;

        /// <summary>Where this item goes when the state says it is connected / in place.</summary>
        Transform DefaultReceiver()
        {
            string want = Type switch { "resistor" => "breadboard", "funnel" => "burette", "slide" => "microscope", "patch_cable" => "network_switch", _ => null };
            if (want == null) return null;
            foreach (var v in Object.FindObjectsByType<EquipmentView>())
                if (v.Type == want) return v is BuretteView b && b.topPoint ? b.topPoint : v.Attach;
            return null;
        }

        /// <summary>Adopt the current pose as the rest pose (after an arrangement move).</summary>
        public void Rebase() { restPos = transform.position; restRot = transform.rotation; }

        public override void Render(float dt)
        {
            base.Render(dt);
            bool connected = Bool("connected") || Bool("inPlace") || Bool("onStage");
            if (connected && !connectedTo) connectedTo = DefaultReceiver();
            Vector3 targetPos = connected && connectedTo ? connectedTo.position : restPos;
            Quaternion targetRot = connected && connectedTo ? connectedTo.rotation : restRot;
            transform.position = Vector3.Lerp(transform.position, targetPos, dt * 7f);
            transform.rotation = Quaternion.Slerp(transform.rotation, targetRot, dt * 7f);
        }
    }
}
