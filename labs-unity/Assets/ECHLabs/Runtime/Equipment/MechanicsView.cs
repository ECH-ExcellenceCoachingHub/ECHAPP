using System.Globalization;
using ECHLabs.Core;
using TMPro;
using UnityEngine;

namespace ECHLabs.Runtime.Equipment
{
    /// <summary>
    /// Equipment that moves with its state: spring + masses, ramp + trolley, the optical bench
    /// (lens and screen slide along the light box's axis at the real distances) and the desk lamp.
    /// The science is in ECHLabs.Core; this only shows it.
    /// </summary>
    public sealed class MechanicsView : EquipmentView
    {
        [Header("Spring")] public Transform coil; public Transform hanger; public float coilRestLength = 0.10f;
        [Header("Ramp")] public Transform rampPivot; public Transform trolley; public float rampLength = 1f;
        [Header("Optics")] public Renderer image; public Transform imageScale;
        [Header("Lamp")] public Light lampLight; public Renderer lampGlow;
        public TMP_Text display;

        Vector3 home;
        Vector3 hangerHome;
        float shownExtension;

        protected override void OnBound(EquipmentSpec spec)
        {
            home = transform.position;
            if (hanger) hangerHome = hanger.localPosition;
            shownExtension = 0;
        }

        public override bool TryGetValueRange(IntentType t, out ValueRange range)
        {
            range = default;
            if (t != IntentType.Rotate) return false;
            switch (Type)
            {
                case "spring": range = new ValueRange { Min = 0, Max = 1000, Step = 50, Default = (float)Num("massG") + 100, Unit = "g", Label = "Total mass hanging", Live = false }; return true;
                case "ramp": range = new ValueRange { Min = 0, Max = 40, Step = 1, Default = (float)Num("angleDeg", 10), Unit = "°", Label = "Ramp angle", Live = true }; return true;
                case "convex_lens": range = new ValueRange { Min = 5, Max = 100, Step = 1, Default = (float)Num("objectDistanceCm", 30), Unit = "cm", Label = "Object distance u", Live = true }; return true;
                case "screen": range = new ValueRange { Min = 5, Max = 150, Step = 0.5f, Default = (float)Num("distanceCm", 40), Unit = "cm", Label = "Screen distance v", Live = true }; return true;
                case "lamp": range = new ValueRange { Min = 5, Max = 60, Step = 1, Default = (float)Num("distanceCm", 20), Unit = "cm", Label = "Lamp distance", Live = true }; return true;
            }
            return false;
        }

        public override string ActionLabel(IntentType t)
        {
            switch (Type)
            {
                case "spring": if (t == IntentType.Rotate) return "Hang masses"; if (t == IntentType.Release) return "Remove masses"; break;
                case "ramp": if (t == IntentType.Rotate) return "Set angle"; if (t == IntentType.Release) return "Let the trolley go"; if (t == IntentType.Grab) return "Back to the top"; break;
                case "convex_lens": if (t == IntentType.Rotate) return "Move the object"; break;
                case "screen": if (t == IntentType.Rotate) return "Move the screen"; break;
                case "lamp": if (t == IntentType.Rotate) return "Move the lamp"; if (t == IntentType.Toggle) return Bool("on") ? "Switch off" : "Switch on"; break;
                case "light_box": if (t == IntentType.Toggle) return Bool("on") ? "Switch off" : "Switch on"; break;
            }
            return base.ActionLabel(t);
        }

        static string F(double v, string f) => v.ToString(f, CultureInfo.InvariantCulture);

