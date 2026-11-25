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

        float shownVolume = -1, swirlBoost;

        /// <summary>Student swirls the flask: a strong circular motion that mixes and fades the pink flash.</summary>
        public void Swirl() { swirlBoost = 1.7f; if (liquid) liquid.Splash(0.8f); }

        public override bool GrabPlacesSomewhere => true;
        public override string ActionLabel(IntentType t) => t == IntentType.Grab ? "Pick up & place" : t == IntentType.Rotate ? "Swirl" : base.ActionLabel(t);

        protected override void OnBound(EquipmentSpec spec)
        {
            if (!liquid) liquid = GetComponentInChildren<LiquidVolume>();
            restPosition = transform.position;
            restRotation = transform.rotation;
            shown = clearColor;
            shownVolume = -1;
            placedOn = null;
            wasUnder = false;
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
            else if (TryStateColor(out var sc)) target = sc;
            shown = Color.Lerp(shown, target, dt * 5f);
            // Level rises smoothly with what is poured in (a stream takes a moment to fill).
            float vol = (float)Num("volumeMl");
            if (shownVolume < 0) shownVolume = vol;
            shownVolume = Mathf.MoveTowards(shownVolume, vol, Mathf.Max(Mathf.Abs(vol - shownVolume) / 1.1f, 1.5f) * dt);
            if (liquid) liquid.Set(shownVolume, shown);

            // Placement under the burette (the white tile's attach point is resolved by the session).
            // Placement follows the lab state (works for clicks, autoplay and resumed attempts).
            bool under = Bool("underBurette");
            if (under != wasUnder) { wasUnder = under; if (liquid) liquid.Splash(0.6f); }
            if (under && placedOn == null) placedOn = FindTileAnchor();
            var host = !under ? FindById(Str("placedIn")) : null;
            Vector3 targetPos = under && placedOn ? placedOn.position : host ? host.Attach.position : restPosition;

            // Gentle swirl while base flows in: a bounded wobble around the upright pose (never accumulates).
            swirlBoost = Mathf.Max(0, swirlBoost - dt);
            swirl = Mathf.MoveTowards(swirl, swirlBoost > 0 ? 2.2f : flash > 0.01f ? 1f : 0f, dt * 3f);
            if (swirlBoost > 0 && liquid) liquid.Splash(0.35f);
            var wobble = Quaternion.Euler(Mathf.Sin(Time.time * 9f) * 4f * swirl, 0, Mathf.Cos(Time.time * 9f) * 4f * swirl);
            // A swirl also moves the flask in a small circle, like a real wrist motion.
            if (swirlBoost > 0) targetPos += new Vector3(Mathf.Sin(Time.time * 9f), 0, Mathf.Cos(Time.time * 9f)) * 0.006f * Mathf.Min(swirl, 1f);
            transform.position = Vector3.Lerp(transform.position, targetPos, dt * (swirlBoost > 0 ? 12f : 6f));
            transform.rotation = Quaternion.Slerp(transform.rotation, restRotation * wobble, dt * 10f);
        }

        Transform placedOn;

        public void PlaceAt(Transform anchor) => placedOn = anchor;

        public override Vector3 SettledFocusPosition
        {
            get
            {
                bool under = Bool("underBurette");
                var anchor = under ? (placedOn ? placedOn : FindTileAnchor()) : null;
                var dest = anchor ? anchor.position : restPosition;
                return FocusPosition - transform.position + dest;
            }
        }

        static Transform FindTileAnchor()
        {
            foreach (var v in Object.FindObjectsByType<EquipmentView>())
                if (v.Type == "white_tile") return v.Attach;
            return null;
        }

        static Color ToColor(float[] rgba) => new Color(rgba[0], rgba[1], rgba[2], rgba[3]);
    }
}
