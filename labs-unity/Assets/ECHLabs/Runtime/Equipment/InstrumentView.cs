using System.Globalization;
using ECHLabs.Core;
using TMPro;
using UnityEngine;

namespace ECHLabs.Runtime.Equipment
{
    /// <summary>
    /// Anything with a display or a knob: ammeter, voltmeter, power supply, stopwatch, microscope,
    /// Bunsen burner, terminals. Shows the live value on a TextMeshPro screen and turns its knob.
    /// </summary>
    public sealed class InstrumentView : EquipmentView
    {
        public TMP_Text display;
        public Transform knob;
        public float knobDegrees = 270f;
        public Light statusLight;
        public ParticleSystem flame;
        bool cableLinked;

        protected override void OnBound(EquipmentSpec spec) => cableLinked = false;

        /// <summary>Bunsen burner alight (for the flame roar).</summary>
        public bool Burning => flame && Type == "bunsen_burner" && Bool("lit");
        public float AirHole => (float)Num("airHole");

        public override bool TryGetValueRange(IntentType t, out ValueRange range)
        {
            range = default;
            if (t == IntentType.Rotate)
            {
                switch (Type)
                {
                    case "power_supply":
                        range = new ValueRange { Min = 0, Max = (float)Num("maxVoltage", 12), Step = 0.1f, Default = 6f, Unit = "V", Label = "Output voltage", Live = true };
                        return true;
                    case "microscope":
                        range = new ValueRange { Min = 0, Max = 1, Step = 0.005f, Default = (float)Num("focus"), Unit = "", Label = "Fine focus", Live = true };
                        return true;
                    case "bunsen_burner":
                        range = new ValueRange { Min = 0, Max = 1, Step = 0.05f, Default = 1, Unit = "", Label = "Air hole (closed → open)", Live = true };
                        return true;
                    case "hot_plate":
                        range = new ValueRange { Min = 0, Max = 400, Step = 10, Default = (float)Num("powerW", 200), Unit = "W", Label = "Heater power", Live = true };
                        return true;
                    case "water_bath":
                        range = new ValueRange { Min = 5, Max = 100, Step = 1, Default = (float)Num("setpointC", 37), Unit = "°C", Label = "Set temperature", Live = false };
                        return true;
                }
            }
            return base.TryGetValueRange(t, out range);
        }

        public override string ActionLabel(IntentType t)
        {
            if (t == IntentType.Toggle)
                switch (Type)
                {
                    case "stopwatch": return Bool("running") ? "Stop" : "Start";
                    case "microscope": return Bool("lightOn") ? "Light off" : "Light on";
                    case "bunsen_burner": return Bool("lit") ? "Turn off" : "Light";
                    default: return Bool("on") ? "Switch off" : "Switch on";
                }
            if (t == IntentType.Toggle && Type == "balance") return "Tare (zero)";
            if (t == IntentType.Toggle && Type == "light_gate") return "Reset";
            if (t == IntentType.Rotate && Type == "hot_plate") return "Set power";
            if (t == IntentType.Rotate && Type == "water_bath") return "Set temperature";
            if (t == IntentType.Connect && Type == "light_gate") return "Set up at…";
                        if (t == IntentType.Rotate && Type == "power_supply") return "Set voltage";
            if (t == IntentType.Rotate && Type == "microscope") return "Focus";
            if (t == IntentType.Type && Type == "microscope") return "Change objective";
            return base.ActionLabel(t);
        }

        public override void Render(float dt)
        {
            base.Render(dt);
            string text = null;
            float knob01 = 0;
            bool active = false;
            switch (Type)
            {
                case "ammeter": text = Num("reading").ToString("0.000", CultureInfo.InvariantCulture) + " A"; active = Bool("connected"); break;
                case "voltmeter": text = Num("reading").ToString("0.00", CultureInfo.InvariantCulture) + " V"; active = Bool("connected"); break;
                case "power_supply":
                    active = Bool("on");
                    text = active ? Num("voltageV").ToString("00.0", CultureInfo.InvariantCulture) + " V" : "";
                    knob01 = (float)(Num("voltageV") / System.Math.Max(Num("maxVoltage", 12), 1));
                    break;
                case "stopwatch":
                    {
                        double s = Num("elapsedS");
                        text = $"{(int)(s / 60):00}:{s % 60:00.00}";
                        active = Bool("running");
                        break;
                    }
                case "microscope": knob01 = (float)Num("focus"); active = Bool("lightOn"); break;
                case "bunsen_burner": knob01 = (float)Num("airHole"); active = Bool("lit"); break;
                case "workstation": case "firewall": text = "> " + (Str("lastCommand") ?? ""); active = true; break;
                case "balance": text = Num("reading").ToString("0.00", CultureInfo.InvariantCulture) + " g"; active = true; break;
                case "hot_plate":
                    active = Bool("on");
                    text = active ? Num("powerW").ToString("0", CultureInfo.InvariantCulture) + " W  " + (Num("energyJ") / 1000).ToString("0.0", CultureInfo.InvariantCulture) + " kJ" : "OFF  " + (Num("energyJ") / 1000).ToString("0.0", CultureInfo.InvariantCulture) + " kJ";
                    knob01 = (float)(Num("powerW") / 400);
                    break;
                case "water_bath":
                    active = Bool("on");
                    text = Num("temperatureC", 20).ToString("0.0", CultureInfo.InvariantCulture) + " °C" + (active ? "  → " + Num("setpointC").ToString("0", CultureInfo.InvariantCulture) : "");
                    break;
                case "light_gate":
                    text = Num("reading").ToString("0.000", CultureInfo.InvariantCulture) + " m/s";
                    active = Bool("connected");
                    break;
                case "light_box": case "lamp": active = Bool("on"); break;
            }
            if (display && text != null) display.text = text;
            if ((Type == "ammeter" || Type == "voltmeter") && TryGetComponent<CableRenderer>(out var cable))
            {
                bool on = Bool("connected");
                if (on && !cableLinked) foreach (var v in Object.FindObjectsByType<EquipmentView>()) if (v.Type == "breadboard") { cable.ConnectTo(v.Attach); cableLinked = true; }
                if (!on && cableLinked) { cable.ConnectTo(null); cableLinked = false; }
            }
            if (knob) knob.localRotation = Quaternion.Euler(0, 0, -knob01 * knobDegrees);
            if (statusLight) statusLight.enabled = active;
            if (flame)
            {
                if (active && !flame.isPlaying) flame.Play();
                else if (!active && flame.isPlaying) flame.Stop();
                var main = flame.main;
                // Air hole open → roaring blue flame, closed → yellow safety flame.
                main.startColor = Color.Lerp(new Color(1f, 0.65f, 0.15f, 0.8f), new Color(0.35f, 0.5f, 1f, 0.7f), knob01);
            }
        }
    }
}
