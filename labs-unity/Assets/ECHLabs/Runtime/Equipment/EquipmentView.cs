using System;
using System.Collections.Generic;
using ECHLabs.Core;
using TMPro;
using UnityEngine;

namespace ECHLabs.Runtime.Equipment
{
    /// <summary>Slider settings for intents that take a value (Rotate a tap/knob, Release a pendulum…).</summary>
    public struct ValueRange
    {
        public float Min, Max, Step, Default;
        public string Unit, Label;
        public bool Live; // send intents while dragging (taps, knobs) vs. once on confirm
    }

    /// <summary>
    /// Visual + interactive representation of one piece of equipment. The science lives in
    /// ECHLabs.Core (LabWorld); views read state each frame and animate it.
    /// </summary>
    [DisallowMultipleComponent]
    public class EquipmentView : MonoBehaviour
    {
        [Tooltip("Where the camera looks when this equipment is in focus")] public Transform focusPoint;
        [Tooltip("Where items placed onto / poured into this equipment go")] public Transform attachPoint;
        [Tooltip("Camera distance for close-up inspection (m)")] public float inspectDistance = 0.45f;
        public Renderer[] highlightRenderers;

        public string EquipmentId { get; private set; }
        public string Type { get; private set; }
        public string Label { get; private set; }
        public LabWorld World { get; private set; }
        public IReadOnlyList<IntentType> Intents => intents;
        /// <summary>Commands offered by terminals (scenario init "commands"), shown as big buttons.</summary>
        public IReadOnlyList<string> Commands => commands;
        readonly List<string> commands = new List<string>();

        readonly List<IntentType> intents = new List<IntentType>();
        MaterialPropertyBlock mpb;
        float highlight, highlightTarget;
        static readonly int RimId = Shader.PropertyToID("_ECH_Highlight");
        static readonly int EmissionId = Shader.PropertyToID("_EmissionColor");
        static readonly Color HighlightColor = new Color(0.063f, 0.725f, 0.506f) * 0.6f; // ECH emerald

        public Vector3 FocusPosition => focusPoint ? focusPoint.position : transform.position + Vector3.up * 0.15f;
        public Transform Attach => attachPoint ? attachPoint : transform;
        /// <summary>Where the camera should look: where the equipment is going, not where it is mid-move.</summary>
        public virtual Vector3 SettledFocusPosition => FocusPosition;

        public virtual void Bind(EquipmentSpec spec, LabWorld world, IEnumerable<string> intentNames)
        {
            EquipmentId = spec.Id;
            Type = spec.Type;
            Label = string.IsNullOrEmpty(spec.Label) ? Catalog.Title(spec.Type) : spec.Label;
            World = world;
            name = $"{spec.Type}:{spec.Id}";
            intents.Clear();
            foreach (var n in intentNames)
                if (Enum.TryParse<IntentType>(n, out var t) && t != IntentType.Select) intents.Add(t);
            commands.Clear();
            if (spec.Init != null && spec.Init.TryGetValue("commands", out var cmds) && cmds is Newtonsoft.Json.Linq.JArray arr)
                foreach (var c in arr) commands.Add(c.ToString());
            if (highlightRenderers == null || highlightRenderers.Length == 0) highlightRenderers = GetComponentsInChildren<Renderer>();
            foreach (var c in GetComponentsInChildren<Collider>()) c.gameObject.layer = gameObject.layer;
            // Printed label on bottles/flasks ("NaOH 0.125 M").
            var printed = transform.Find("LabelText");
            if (printed && printed.TryGetComponent<TMP_Text>(out var tmp)) tmp.text = Label;
            // Re-binding (demo → student's own run) starts from a clean visual state.
            foreach (var c in GetComponentsInChildren<CableRenderer>()) c.ConnectTo(null);
            highlightTarget = 0;
            OnBound(spec);
        }

        protected virtual void OnBound(EquipmentSpec spec) { }

        /// <summary>Called every frame after the simulation tick.</summary>
        public virtual void Render(float dt)
        {
            if (Mathf.Abs(highlight - highlightTarget) > 0.001f)
            {
                highlight = Mathf.MoveTowards(highlight, highlightTarget, dt * 6f);
                ApplyHighlight();
            }
        }

        public void SetHighlight(bool on) => highlightTarget = on ? 1f : 0f;

        void ApplyHighlight()
        {
            mpb ??= new MaterialPropertyBlock();
            foreach (var r in highlightRenderers)
            {
                if (!r || r is ParticleSystemRenderer) continue;
                r.GetPropertyBlock(mpb);
                mpb.SetFloat(RimId, highlight);
                if (r.sharedMaterial && r.sharedMaterial.HasProperty(EmissionId) && !r.sharedMaterial.IsKeywordEnabled("_EMISSION_LOCKED"))
                    mpb.SetColor(EmissionId, HighlightColor * highlight * 0.35f);
                r.SetPropertyBlock(mpb);
            }
        }

