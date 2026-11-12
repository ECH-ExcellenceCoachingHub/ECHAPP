using System;
using System.Collections.Generic;
using System.IO;
using ECHLabs.Runtime.Equipment;
using TMPro;
using UnityEditor;
using UnityEngine;

namespace ECHLabs.EditorTools
{
    /// <summary>
    /// Builds every equipment prefab from code (no manual Editor work):
    /// real-dimension glassware via lathe profiles, bevelled instruments, colliders sized for easy
    /// picking (even by gaze), liquids with exact volume curves, displays, particles and behaviour.
    /// Output: Assets/ECHLabs/Resources/Equipment/&lt;type&gt;.prefab (+ meshes in Art/Generated).
    /// Run: menu "ECH Labs/Build equipment prefabs" or batch -executeMethod ECHLabs.EditorTools.PrefabFactory.BuildAll
    /// </summary>
    public static class PrefabFactory
    {
        const string PrefabDir = "Assets/ECHLabs/Resources/Equipment";
        const string MeshDir = "Assets/ECHLabs/Art/Generated";
        const float MinPick = 0.08f; // minimum collider size (m) so small items are easy to select

        [MenuItem("ECH Labs/Build equipment prefabs")]
        public static void BuildAll()
        {
            Directory.CreateDirectory(PrefabDir);
            Directory.CreateDirectory(MeshDir);
            MaterialLibrary.BuildAll();
            var builders = new Dictionary<string, Func<GameObject>>
            {
                { "goggles", Goggles }, { "labcoat", LabCoat }, { "gloves", Gloves },
                { "reagent_bottle", ReagentBottle }, { "burette", Burette }, { "pipette", Pipette },
                { "conical_flask", ConicalFlask }, { "beaker", Beaker }, { "indicator", () => Dropper("indicator") },
                { "stain", () => Dropper("stain") }, { "retort_stand", RetortStand }, { "white_tile", WhiteTile },
                { "funnel", Funnel }, { "bunsen_burner", Bunsen }, { "power_supply", PowerSupply },
                { "resistor", Resistor }, { "ammeter", () => Meter("ammeter", "A") }, { "voltmeter", () => Meter("voltmeter", "V") },
                { "breadboard", Breadboard }, { "pendulum", Pendulum }, { "stopwatch", Stopwatch },
                { "metre_rule", MetreRule }, { "microscope", Microscope }, { "slide", Slide },
                { "workstation", Workstation }, { "firewall", () => RackUnit("firewall", true) },
                { "server_rack", ServerRack }, { "network_switch", () => RackUnit("network_switch", false) },
                { "patch_cable", PatchCable }, { "wall_display", WallDisplay },
            };
            foreach (var kv in builders)
            {
                var go = kv.Value();
                go.name = kv.Key;
                FinishColliders(go);
                PrefabUtility.SaveAsPrefabAsset(go, $"{PrefabDir}/{kv.Key}.prefab");
                UnityEngine.Object.DestroyImmediate(go);
            }
            AssetDatabase.SaveAssets();
            Debug.Log($"[ECHLabs] Built {builders.Count} equipment prefabs.");
        }

        // ─── Helpers ─────────────────────────────────────────────────────────

        static Mesh Save(Mesh m)
        {
            string path = $"{MeshDir}/{m.name}.asset";
            var existing = AssetDatabase.LoadAssetAtPath<Mesh>(path);
            if (existing) { EditorUtility.CopySerialized(m, existing); return existing; }
            AssetDatabase.CreateAsset(m, path);
            return m;
        }

        static GameObject Part(Transform parent, string name, Mesh mesh, Material mat, Vector3 pos, Vector3 euler = default, Vector3? scale = null)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            go.transform.localPosition = pos;
            go.transform.localEulerAngles = euler;
            go.transform.localScale = scale ?? Vector3.one;
            go.AddComponent<MeshFilter>().sharedMesh = Save(mesh);
            var r = go.AddComponent<MeshRenderer>();
            r.sharedMaterial = mat;
            r.shadowCastingMode = mat.renderQueue >= 3000 ? UnityEngine.Rendering.ShadowCastingMode.Off : UnityEngine.Rendering.ShadowCastingMode.On;
            return go;
        }

        static GameObject Box(Transform p, string name, Vector3 size, float bevel, Material mat, Vector3 pos, Vector3 euler = default)
            => Part(p, name, MeshKit.RoundedBox($"{name}_{size.x:0.###}x{size.y:0.###}x{size.z:0.###}_{bevel:0.####}".Replace(',', '.'), size, bevel), mat, pos, euler);

        static GameObject Cyl(Transform p, string name, float r, float h, Material mat, Vector3 pos, Vector3 euler = default, int seg = 32)
            => Part(p, name, MeshKit.Cylinder($"cyl_{r:0.####}_{h:0.####}".Replace(',', '.'), r, h, seg), mat, pos, euler);

        static Transform Point(Transform parent, string name, Vector3 pos)
        {
            var t = new GameObject(name).transform;
            t.SetParent(parent, false);
            t.localPosition = pos;
            return t;
        }

