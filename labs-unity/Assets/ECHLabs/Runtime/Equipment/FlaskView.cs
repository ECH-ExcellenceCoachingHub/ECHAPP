using ECHLabs.Core;
using ECHLabs.Sim;
using UnityEngine;

namespace ECHLabs.Runtime.Equipment
{
    /// <summary>
    /// Conical flask: liquid colour follows the indicator and the live pH (continuous, so students
    /// see the transient pink flash that fades while swirling, then the permanent pale pink).
    /// Moves under the burette when placed on the white tile.
    /// </summary>
    public sealed class FlaskView : EquipmentView
    {
        public LiquidVolume liquid;
        public Color clearColor = new Color(0.8f, 0.9f, 1f, 0.3f);
        [Tooltip("Variable name of the chem.titration model driving the colour (auto-detected)")] public string titrationVariable;

        Vector3 restPosition;
        Quaternion restRotation;
        Color shown;
        float swirl;
        bool wasUnder;
        float flash;
        double lastBase;

        public override bool GrabPlacesSomewhere => true;
        public override string ActionLabel(IntentType t) => t == IntentType.Grab ? "Pick up & place" : t == IntentType.Rotate ? "Swirl" : base.ActionLabel(t);

        protected override void OnBound(EquipmentSpec spec)
        {
            if (!liquid) liquid = GetComponentInChildren<LiquidVolume>();
            restPosition = transform.position;
            restRotation = transform.rotation;
            shown = clearColor;
            if (string.IsNullOrEmpty(titrationVariable))
                foreach (var kv in World.Definition.Variables)
                    if (kv.Value.Model == "chem.titration" && kv.Value.Inputs.TryGetValue("flask", out var f) && f == spec.Id) titrationVariable = kv.Key;
        }

        public override void Render(float dt)
        {
            base.Render(dt);
            Color target = clearColor;
            if (!string.IsNullOrEmpty(titrationVariable) && World.Variables.TryGetValue(titrationVariable, out var v) && v.TryGetValue("indicator", out var indObj) && indObj is string ind
                && Chemistry.Indicators.TryGetValue(ind, out var info))
            {
                float c = (float)World.Var(titrationVariable, "colorIndex");
                // Local excess where a drop lands: brief flash that swirls away.
                double baseNow = Num("baseAddedMl");
                if (baseNow > lastBase + 1e-4) flash = Mathf.Min(flash + (float)(baseNow - lastBase) * 3f, 1f);
                lastBase = baseNow;
                flash = Mathf.MoveTowards(flash, 0, dt * 1.6f);
                float pH = (float)World.Var(titrationVariable, "pH");
                float nearEnd = Mathf.InverseLerp(4f, 7.5f, pH);
                float display = Mathf.Max(c, flash * nearEnd * 0.8f);
                target = Color.Lerp(ToColor(info.FromRgba), ToColor(info.ToRgba), display);
            }
            shown = Color.Lerp(shown, target, dt * 5f);
            if (liquid) liquid.Set((float)Num("volumeMl"), shown);

            // Placement under the burette (the white tile's attach point is resolved by the session).
            // Placement follows the lab state (works for clicks, autoplay and resumed attempts).
            bool under = Bool("underBurette");
            if (under != wasUnder) { wasUnder = under; if (liquid) liquid.Splash(0.6f); }
            if (under && placedOn == null) placedOn = FindTileAnchor();
            Vector3 targetPos = under && placedOn ? placedOn.position : restPosition;
            transform.position = Vector3.Lerp(transform.position, targetPos, dt * 6f);

            // Gentle swirl while base flows in: a bounded wobble around the upright pose (never accumulates).
            swirl = Mathf.MoveTowards(swirl, flash > 0.01f ? 1f : 0f, dt * 2f);
            var wobble = Quaternion.Euler(Mathf.Sin(Time.time * 9f) * 4f * swirl, 0, Mathf.Cos(Time.time * 9f) * 4f * swirl);
            transform.rotation = Quaternion.Slerp(transform.rotation, restRotation * wobble, dt * 10f);
        }

        Transform placedOn;

        public void PlaceAt(Transform anchor) => placedOn = anchor;

        static Transform FindTileAnchor()
        {
            foreach (var v in Object.FindObjectsByType<EquipmentView>())
                if (v.Type == "white_tile") return v.Attach;
            return null;
        }

        static Color ToColor(float[] rgba) => new Color(rgba[0], rgba[1], rgba[2], rgba[3]);
    }
}
