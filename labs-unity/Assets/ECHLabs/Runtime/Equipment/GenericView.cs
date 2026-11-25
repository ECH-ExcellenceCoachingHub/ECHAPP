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
            connectedTo = null;
        }

        public void ConnectTo(Transform anchor) => connectedTo = anchor;

        /// <summary>Where this item goes when the state says it is connected / in place.</summary>
        Transform DefaultReceiver()
        {
            string want = Type switch
            {
                "resistor" => "breadboard", "funnel" => "burette", "slide" => "microscope", "patch_cable" => "network_switch",
                "battery" => "breadboard", "switch" => "breadboard", "variable_resistor" => "breadboard", "bulb" => "breadboard", "led" => "breadboard",
                "light_gate" => "ramp", _ => null,
            };
            if (want == null) return null;
            foreach (var v in Object.FindObjectsByType<EquipmentView>())
                if (v.Type == want) return v is BuretteView b && b.topPoint ? b.topPoint : v.Attach;
            return null;
        }

        /// <summary>Adopt the current pose as the rest pose (after an arrangement move).</summary>
        public void Rebase() { restPos = transform.position; restRot = transform.rotation; }

        public TMPro.TMP_Text display;
        public Renderer glow;
        public Light glowLight;
        public ParticleSystem bubbles;
        Vector3 baseScale = Vector3.one;
        bool scaleKnown;

        public override string ActionLabel(IntentType t)
        {
            switch (Type)
            {
                case "thermometer": if (t == IntentType.Connect) return "Put into…"; if (t == IntentType.Release) return "Take out"; break;
                case "ph_meter": if (t == IntentType.Connect) return "Dip into…"; if (t == IntentType.Release) return "Take out"; break;
                case "splint": if (t == IntentType.Grab) return "Hold at the mouth of…"; break;
                case "delivery_tube": if (t == IntentType.Grab) return "Fit bung into…"; if (t == IntentType.Connect) return "Lead tube into…"; break;
                case "switch": if (t == IntentType.Toggle) return Bool("closed") ? "Open (off)" : "Close (on)"; break;
                case "pondweed": if (t == IntentType.Inspect) return "Count bubbles"; break;
            }
            if (t == IntentType.Grab && placesSomewhere) return "Place in / on…";
            return base.ActionLabel(t);
        }

        public override bool TryGetValueRange(IntentType t, out ValueRange range)
        {
            if (t == IntentType.Rotate && Type == "variable_resistor")
            {
                range = new ValueRange { Min = 1, Max = (float)Num("maxOhms", 100), Step = 1, Default = (float)Num("ohms", 50), Unit = "Ω", Label = "Resistance", Live = true };
                return true;
            }
            return base.TryGetValueRange(t, out range);
        }

        static readonly string[] BoardParts = { "resistor", "battery", "switch", "variable_resistor", "bulb", "led" };

        /// <summary>Several components on one circuit board sit in a neat grid instead of on top of each other.</summary>
        Vector3 BoardOffset(Transform board)
        {
            if (World == null || System.Array.IndexOf(BoardParts, Type) < 0) return Vector3.zero;
            int index = 0, count = 0;
            foreach (var e in World.Definition.Equipment)
            {
                if (System.Array.IndexOf(BoardParts, e.Type) < 0 || !World.Bool(e.Id, "connected")) continue;
                if (e.Id == EquipmentId) index = count;
                count++;
            }
            int col = index % 4, row = index / 4;
            return board.right * ((col - 1.5f) * 0.065f) + board.forward * (row * 0.07f - 0.03f);
        }

        static string Fmt(double v, string f) => v.ToString(f, System.Globalization.CultureInfo.InvariantCulture);

        public override void Render(float dt)
        {
            base.Render(dt);
            if (display)
            {
                display.text = Type switch
                {
                    "thermometer" => Fmt(Num("reading", 20), "0.0") + " °C",
                    "ph_meter" => Bool("connected") ? "pH " + Fmt(Num("reading", 7), "0.00") : "pH --",
                    "light_gate" => Fmt(Num("reading"), "0.000") + " m/s",
                    "variable_resistor" => Fmt(Num("ohms"), "0") + " Ω",
                    "battery" => Fmt(Num("emfV"), "0.#") + " V",
                    _ => display.text,
                };
            }
            if (glow || glowLight)
            {
                float b = Mathf.Clamp01((float)Num("brightness"));
                if (glow) glow.enabled = b > 0.03f;
                if (glowLight) { glowLight.enabled = b > 0.03f; glowLight.intensity = 0.6f * b; }
            }
            if (bubbles) { var em = bubbles.emission; em.rateOverTime = (float)Num("bubblesPerMin") / 60f; }
            if (Type == "potato_cylinder")
            {
                if (!scaleKnown) { baseScale = transform.localScale; scaleKnown = true; }
                float k = (float)(Num("lengthMm", 30) / System.Math.Max(Num("startLengthMm", 30), 1));
                transform.localScale = new Vector3(baseScale.x * Mathf.Sqrt(k), baseScale.y * k, baseScale.z * Mathf.Sqrt(k));
            }
            // Placed in / dipped into / fitted to another piece of equipment (state decides, so resumes and demos agree).
            string host = Str("placedIn") ?? Str("in") ?? Str("from");
            if (host != null)
            {
                var hv = FindById(host);
                if (hv)
                {
                    var key = Str("placedIn") != null ? "placedIn" : Str("in") != null ? "in" : "from";
                    // Probes go down into the liquid; a bung sits in the mouth.
                    var dip = key == "in" ? Vector3.down * (Type == "thermometer" ? 0.08f : 0.07f) : key == "from" ? Vector3.down * 0.01f : Vector3.zero;
                    var p = hv.Attach.position + PlacementOffset(host, key) + dip;
                    transform.position = Vector3.Lerp(transform.position, p, dt * 7f);
                    transform.rotation = Quaternion.Slerp(transform.rotation, restRot, dt * 7f);
                    return;
                }
            }
            bool connected = Bool("connected") || Bool("inPlace") || Bool("onStage");
            if (connected && !connectedTo) connectedTo = DefaultReceiver();
            Vector3 targetPos = connected && connectedTo ? connectedTo.position + BoardOffset(connectedTo) : restPos;
            Quaternion targetRot = connected && connectedTo ? connectedTo.rotation : restRot;
            transform.position = Vector3.Lerp(transform.position, targetPos, dt * 7f);
            transform.rotation = Quaternion.Slerp(transform.rotation, targetRot, dt * 7f);
        }
    }
}
