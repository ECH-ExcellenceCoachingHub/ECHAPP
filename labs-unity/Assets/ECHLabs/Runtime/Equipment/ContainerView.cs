using System;
using ECHLabs.Core;
using UnityEngine;

namespace ECHLabs.Runtime.Equipment
{
    /// <summary>
    /// Reagent bottle, beaker, pipette: liquid level + a real pour. When poured into something,
    /// the container is lifted over the receiver, tilted about its lip (the spout stays above the
    /// opening), a liquid stream runs into the receiver, then it is put back. Levels drain and fill
    /// smoothly while the stream runs (the transfer itself already happened in the simulation).
    /// </summary>
    public class ContainerView : EquipmentView
    {
        public LiquidVolume liquid;
        public Color liquidColor = new Color(0.78f, 0.89f, 1f, 0.35f);
        [Tooltip("Pivot rotated to show pouring")] public Transform tiltPivot;

        /// <summary>Raised when a stream starts/stops (sound, haptics).</summary>
        public static event Action<ContainerView, bool, Vector3> StreamChanged;

        public bool Pouring => pourT >= 0 || pourDelay > 0;
        float pourDelay;

        const float MoveIn = 0.55f, TiltEnd = 1.95f, Total = 2.6f;
        float pourT = -1;
        EquipmentView pourInto;
        Vector3 restPos;
        Quaternion restRot;
        float height = 0.15f, radius = 0.035f;
        float shownVolume = -1;
        LineRenderer stream;
        bool streaming;
        LiquidVolume intoLiquid;

        protected override void OnBound(EquipmentSpec spec)
        {
            if (!liquid) liquid = GetComponentInChildren<LiquidVolume>();
            if (!tiltPivot) tiltPivot = transform;
            restPos = tiltPivot.position;
            restRot = tiltPivot.rotation;
            var b = EquipmentGeometry.BoundsOf(this);
            height = Mathf.Max(0.03f, b.max.y - tiltPivot.position.y);
            radius = Mathf.Clamp(Mathf.Min(b.extents.x, b.extents.z), 0.008f, 0.08f);
            shownVolume = -1;
            pourT = -1;
            pourDelay = 0;
            SetStream(false, Vector3.zero);
        }

        /// <summary>Pour into a receiver (lift, tilt at its opening, stream) or just tilt in place.</summary>
        public void PlayPour(EquipmentView into = null, float delay = 0.4f)
        {
            pourInto = into;
            intoLiquid = into ? into.GetComponentInChildren<LiquidVolume>() : null;
            pourDelay = delay; // the hand takes hold first
            pourT = -1;
        }

        public override void Render(float dt)
        {
            base.Render(dt);
            float target = (float)Num("volumeMl");
            if (shownVolume < 0) shownVolume = target;
            bool draining = Pouring && pourT > MoveIn && pourT < TiltEnd;
            float rate = Pouring ? (draining ? Mathf.Abs(target - shownVolume) / Mathf.Max(TiltEnd - pourT, 0.05f) : 0f) : Mathf.Max(Mathf.Abs(target - shownVolume) * 4f, 40f);
            shownVolume = Mathf.MoveTowards(shownVolume, target, rate * dt);
            if (liquid) liquid.Set(shownVolume, liquidColor);

            if (pourDelay > 0)
            {
                pourDelay -= dt;
                if (pourDelay <= 0) pourT = 0;
                else return;
            }
            if (pourT < 0)
            {
                tiltPivot.SetPositionAndRotation(Vector3.Lerp(tiltPivot.position, restPos, dt * 10f), Quaternion.Slerp(tiltPivot.rotation, restRot, dt * 10f));
                return;
            }

            pourT += dt;
            if (pourT >= Total)
            {
                pourT = -1;
                SetStream(false, Vector3.zero);
                return;
            }
            if (!pourInto) { InPlaceTilt(); return; }

            var mouth = EquipmentGeometry.Mouth(pourInto) + Vector3.up * 0.035f;
            var d = mouth - restPos; d.y = 0;
            d = d.sqrMagnitude < 1e-6f ? transform.right : d.normalized;
            Vector3 pos; Quaternion rot;
            if (pourT < MoveIn)
            {
                float k = Smooth(pourT / MoveIn);
                Pose(mouth, d, 40f, out var p1, out var r1);
                pos = Vector3.Lerp(restPos, p1, k) + Vector3.up * 0.06f * Mathf.Sin(k * Mathf.PI);
                rot = Quaternion.Slerp(restRot, r1, k);
            }
            else if (pourT < TiltEnd)
            {
                float k = Smooth((pourT - MoveIn) / (TiltEnd - MoveIn));
                Pose(mouth, d, Mathf.Lerp(40f, 105f, Mathf.Sin(k * Mathf.PI * 0.5f)), out pos, out rot);
            }
            else
            {
                float k = Smooth((pourT - TiltEnd) / (Total - TiltEnd));
                Pose(mouth, d, 105f, out var p2, out var r2);
                pos = Vector3.Lerp(p2, restPos, k) + Vector3.up * 0.05f * Mathf.Sin(k * Mathf.PI);
                rot = Quaternion.Slerp(r2, restRot, k);
            }
            tiltPivot.SetPositionAndRotation(pos, rot);

            bool flow = pourT > MoveIn + 0.35f && pourT < TiltEnd - 0.05f && shownVolume > 0.05f;
            if (flow) DrawStream(mouth - Vector3.up * 0.035f, d);
            SetStream(flow, mouth);
        }