        /// <summary>Does this action need a second object (pour INTO, connect TO, place ONTO)?</summary>
        public virtual bool NeedsReceiver(IntentType t) => t == IntentType.Pour || t == IntentType.Connect;

        /// <summary>Grab = put on / pick up immediately, or pick up then choose where to place it.</summary>
        public virtual bool GrabPlacesSomewhere => false;

        public virtual bool TryGetValueRange(IntentType t, out ValueRange range)
        {
            range = default;
            return false;
        }

        /// <summary>Human label for the action button ("Pour", "Open tap", "Put on"…).</summary>
        public virtual string ActionLabel(IntentType t)
        {
            switch (t)
            {
                case IntentType.Grab: return GrabPlacesSomewhere ? "Pick up" : "Use";
                case IntentType.Release: return "Release";
                case IntentType.Pour: return "Pour";
                case IntentType.Rotate: return "Adjust";
                case IntentType.Inspect: return "Look closer";
                case IntentType.Toggle: return "Switch on/off";
                case IntentType.Connect: return "Connect";
                case IntentType.Type: return "Run a command";
            }
            return t.ToString();
        }

        static readonly Dictionary<string, EquipmentView> byId = new Dictionary<string, EquipmentView>();

        /// <summary>The view of a piece of equipment by its scenario id (placement targets, probes…).</summary>
        public static EquipmentView FindById(string id)
        {
            if (string.IsNullOrEmpty(id)) return null;
            if (byId.TryGetValue(id, out var v) && v && v.EquipmentId == id) return v;
            foreach (var x in UnityEngine.Object.FindObjectsByType<EquipmentView>())
                if (x.EquipmentId == id) { byId[id] = x; return x; }
            return null;
        }

        /// <summary>Liquid colour published by the simulation ("r,g,b,a" in the colorRGBA state key).</summary>
        protected bool TryStateColor(out Color c)
        {
            c = default;
            var s = Str("colorRGBA");
            if (string.IsNullOrEmpty(s)) return false;
            var parts = s.Split(',');
            if (parts.Length != 4) return false;
            var f = new float[4];
            for (int i = 0; i < 4; i++) if (!float.TryParse(parts[i], System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out f[i])) return false;
            c = new Color(f[0], f[1], f[2], f[3]);
            return true;
        }

        /// <summary>Several items placed on the same thing sit side by side instead of inside each other.</summary>
        protected Vector3 PlacementOffset(string placedIn, string key = "placedIn")
        {
            if (World == null || placedIn == null) return Vector3.zero;
            int index = 0, count = 0;
            foreach (var e in World.Definition.Equipment)
            {
                if (World.Str(e.Id, key) != placedIn) continue;
                if (e.Id == EquipmentId) index = count;
                count++;
            }
            return Vector3.right * (index - (count - 1) / 2f) * 0.045f;
        }

        protected double Num(string key, double fallback = 0) => World != null ? World.Num(EquipmentId, key, fallback) : fallback;
        protected bool Bool(string key) => World != null && World.Bool(EquipmentId, key);
        protected string Str(string key) => World?.Str(EquipmentId, key);
    }

    /// <summary>Titles for equipment types (mirrors catalog.json; used when no label is given).</summary>
    public static class Catalog
    {
        static readonly Dictionary<string, string> titles = new Dictionary<string, string>
        {
            { "goggles", "Safety goggles" }, { "labcoat", "Lab coat" }, { "gloves", "Gloves" },
            { "reagent_bottle", "Reagent bottle" }, { "burette", "Burette" }, { "pipette", "Pipette" },
            { "conical_flask", "Conical flask" }, { "beaker", "Beaker" }, { "indicator", "Indicator" },
            { "retort_stand", "Retort stand" }, { "white_tile", "White tile" }, { "funnel", "Funnel" },
            { "bunsen_burner", "Bunsen burner" }, { "power_supply", "Power supply" }, { "resistor", "Resistor" },
            { "ammeter", "Ammeter" }, { "voltmeter", "Voltmeter" }, { "breadboard", "Circuit board" },
            { "pendulum", "Pendulum" }, { "stopwatch", "Stopwatch" }, { "metre_rule", "Metre rule" },
            { "microscope", "Microscope" }, { "slide", "Slide" }, { "stain", "Stain" },
            { "workstation", "Workstation" }, { "firewall", "Firewall" }, { "server_rack", "Server rack" },
            { "network_switch", "Network switch" }, { "patch_cable", "Patch cable" }, { "wall_display", "Display" },
        };
        public static string Title(string type)
        {
            if (titles.TryGetValue(type, out var t)) return t;
            // Newer equipment: the bundled catalog has the title ("Test tube", "Hot plate"…).
            var fromCatalog = (string)ECHLabs.Runtime.World.EquipmentFactory.Catalog["equipment"]?[type]?["title"];
            return !string.IsNullOrEmpty(fromCatalog) ? System.Text.RegularExpressions.Regex.Replace(fromCatalog, @"\s*\(.*\)$", "") : type.Replace('_', ' ');
        }
    }
}