        static TextMeshPro Text(Transform parent, string name, string text, Vector3 pos, float size, Color color, Vector3 euler = default, float width = 0.2f)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            go.transform.localPosition = pos;
            go.transform.localEulerAngles = euler;
            var t = go.AddComponent<TextMeshPro>();
            t.text = text;
            t.fontSize = size;
            t.color = color;
            t.alignment = TextAlignmentOptions.Center;
            t.rectTransform.sizeDelta = new Vector2(width, size * 0.02f);
            t.textWrappingMode = TextWrappingModes.NoWrap;
            if (TMP_Settings.defaultFontAsset) t.font = TMP_Settings.defaultFontAsset;
            return t;
        }

        /// <summary>Paper label wrapped on glassware (text set at runtime from the scenario label).</summary>
        static void PrintedLabel(Transform root, float y, float radius, float height)
        {
            var paper = Box(root, "Label", new Vector3(radius * 1.2f, height, 0.0006f), 0.0002f, MaterialLibrary.Fabric, new Vector3(0, y, -radius - 0.0008f));
            paper.GetComponent<Renderer>().shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            var t = Text(root, "LabelText", "", new Vector3(0, y, -radius - 0.0016f), 0.12f, new Color(0.1f, 0.1f, 0.12f), new Vector3(0, 0, 0), radius * 1.15f);
            t.enableAutoSizing = true;
            t.fontSizeMin = 0.04f;
            t.fontSizeMax = 0.14f;
            t.rectTransform.sizeDelta = new Vector2(radius * 1.15f, height * 0.9f);
        }

        static void FinishColliders(GameObject go)
        {
            if (go.GetComponent<Collider>()) return;
            var renderers = go.GetComponentsInChildren<Renderer>();
            if (renderers.Length == 0) return;
            var b = new Bounds(go.transform.InverseTransformPoint(renderers[0].bounds.center), Vector3.zero);
            foreach (var r in renderers)
            {
                if (r is ParticleSystemRenderer || r is LineRenderer) continue;
                var rb = r.bounds;
                b.Encapsulate(go.transform.InverseTransformPoint(rb.min));
                b.Encapsulate(go.transform.InverseTransformPoint(rb.max));
            }
            var c = go.AddComponent<BoxCollider>();
            c.center = b.center;
            c.size = Vector3.Max(b.size, Vector3.one * MinPick);
        }

        static LiquidVolume Liquid(Transform parent, MeshKit.LatheResult lathe, float? capacityMl = null)
        {
            var go = Part(parent, "Liquid", lathe.Liquid, MaterialLibrary.Liquid, Vector3.zero);
            go.GetComponent<Renderer>().shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            var lv = go.AddComponent<LiquidVolume>();
            lv.capacityMl = capacityMl ?? lathe.CapacityMl;
            lv.volumeToHeight = lathe.VolumeToHeight;
            return lv;
        }

        static GameObject Root(string type, out Transform t)
        {
            var go = new GameObject(type);
            t = go.transform;
            return go;
        }

        static List<Vector2> P(params float[] rz)
        {
            var l = new List<Vector2>();
            for (int i = 0; i < rz.Length; i += 2) l.Add(new Vector2(rz[i], rz[i + 1]));
            return l;
        }

        // ─── Glassware ───────────────────────────────────────────────────────

        static GameObject ConicalFlask()
        {
            var go = Root("conical_flask", out var t);
            // 250 mL Erlenmeyer: Ø84 mm base, 145 mm tall, Ø25 mm neck.
            var lathe = MeshKit.Lathe("flask250", P(0, 0, 0.040f, 0, 0.042f, 0.004f, 0.036f, 0.04f, 0.022f, 0.08f, 0.0135f, 0.104f, 0.0125f, 0.112f, 0.0125f, 0.140f, 0.0145f, 0.145f), 0.0016f, 64, liquidTo: 0.135f);
            Part(t, "Glass", lathe.Glass, MaterialLibrary.GlassClear, Vector3.zero);
            Liquid(t, lathe);
            var v = go.AddComponent<FlaskView>();
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.05f, 0));
            v.attachPoint = Point(t, "Attach", new Vector3(0, 0.15f, 0));
            v.inspectDistance = 0.35f;
            PrintedLabel(t, 0.03f, 0.03f, 0.018f);
            return go;
        }

        static GameObject Beaker()
        {
            var go = Root("beaker", out var t);
            // 250 mL low-form beaker: Ø70 mm × 95 mm with pouring lip.
            var lathe = MeshKit.Lathe("beaker250", P(0, 0, 0.033f, 0, 0.035f, 0.003f, 0.035f, 0.092f, 0.0365f, 0.095f), 0.0015f, 64);
            Part(t, "Glass", lathe.Glass, MaterialLibrary.GlassClear, Vector3.zero);
            Liquid(t, lathe);
            var v = go.AddComponent<ContainerView>();
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.05f, 0));
            v.attachPoint = Point(t, "Attach", new Vector3(0, 0.1f, 0));
            return go;
        }

        static GameObject ReagentBottle()
        {
            var go = Root("reagent_bottle", out var t);
            var pivot = new GameObject("TiltPivot").transform;
            pivot.SetParent(t, false);
            var lathe = MeshKit.Lathe("bottle500", P(0, 0, 0.038f, 0, 0.040f, 0.004f, 0.040f, 0.11f, 0.034f, 0.13f, 0.016f, 0.145f, 0.015f, 0.16f, 0.016f, 0.168f), 0.0022f, 48, liquidTo: 0.15f);
            Part(pivot, "Glass", lathe.Glass, MaterialLibrary.GlassClear, Vector3.zero);
            Liquid(pivot, lathe, 500);
            Cyl(pivot, "Cap", 0.0175f, 0.02f, MaterialLibrary.PlasticBlue, new Vector3(0, 0.162f, 0));
            PrintedLabel(pivot, 0.065f, 0.04f, 0.05f);
            var v = go.AddComponent<ContainerView>();
            v.tiltPivot = pivot;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.08f, 0));
            return go;
        }

        static GameObject Burette()
        {
            var go = Root("burette", out var t);
            // Self-standing burette on its stand and clamp. 50 mL graduated over ≈0.59 m (inner Ø10.4 mm).
            const float r = 0.0060f, wall = 0.0008f, y50 = 0.30f;
            float rin = r - wall - 0.0006f;
            float L = 50e-6f / (Mathf.PI * rin * rin);
            float y0 = y50 + L, top = y0 + 0.05f;
            float tipY = 0.20f;
            var prof = P(0, tipY, 0.0012f, tipY, 0.0016f, tipY + 0.03f, 0.0035f, tipY + 0.06f, r, tipY + 0.075f, r, top - 0.004f, r + 0.0015f, top);
            var lathe = MeshKit.Lathe("burette50", prof, wall, 32, liquidTo: y0, liquidFrom: y50);

            // Stand
            Box(t, "StandBase", new Vector3(0.20f, 0.014f, 0.28f), 0.004f, MaterialLibrary.SteelDark, new Vector3(-0.06f, 0.007f, 0.04f));
            Cyl(t, "StandRod", 0.0065f, 1.0f, MaterialLibrary.SteelBrushed, new Vector3(-0.06f, 0.014f, 0.12f));
            Box(t, "Clamp", new Vector3(0.025f, 0.03f, 0.13f), 0.004f, MaterialLibrary.SteelBrushed, new Vector3(-0.03f, y0 - 0.12f, 0.06f));
            Box(t, "ClampPad", new Vector3(0.03f, 0.035f, 0.025f), 0.006f, MaterialLibrary.Rubber, new Vector3(0, y0 - 0.12f, 0));

            Part(t, "Tube", lathe.Glass, MaterialLibrary.GlassClear, Vector3.zero);
            var liquid = Liquid(t, lathe, 50);
            liquid.bottomUp = true;

            // Graduation lines (every 1 mL, longer every 5) + numbers every 5 mL, facing the student (−Z).
            var lines = new List<CombineInstance>();
            for (int ml = 0; ml <= 50; ml++)
            {
                float y = y0 - ml / 50f * L;
                bool major = ml % 5 == 0;
                var m = MeshKit.RoundedBox("gradline", new Vector3(major ? 0.007f : 0.0045f, 0.0004f, 0.0003f), 0.0001f, 1);
                lines.Add(new CombineInstance { mesh = m, transform = Matrix4x4.Translate(new Vector3(-0.0015f, y, -r - 0.0002f)) });
                if (major) Text(t, $"Mark{ml}", ml.ToString(), new Vector3(0.0065f, y, -r - 0.0003f), 0.05f, new Color(0.05f, 0.05f, 0.08f), default, 0.012f);
                // 0.1 mL minor ticks between 1 mL marks would be 500 lines; the close-up camera
                // shows the meniscus between the 1 mL marks and students interpolate, as on a real burette.
            }
            var scale = new Mesh { name = "burette_scale" };
            scale.CombineMeshes(lines.ToArray(), true, true);
            Part(t, "Scale", scale, MaterialLibrary.PlasticGraphite, Vector3.zero);

            // Stopcock (PTFE key) just above the tip.
            var stop = new GameObject("Stopcock").transform;
            stop.SetParent(t, false);
            stop.localPosition = new Vector3(0, tipY + 0.07f, 0);
            Cyl(stop, "Barrel", 0.006f, 0.03f, MaterialLibrary.GlassClear, new Vector3(-0.015f, 0, 0), new Vector3(0, 0, 90));
            Box(stop, "Key", new Vector3(0.008f, 0.032f, 0.006f), 0.002f, MaterialLibrary.PlasticBlue, new Vector3(-0.024f, 0, 0));

            // Drips
            var tip = Point(t, "Tip", new Vector3(0, tipY - 0.002f, 0));
            var ps = DripParticles(tip);

            var v = go.AddComponent<BuretteView>();
            v.liquid = liquid;
            v.stopcock = stop;
            v.drips = ps;
            v.tip = tip;
            v.topPoint = Point(t, "Top", new Vector3(0, top + 0.01f, 0));
            v.focusPoint = Point(t, "Focus", new Vector3(0, y50 + L * 0.5f, 0));
            v.attachPoint = Point(t, "UnderTip", new Vector3(0, 0.014f, 0)); // on the stand base, under the tip
            v.inspectDistance = 0.22f;
            return go;
        }

        static ParticleSystem DripParticles(Transform at)
        {
            var go = new GameObject("Drips");
            go.transform.SetParent(at, false);
            go.transform.localEulerAngles = new Vector3(90, 0, 0);
            var ps = go.AddComponent<ParticleSystem>();
            var main = ps.main;
            main.startSpeed = 0.05f;
            main.startLifetime = 0.45f;
            main.startSize = 0.006f;
            main.gravityModifier = 1f;
            main.startColor = new Color(0.9f, 0.95f, 1f, 0.6f);
            main.simulationSpace = ParticleSystemSimulationSpace.World;
            main.maxParticles = 200;
            var em = ps.emission; em.rateOverTime = 0;
            var shape = ps.shape; shape.enabled = false;
            var col = ps.collision; col.enabled = true; col.type = ParticleSystemCollisionType.World; col.lifetimeLoss = 1f; col.bounce = 0;
            var r = go.GetComponent<ParticleSystemRenderer>();
            r.sharedMaterial = MaterialLibrary.GlassClear;
            r.renderMode = ParticleSystemRenderMode.Mesh;
            r.mesh = Save(MeshKit.Sphere("drop", 0.5f, 8));
            ps.Stop();
            return ps;
        }

        static GameObject Pipette()
        {
            var go = Root("pipette", out var t);
            var lathe = MeshKit.Lathe("pipette25", P(0, 0, 0.0008f, 0, 0.003f, 0.08f, 0.011f, 0.14f, 0.011f, 0.2f, 0.003f, 0.25f, 0.003f, 0.45f), 0.0007f, 24);
            var pivot = new GameObject("TiltPivot").transform; pivot.SetParent(t, false);
            pivot.localEulerAngles = new Vector3(0, 0, 0);
            Part(pivot, "Glass", lathe.Glass, MaterialLibrary.GlassClear, new Vector3(0, 0.02f, 0));
            Liquid(pivot, lathe, 25).transform.localPosition = new Vector3(0, 0.02f, 0);
            Cyl(t, "Filler", 0.012f, 0.05f, MaterialLibrary.Rubber, new Vector3(0, 0.47f, 0));
            var v = go.AddComponent<ContainerView>();
            v.tiltPivot = pivot;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.2f, 0));
            return go;
        }

        static GameObject Funnel()
        {
            var go = Root("funnel", out var t);
            var lathe = MeshKit.Lathe("funnel", P(0, 0, 0.0035f, 0, 0.0035f, 0.04f, 0.035f, 0.085f), 0.0012f, 48);
            Part(t, "Glass", lathe.Glass, MaterialLibrary.GlassClear, Vector3.zero);
            var v = go.AddComponent<GenericView>();
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.05f, 0));
            return go;
        }

        static GameObject Dropper(string type)
        {
            var go = Root(type, out var t);
            var pivot = new GameObject("TiltPivot").transform; pivot.SetParent(t, false);
            var lathe = MeshKit.Lathe(type + "_bottle", P(0, 0, 0.018f, 0, 0.019f, 0.003f, 0.019f, 0.055f, 0.009f, 0.065f, 0.008f, 0.072f), 0.0015f, 32);
            Part(pivot, "Glass", lathe.Glass, MaterialLibrary.GlassAmber, Vector3.zero);
            Part(pivot, "Teat", MeshKit.Solid(type + "_teat", P(0, 0, 0.0085f, 0, 0.0085f, 0.012f, 0.006f, 0.03f, 0, 0.034f)), MaterialLibrary.Rubber, new Vector3(0, 0.072f, 0));
            PrintedLabel(pivot, 0.03f, 0.019f, 0.022f);
            var v = go.AddComponent<ContainerView>();
            v.tiltPivot = pivot;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.05f, 0));
            return go;
        }

        static GameObject WhiteTile()
        {
            var go = Root("white_tile", out var t);
            Box(t, "Tile", new Vector3(0.15f, 0.007f, 0.15f), 0.002f, MaterialLibrary.Ceramic, new Vector3(0, 0.0035f, 0));
            var v = go.AddComponent<GenericView>();
            v.attachPoint = Point(t, "Attach", new Vector3(0, 0.007f, 0));
            return go;
        }

        static GameObject RetortStand()
        {
            var go = Root("retort_stand", out var t);
            Box(t, "Base", new Vector3(0.18f, 0.014f, 0.26f), 0.004f, MaterialLibrary.SteelDark, new Vector3(0, 0.007f, 0.03f));
            Cyl(t, "Rod", 0.0065f, 0.75f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.014f, 0.1f));
            Box(t, "Clamp", new Vector3(0.025f, 0.03f, 0.12f), 0.004f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.45f, 0.05f));
            var v = go.AddComponent<GenericView>();
            v.attachPoint = Point(t, "Attach", new Vector3(0, 0.45f, 0));
            return go;
        }

        // ─── PPE ─────────────────────────────────────────────────────────────

        static GameObject Goggles()
        {
            var go = Root("goggles", out var t);
            var vis = new GameObject("Visual").transform; vis.SetParent(t, false);
            Box(vis, "Frame", new Vector3(0.17f, 0.06f, 0.045f), 0.018f, MaterialLibrary.PlasticBlue, new Vector3(0, 0.035f, 0));
            Box(vis, "Lens", new Vector3(0.155f, 0.048f, 0.006f), 0.012f, MaterialLibrary.GlassLens, new Vector3(0, 0.035f, -0.024f));
            Box(vis, "Strap", new Vector3(0.2f, 0.022f, 0.004f), 0.002f, MaterialLibrary.Rubber, new Vector3(0, 0.035f, 0.03f));
            var v = go.AddComponent<WearableView>();
            v.visual = vis.gameObject;
            return go;
        }

        static GameObject LabCoat()
        {
            var go = Root("labcoat", out var t);
            var vis = new GameObject("Visual").transform; vis.SetParent(t, false);
            // Neatly folded coat on the PPE counter.
            Box(vis, "Fold", new Vector3(0.34f, 0.07f, 0.28f), 0.025f, MaterialLibrary.Fabric, new Vector3(0, 0.035f, 0));
            Box(vis, "Collar", new Vector3(0.2f, 0.02f, 0.06f), 0.008f, MaterialLibrary.Fabric, new Vector3(0, 0.075f, 0.1f));
            Box(vis, "Badge", new Vector3(0.07f, 0.004f, 0.03f), 0.0015f, MaterialLibrary.AccentEmerald, new Vector3(0.09f, 0.071f, -0.06f));
            var v = go.AddComponent<WearableView>();
            v.visual = vis.gameObject;
            return go;
        }

        static GameObject Gloves()
        {
            var go = Root("gloves", out var t);
            var vis = new GameObject("Visual").transform; vis.SetParent(t, false);
            Box(vis, "Box", new Vector3(0.24f, 0.09f, 0.125f), 0.006f, MaterialLibrary.PlasticWhite, new Vector3(0, 0.045f, 0));
            Box(vis, "Stripe", new Vector3(0.241f, 0.03f, 0.126f), 0.004f, MaterialLibrary.PlasticBlue, new Vector3(0, 0.045f, 0));
            var v = go.AddComponent<WearableView>();
            v.visual = vis.gameObject;
            return go;
        }

        // ─── Electrical & instruments ────────────────────────────────────────

        static GameObject PowerSupply()
        {
            var go = Root("power_supply", out var t);
            Box(t, "Body", new Vector3(0.24f, 0.12f, 0.2f), 0.012f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.06f, 0));
            Box(t, "Panel", new Vector3(0.22f, 0.1f, 0.004f), 0.004f, MaterialLibrary.PlasticWhite, new Vector3(0, 0.06f, -0.101f));
            Box(t, "Screen", new Vector3(0.09f, 0.035f, 0.003f), 0.002f, MaterialLibrary.Screen, new Vector3(-0.05f, 0.075f, -0.104f));
            var display = Text(t, "Display", "", new Vector3(-0.05f, 0.075f, -0.106f), 0.35f, new Color(0.3f, 1f, 0.6f), default, 0.085f);
            var knob = new GameObject("Knob").transform; knob.SetParent(t, false); knob.localPosition = new Vector3(0.05f, 0.075f, -0.104f); knob.localEulerAngles = new Vector3(-90, 0, 0);
            Part(knob, "KnobMesh", MeshKit.Solid("knob", P(0, 0, 0.016f, 0, 0.016f, 0.012f, 0.012f, 0.018f, 0, 0.018f)), MaterialLibrary.PlasticGraphite, Vector3.zero);
            Box(knob, "KnobMark", new Vector3(0.002f, 0.003f, 0.01f), 0.0005f, MaterialLibrary.AccentEmerald, new Vector3(0, 0.0185f, 0.007f));
            Cyl(t, "TermRed", 0.006f, 0.014f, MaterialLibrary.WireRed, new Vector3(-0.07f, 0.03f, -0.104f), new Vector3(-90, 0, 0));
            Cyl(t, "TermBlack", 0.006f, 0.014f, MaterialLibrary.WireBlack, new Vector3(-0.03f, 0.03f, -0.104f), new Vector3(-90, 0, 0));
            var led = Box(t, "Led", new Vector3(0.006f, 0.006f, 0.003f), 0.001f, MaterialLibrary.LedGreen, new Vector3(0.09f, 0.03f, -0.104f));
            var v = go.AddComponent<InstrumentView>();
            v.display = display;
            v.knob = knob;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.07f, -0.1f));
            v.attachPoint = Point(t, "Terminals", new Vector3(-0.05f, 0.03f, -0.11f));
            var light = led.AddComponent<Light>(); light.type = LightType.Point; light.range = 0.04f; light.intensity = 0.08f; light.color = new Color(0.3f, 1f, 0.5f);
            v.statusLight = light;
            return go;
        }

        static GameObject Meter(string type, string unit)
        {
            var go = Root(type, out var t);
            Box(t, "Body", new Vector3(0.11f, 0.05f, 0.16f), 0.01f, MaterialLibrary.PlasticWhite, new Vector3(0, 0.025f, 0));
            Box(t, "Face", new Vector3(0.09f, 0.004f, 0.06f), 0.003f, MaterialLibrary.Screen, new Vector3(0, 0.051f, -0.03f), new Vector3(-12, 0, 0));
            var display = Text(t, "Display", "0.00 " + unit, new Vector3(0, 0.056f, -0.03f), 0.28f, new Color(0.35f, 1f, 0.6f), new Vector3(78, 0, 0), 0.085f);
            Text(t, "Unit", unit, new Vector3(0.035f, 0.052f, 0.04f), 0.4f, new Color(0.1f, 0.1f, 0.12f), new Vector3(90, 0, 0), 0.03f);
            Cyl(t, "TermRed", 0.005f, 0.012f, MaterialLibrary.WireRed, new Vector3(-0.025f, 0.05f, 0.05f));
            Cyl(t, "TermBlack", 0.005f, 0.012f, MaterialLibrary.WireBlack, new Vector3(0.0f, 0.05f, 0.05f));
            var v = go.AddComponent<InstrumentView>();
            v.display = display;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.05f, -0.03f));
            v.inspectDistance = 0.28f;
            AddCable(go, new Vector3(-0.012f, 0.06f, 0.05f), MaterialLibrary.WireRed);
            return go;
        }

        static void AddCable(GameObject go, Vector3 plugLocal, Material mat)
        {
            var lr = go.AddComponent<LineRenderer>();
            lr.widthMultiplier = 0.004f;
            lr.sharedMaterial = mat;
            lr.numCapVertices = 4;
            lr.numCornerVertices = 2;
            var cr = go.AddComponent<CableRenderer>();
            cr.plug = Point(go.transform, "Plug", plugLocal);
        }

        static GameObject Resistor()
        {
            var go = Root("resistor", out var t);
            Box(t, "Holder", new Vector3(0.07f, 0.012f, 0.03f), 0.004f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.006f, 0));
            Cyl(t, "Body", 0.0045f, 0.024f, MaterialLibrary.ResistorBeige, new Vector3(-0.012f, 0.022f, 0), new Vector3(0, 0, -90), 20);
            var bands = new[] { MaterialLibrary.LedGreen, MaterialLibrary.PlasticGraphite, MaterialLibrary.WireBlack, MaterialLibrary.Brass }; // 47 Ω-ish colours
            for (int i = 0; i < bands.Length; i++) Cyl(t, "Band" + i, 0.0047f, 0.0025f, bands[i], new Vector3(-0.008f + i * 0.005f, 0.022f, 0), new Vector3(0, 0, -90), 20);
            Cyl(t, "LeadL", 0.0006f, 0.02f, MaterialLibrary.SteelBrushed, new Vector3(-0.032f, 0.022f, 0), new Vector3(0, 0, -90), 8);
            Cyl(t, "LeadR", 0.0006f, 0.02f, MaterialLibrary.SteelBrushed, new Vector3(0.012f, 0.022f, 0), new Vector3(0, 0, -90), 8);
            var v = go.AddComponent<GenericView>();
            v.inspectDistance = 0.15f;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.022f, 0));
            return go;
        }

        static GameObject Breadboard()
        {
            var go = Root("breadboard", out var t);
            Box(t, "Board", new Vector3(0.30f, 0.016f, 0.2f), 0.004f, MaterialLibrary.BoardGreen, new Vector3(0, 0.008f, 0));
            for (int i = 0; i < 6; i++) Box(t, "Rail" + i, new Vector3(0.26f, 0.002f, 0.006f), 0.001f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.017f, -0.07f + i * 0.028f));
            Cyl(t, "Post+", 0.007f, 0.02f, MaterialLibrary.WireRed, new Vector3(-0.12f, 0.016f, 0.085f));
            Cyl(t, "Post-", 0.007f, 0.02f, MaterialLibrary.WireBlack, new Vector3(-0.09f, 0.016f, 0.085f));
            var v = go.AddComponent<GenericView>();
            v.attachPoint = Point(t, "Attach", new Vector3(0.02f, 0.018f, 0));
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.02f, 0));
            return go;
        }

        static GameObject Bunsen()
        {
            var go = Root("bunsen_burner", out var t);
            Part(t, "Base", MeshKit.Solid("bunsen_base", P(0, 0, 0.045f, 0, 0.045f, 0.01f, 0.02f, 0.018f, 0, 0.018f)), MaterialLibrary.SteelDark, Vector3.zero);
            Cyl(t, "Barrel", 0.0085f, 0.12f, MaterialLibrary.Brass, new Vector3(0, 0.018f, 0));
            var collar = new GameObject("Collar").transform; collar.SetParent(t, false); collar.localPosition = new Vector3(0, 0.03f, 0);
            Cyl(collar, "CollarMesh", 0.011f, 0.015f, MaterialLibrary.SteelBrushed, Vector3.zero);
            var flameGo = new GameObject("Flame"); flameGo.transform.SetParent(t, false); flameGo.transform.localPosition = new Vector3(0, 0.14f, 0); flameGo.transform.localEulerAngles = new Vector3(-90, 0, 0);
            var ps = flameGo.AddComponent<ParticleSystem>();
            var main = ps.main; main.startLifetime = 0.35f; main.startSpeed = 0.35f; main.startSize = 0.025f; main.maxParticles = 300; main.simulationSpace = ParticleSystemSimulationSpace.World;
            var em = ps.emission; em.rateOverTime = 160;
            var shape = ps.shape; shape.shapeType = ParticleSystemShapeType.Cone; shape.angle = 4; shape.radius = 0.006f;
            var sol = ps.sizeOverLifetime; sol.enabled = true; sol.size = new ParticleSystem.MinMaxCurve(1, AnimationCurve.Linear(0, 1, 1, 0));
            var r = flameGo.GetComponent<ParticleSystemRenderer>(); r.sharedMaterial = MaterialLibrary.AccentBlue;
            ps.Stop();
            var v = go.AddComponent<InstrumentView>();
            v.knob = collar;
            v.knobDegrees = 180;
            v.flame = ps;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.1f, 0));
            return go;
        }

        static GameObject Pendulum()
        {
            var go = Root("pendulum", out var t);
            Box(t, "Base", new Vector3(0.22f, 0.016f, 0.3f), 0.005f, MaterialLibrary.SteelDark, new Vector3(0, 0.008f, 0.06f));
            Cyl(t, "Rod", 0.007f, 1.18f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.016f, 0.16f));
            Box(t, "Arm", new Vector3(0.018f, 0.02f, 0.2f), 0.004f, MaterialLibrary.SteelBrushed, new Vector3(0, 1.18f, 0.07f));
            Box(t, "Cheeks", new Vector3(0.03f, 0.03f, 0.012f), 0.003f, MaterialLibrary.Wood, new Vector3(0, 1.17f, -0.03f));
            var pivot = new GameObject("Pivot").transform; pivot.SetParent(t, false); pivot.localPosition = new Vector3(0, 1.155f, -0.03f);
            var str = Cyl(pivot, "String", 0.0006f, 2f, MaterialLibrary.Fabric, Vector3.zero, default, 6);
            var bob = Part(pivot, "Bob", MeshKit.Sphere("bob", 0.0125f, 20), MaterialLibrary.Brass, new Vector3(0, -0.8f, 0));
            var v = go.AddComponent<PendulumView>();
            v.pivot = pivot;
            v.stringTransform = str.transform;
            v.bob = bob.transform;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.6f, -0.03f));
            v.inspectDistance = 1.1f;
            return go;
        }

        static GameObject Stopwatch()
        {
            var go = Root("stopwatch", out var t);
            Part(t, "Body", MeshKit.Solid("stopwatch", P(0, 0, 0.032f, 0, 0.034f, 0.006f, 0.034f, 0.014f, 0.03f, 0.02f, 0, 0.02f)), MaterialLibrary.PlasticGraphite, Vector3.zero, new Vector3(-70, 0, 0));
            Box(t, "Screen", new Vector3(0.042f, 0.018f, 0.002f), 0.002f, MaterialLibrary.Screen, new Vector3(0, 0.018f, -0.02f), new Vector3(20, 0, 0));
            var display = Text(t, "Display", "00:00.00", new Vector3(0, 0.0185f, -0.0215f), 0.14f, new Color(0.3f, 1f, 0.6f), new Vector3(20, 0, 0), 0.04f);
            Cyl(t, "Button", 0.005f, 0.008f, MaterialLibrary.AccentEmerald, new Vector3(0, 0.04f, 0.005f));
            var v = go.AddComponent<InstrumentView>();
            v.display = display;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.02f, -0.02f));
            v.inspectDistance = 0.18f;
            return go;
        }

        static GameObject MetreRule()
        {
            var go = Root("metre_rule", out var t);
            Box(t, "Rule", new Vector3(1.0f, 0.004f, 0.03f), 0.001f, MaterialLibrary.Wood, new Vector3(0.5f - 0.1f, 0.002f, 0));
            var ticks = new List<CombineInstance>();
            for (int cm = 0; cm <= 100; cm++)
            {
                var m = MeshKit.RoundedBox("tick", new Vector3(0.0006f, 0.0003f, cm % 10 == 0 ? 0.012f : 0.006f), 0.0001f, 1);
                ticks.Add(new CombineInstance { mesh = m, transform = Matrix4x4.Translate(new Vector3(cm / 100f - 0.1f, 0.0042f, -0.009f)) });
                if (cm % 10 == 0) Text(t, "n" + cm, cm.ToString(), new Vector3(cm / 100f - 0.1f, 0.0043f, 0.004f), 0.07f, new Color(0.1f, 0.08f, 0.05f), new Vector3(90, 0, 0), 0.02f);
            }
            var tm = new Mesh { name = "rule_ticks" }; tm.CombineMeshes(ticks.ToArray(), true, true);
            Part(t, "Ticks", tm, MaterialLibrary.PlasticGraphite, Vector3.zero);
            var v = go.AddComponent<GenericView>();
            v.focusPoint = Point(t, "Focus", new Vector3(0.4f, 0.01f, 0));
            v.inspectDistance = 0.5f;
            return go;
        }

        static GameObject Microscope()
        {
            var go = Root("microscope", out var t);
            Box(t, "Base", new Vector3(0.16f, 0.03f, 0.22f), 0.012f, MaterialLibrary.PlasticWhite, new Vector3(0, 0.015f, 0.02f));
            Box(t, "Arm", new Vector3(0.05f, 0.26f, 0.05f), 0.015f, MaterialLibrary.PlasticWhite, new Vector3(0, 0.15f, 0.09f), new Vector3(-8, 0, 0));
            Box(t, "Stage", new Vector3(0.13f, 0.01f, 0.12f), 0.003f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.12f, 0.01f));
            Cyl(t, "Lamp", 0.015f, 0.01f, MaterialLibrary.LightPanel, new Vector3(0, 0.03f, 0.01f));
            var turret = new GameObject("Turret").transform; turret.SetParent(t, false); turret.localPosition = new Vector3(0, 0.2f, 0.01f);
            Cyl(turret, "Nose", 0.028f, 0.02f, MaterialLibrary.SteelBrushed, Vector3.zero);
            for (int i = 0; i < 3; i++)
            {
                float a = i * 120 * Mathf.Deg2Rad;
                Cyl(turret, "Objective" + i, 0.007f, 0.035f, MaterialLibrary.SteelBrushed, new Vector3(Mathf.Cos(a) * 0.015f, -0.035f, Mathf.Sin(a) * 0.015f));
            }
            Cyl(t, "Tube", 0.016f, 0.12f, MaterialLibrary.PlasticWhite, new Vector3(0, 0.22f, 0.01f), new Vector3(-30, 0, 0));
            Cyl(t, "Eyepiece", 0.012f, 0.04f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.32f, -0.05f), new Vector3(-30, 0, 0));
            var knob = new GameObject("Knob").transform; knob.SetParent(t, false); knob.localPosition = new Vector3(0.03f, 0.1f, 0.09f); knob.localEulerAngles = new Vector3(0, 0, -90);
            Cyl(knob, "KnobMesh", 0.022f, 0.012f, MaterialLibrary.PlasticGraphite, Vector3.zero);
            var v = go.AddComponent<InstrumentView>();
            v.knob = knob;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.15f, 0));
            v.attachPoint = Point(t, "StageClip", new Vector3(0, 0.126f, 0.01f));
            v.inspectDistance = 0.35f;
            return go;
        }

        static GameObject Slide()
        {
            var go = Root("slide", out var t);
            Box(t, "Glass", new Vector3(0.075f, 0.0012f, 0.025f), 0.0004f, MaterialLibrary.GlassClear, new Vector3(0, 0.0006f, 0));
            Cyl(t, "Specimen", 0.006f, 0.0003f, MaterialLibrary.ResistorBeige, new Vector3(0, 0.0012f, 0), default, 20);
            var v = go.AddComponent<GenericView>();
            v.placesSomewhere = true;
            v.inspectDistance = 0.12f;
            return go;
        }

        // ─── Tech & digital ──────────────────────────────────────────────────

        static GameObject Workstation()
        {
            var go = Root("workstation", out var t);
            Box(t, "Stand", new Vector3(0.06f, 0.18f, 0.04f), 0.01f, MaterialLibrary.SteelDark, new Vector3(0, 0.09f, 0.08f));
            Box(t, "Foot", new Vector3(0.22f, 0.01f, 0.16f), 0.004f, MaterialLibrary.SteelDark, new Vector3(0, 0.005f, 0.07f));
            Box(t, "Monitor", new Vector3(0.62f, 0.36f, 0.025f), 0.01f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.33f, 0.06f));
            Box(t, "Screen", new Vector3(0.6f, 0.34f, 0.002f), 0.004f, MaterialLibrary.Screen, new Vector3(0, 0.33f, 0.047f));
            var display = Text(t, "Display", "> _", new Vector3(-0.27f, 0.47f, 0.045f), 0.25f, new Color(0.35f, 1f, 0.6f), default, 0.55f);
            display.alignment = TextAlignmentOptions.TopLeft;
            display.rectTransform.sizeDelta = new Vector2(0.56f, 0.3f);
            display.rectTransform.pivot = new Vector2(0, 1);
            Box(t, "Keyboard", new Vector3(0.44f, 0.018f, 0.14f), 0.006f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.009f, -0.16f));
            var v = go.AddComponent<InstrumentView>();
            v.display = display;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.33f, 0.04f));
            v.inspectDistance = 0.7f;
            return go;
        }

        static GameObject RackUnit(string type, bool firewall)
        {
            var go = Root(type, out var t);
            Box(t, "Chassis", new Vector3(0.44f, 0.045f, 0.3f), 0.004f, MaterialLibrary.SteelDark, new Vector3(0, 0.0225f, 0));
            Box(t, "Front", new Vector3(0.44f, 0.045f, 0.004f), 0.003f, firewall ? MaterialLibrary.PlasticBlue : MaterialLibrary.PlasticGraphite, new Vector3(0, 0.0225f, -0.15f));
            for (int i = 0; i < (firewall ? 8 : 24); i++)
                Box(t, "Port" + i, new Vector3(0.012f, 0.01f, 0.003f), 0.001f, MaterialLibrary.Rubber, new Vector3(-0.19f + i * (firewall ? 0.03f : 0.014f), 0.02f, -0.1525f));
            Box(t, "Led", new Vector3(0.005f, 0.005f, 0.002f), 0.001f, MaterialLibrary.LedGreen, new Vector3(0.2f, 0.03f, -0.153f));
            TextMeshPro display = null;
            if (firewall) display = Text(t, "Display", "", new Vector3(0.13f, 0.022f, -0.154f), 0.12f, new Color(0.35f, 1f, 0.6f), default, 0.1f);
            EquipmentView v;
            if (firewall) { var iv = go.AddComponent<InstrumentView>(); iv.display = display; v = iv; }
            else v = go.AddComponent<GenericView>();
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.03f, -0.15f));
            v.attachPoint = Point(t, "Attach", new Vector3(0, 0.02f, -0.16f));
            return go;
        }

        static GameObject ServerRack()
        {
            var go = Root("server_rack", out var t);
            Box(t, "Cabinet", new Vector3(0.6f, 2.0f, 1.0f), 0.01f, MaterialLibrary.SteelDark, new Vector3(0, 1.0f, 0));
            Box(t, "Door", new Vector3(0.58f, 1.96f, 0.01f), 0.004f, MaterialLibrary.GlassLens, new Vector3(0, 1.0f, -0.505f));
            for (int i = 0; i < 16; i++)
            {
                Box(t, "Unit" + i, new Vector3(0.5f, 0.08f, 0.02f), 0.003f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.25f + i * 0.1f, -0.49f));
                Box(t, "UnitLed" + i, new Vector3(0.006f, 0.006f, 0.002f), 0.001f, i % 5 == 3 ? MaterialLibrary.LedRed : MaterialLibrary.LedGreen, new Vector3(0.22f, 0.25f + i * 0.1f, -0.501f));
            }
            Box(t, "Accent", new Vector3(0.6f, 0.02f, 0.012f), 0.004f, MaterialLibrary.AccentEmerald, new Vector3(0, 1.98f, -0.506f));
            var v = go.AddComponent<GenericView>();
            v.focusPoint = Point(t, "Focus", new Vector3(0, 1.1f, -0.5f));
            v.attachPoint = Point(t, "Attach", new Vector3(0, 1.1f, -0.52f));
            v.inspectDistance = 1.2f;
            return go;
        }

        static GameObject PatchCable()
        {
            var go = Root("patch_cable", out var t);
            Part(t, "Coil", MeshKit.Solid("coil", P(0, 0, 0.05f, 0, 0.06f, 0.006f, 0.05f, 0.012f, 0, 0.012f), 32), MaterialLibrary.PlasticBlue, Vector3.zero);
            Box(t, "Plug", new Vector3(0.014f, 0.012f, 0.025f), 0.002f, MaterialLibrary.GlassLens, new Vector3(0.05f, 0.012f, 0));
            var v = go.AddComponent<GenericView>();
            AddCable(go, new Vector3(0.05f, 0.012f, 0), MaterialLibrary.PlasticBlue);
            return go;
        }

        static GameObject WallDisplay()
        {
            var go = Root("wall_display", out var t);
            Box(t, "Frame", new Vector3(1.6f, 0.92f, 0.04f), 0.01f, MaterialLibrary.PlasticGraphite, new Vector3(0, 1.6f, 0));
            Box(t, "Screen", new Vector3(1.56f, 0.88f, 0.002f), 0.004f, MaterialLibrary.Screen, new Vector3(0, 1.6f, -0.021f));
            Box(t, "Glow", new Vector3(1.6f, 0.01f, 0.01f), 0.004f, MaterialLibrary.AccentEmerald, new Vector3(0, 1.135f, -0.02f));
            Text(t, "Title", "LIVE THREAT MAP", new Vector3(0, 1.9f, -0.024f), 1.1f, new Color(0.3f, 1f, 0.65f), default, 1.4f);
            for (int i = 0; i < 5; i++)
                Box(t, "Bar" + i, new Vector3(0.12f, 0.08f + i * 0.07f, 0.004f), 0.002f, i == 3 ? MaterialLibrary.LedRed : MaterialLibrary.AccentBlue, new Vector3(-0.5f + i * 0.25f, 1.25f + (0.08f + i * 0.07f) / 2, -0.024f));
            var v = go.AddComponent<GenericView>();
            v.focusPoint = Point(t, "Focus", new Vector3(0, 1.6f, -0.02f));
            v.inspectDistance = 1.6f;
            return go;
        }
    }
}
