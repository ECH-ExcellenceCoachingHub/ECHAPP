using ECHLabs.Core;
using ECHLabs.Runtime.Equipment;
using UnityEngine;
using UnityEngine.Rendering;

namespace ECHLabs.Runtime.Interaction
{
    /// <summary>
    /// A glowing emerald arrow that bobs over the object to use next (guided mode), with a soft
    /// ring on the bench around it. It points at the exact control for small things (the burette
    /// tap, a knob) and stays readable from across the room by growing with distance.
    /// </summary>
    public sealed class GuideArrow : MonoBehaviour
    {
        public Camera cam;
        EquipmentView target;
        IntentType intent;
        Transform arrow, ring;
        Renderer[] renderers;
        float flash, appear, measureTimer;
        Bounds cachedBounds;
        EquipmentGeometry.Hotspot cachedSpot;

        public EquipmentView Target => target;

        public static GuideArrow Create()
        {
            var root = new GameObject("Guide arrow");
            var g = root.AddComponent<GuideArrow>();
            g.Build();
            root.SetActive(true);
            return g;
        }

        void Build()
        {
            var mat = Resources.Load<Material>("FX/GuideGlow");
            if (!mat)
            {
                mat = new Material(Shader.Find("Universal Render Pipeline/Unlit") ?? Shader.Find("Unlit/Color"));
                mat.SetColor("_BaseColor", new Color(0.2f, 0.95f, 0.65f));
                mat.color = new Color(0.2f, 0.95f, 0.65f);
            }
            arrow = new GameObject("Arrow").transform;
            arrow.SetParent(transform, false);
            var head = MakePart("Head", ConeMesh(0.024f, 0.042f, 20), mat, arrow);
            head.localRotation = Quaternion.Euler(180, 0, 0); // tip down
            var stem = MakePart("Stem", CylinderMesh(0.009f, 0.04f, 14), mat, arrow);
            stem.localPosition = new Vector3(0, 0.02f, 0);
            ring = MakePart("Ring", RingMesh(0.05f, 0.058f, 40), mat, transform);
            renderers = GetComponentsInChildren<Renderer>();
            SetVisible(false);
        }

        static Transform MakePart(string name, Mesh mesh, Material mat, Transform parent)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            go.AddComponent<MeshFilter>().sharedMesh = mesh;
            var r = go.AddComponent<MeshRenderer>();
            r.sharedMaterial = mat;
            r.shadowCastingMode = ShadowCastingMode.Off;
            r.receiveShadows = false;
            return go.transform;
        }

        public void Point(EquipmentView v, IntentType forIntent)
        {
            if (v == target && forIntent == intent) return;
            target = v;
            intent = forIntent;
            appear = 0;
            SetVisible(v);
        }

        /// <summary>"Where do I go?": a brighter, bigger pulse for a couple of seconds.</summary>
        public void Flash() => flash = 2.2f;

        public void Hide() { target = null; SetVisible(false); }

        void SetVisible(bool on)
        {
            if (renderers == null) return;
            foreach (var r in renderers) r.enabled = on;
        }