        /// <summary>Container pose for a tilt angle with its lip held at the receiver's opening.</summary>
        void Pose(Vector3 lip, Vector3 d, float angleDeg, out Vector3 pos, out Quaternion rot)
        {
            float a = angleDeg * Mathf.Deg2Rad;
            var up = Mathf.Cos(a) * Vector3.up + Mathf.Sin(a) * d;     // container axis
            var rim = Mathf.Cos(a) * d - Mathf.Sin(a) * Vector3.up;    // from axis to the pouring lip
            pos = lip - up * height - rim * radius;
            rot = Quaternion.FromToRotation(Vector3.up, up) * restRot;
        }

        void InPlaceTilt()
        {
            float t = Mathf.Sin(Mathf.Clamp01(pourT / Total) * Mathf.PI);
            tiltPivot.rotation = restRot * Quaternion.Euler(0, 0, -95f * t);
        }

        void DrawStream(Vector3 lip, Vector3 d)
        {
            if (!stream) stream = CreateStream();
            float endY;
            if (intoLiquid && intoLiquid.TryGetComponent<Renderer>(out var lr))
            {
                var lb = lr.bounds;
                float frac = intoLiquid.capacityMl > 0 ? Mathf.Clamp01(intoLiquid.VolumeMl / intoLiquid.capacityMl) : 0;
                endY = Mathf.Lerp(lb.min.y, lb.max.y, frac);
            }
            else endY = EquipmentGeometry.BoundsOf(pourInto).min.y + 0.01f;
            endY = Mathf.Min(endY, lip.y - 0.02f);
            if (pourInto is BuretteView) endY = Mathf.Max(endY, lip.y - 0.09f); // disappears into the funnel

            const int n = 12;
            stream.positionCount = n;
            float t = Time.time;
            for (int i = 0; i < n; i++)
            {
                float u = i / (n - 1f);
                // Leaves the lip with a little forward speed, then falls (parabola), with a slight shimmer.
                var p = lip + d * (0.012f * Mathf.Sqrt(u)) + Vector3.down * (lip.y - endY) * u * u;
                p += Vector3.Cross(Vector3.up, d) * Mathf.Sin(t * 40f + u * 12f) * 0.0008f * u;
                stream.SetPosition(i, p);
            }
            var c = liquidColor; c.a = Mathf.Max(c.a, 0.55f);
            var c2 = c; c2.a *= 0.85f;
            stream.startColor = c;
            stream.endColor = c2;
            if (intoLiquid) intoLiquid.Splash(0.5f);
        }

        void SetStream(bool on, Vector3 at)
        {
            if (stream) stream.enabled = on;
            if (on == streaming) return;
            streaming = on;
            StreamChanged?.Invoke(this, on, at);
        }

        LineRenderer CreateStream()
        {
            var go = new GameObject("PourStream");
            go.transform.SetParent(transform, false);
            var l = go.AddComponent<LineRenderer>();
            l.useWorldSpace = true;
            l.numCapVertices = 3;
            l.widthCurve = new AnimationCurve(new Keyframe(0, 0.008f), new Keyframe(0.5f, 0.0055f), new Keyframe(1, 0.0045f));
            l.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            l.receiveShadows = false;
            var mat = Resources.Load<Material>("FX/Stream");
            l.sharedMaterial = mat ? mat : new Material(Shader.Find("Universal Render Pipeline/Particles/Unlit") ?? Shader.Find("Sprites/Default"));
            return l;
        }

        static float Smooth(float x) { x = Mathf.Clamp01(x); return x * x * (3f - 2f * x); }
    }
}