        public override void Render(float dt)
        {
            base.Render(dt);
            switch (Type)
            {
                case "spring":
                    {
                        float ext = (float)Num("extensionCm") / 100f;
                        shownExtension = Mathf.Lerp(shownExtension, ext, dt * 6f);
                        if (coil) coil.localScale = new Vector3(1, (coilRestLength + shownExtension) / coilRestLength, 1);
                        if (hanger) hanger.localPosition = hangerHome + Vector3.down * shownExtension;
                        if (hanger) for (int i = 0; i < hanger.childCount; i++) hanger.GetChild(i).gameObject.SetActive(i < Mathf.RoundToInt((float)Num("massG") / 100f) || hanger.GetChild(i).name == "Hook");
                        if (display) display.text = F(Num("massG"), "0") + " g";
                        break;
                    }
                case "ramp":
                    {
                        if (rampPivot) rampPivot.localRotation = Quaternion.Slerp(rampPivot.localRotation, Quaternion.Euler(0, 0, (float)Num("angleDeg")), dt * 6f);
                        if (trolley)
                        {
                            float L = (float)Num("lengthM", 1);
                            float u = Mathf.Clamp01((float)(Num("distanceM") / System.Math.Max(L, 0.01)));
                            trolley.localPosition = new Vector3(Mathf.Lerp(rampLength * 0.45f, -rampLength * 0.45f, u), trolley.localPosition.y, trolley.localPosition.z);
                        }
                        break;
                    }
                case "convex_lens":
                case "screen":
                    {
                        // The optical bench: light box → lens at u → screen at v, along the light box's axis.
                        var box = FindFirst("light_box");
                        var lens = Type == "screen" ? FindFirst("convex_lens") : this;
                        if (box)
                        {
                            Vector3 axis = OpticalAxis(box.transform);
                            Vector3 lensPos = box.transform.position + axis * (float)(World.Num(lens ? lens.EquipmentId : EquipmentId, "objectDistanceCm", 30) / 100.0);
                            Vector3 target = Type == "convex_lens" ? lensPos : lensPos + axis * (float)(Num("distanceCm", 40) / 100.0);
                            target.y = home.y;
                            transform.position = Vector3.Lerp(transform.position, target, dt * 8f);
                        }
                        if (Type == "screen" && image)
                        {
                            float sharp = (float)Num("sharpness");
                            image.enabled = sharp > 0.02f;
                            var c = Color.Lerp(new Color(1f, 0.85f, 0.4f, 0.15f), new Color(1f, 0.9f, 0.5f, 1f), sharp);
                            image.material.SetColor("_BaseColor", c);
                            image.material.SetColor("_EmissionColor", c * sharp * 1.5f);
                            if (imageScale) { float h = Mathf.Max(0.002f, (float)Num("imageHeightCm") / 100f); imageScale.localScale = new Vector3(1 + (1 - sharp) * 2f, -h / 0.02f, 1); } // inverted image
                        }
                        break;
                    }
                case "lamp":
                    {
                        bool on = Bool("on");
                        if (lampLight) lampLight.enabled = on;
                        if (lampGlow) lampGlow.enabled = on;
                        // The lamp slides towards the pondweed (or stays put if there is none).
                        var weed = FindFirst("pondweed");
                        if (weed)
                        {
                            Vector3 dir = (home - weed.transform.position); dir.y = 0;
                            if (dir.sqrMagnitude < 1e-4f) dir = Vector3.left;
                            Vector3 target = weed.transform.position + dir.normalized * (float)(Num("distanceCm", 20) / 100.0);
                            target.y = home.y;
                            transform.position = Vector3.Lerp(transform.position, target, dt * 6f);
                        }
                        if (display) display.text = F(Num("distanceCm", 20), "0") + " cm";
                        break;
                    }
                case "light_box":
                    if (lampLight) lampLight.enabled = Bool("on");
                    if (lampGlow) lampGlow.enabled = Bool("on");
                    break;
            }
        }

        static Vector3 OpticalAxis(Transform box)
        {
            // The rail runs along the bench: pick the horizontal direction that still has worktop under it 60 cm away.
            foreach (var dir in new[] { box.right, -box.right, box.forward, -box.forward })
            {
                var from = box.position + dir * 0.6f + Vector3.up * 0.3f;
                if (UnityEngine.Physics.Raycast(from, Vector3.down, out var hit, 0.6f) && Mathf.Abs(hit.point.y - box.position.y) < 0.05f) return dir;
            }
            return box.right;
        }

        EquipmentView FindFirst(string type)
        {
            if (World == null) return null;
            foreach (var e in World.OfType(type)) { var v = FindById(e.Id); if (v) return v; }
            return null;
        }
    }
}
