using ECHLabs.Core;
using UnityEngine;

namespace ECHLabs.Runtime.Equipment
{
    /// <summary>How a hand works a control: wrap around it, pinch it, press it with a finger, or type on it.</summary>
    public enum GripKind { None, Side, Pinch, Poke, Type }

    /// <summary>
    /// Where on a piece of equipment an action happens (the burette stopcock, a power-supply knob,
    /// the keyboard of a workstation, the body of a bottle…). Shared by the first-person hands,
    /// the guide arrow and the pour animation, so they always agree.
    /// </summary>
    public static class EquipmentGeometry
    {
        public struct Hotspot
        {
            public Vector3 Point;
            public GripKind Kind;
            /// <summary>Radius of the object at the grip (for wrapping fingers around it).</summary>
            public float Radius;
            /// <summary>True when the point is a small control (knob, tap) rather than the whole object.</summary>
            public bool Control;
        }

        public static Bounds BoundsOf(EquipmentView v)
        {
            bool has = false;
            Bounds b = default;
            foreach (var r in v.GetComponentsInChildren<Renderer>())
            {
                if (!r.enabled || !r.gameObject.activeInHierarchy || r is ParticleSystemRenderer || r is LineRenderer || r is TrailRenderer) continue;
                if (r.GetComponent<TMPro.TMP_Text>()) continue;
                if (!has) { b = r.bounds; has = true; }
                else b.Encapsulate(r.bounds);
            }
            if (!has) b = new Bounds(v.transform.position + Vector3.up * 0.05f, Vector3.one * 0.1f);
            return b;
        }

        public static Hotspot For(EquipmentView v, IntentType intent, Vector3 viewer)
        {
            var b = BoundsOf(v);
            float radius = Mathf.Clamp(Mathf.Min(b.extents.x, b.extents.z), 0.012f, 0.09f);
            switch (intent)
            {
                case IntentType.Inspect:
                    return new Hotspot { Point = b.center, Kind = GripKind.None, Radius = radius };
                case IntentType.Type:
                    {
                        var kb = FindDeep(v.transform, "Keyboard");
                        if (kb) return new Hotspot { Point = kb.position + Vector3.up * 0.012f, Kind = GripKind.Type, Control = true };
                        return new Hotspot { Point = Face(b, viewer, 0.35f), Kind = GripKind.Poke, Control = true };
                    }
                case IntentType.Toggle:
                    if (v is InstrumentView tv && tv.knob) return new Hotspot { Point = Face(b, viewer, 0.45f), Kind = GripKind.Poke, Control = true };
                    return new Hotspot { Point = Face(b, viewer, 0.5f), Kind = GripKind.Poke, Control = true };
                case IntentType.Rotate:
                    if (v is BuretteView bv && bv.stopcock) return new Hotspot { Point = bv.stopcock.position, Kind = GripKind.Pinch, Control = true };
                    if (v is InstrumentView iv && iv.knob) return new Hotspot { Point = iv.knob.position, Kind = GripKind.Pinch, Control = true };
                    if (v is FlaskView) return new Hotspot { Point = BodyPoint(b, 0.35f), Kind = GripKind.Side, Radius = radius };
                    return new Hotspot { Point = Face(b, viewer, 0.5f), Kind = GripKind.Pinch, Control = true };
                case IntentType.Release:
                    if (v is PendulumView pv && pv.bob) return new Hotspot { Point = pv.bob.position, Kind = GripKind.Pinch, Control = true };
                    return new Hotspot { Point = b.center, Kind = GripKind.Pinch, Radius = radius };
                case IntentType.Connect:
                    return new Hotspot { Point = b.size.y < 0.06f ? b.center : BodyPoint(b, 0.6f), Kind = GripKind.Pinch, Radius = radius };
                default: // Grab, Pour
                    if (b.size.y < 0.05f || b.size.x < 0.025f && b.size.z < 0.025f)
                        return new Hotspot { Point = b.center, Kind = GripKind.Pinch, Radius = radius }; // slides, resistors, droppers
                    return new Hotspot { Point = BodyPoint(b, 0.4f), Kind = GripKind.Side, Radius = radius };
            }
        }

        /// <summary>Opening at the top of a container (where liquid goes in).</summary>
        public static Vector3 Mouth(EquipmentView v)
        {
            if (v is BuretteView bv && bv.topPoint) return bv.topPoint.position;
            var b = BoundsOf(v);
            return new Vector3(b.center.x, b.max.y, b.center.z);
        }

        /// <summary>A point up the body of a vessel; tall things are held low (like a real hand would).</summary>
        static Vector3 BodyPoint(Bounds b, float frac)
        {
            var p = b.center;
            p.y = b.min.y + Mathf.Min(b.size.y * frac, 0.11f);
            return p;
        }

        /// <summary>Point on the face of the bounds that looks at the viewer, at a height fraction.</summary>
        static Vector3 Face(Bounds b, Vector3 viewer, float yFrac)
        {
            var flatViewer = new Vector3(viewer.x, b.center.y, viewer.z);
            var p = b.ClosestPoint(flatViewer);
            p.y = Mathf.Lerp(b.min.y, b.max.y, yFrac);
            return p;
        }

        public static Transform FindDeep(Transform t, string name)
        {
            if (t.name == name) return t;
            for (int i = 0; i < t.childCount; i++)
            {
                var r = FindDeep(t.GetChild(i), name);
                if (r) return r;
            }
            return null;
        }
    }
}
