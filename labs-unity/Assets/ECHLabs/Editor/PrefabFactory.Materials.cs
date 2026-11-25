using System;
using System.Collections.Generic;
using ECHLabs.Runtime.Equipment;
using UnityEditor;
using UnityEngine;

namespace ECHLabs.EditorTools
{
    /// <summary>
    /// Prefabs for the general lab materials students use in their own experiments
    /// (real dimensions, built from code like the rest of the kit).
    /// </summary>
    public static partial class PrefabFactory
    {
        static void AddMaterialBuilders(Dictionary<string, Func<GameObject>> b)
        {
            b["test_tube"] = TestTube; b["measuring_cylinder"] = MeasuringCylinder; b["evaporating_dish"] = EvaporatingDish;
            b["solid_jar"] = SolidJar; b["dropper_bottle"] = () => Dropper("dropper_bottle");
            b["hot_plate"] = HotPlate; b["water_bath"] = WaterBath; b["thermometer"] = Thermometer; b["ph_meter"] = PhMeter; b["balance"] = Balance;
            b["splint"] = Splint; b["delivery_tube"] = DeliveryTube; b["potato_cylinder"] = PotatoCylinder; b["pondweed"] = Pondweed;
            b["lamp"] = DeskLamp; b["scalpel"] = Scalpel; b["forceps"] = Forceps;
            b["battery"] = Battery; b["switch"] = Switch; b["variable_resistor"] = Rheostat; b["bulb"] = Bulb; b["led"] = Led;
            b["spring"] = Spring; b["ramp"] = Ramp; b["light_gate"] = LightGate; b["metal_block"] = MetalBlock;
            b["light_box"] = LightBox; b["convex_lens"] = ConvexLens; b["screen"] = Screen;
            b["bunsen_burner"] = BunsenWithTripod;
        }

        static Light PointLight(GameObject on, Color color, float range, float intensity)
        {
            var l = on.AddComponent<Light>();
            l.type = LightType.Point; l.color = color; l.range = range; l.intensity = intensity; l.enabled = false;
            return l;
        }

        // ─── Glassware ───────────────────────────────────────────────────────

