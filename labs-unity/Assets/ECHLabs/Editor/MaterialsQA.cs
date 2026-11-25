using System.IO;
using System.Linq;
using ECHLabs.Core;
using ECHLabs.Runtime.Equipment;
using ECHLabs.Runtime.World;
using Newtonsoft.Json;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace ECHLabs.EditorTools
{
    /// <summary>
    /// Renders the general lab materials in use (labs-unity/QA/Materials_*.png): reactions with
    /// real colours, precipitates, heaters, probes, circuits, spring, ramp and optics.
    /// batch: -executeMethod ECHLabs.EditorTools.MaterialsQA.Run
    /// </summary>
    public static class MaterialsQA
    {
        static object Eq(string id, string type, string slot, object init = null, string label = null) => new { id, type, slot, label, init = init ?? new { } };

        static LabWorld Stage(string room, object[] equipment, Transform parent, out System.Collections.Generic.Dictionary<string, EquipmentView> views)
        {
            var def = new { id = "qa-" + room.ToLowerInvariant(), version = 1, title = "QA", summary = "QA", subject = "chemistry", environment = room, objectives = new[] { "QA" }, equipment, variables = new { }, steps = new[] { new { id = "s1", kind = "info", instruction = "QA" } } };
            var world = new LabWorld(ScenarioDefinition.FromJson(JsonConvert.SerializeObject(def)), 3);
            views = EquipmentFactory.SpawnAll(world, parent);
            return world;
        }

        [MenuItem("ECH Labs/Render materials QA")]
        public static void Run()
        {
            string outDir = Path.GetFullPath(Path.Combine(Application.dataPath, "../QA"));
            Directory.CreateDirectory(outDir);

            // ── Chemistry: tests and reactions on bench A, heat and measuring on bench B ──
            {
                var scene = EditorSceneManager.OpenScene($"{SceneBuilder.SceneDir}/ChemLab.unity", OpenSceneMode.Single);
                var root = scene.GetRootGameObjects()[0].transform;
                var w = Stage("ChemLab", new[]
                {
                    Eq("t1", "test_tube", "benchA.left", new { solution = "CuSO4", conc = 0.5, volume = 10 }, "CuSO4"),
                    Eq("t2", "test_tube", "benchA.left", new { solution = "NaCl", conc = 0.2, volume = 10 }, "NaCl"),
                    Eq("t3", "test_tube", "benchA.left", new { solution = "FeCl3", conc = 0.2, volume = 10 }, "FeCl3"),
                    Eq("t4", "test_tube", "benchA.left", new { solution = "HCl", conc = 1, volume = 12 }, "HCl + Mg"),
                    Eq("u1", "test_tube", "benchA.center", new { solution = "HCl", conc = 0.1, volume = 10 }, "pH 1"),
                    Eq("u2", "test_tube", "benchA.center", new { solution = "CH3COOH", conc = 0.1, volume = 10 }, "pH 3"),
                    Eq("u3", "test_tube", "benchA.center", new { solution = "water", volume = 10 }, "pH 7"),
                    Eq("u4", "test_tube", "benchA.center", new { solution = "NaOH", conc = 0.1, volume = 10 }, "pH 13"),
                    Eq("naoh", "reagent_bottle", "shelf.1", new { solution = "NaOH", conc = 1, volume = 500 }, "NaOH 1 M"),
                    Eq("silver", "dropper_bottle", "benchA.right", new { reagent = "AgNO3" }, "Silver nitrate"),
                    Eq("uni", "dropper_bottle", "benchA.right", new { reagent = "universal" }, "Universal ind."),
                    Eq("mg", "solid_jar", "benchA.right", new { substance = "Mg" }, "Magnesium"),
                    Eq("beaker1", "beaker", "benchB.left", new { solution = "NaCl", conc = 1, volume = 150 }, "Salt water"),
                    Eq("plate", "hot_plate", "benchB.left", new { powerW = 400 }),
                    Eq("thermo", "thermometer", "benchB.center"),
                    Eq("phm", "ph_meter", "benchB.center"),
                    Eq("bal", "balance", "benchB.right"),
                    Eq("dish", "evaporating_dish", "benchB.right", new { solution = "CuSO4", conc = 1, volume = 20 }, "CuSO4"),
                    Eq("cyl", "measuring_cylinder", "benchC.left", new { solution = "water", volume = 64 }),
                    Eq("bunsen", "bunsen_burner", "benchC.center"),
                    Eq("splint", "splint", "benchC.right", new { mode = "lit" }),
                }, root, out var views);
                w.Apply(Intent.Of(IntentType.Pour, "naoh", "t1", 3));
                w.Apply(Intent.Of(IntentType.Pour, "silver", "t2"));
                w.Apply(Intent.Of(IntentType.Pour, "naoh", "t3", 3));
                w.Apply(Intent.Of(IntentType.Pour, "mg", "t4"));
                foreach (var u in new[] { "u1", "u2", "u3", "u4" }) w.Apply(Intent.Of(IntentType.Pour, "uni", u, 0.5));
                w.Apply(Intent.Of(IntentType.Grab, "beaker1", "plate"));
                w.Apply(Intent.Of(IntentType.Toggle, "plate"));
                w.Apply(Intent.Of(IntentType.Connect, "thermo", "beaker1"));
                w.Apply(Intent.Of(IntentType.Connect, "phm", "u4"));
                w.Apply(Intent.Of(IntentType.Grab, "dish", "bal"));
                w.Apply(Intent.Of(IntentType.Toggle, "bunsen"));
                for (int i = 0; i < 60 * 40; i++) w.Tick(1 / 60.0);
                Animate(views, 300);
                Log(w, "t1", "t2", "t3", "t4", "u1", "u2", "u3", "u4", "beaker1");
                SlotShot(outDir, "Materials_Chem_tubes", "benchA.left", 40, 0.8f);
                SlotShot(outDir, "Materials_Chem_indicator", "benchA.center", 40, 0.8f);
                SlotShot(outDir, "Materials_Chem_heat", "benchB.left", 45, 0.9f);
                SlotShot(outDir, "Materials_Chem_balance", "benchB.right", 45, 0.9f);
                SlotShot(outDir, "Materials_Chem_benchC", "benchC.center", 60, 1.2f);
                Shot(outDir, "Materials_Chem_overview", new Vector3(0, 2.1f, -2.6f), new Vector3(0, 0.9f, 1.0f), 60);
            }

            // ── Physics: circuit with bulb + LED, spring, ramp + gate, optical bench ──
            {
                var scene = EditorSceneManager.OpenScene($"{SceneBuilder.SceneDir}/PhysicsLab.unity", OpenSceneMode.Single);
                var root = scene.GetRootGameObjects()[0].transform;
                var w = Stage("PhysicsLab", new[]
                {
                    Eq("psu", "power_supply", "benchA.left", new { maxVoltage = 12 }),
                    Eq("board", "breadboard", "benchA.center", new { layout = "parallel" }),
                    Eq("lamp", "bulb", "benchA.right", new { ratedVoltage = 6, ratedPower = 3 }),
                    Eq("led", "led", "benchA.right", new { colour = "red" }),
                    Eq("sw", "switch", "benchA.right"),
                    Eq("rh", "variable_resistor", "benchB.left", new { maxOhms = 100 }),
                    Eq("spring1", "spring", "benchB.center", new { springConstant = 20, elasticLimitN = 8 }),
                    Eq("cell", "battery", "benchB.right", new { voltage = 3 }),
                    Eq("block", "metal_block", "benchB.right", new { material = "brass", volumeCm3 = 20 }),
                    Eq("ramp1", "ramp", "benchC.center"),
                    Eq("gate", "light_gate", "benchC.right"),
                    Eq("box", "light_box", "optics.rail"),
                    Eq("lens", "convex_lens", "optics.rail", new { focalLengthCm = 10 }),
                    Eq("scr", "screen", "optics.rail"),
                }, root, out var views);
                foreach (var c in new[] { "lamp", "led", "sw" }) w.Apply(Intent.Of(IntentType.Connect, c, "board"));
                w.Apply(Intent.Of(IntentType.Toggle, "sw"));
                w.Apply(Intent.Of(IntentType.Toggle, "psu"));
                w.Apply(Intent.Of(IntentType.Rotate, "psu", null, 6));
                w.Apply(Intent.Of(IntentType.Rotate, "spring1", null, 300));
                w.Apply(Intent.Of(IntentType.Connect, "gate", "ramp1"));
                w.Apply(Intent.Of(IntentType.Rotate, "ramp1", null, 15));
                w.Apply(Intent.Of(IntentType.Release, "ramp1"));
                w.Apply(Intent.Of(IntentType.Toggle, "box"));
                w.Apply(Intent.Of(IntentType.Rotate, "lens", null, 30));
                w.Apply(Intent.Of(IntentType.Rotate, "scr", null, 15));
                for (int i = 0; i < 60 * 5; i++) w.Tick(1 / 60.0);
                Animate(views, 300);
                Debug.Log($"[ECHLabs] QA bulb lit={w.Bool("lamp", "lit")} brightness={w.Num("lamp", "brightness")} led={w.Bool("led", "lit")} spring ext={w.Num("spring1", "extensionCm")}cm gate={w.Num("gate", "reading")} screen sharp={w.Bool("scr", "sharp")}");
                SlotShot(outDir, "Materials_Phys_circuit", "benchA.center", 55, 1f);
                SlotShot(outDir, "Materials_Phys_spring", "benchB.center", 60, 1.4f);
                SlotShot(outDir, "Materials_Phys_ramp", "benchC.center", 60, 1.5f);
                SlotShot(outDir, "Materials_Phys_optics", "optics.rail", 55, 1.2f);
            }

            // ── Biology: food tests in a water bath, osmosis, pondweed + lamp ──
            {
                var scene = EditorSceneManager.OpenScene($"{SceneBuilder.SceneDir}/BioLab.unity", OpenSceneMode.Single);
                var root = scene.GetRootGameObjects()[0].transform;
                var w = Stage("BioLab", new[]
                {
                    Eq("starch", "test_tube", "benchA.left", new { solution = "starch_sol", volume = 8 }, "Starch"),
                    Eq("sugar", "test_tube", "benchA.left", new { solution = "glucose_sol", conc = 0.1, volume = 8 }, "Glucose"),
                    Eq("protein", "test_tube", "benchA.left", new { solution = "water", volume = 6 }, "Egg white"),
                    Eq("iod", "dropper_bottle", "benchA.center", new { reagent = "iodine" }, "Iodine"),
                    Eq("ben", "dropper_bottle", "benchA.center", new { reagent = "benedicts" }, "Benedict's"),
                    Eq("biu", "dropper_bottle", "benchA.center", new { reagent = "biuret" }, "Biuret"),
                    Eq("egg", "solid_jar", "benchA.center", new { substance = "egg_white" }, "Egg white"),
                    Eq("bath", "water_bath", "benchA.right", new { setpointC = 80 }),
                    Eq("b1", "beaker", "benchB.left", new { solution = "NaHCO3", conc = 0.1, volume = 200 }, "NaHCO3"),
                    Eq("weed", "pondweed", "benchB.left"),
                    Eq("lampA", "lamp", "benchB.center", new { distanceCm = 15 }),
                    Eq("p1", "potato_cylinder", "benchB.right", new { massG = 2.5 }),
                    Eq("bal", "balance", "benchB.right"),
                }, root, out var views);
                w.Apply(Intent.Of(IntentType.Pour, "iod", "starch"));
                w.Apply(Intent.Of(IntentType.Pour, "ben", "sugar")); w.Apply(Intent.Of(IntentType.Pour, "ben", "sugar"));
                w.Apply(Intent.Of(IntentType.Toggle, "bath"));
                w.Apply(Intent.Of(IntentType.Grab, "sugar", "bath"));
                w.Apply(Intent.Of(IntentType.Pour, "egg", "protein")); w.Apply(Intent.Of(IntentType.Pour, "biu", "protein"));
                w.Apply(Intent.Of(IntentType.Grab, "weed", "b1"));
                w.Apply(Intent.Of(IntentType.Toggle, "lampA"));
                w.Apply(Intent.Of(IntentType.Grab, "p1", "bal"));
                for (int i = 0; i < 60 * 90; i++) w.Tick(1 / 60.0);
                Animate(views, 300);
                Log(w, "starch", "sugar", "protein", "b1");
                Debug.Log($"[ECHLabs] QA pondweed {w.Num("weed", "bubblesPerMin")} bubbles/min, balance {w.Num("bal", "reading")} g");
                SlotShot(outDir, "Materials_Bio_foodtests", "benchA.left", 45, 0.9f);
                SlotShot(outDir, "Materials_Bio_bath", "benchA.right", 45, 0.9f);
                SlotShot(outDir, "Materials_Bio_pondweed", "benchB.left", 50, 1f);
            }
        }

        static void Animate(System.Collections.Generic.Dictionary<string, EquipmentView> views, int frames)
        {
            for (int i = 0; i < frames; i++) foreach (var v in views.Values) v.Render(1 / 60f);
            // Anything that would render magenta (missing material / shader) is reported.
            foreach (var r in Object.FindObjectsByType<Renderer>())
            {
                var mats = r.sharedMaterials;
                if (mats.Length == 0 || mats.Any(m => !m || !m.shader || !m.shader.isSupported))
                    Debug.LogWarning($"[ECHLabs] QA MAGENTA {r.transform.parent?.name}/{r.name} ({r.GetType().Name}) mats={string.Join(",", mats.Select(m => m ? m.name : "NULL"))}");
            }
            foreach (var lv in Object.FindObjectsByType<LiquidVolume>()) lv.SendMessage("LateUpdate", SendMessageOptions.DontRequireReceiver);
        }

        static void Log(LabWorld w, params string[] ids)
        {
            foreach (var id in ids)
                Debug.Log($"[ECHLabs] QA {id}: {w.Str(id, "observation")} | colour {w.Str(id, "colour")} pH {w.Num(id, "pH"):0.00} T {w.Num(id, "temperatureC"):0.0} °C");
        }

        /// <summary>Close-up from a slot's own viewpoint (the camera a student gets with GO TO).</summary>
        static void SlotShot(string dir, string name, string slot, float fov = 50, float pull = 1f)
        {
            var a = Object.FindObjectsByType<SlotAnchor>().FirstOrDefault(x => x.slotId == slot);
            if (!a) { Debug.LogWarning("[ECHLabs] QA: no slot " + slot); return; }
            var target = a.transform.position + Vector3.up * 0.08f;
            var from = a.viewpoint ? a.viewpoint.position : a.transform.position + new Vector3(0, 0.6f, -0.7f);
            Shot(dir, name, target + (from - target) * pull, target, fov);
        }

        static void Shot(string dir, string name, Vector3 pos, Vector3 look, float fov)
        {
            var t = new GameObject("QAShot_tmp").transform;
            t.position = pos;
            t.LookAt(look);
            // First render of a shader variant in batch mode can come out magenta while it compiles: warm up first.
            ScreenshotQA.RenderShot(t, Path.Combine(dir, name + ".png"), 320, 180, fov);
            ScreenshotQA.RenderShot(t, Path.Combine(dir, name + ".png"), 1600, 900, fov);
            Object.DestroyImmediate(t.gameObject);
            Debug.Log("[ECHLabs] QA → " + name);
        }
    }
}