        void LateUpdate()
        {
            if (!target || !cam || !cam.isActiveAndEnabled) { if (renderers != null && renderers[0].enabled) SetVisible(false); return; }
            if (!renderers[0].enabled) SetVisible(true);
            float t = Time.unscaledTime;
            appear = Mathf.MoveTowards(appear, 1, Time.unscaledDeltaTime * 3f);
            flash = Mathf.Max(0, flash - Time.unscaledDeltaTime);

            // Measuring renderers allocates; a few times a second is plenty for a bobbing arrow.
            measureTimer -= Time.unscaledDeltaTime;
            if (measureTimer <= 0 || appear < 0.05f)
            {
                measureTimer = 0.25f;
                cachedSpot = EquipmentGeometry.For(target, intent, cam.transform.position);
                cachedBounds = EquipmentGeometry.BoundsOf(target);
            }
            var hs = cachedSpot;
            var b = cachedBounds;
            Vector3 tip;
            if (hs.Control)
            {
                // Small control: hover just in front of and above it, tip pointing at it.
                var toCam = cam.transform.position - hs.Point; toCam.y = 0;
                tip = hs.Point + toCam.normalized * 0.03f + Vector3.up * 0.035f;
            }
            else tip = new Vector3(b.center.x, b.max.y + 0.025f, b.center.z);

            float dist = Vector3.Distance(cam.transform.position, tip);
            float scale = Mathf.Clamp(dist / 0.9f, 0.8f, 3.2f) * (1f + 0.6f * Mathf.Clamp01(flash)) * Mathf.SmoothStep(0, 1, appear);
            float bob = (0.012f + 0.01f * Mathf.Clamp01(flash)) * scale * (0.5f + 0.5f * Mathf.Sin(t * 5f));
            arrow.position = tip + Vector3.up * (bob + 0.004f * scale);
            arrow.rotation = Quaternion.Euler(0, t * 90f, 0);
            arrow.localScale = Vector3.one * scale;

            ring.gameObject.SetActive(!hs.Control);
            ring.position = new Vector3(b.center.x, b.min.y + 0.004f, b.center.z);
            float rs = Mathf.Max(b.extents.x, b.extents.z) / 0.05f + 0.25f;
            ring.localScale = Vector3.one * rs * (1f + 0.08f * Mathf.Sin(t * 4f));
        }

        // ─── Meshes ──────────────────────────────────────────────────────────

        static Mesh ConeMesh(float radius, float height, int seg)
        {
            var v = new Vector3[seg + 2];
            var tris = new int[seg * 6];
            v[0] = new Vector3(0, height, 0);
            v[1] = Vector3.zero;
            for (int i = 0; i < seg; i++)
            {
                float a = i * Mathf.PI * 2 / seg;
                v[i + 2] = new Vector3(Mathf.Cos(a) * radius, 0, Mathf.Sin(a) * radius);
                int n = (i + 1) % seg + 2;
                tris[i * 6] = 0; tris[i * 6 + 1] = n; tris[i * 6 + 2] = i + 2;
                tris[i * 6 + 3] = 1; tris[i * 6 + 4] = i + 2; tris[i * 6 + 5] = n;
            }
            var m = new Mesh { name = "GuideCone", vertices = v, triangles = tris };
            m.RecalculateNormals();
            return m;
        }

        static Mesh CylinderMesh(float radius, float height, int seg)
        {
            var v = new Vector3[seg * 2];
            var tris = new int[seg * 6];
            for (int i = 0; i < seg; i++)
            {
                float a = i * Mathf.PI * 2 / seg;
                var p = new Vector3(Mathf.Cos(a) * radius, 0, Mathf.Sin(a) * radius);
                v[i] = p;
                v[i + seg] = p + Vector3.up * height;
                int n = (i + 1) % seg;
                tris[i * 6] = i; tris[i * 6 + 1] = i + seg; tris[i * 6 + 2] = n;
                tris[i * 6 + 3] = n; tris[i * 6 + 4] = i + seg; tris[i * 6 + 5] = n + seg;
            }
            var m = new Mesh { name = "GuideStem", vertices = v, triangles = tris };
            m.RecalculateNormals();
            return m;
        }

        static Mesh RingMesh(float inner, float outer, int seg)
        {
            var v = new Vector3[seg * 2];
            var tris = new int[seg * 12];
            for (int i = 0; i < seg; i++)
            {
                float a = i * Mathf.PI * 2 / seg;
                var d = new Vector3(Mathf.Cos(a), 0, Mathf.Sin(a));
                v[i] = d * inner;
                v[i + seg] = d * outer;
                int n = (i + 1) % seg;
                int k = i * 12;
                // both faces, so it reads from any angle
                tris[k] = i; tris[k + 1] = i + seg; tris[k + 2] = n;
                tris[k + 3] = n; tris[k + 4] = i + seg; tris[k + 5] = n + seg;
                tris[k + 6] = i; tris[k + 7] = n; tris[k + 8] = i + seg;
                tris[k + 9] = n; tris[k + 10] = n + seg; tris[k + 11] = i + seg;
            }
            var m = new Mesh { name = "GuideRing", vertices = v, triangles = tris };
            m.RecalculateNormals();
            return m;
        }
    }
}