        static GameObject TestTube()
        {
            var go = Root("test_tube", out var t);
            var pivot = new GameObject("TiltPivot").transform; pivot.SetParent(t, false);
            // 16 × 150 mm tube with a round bottom.
            // Wire stand so a tube stands on the bench (a one-tube rack).
            Cyl(t, "StandBase", 0.02f, 0.004f, MaterialLibrary.PlasticWhite, Vector3.zero, default, 24);
            Cyl(t, "StandRing", 0.011f, 0.003f, MaterialLibrary.PlasticWhite, new Vector3(0, 0.08f, 0), default, 24);
            Cyl(t, "StandPost", 0.0015f, 0.08f, MaterialLibrary.SteelBrushed, new Vector3(0.014f, 0.004f, 0), default, 8);
            pivot.localPosition = new Vector3(0, 0.004f, 0);
            var lathe = MeshKit.Lathe("tube16", P(0, 0, 0.004f, 0.0006f, 0.0068f, 0.003f, 0.008f, 0.008f, 0.008f, 0.147f, 0.0088f, 0.15f), 0.0008f, 32, liquidTo: 0.145f);
            Part(pivot, "Glass", lathe.Glass, MaterialLibrary.GlassClear, Vector3.zero);
            Liquid(pivot, lathe, 20);
            PrintedLabel(pivot, 0.11f, 0.0085f, 0.014f);
            var v = go.AddComponent<ContainerView>();
            v.tiltPivot = pivot;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.06f, 0));
            v.attachPoint = Point(t, "Mouth", new Vector3(0, 0.15f, 0));
            v.inspectDistance = 0.2f;
            return go;
        }

        static GameObject MeasuringCylinder()
        {
            var go = Root("measuring_cylinder", out var t);
            var pivot = new GameObject("TiltPivot").transform; pivot.SetParent(t, false);
            const float r = 0.0145f, baseH = 0.01f;
            var lathe = MeshKit.Lathe("cyl100", P(0, baseH, r, baseH, r, 0.215f, r + 0.002f, 0.22f), 0.0012f, 40, liquidTo: 0.21f);
            Part(pivot, "Glass", lathe.Glass, MaterialLibrary.GlassClear, Vector3.zero);
            Liquid(pivot, lathe);
            Part(pivot, "Foot", MeshKit.Solid("cylfoot", P(0, 0, 0.035f, 0, 0.035f, 0.006f, 0.018f, baseH, 0, baseH)), MaterialLibrary.PlasticBlue, Vector3.zero);
            // Graduations every 10 mL with numbers every 20 mL (inner radius gives the height per mL).
            float rin = r - 0.0012f;
            float perMl = 1e-6f / (Mathf.PI * rin * rin);
            var lines = new List<CombineInstance>();
            for (int ml = 10; ml <= 100; ml += 10)
            {
                float y = baseH + ml * perMl;
                lines.Add(new CombineInstance { mesh = MeshKit.RoundedBox("cylgrad", new Vector3(ml % 20 == 0 ? 0.008f : 0.005f, 0.0005f, 0.0003f), 0.0001f, 1), transform = Matrix4x4.Translate(new Vector3(0, y, -r - 0.0002f)) });
                if (ml % 20 == 0) Text(pivot, "Mark" + ml, ml.ToString(), new Vector3(0.009f, y, -r - 0.0004f), 0.05f, new Color(0.05f, 0.05f, 0.1f), default, 0.012f);
            }
            var scale = new Mesh { name = "cyl_scale" };
            scale.CombineMeshes(lines.ToArray(), true, true);
            Part(pivot, "Scale", scale, MaterialLibrary.PlasticGraphite, Vector3.zero);
            var v = go.AddComponent<ContainerView>();
            v.tiltPivot = pivot;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.1f, 0));
            v.attachPoint = Point(t, "Inside", new Vector3(0, baseH + 0.004f, 0));
            v.inspectDistance = 0.3f;
            return go;
        }

        static GameObject EvaporatingDish()
        {
            var go = Root("evaporating_dish", out var t);
            var pivot = new GameObject("TiltPivot").transform; pivot.SetParent(t, false);
            var lathe = MeshKit.Lathe("evapdish", P(0, 0, 0.018f, 0, 0.034f, 0.012f, 0.042f, 0.024f, 0.045f, 0.026f), 0.0025f, 48);
            Part(pivot, "Bowl", lathe.Glass, MaterialLibrary.Ceramic, Vector3.zero);
            Liquid(pivot, lathe, 60);
            var v = go.AddComponent<ContainerView>();
            v.tiltPivot = pivot;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.015f, 0));
            v.attachPoint = Point(t, "Top", new Vector3(0, 0.03f, 0));
            v.inspectDistance = 0.22f;
            return go;
        }

        static GameObject SolidJar()
        {
            var go = Root("solid_jar", out var t);
            var pivot = new GameObject("TiltPivot").transform; pivot.SetParent(t, false);
            var lathe = MeshKit.Lathe("solidjar", P(0, 0, 0.026f, 0, 0.027f, 0.003f, 0.027f, 0.06f, 0.022f, 0.066f, 0.022f, 0.072f), 0.0018f, 40);
            Part(pivot, "Jar", lathe.Glass, MaterialLibrary.GlassClear, Vector3.zero);
            Cyl(pivot, "Contents", 0.024f, 0.03f, MaterialLibrary.PlasticWhite, new Vector3(0, 0.003f, 0));
            Cyl(pivot, "Lid", 0.024f, 0.012f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.072f, 0));
            Box(pivot, "Spatula", new Vector3(0.006f, 0.12f, 0.002f), 0.001f, MaterialLibrary.SteelBrushed, new Vector3(0.03f, 0.06f, 0), new Vector3(0, 0, -12));
            PrintedLabel(pivot, 0.045f, 0.027f, 0.022f);
            var v = go.AddComponent<ContainerView>();
            v.tiltPivot = pivot;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.04f, 0));
            return go;
        }

        // ─── Heat ────────────────────────────────────────────────────────────

        static GameObject HotPlate()
        {
            var go = Root("hot_plate", out var t);
            Box(t, "Body", new Vector3(0.2f, 0.07f, 0.24f), 0.012f, MaterialLibrary.PlasticWhite, new Vector3(0, 0.035f, 0));
            var plate = Cyl(t, "Plate", 0.08f, 0.008f, MaterialLibrary.SteelDark, new Vector3(0, 0.07f, 0.02f), default, 48);
            Box(t, "Panel", new Vector3(0.18f, 0.05f, 0.004f), 0.003f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.035f, -0.121f));
            var display = Text(t, "Display", "OFF", new Vector3(-0.03f, 0.04f, -0.124f), 0.2f, new Color(1f, 0.55f, 0.2f), default, 0.1f);
            var knob = new GameObject("Knob").transform; knob.SetParent(t, false); knob.localPosition = new Vector3(0.06f, 0.035f, -0.123f); knob.localEulerAngles = new Vector3(-90, 0, 0);
            Part(knob, "KnobMesh", MeshKit.Solid("knob", P(0, 0, 0.012f, 0, 0.012f, 0.01f, 0.009f, 0.014f, 0, 0.014f)), MaterialLibrary.PlasticGraphite, Vector3.zero);
            Box(t, "Led", new Vector3(0.006f, 0.006f, 0.004f), 0.0008f, MaterialLibrary.LedRed, new Vector3(0.085f, 0.05f, -0.122f));
            var v = go.AddComponent<InstrumentView>();
            v.display = display; v.knob = knob;
            var glowAt = new GameObject("HeatGlow"); glowAt.transform.SetParent(t, false); glowAt.transform.localPosition = new Vector3(0, 0.09f, 0.02f);
            v.statusLight = PointLight(glowAt, new Color(1f, 0.35f, 0.1f), 0.18f, 0.6f);
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.06f, -0.05f));
            v.attachPoint = Point(t, "Top", new Vector3(0, 0.078f, 0.02f));
            return go;
        }

        static GameObject WaterBath()
        {
            var go = Root("water_bath", out var t);
            // Open stainless tank (floor + four walls) so the water and the tubes in it are visible.
            Box(t, "Floor", new Vector3(0.34f, 0.01f, 0.24f), 0.003f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.005f, 0));
            Box(t, "WallFront", new Vector3(0.34f, 0.16f, 0.01f), 0.003f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.08f, -0.115f));
            Box(t, "WallBack", new Vector3(0.34f, 0.16f, 0.01f), 0.003f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.08f, 0.115f));
            Box(t, "WallL", new Vector3(0.01f, 0.16f, 0.24f), 0.003f, MaterialLibrary.SteelBrushed, new Vector3(-0.165f, 0.08f, 0));
            Box(t, "WallR", new Vector3(0.01f, 0.16f, 0.24f), 0.003f, MaterialLibrary.SteelBrushed, new Vector3(0.165f, 0.08f, 0));
            Box(t, "Water", new Vector3(0.32f, 0.11f, 0.22f), 0.002f, MaterialLibrary.GlassLens, new Vector3(0, 0.065f, 0));
            Box(t, "Rack", new Vector3(0.28f, 0.006f, 0.05f), 0.002f, MaterialLibrary.PlasticWhite, new Vector3(0, 0.13f, 0.03f));
            Box(t, "Panel", new Vector3(0.2f, 0.05f, 0.004f), 0.003f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.08f, -0.121f));
            var display = Text(t, "Display", "20.0 °C", new Vector3(-0.03f, 0.085f, -0.124f), 0.2f, new Color(0.35f, 0.85f, 1f), default, 0.12f);
            var knob = new GameObject("Knob").transform; knob.SetParent(t, false); knob.localPosition = new Vector3(0.07f, 0.08f, -0.123f); knob.localEulerAngles = new Vector3(-90, 0, 0);
            Part(knob, "KnobMesh", MeshKit.Solid("knob", P(0, 0, 0.012f, 0, 0.012f, 0.01f, 0.009f, 0.014f, 0, 0.014f)), MaterialLibrary.PlasticGraphite, Vector3.zero);
            var led = Box(t, "Led", new Vector3(0.006f, 0.006f, 0.003f), 0.001f, MaterialLibrary.LedGreen, new Vector3(0.09f, 0.095f, -0.123f));
            var v = go.AddComponent<InstrumentView>();
            v.display = display; v.knob = knob;
            v.statusLight = PointLight(led, new Color(0.3f, 1f, 0.5f), 0.04f, 0.08f);
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.12f, -0.05f));
            // Tubes stand in the rack with their bottoms under water.
            v.attachPoint = Point(t, "Rack", new Vector3(0, 0.03f, 0.03f));
            return go;
        }

        static GameObject BunsenWithTripod()
        {
            var go = Bunsen();
            var t = go.transform;
            for (int i = 0; i < 3; i++)
            {
                float a = i * 120 * Mathf.Deg2Rad;
                Cyl(t, "TripodLeg" + i, 0.003f, 0.2f, MaterialLibrary.SteelDark, new Vector3(Mathf.Cos(a) * 0.07f, 0, Mathf.Sin(a) * 0.07f));
            }
            Cyl(t, "TripodRing", 0.075f, 0.004f, MaterialLibrary.SteelDark, new Vector3(0, 0.2f, 0), default, 32);
            Box(t, "Gauze", new Vector3(0.12f, 0.002f, 0.12f), 0.001f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.205f, 0));
            go.GetComponent<InstrumentView>().attachPoint = Point(t, "OnGauze", new Vector3(0, 0.207f, 0));
            return go;
        }

        // ─── Measuring ───────────────────────────────────────────────────────

        static GameObject Thermometer()
        {
            var go = Root("thermometer", out var t);
            Box(t, "Body", new Vector3(0.03f, 0.05f, 0.012f), 0.005f, MaterialLibrary.PlasticWhite, new Vector3(0, 0.2f, 0));
            Box(t, "Screen", new Vector3(0.026f, 0.016f, 0.004f), 0.0008f, MaterialLibrary.Screen, new Vector3(0, 0.21f, -0.0055f));
            var display = Text(t, "Display", "20.0 °C", new Vector3(0, 0.21f, -0.0081f), 0.07f, new Color(0.35f, 1f, 0.6f), default, 0.024f);
            Cyl(t, "Probe", 0.0018f, 0.175f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.0f, 0), default, 12);
            var v = go.AddComponent<GenericView>();
            v.display = display;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.2f, 0));
            v.inspectDistance = 0.18f;
            return go;
        }

        static GameObject PhMeter()
        {
            var go = Root("ph_meter", out var t);
            Box(t, "Body", new Vector3(0.035f, 0.07f, 0.016f), 0.006f, MaterialLibrary.PlasticBlue, new Vector3(0, 0.2f, 0));
            Box(t, "Screen", new Vector3(0.028f, 0.016f, 0.004f), 0.0008f, MaterialLibrary.Screen, new Vector3(0, 0.215f, -0.0075f));
            var display = Text(t, "Display", "pH --", new Vector3(0, 0.215f, -0.0105f), 0.09f, new Color(0.35f, 1f, 0.6f), default, 0.026f);
            Cyl(t, "Electrode", 0.004f, 0.16f, MaterialLibrary.GlassClear, new Vector3(0, 0.0f, 0), default, 16);
            Part(t, "Bulb", MeshKit.Sphere("phbulb", 0.005f, 12), MaterialLibrary.GlassClear, new Vector3(0, 0.0f, 0));
            var v = go.AddComponent<GenericView>();
            v.display = display;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.2f, 0));
            v.inspectDistance = 0.18f;
            return go;
        }

        static GameObject Balance()
        {
            var go = Root("balance", out var t);
            Box(t, "Body", new Vector3(0.2f, 0.05f, 0.26f), 0.012f, MaterialLibrary.PlasticWhite, new Vector3(0, 0.025f, 0));
            Cyl(t, "Pan", 0.075f, 0.006f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.05f, 0.03f), default, 48);
            Box(t, "Screen", new Vector3(0.1f, 0.025f, 0.004f), 0.002f, MaterialLibrary.Screen, new Vector3(0, 0.03f, -0.131f));
            var display = Text(t, "Display", "0.00 g", new Vector3(0, 0.03f, -0.134f), 0.22f, new Color(0.35f, 1f, 0.6f), default, 0.095f);
            Box(t, "Tare", new Vector3(0.02f, 0.008f, 0.004f), 0.002f, MaterialLibrary.AccentEmerald, new Vector3(0.075f, 0.03f, -0.131f));
            var v = go.AddComponent<InstrumentView>();
            v.display = display;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.04f, -0.08f));
            v.attachPoint = Point(t, "PanTop", new Vector3(0, 0.054f, 0.03f));
            v.inspectDistance = 0.3f;
            return go;
        }

        static GameObject LightGate()
        {
            var go = Root("light_gate", out var t);
            Box(t, "Base", new Vector3(0.12f, 0.012f, 0.06f), 0.003f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.006f, 0));
            Box(t, "ArmL", new Vector3(0.012f, 0.12f, 0.03f), 0.003f, MaterialLibrary.PlasticBlue, new Vector3(-0.05f, 0.07f, 0));
            Box(t, "ArmR", new Vector3(0.012f, 0.12f, 0.03f), 0.003f, MaterialLibrary.PlasticBlue, new Vector3(0.05f, 0.07f, 0));
            Box(t, "Beam", new Vector3(0.088f, 0.002f, 0.002f), 0.0005f, MaterialLibrary.LedRed, new Vector3(0, 0.1f, 0));
            Box(t, "Screen", new Vector3(0.08f, 0.025f, 0.004f), 0.002f, MaterialLibrary.Screen, new Vector3(0, 0.025f, -0.032f));
            var display = Text(t, "Display", "0.000 m/s", new Vector3(0, 0.025f, -0.035f), 0.16f, new Color(0.35f, 1f, 0.6f), default, 0.075f);
            var v = go.AddComponent<GenericView>(); // snaps to the foot of the ramp when set up
            v.display = display;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.05f, 0));
            return go;
        }

        // ─── Tools & samples ─────────────────────────────────────────────────

        static GameObject Splint()
        {
            var go = Root("splint", out var t);
            Box(t, "Stick", new Vector3(0.15f, 0.003f, 0.006f), 0.001f, MaterialLibrary.Wood, new Vector3(0, 0.003f, 0));
            Box(t, "Tip", new Vector3(0.01f, 0.0035f, 0.0065f), 0.001f, MaterialLibrary.LedRed, new Vector3(0.075f, 0.003f, 0));
            var v = go.AddComponent<GenericView>();
            v.placesSomewhere = true;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.01f, 0));
            v.inspectDistance = 0.15f;
            return go;
        }

        static GameObject DeliveryTube()
        {
            var go = Root("delivery_tube", out var t);
            Part(t, "Bung", MeshKit.Solid("bung", P(0, 0, 0.0075f, 0, 0.0095f, 0.02f, 0, 0.02f)), MaterialLibrary.Rubber, Vector3.zero);
            Cyl(t, "Up", 0.0025f, 0.08f, MaterialLibrary.GlassClear, new Vector3(0, 0.0f, 0), default, 12);
            Cyl(t, "Across", 0.0025f, 0.14f, MaterialLibrary.GlassClear, new Vector3(0, 0.08f, 0), new Vector3(0, 0, -90), 12);
            Cyl(t, "Down", 0.0025f, 0.1f, MaterialLibrary.GlassClear, new Vector3(0.14f, 0.08f, 0), new Vector3(180, 0, 0), 12);
            var v = go.AddComponent<GenericView>();
            v.placesSomewhere = true;
            v.focusPoint = Point(t, "Focus", new Vector3(0.07f, 0.06f, 0));
            return go;
        }

        static GameObject PotatoCylinder()
        {
            var go = Root("potato_cylinder", out var t);
            Cyl(t, "Potato", 0.0045f, 0.03f, MaterialLibrary.ResistorBeige, Vector3.zero, default, 20);
            var v = go.AddComponent<GenericView>();
            v.placesSomewhere = true;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.015f, 0));
            v.inspectDistance = 0.12f;
            return go;
        }

        static GameObject Pondweed()
        {
            var go = Root("pondweed", out var t);
            for (int i = 0; i < 5; i++)
            {
                float a = i * 72 * Mathf.Deg2Rad;
                Cyl(t, "Stem" + i, 0.0012f, 0.09f + i * 0.006f, MaterialLibrary.BoardGreen, new Vector3(Mathf.Cos(a) * 0.004f, 0, Mathf.Sin(a) * 0.004f), new Vector3(Mathf.Sin(a) * 8, 0, Mathf.Cos(a) * 8), 6);
                for (int k = 0; k < 4; k++) Box(t, $"Leaf{i}_{k}", new Vector3(0.012f, 0.001f, 0.004f), 0.0005f, MaterialLibrary.BoardGreen, new Vector3(Mathf.Cos(a) * 0.01f, 0.02f + k * 0.02f, Mathf.Sin(a) * 0.01f), new Vector3(0, i * 72 + k * 40, 25));
            }
            var tip = Point(t, "Tip", new Vector3(0, 0.1f, 0));
            var ps = new GameObject("O2Bubbles").AddComponent<ParticleSystem>();
            ps.transform.SetParent(tip, false); ps.transform.localEulerAngles = new Vector3(-90, 0, 0);
            var main = ps.main; main.startSize = 0.003f; main.startSpeed = 0.04f; main.startLifetime = 1.5f; main.startColor = new Color(1, 1, 1, 0.7f); main.simulationSpace = ParticleSystemSimulationSpace.World;
            var em = ps.emission; em.rateOverTime = 0;
            var sh = ps.shape; sh.shapeType = ParticleSystemShapeType.Sphere; sh.radius = 0.002f;
            ps.GetComponent<ParticleSystemRenderer>().sharedMaterial = AssetDatabase.LoadAssetAtPath<Material>(MaterialLibrary.FxDir + "/Bubble.mat") ?? MaterialLibrary.GlassClear;
            var v = go.AddComponent<GenericView>();
            v.placesSomewhere = true;
            v.bubbles = ps;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.05f, 0));
            v.inspectDistance = 0.2f;
            return go;
        }

        static GameObject DeskLamp()
        {
            var go = Root("lamp", out var t);
            Cyl(t, "Base", 0.06f, 0.015f, MaterialLibrary.PlasticGraphite, Vector3.zero, default, 32);
            Cyl(t, "Arm", 0.006f, 0.3f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.015f, 0));
            var head = new GameObject("Head").transform; head.SetParent(t, false); head.localPosition = new Vector3(0, 0.3f, 0); head.localEulerAngles = new Vector3(0, 0, 60);
            // Hollow shade, open at the bottom, so the bulb shows.
            Part(head, "Shade", MeshKit.Lathe("lampshade2", P(0.05f, 0, 0.02f, 0.06f), 0.002f, 32).Glass, MaterialLibrary.PlasticGraphite, new Vector3(0, -0.06f, 0));
            var bulb = Part(head, "BulbGlow", MeshKit.Sphere("lampbulb", 0.018f, 14), MaterialLibrary.LightPanel, new Vector3(0, -0.035f, 0));
            var lightGo = new GameObject("Spot"); lightGo.transform.SetParent(head, false); lightGo.transform.localPosition = new Vector3(0, -0.04f, 0); lightGo.transform.localEulerAngles = new Vector3(90, 0, 0);
            var l = lightGo.AddComponent<Light>(); l.type = LightType.Spot; l.spotAngle = 80; l.range = 1.5f; l.intensity = 8f; l.color = new Color(1f, 0.95f, 0.85f); l.enabled = false;
            var v = go.AddComponent<MechanicsView>();
            v.lampLight = l; v.lampGlow = bulb.GetComponent<Renderer>();
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.2f, 0));
            return go;
        }

        static GameObject Scalpel()
        {
            var go = Root("scalpel", out var t);
            Box(t, "Handle", new Vector3(0.1f, 0.004f, 0.01f), 0.0015f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.002f, 0));
            Box(t, "Blade", new Vector3(0.03f, 0.002f, 0.008f), 0.0005f, MaterialLibrary.SteelDark, new Vector3(0.065f, 0.002f, 0));
            var v = go.AddComponent<GenericView>();
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.01f, 0)); v.inspectDistance = 0.15f;
            return go;
        }

        static GameObject Forceps()
        {
            var go = Root("forceps", out var t);
            Box(t, "ArmA", new Vector3(0.12f, 0.003f, 0.005f), 0.001f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.002f, 0.004f), new Vector3(0, 3, 0));
            Box(t, "ArmB", new Vector3(0.12f, 0.003f, 0.005f), 0.001f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.002f, -0.004f), new Vector3(0, -3, 0));
            var v = go.AddComponent<GenericView>();
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.01f, 0)); v.inspectDistance = 0.15f;
            return go;
        }

        // ─── Electricity ─────────────────────────────────────────────────────

        static GameObject Battery()
        {
            var go = Root("battery", out var t);
            Box(t, "Holder", new Vector3(0.08f, 0.02f, 0.04f), 0.004f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.01f, 0));
            Cyl(t, "CellA", 0.007f, 0.05f, MaterialLibrary.AccentEmerald, new Vector3(-0.025f, 0.022f, -0.009f), new Vector3(0, 0, -90), 20);
            Cyl(t, "CellB", 0.007f, 0.05f, MaterialLibrary.AccentEmerald, new Vector3(-0.025f, 0.022f, 0.009f), new Vector3(0, 0, -90), 20);
            var display = Text(t, "Display", "3 V", new Vector3(0, 0.0205f, -0.021f), 0.12f, Color.white, default, 0.04f);
            var v = go.AddComponent<GenericView>();
            v.display = display;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.02f, 0)); v.inspectDistance = 0.15f;
            return go;
        }

        static GameObject Switch()
        {
            var go = Root("switch", out var t);
            Box(t, "Base", new Vector3(0.06f, 0.01f, 0.04f), 0.003f, MaterialLibrary.Wood, new Vector3(0, 0.005f, 0));
            Box(t, "Lever", new Vector3(0.045f, 0.004f, 0.008f), 0.001f, MaterialLibrary.Brass, new Vector3(0, 0.016f, 0), new Vector3(0, 0, 15));
            Cyl(t, "Contact", 0.004f, 0.006f, MaterialLibrary.Brass, new Vector3(0.02f, 0.01f, 0));
            var v = go.AddComponent<GenericView>();
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.015f, 0)); v.inspectDistance = 0.15f;
            return go;
        }

        static GameObject Rheostat()
        {
            var go = Root("variable_resistor", out var t);
            Box(t, "Base", new Vector3(0.22f, 0.012f, 0.05f), 0.003f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.006f, 0));
            Cyl(t, "Coil", 0.014f, 0.18f, MaterialLibrary.Brass, new Vector3(-0.09f, 0.03f, 0), new Vector3(0, 0, -90), 24);
            Box(t, "Rail", new Vector3(0.19f, 0.004f, 0.004f), 0.001f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.05f, 0));
            Box(t, "Slider", new Vector3(0.014f, 0.016f, 0.02f), 0.003f, MaterialLibrary.AccentBlue, new Vector3(0, 0.05f, 0));
            var display = Text(t, "Display", "50 Ω", new Vector3(0.08f, 0.0125f, -0.026f), 0.1f, Color.white, default, 0.04f);
            var v = go.AddComponent<GenericView>();
            v.display = display;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.03f, 0)); v.inspectDistance = 0.25f;
            return go;
        }

        static GameObject Bulb()
        {
            var go = Root("bulb", out var t);
            Box(t, "Holder", new Vector3(0.05f, 0.015f, 0.04f), 0.004f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.0075f, 0));
            Cyl(t, "Socket", 0.008f, 0.012f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.015f, 0));
            Part(t, "GlassBulb", MeshKit.Sphere("bulbglass", 0.016f, 16), MaterialLibrary.GlassClear, new Vector3(0, 0.042f, 0));
            var glow = Part(t, "Filament", MeshKit.Sphere("filament", 0.005f, 8), MaterialLibrary.LightPanel, new Vector3(0, 0.042f, 0));
            var v = go.AddComponent<GenericView>();
            v.glow = glow.GetComponent<Renderer>();
            v.glowLight = PointLight(glow, new Color(1f, 0.85f, 0.55f), 0.5f, 0.6f);
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.03f, 0)); v.inspectDistance = 0.15f;
            return go;
        }

        static GameObject Led()
        {
            var go = Root("led", out var t);
            Box(t, "Holder", new Vector3(0.04f, 0.012f, 0.03f), 0.003f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.006f, 0));
            Part(t, "Dome", MeshKit.Solid("leddome", P(0, 0, 0.0025f, 0, 0.0025f, 0.005f, 0.0015f, 0.007f, 0, 0.0075f)), MaterialLibrary.GlassClear, new Vector3(0, 0.012f, 0));
            var glow = Part(t, "Glow", MeshKit.Sphere("ledglow", 0.002f, 8), MaterialLibrary.LedRed, new Vector3(0, 0.016f, 0));
            var v = go.AddComponent<GenericView>();
            v.glow = glow.GetComponent<Renderer>();
            v.glowLight = PointLight(glow, new Color(1f, 0.25f, 0.2f), 0.15f, 0.4f);
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.015f, 0)); v.inspectDistance = 0.12f;
            return go;
        }

        // ─── Forces & motion ─────────────────────────────────────────────────

        static GameObject Spring()
        {
            var go = Root("spring", out var t);
            Box(t, "Base", new Vector3(0.18f, 0.014f, 0.2f), 0.004f, MaterialLibrary.SteelDark, new Vector3(0, 0.007f, 0.04f));
            Cyl(t, "Rod", 0.0065f, 0.7f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.014f, 0.1f));
            Box(t, "Arm", new Vector3(0.018f, 0.018f, 0.12f), 0.004f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.7f, 0.05f));
            // Coil: rings stacked under the arm; the view stretches it.
            var coil = new GameObject("Coil").transform; coil.SetParent(t, false); coil.localPosition = new Vector3(0, 0.69f, 0);
            for (int i = 0; i < 20; i++) Cyl(coil, "Ring" + i, 0.009f, 0.0016f, MaterialLibrary.SteelBrushed, new Vector3(0, -0.005f * (i + 1), 0), new Vector3(i % 2 == 0 ? 6 : -6, 0, 0), 16);
            var hanger = new GameObject("Hanger").transform; hanger.SetParent(t, false); hanger.localPosition = new Vector3(0, 0.69f - 0.10f, 0);
            Cyl(hanger, "Hook", 0.0015f, 0.03f, MaterialLibrary.SteelBrushed, new Vector3(0, -0.03f, 0), default, 8);
            for (int i = 0; i < 10; i++) Cyl(hanger, "Mass" + i, 0.02f, 0.007f, MaterialLibrary.Brass, new Vector3(0, -0.034f - i * 0.0075f, 0), default, 24);
            // Pointer + scale (the metre rule is optional; the stand has its own cm scale).
            Box(t, "Scale", new Vector3(0.02f, 0.45f, 0.004f), 0.001f, MaterialLibrary.PlasticWhite, new Vector3(0.05f, 0.42f, 0));
            var display = Text(t, "Display", "0 g", new Vector3(0, 0.03f, -0.065f), 0.12f, Color.white, default, 0.06f);
            var v = go.AddComponent<MechanicsView>();
            v.coil = coil; v.hanger = hanger; v.coilRestLength = 0.10f; v.display = display;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.55f, 0));
            v.inspectDistance = 0.8f;
            return go;
        }

        static GameObject Ramp()
        {
            var go = Root("ramp", out var t);
            Box(t, "Stand", new Vector3(0.05f, 0.02f, 0.12f), 0.004f, MaterialLibrary.SteelDark, new Vector3(0.45f, 0.01f, 0));
            var pivot = new GameObject("RampPivot").transform; pivot.SetParent(t, false); pivot.localPosition = new Vector3(-0.5f, 0.02f, 0);
            var board = new GameObject("Board").transform; board.SetParent(pivot, false); board.localPosition = new Vector3(0.5f, 0, 0);
            Box(board, "Plank", new Vector3(1.0f, 0.012f, 0.12f), 0.003f, MaterialLibrary.Wood, Vector3.zero);
            Box(board, "RailL", new Vector3(1.0f, 0.01f, 0.006f), 0.002f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.011f, 0.05f));
            Box(board, "RailR", new Vector3(1.0f, 0.01f, 0.006f), 0.002f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.011f, -0.05f));
            var trolley = new GameObject("Trolley").transform; trolley.SetParent(board, false); trolley.localPosition = new Vector3(0.45f, 0.03f, 0);
            Box(trolley, "Body", new Vector3(0.1f, 0.03f, 0.08f), 0.006f, MaterialLibrary.PlasticBlue, Vector3.zero);
            Box(trolley, "Card", new Vector3(0.05f, 0.04f, 0.002f), 0.001f, MaterialLibrary.PlasticWhite, new Vector3(0, 0.035f, 0));
            foreach (var (x, z) in new[] { (0.035f, 0.042f), (-0.035f, 0.042f), (0.035f, -0.042f), (-0.035f, -0.042f) })
                Cyl(trolley, "Wheel", 0.012f, 0.006f, MaterialLibrary.Rubber, new Vector3(x, -0.012f, z), new Vector3(90, 0, 0), 16);
            var v = go.AddComponent<MechanicsView>();
            v.rampPivot = pivot; v.trolley = trolley; v.rampLength = 1.0f;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.15f, 0));
            v.attachPoint = Point(t, "Bottom", new Vector3(-0.45f, 0.02f, -0.09f));
            v.inspectDistance = 1.2f;
            return go;
        }

        static GameObject MetalBlock()
        {
            var go = Root("metal_block", out var t);
            Box(t, "Block", new Vector3(0.027f, 0.027f, 0.027f), 0.002f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.0135f, 0));
            var v = go.AddComponent<GenericView>();
            v.placesSomewhere = true;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.014f, 0)); v.inspectDistance = 0.15f;
            return go;
        }

        // ─── Light ───────────────────────────────────────────────────────────

        static GameObject LightBox()
        {
            var go = Root("light_box", out var t);
            Box(t, "Box", new Vector3(0.08f, 0.1f, 0.1f), 0.006f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.05f, 0));
            var window = Box(t, "Window", new Vector3(0.002f, 0.05f, 0.05f), 0.001f, MaterialLibrary.LightPanel, new Vector3(0.041f, 0.06f, 0));
            Box(t, "ArrowObject", new Vector3(0.0025f, 0.02f, 0.004f), 0.0005f, MaterialLibrary.WireBlack, new Vector3(0.0425f, 0.06f, 0));
            var v = go.AddComponent<MechanicsView>();
            v.lampLight = PointLight(window, new Color(1f, 0.95f, 0.8f), 0.4f, 0.8f);
            v.lampGlow = window.GetComponent<Renderer>();
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.06f, 0));
            return go;
        }

        static GameObject ConvexLens()
        {
            var go = Root("convex_lens", out var t);
            Box(t, "Foot", new Vector3(0.04f, 0.01f, 0.04f), 0.003f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.005f, 0));
            Cyl(t, "Post", 0.003f, 0.05f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.01f, 0), default, 10);
            Part(t, "Lens", MeshKit.Sphere("lens", 0.025f, 20), MaterialLibrary.GlassLens, new Vector3(0, 0.06f, 0)).transform.localScale = new Vector3(0.22f, 1, 1);
            var v = go.AddComponent<MechanicsView>();
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.06f, 0)); v.inspectDistance = 0.4f;
            return go;
        }

        static GameObject Screen()
        {
            var go = Root("screen", out var t);
            Box(t, "Foot", new Vector3(0.04f, 0.01f, 0.06f), 0.003f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.005f, 0));
            Box(t, "Board", new Vector3(0.004f, 0.1f, 0.1f), 0.002f, MaterialLibrary.Fabric, new Vector3(0, 0.06f, 0));
            var scale = new GameObject("ImageScale").transform; scale.SetParent(t, false); scale.localPosition = new Vector3(-0.0025f, 0.06f, 0);
            var img = Box(scale, "Image", new Vector3(0.0005f, 0.02f, 0.006f), 0.0002f, MaterialLibrary.LightPanel, Vector3.zero);
            var v = go.AddComponent<MechanicsView>();
            v.image = img.GetComponent<Renderer>(); v.imageScale = scale;
            v.focusPoint = Point(t, "Focus", new Vector3(0, 0.06f, 0)); v.inspectDistance = 0.35f;
            return go;
        }
    }
}
