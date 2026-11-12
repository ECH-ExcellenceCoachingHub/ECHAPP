using System.IO;
using System.Linq;
using ECHLabs.Core;
using ECHLabs.Runtime.Equipment;
using ECHLabs.Runtime.World;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace ECHLabs.EditorTools
{
    /// <summary>
    /// Renders every room from its QA shots (with a real scenario's equipment placed and a
    /// mid-experiment state, e.g. half-titrated pink flask) into labs-unity/QA/*.png.
    /// These images are how the scenes are reviewed and tuned without opening the Editor.
    /// batch: -executeMethod ECHLabs.EditorTools.ScreenshotQA.Run
    /// </summary>
    public static class ScreenshotQA
    {
        static readonly (string room, string scenario)[] Samples =
        {
            ("ChemLab", "chem-titration-hcl-naoh"),
            ("PhysicsLab", "phys-ohms-law"),
            ("CyberSOC", "cyber-firewall-basics"),
        };

        [MenuItem("ECH Labs/Render QA screenshots")]
        public static void Run()
        {
            string outDir = Path.GetFullPath(Path.Combine(Application.dataPath, "../QA"));
            Directory.CreateDirectory(outDir);
            foreach (var path in Directory.GetFiles(SceneBuilder.SceneDir, "*.unity").Where(p => !p.EndsWith("Bootstrap.unity")))
            {
                var scene = EditorSceneManager.OpenScene(path.Replace('\\', '/'), OpenSceneMode.Single);
                var sample = Samples.FirstOrDefault(s => s.room == scene.name);
                if (sample.scenario != null) StageScenario(sample.scenario, scene.GetRootGameObjects()[0].transform);

                var shots = scene.GetRootGameObjects().SelectMany(g => g.GetComponentsInChildren<Transform>()).Where(t => t.name.StartsWith("QAShot_")).ToList();
                foreach (var shot in shots)
                {
                    string file = Path.Combine(outDir, $"{scene.name}_{shot.name.Substring(7)}.png");
                    Render(shot, file, 1920, 1080);
                    Debug.Log("[ECHLabs] QA → " + file);
                }
            }
        }

        /// <summary>Spawns the scenario's equipment and advances it to an interesting moment.</summary>
        static void StageScenario(string id, Transform parent)
        {
            var asset = Resources.Load<TextAsset>("Scenarios/" + id);
            if (!asset) return;
            var def = ScenarioDefinition.FromJson(asset.text);
            var world = new LabWorld(def, 1);
            var views = EquipmentFactory.SpawnAll(world, parent);
            if (id.StartsWith("chem"))
            {
                world.Apply(Intent.Of(IntentType.Pour, "naoh", "burette1"));
                world.Apply(Intent.Of(IntentType.Pour, "naoh", "burette1"));
                world.Apply(Intent.Of(IntentType.Pour, "phth", "flask1"));
                world.Apply(Intent.Of(IntentType.Grab, "flask1", "tile1"));
                world.Apply(Intent.Of(IntentType.Rotate, "burette1", null, 1));
                for (int i = 0; i < (int)(60 * 8.12); i++) world.Tick(1 / 60.0);    // ≈20.3 mL: just past the end point (pale pink)
                world.Apply(Intent.Of(IntentType.Rotate, "burette1", null, 0));
                if (views.TryGetValue("flask1", out var f) && f is FlaskView fv && views.TryGetValue("tile1", out var tile)) { fv.PlaceAt(tile.Attach); f.transform.position = tile.Attach.position; }
            }
            if (id.StartsWith("phys-ohms"))
            {
                world.Apply(Intent.Of(IntentType.Connect, "r1", "board"));
                world.Apply(Intent.Of(IntentType.Connect, "amm", "board"));
                world.Apply(Intent.Of(IntentType.Connect, "volt", "board"));
                world.Apply(Intent.Of(IntentType.Toggle, "psu"));
                world.Apply(Intent.Of(IntentType.Rotate, "psu", null, 6));
                world.Tick(0.1);
            }
            // Views animate towards state over time; render a few seconds of frames instantly.
            for (int i = 0; i < 240; i++) foreach (var v in views.Values) v.Render(1 / 60f);
            foreach (var lv in parent.GetComponentsInChildren<LiquidVolume>())
            {
                lv.SendMessage("LateUpdate", SendMessageOptions.DontRequireReceiver);
                Debug.Log($"[ECHLabs] QA liquid {lv.transform.parent.name}: {lv.VolumeMl:0.0} mL colour {lv.Color}");
            }
            foreach (var v in world.Variables) foreach (var o in v.Value) Debug.Log($"[ECHLabs] QA {v.Key}.{o.Key} = {o.Value}");
        }

        static void Render(Transform shot, string file, int w, int h)
        {
            var go = new GameObject("QA Camera");
            var cam = go.AddComponent<Camera>();
            go.transform.SetPositionAndRotation(shot.position, shot.rotation);
            cam.fieldOfView = 55;
            cam.nearClipPlane = 0.02f;
            cam.farClipPlane = 60;
            var data = go.AddComponent<UniversalAdditionalCameraData>();
            data.renderPostProcessing = true;
            data.antialiasing = AntialiasingMode.SubpixelMorphologicalAntiAliasing;
            var post = new GameObject("QA PostFX").AddComponent<UnityEngine.Rendering.Volume>();
            post.isGlobal = true;
            post.sharedProfile = AssetDatabase.LoadAssetAtPath<UnityEngine.Rendering.VolumeProfile>(ProjectSetup.PostProfilePath);

            var rt = new RenderTexture(w, h, 24, RenderTextureFormat.ARGB32) { antiAliasing = 4 };
            cam.targetTexture = rt;
            cam.Render();
            RenderTexture.active = rt;
            var tex = new Texture2D(w, h, TextureFormat.RGB24, false);
            tex.ReadPixels(new Rect(0, 0, w, h), 0, 0);
            tex.Apply();
            var png = tex.EncodeToPNG();
            try { File.WriteAllBytes(file, png); }
            catch (IOException e)
            {
                // The PNG may be open in a viewer: write next to it instead of failing the run.
                var alt = Path.ChangeExtension(file, null) + "_new.png";
                File.WriteAllBytes(alt, png);
                Debug.LogWarning($"[ECHLabs] {Path.GetFileName(file)} is locked ({e.Message}); wrote {Path.GetFileName(alt)}");
            }
            RenderTexture.active = null;
            cam.targetTexture = null;
            Object.DestroyImmediate(rt);
            Object.DestroyImmediate(tex);
            Object.DestroyImmediate(go);
            Object.DestroyImmediate(post.gameObject);
        }
    }
}
