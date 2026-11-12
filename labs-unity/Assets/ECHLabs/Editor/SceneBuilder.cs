using System.Collections.Generic;
using System.IO;
using System.Linq;
using ECHLabs.Runtime;
using ECHLabs.Runtime.Interaction;
using ECHLabs.Runtime.Rendering;
using ECHLabs.Runtime.UI;
using ECHLabs.Runtime.World;
using Newtonsoft.Json.Linq;
using TMPro;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.InputSystem.UI;
using UnityEngine.EventSystems;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.SceneManagement;
using UnityEngine.UIElements;

namespace ECHLabs.EditorTools
{
    /// <summary>
    /// Generates every scene from data — no hand placement:
    ///   Bootstrap.unity  (session, rigs, HUD, post FX)
    ///   &lt;Room&gt;.unity     from labs-unity/Layouts/&lt;Room&gt;.json (architecture, furniture, lights,
    ///                    probes, slot anchors, spawn point, QA shots)
    /// batch: -executeMethod ECHLabs.EditorTools.SceneBuilder.BuildAll
    /// </summary>
    public static class SceneBuilder
    {
        public const string SceneDir = "Assets/ECHLabs/Scenes";
        static string LayoutDir => Path.GetFullPath(Path.Combine(Application.dataPath, "../Layouts"));

        const float BenchTop = 0.92f, DeskTop = 0.75f, PpeTop = 0.95f;

        [MenuItem("ECH Labs/Build scenes")]
        public static void BuildAll()
        {
            Directory.CreateDirectory(SceneDir);
            var scenes = new List<EditorBuildSettingsScene> { new EditorBuildSettingsScene(BuildBootstrap(), true) };
            foreach (var file in Directory.GetFiles(LayoutDir, "*.json").OrderBy(f => f))
                scenes.Add(new EditorBuildSettingsScene(BuildRoom(JObject.Parse(File.ReadAllText(file))), true));
            EditorBuildSettings.scenes = scenes.ToArray();
            Debug.Log($"[ECHLabs] Built {scenes.Count} scenes.");
        }

        // ─── Bootstrap ───────────────────────────────────────────────────────

        static string BuildBootstrap()
        {
            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            RenderSettings.ambientMode = AmbientMode.Flat;

            var sessionGo = new GameObject("ECH Lab Session");
            var session = sessionGo.AddComponent<LabSession>();
            var interaction = sessionGo.AddComponent<InteractionController>();
            interaction.equipmentMask = 1 << 8;
            var director = sessionGo.AddComponent<CameraDirector>();
            var quality = sessionGo.AddComponent<QualityManager>();

            var post = new GameObject("PostFX");
            var vol = post.AddComponent<Volume>();
            vol.isGlobal = true;
            vol.sharedProfile = AssetDatabase.LoadAssetAtPath<VolumeProfile>(ProjectSetup.PostProfilePath);
            quality.postVolume = vol;

            // Flat camera (desktop + touch)
            var camGo = new GameObject("Main Camera") { tag = "MainCamera" };
            var cam = camGo.AddComponent<Camera>();
            cam.nearClipPlane = 0.02f; cam.farClipPlane = 60; cam.fieldOfView = 55;
            camGo.AddComponent<AudioListener>();
            var camData = camGo.AddComponent<UniversalAdditionalCameraData>();
            camData.renderPostProcessing = true;
            camGo.transform.position = new Vector3(0, 1.62f, -3.4f);
            director.cameraTransform = camGo.transform;

            var desktop = new GameObject("DesktopRig").AddComponent<DesktopRig>();
            desktop.cam = cam; desktop.director = director;
            var touch = new GameObject("TouchRig").AddComponent<TouchRig>();
            touch.cam = cam; touch.director = director;
            touch.gameObject.SetActive(false);

            // Phone-VR rig
            var stereoRoot = new GameObject("StereoRig");
            var head = new GameObject("Head").transform; head.SetParent(stereoRoot.transform, false); head.localPosition = new Vector3(0, 1.62f, 0);
            var sCam = new GameObject("StereoCamera").AddComponent<Camera>();
            sCam.transform.SetParent(head, false);
            sCam.nearClipPlane = 0.02f; sCam.farClipPlane = 60;
            sCam.gameObject.AddComponent<UniversalAdditionalCameraData>().renderPostProcessing = true;
            var reticleGo = GameObject.CreatePrimitive(PrimitiveType.Quad);
            Object.DestroyImmediate(reticleGo.GetComponent<Collider>());
            reticleGo.name = "Reticle";
            reticleGo.transform.SetParent(sCam.transform, false);
            reticleGo.GetComponent<Renderer>().sharedMaterial = MaterialLibrary.Reticle;
            var reticle = reticleGo.AddComponent<GazeReticle>();
            reticle.ring = reticleGo.GetComponent<Renderer>();
            var stereo = stereoRoot.AddComponent<StereoRig>();
            stereo.cam = sCam; stereo.head = head; stereo.reticle = reticle;
            stereoRoot.SetActive(false);

            // Headset rig
            var xrRoot = new GameObject("XRRig");
            var origin = new GameObject("XR Origin").transform; origin.SetParent(xrRoot.transform, false);
            var xCam = new GameObject("XRCamera").AddComponent<Camera>();
            xCam.transform.SetParent(origin, false);
            xCam.nearClipPlane = 0.02f; xCam.farClipPlane = 60;
            xCam.gameObject.AddComponent<UniversalAdditionalCameraData>().renderPostProcessing = true;
            var hand = new GameObject("RightHand").transform; hand.SetParent(origin, false);
            var ctrl = GameObject.CreatePrimitive(PrimitiveType.Cube);
            Object.DestroyImmediate(ctrl.GetComponent<Collider>());
            ctrl.name = "Controller"; ctrl.transform.SetParent(hand, false); ctrl.transform.localScale = new Vector3(0.035f, 0.03f, 0.11f);
            ctrl.GetComponent<Renderer>().sharedMaterial = MaterialLibrary.PlasticGraphite;
            var laser = hand.gameObject.AddComponent<LineRenderer>();
            laser.widthMultiplier = 0.004f; laser.positionCount = 2; laser.sharedMaterial = MaterialLibrary.Laser; laser.useWorldSpace = true;
            var xr = xrRoot.AddComponent<XRRig>();
            xr.cam = xCam; xr.origin = origin; xr.rightHand = hand; xr.laser = laser;
            xrRoot.SetActive(false);

            // HUD (UI Toolkit) + input module
            var hudGo = new GameObject("HUD");
            var docu = hudGo.AddComponent<UIDocument>();
            docu.panelSettings = PanelSettingsAsset();
            var hud = hudGo.AddComponent<LabHud>();
            var es = new GameObject("EventSystem");
            es.AddComponent<EventSystem>();
            es.AddComponent<InputSystemUIInputModule>();

            session.hud = hud; session.interaction = interaction; session.director = director; session.quality = quality;
            session.desktopRig = desktop; session.touchRig = touch; session.stereoRig = stereo; session.xrRig = xr; session.flatCamera = cam;

            string path = $"{SceneDir}/Bootstrap.unity";
            EditorSceneManager.SaveScene(scene, path);
            return path;
        }

        static PanelSettings PanelSettingsAsset()
        {
            const string path = "Assets/ECHLabs/Resources/UI/ECHPanel.asset";
            var ps = AssetDatabase.LoadAssetAtPath<PanelSettings>(path);
            if (!ps) { ps = ScriptableObject.CreateInstance<PanelSettings>(); AssetDatabase.CreateAsset(ps, path); }
            ps.scaleMode = PanelScaleMode.ScaleWithScreenSize;
            ps.referenceResolution = new Vector2Int(1920, 1080);
            ps.match = 0.5f;
            ps.themeStyleSheet = AssetDatabase.LoadAssetAtPath<ThemeStyleSheet>("Assets/ECHLabs/Resources/UI/ECHTheme.tss");
            EditorUtility.SetDirty(ps);
            return ps;
        }

        // ─── Rooms ───────────────────────────────────────────────────────────

        static string BuildRoom(JObject L)
        {
            string name = (string)L["name"];
            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            var root = new GameObject(name).transform;
            bool dark = (string)L["style"] == "dark";
            var size = V3(L["size"]);
            float W = size.x, H = size.y, D = size.z;

            Lighting(root, W, H, D, dark);
            Architecture(root, W, H, D, dark);

            foreach (var b in L["benches"] ?? new JArray()) Bench(root, (string)b["id"], V3(b["pos"]), (float)b["yaw"], (float?)b["length"] ?? 2.6f, (bool?)b["riser"] ?? false, true);
            foreach (var s in L["shelves"] ?? new JArray()) Shelf(root, (string)s["id"], V3(s["pos"]), (float)s["yaw"], (int)s["count"], (float?)s["spacing"] ?? 0.9f);
            if (L["stations"] is JObject st)
                foreach (var kv in st)
                {
                    var o = (JObject)kv.Value;
                    Station(root, kv.Key, (string)o["kind"], V3(o["pos"]), (float?)o["yaw"] ?? 0, (float?)o["length"] ?? 1.6f, dark);
                }
            foreach (var p in L["props"] ?? new JArray()) Prop(root, (JObject)p, W, H, D, dark);

            var spawn = new GameObject("SpawnPoint").transform;
            spawn.SetParent(root, false);
            spawn.position = V3(L["spawn"]["pos"]);
            spawn.rotation = Quaternion.Euler(8, (float)L["spawn"]["yaw"], 0);

            foreach (var s in L["shots"] ?? new JArray())
            {
                var shot = new GameObject("QAShot_" + (string)s["name"]).transform;
                shot.SetParent(root, false);
                shot.position = V3(s["pos"]);
                shot.LookAt(V3(s["look"]));
            }

            Probes(root, W, H, D);
            string path = $"{SceneDir}/{name}.unity";
            EditorSceneManager.SaveScene(scene, path);
            return path;
        }

        static void Lighting(Transform root, float W, float H, float D, bool dark)
        {
            var sky = new Material(Shader.Find("Skybox/Procedural"));
            sky.SetFloat("_SunSize", 0.03f);
            sky.SetFloat("_AtmosphereThickness", 0.9f);
            sky.SetColor("_SkyTint", new Color(0.55f, 0.65f, 0.75f));
            sky.SetFloat("_Exposure", dark ? 0.9f : 1.15f);
            Directory.CreateDirectory("Assets/ECHLabs/Rendering/Sky");
            string skyPath = $"Assets/ECHLabs/Rendering/Sky/Sky_{(dark ? "Dark" : "Bright")}.mat";
            if (!AssetDatabase.LoadAssetAtPath<Material>(skyPath)) AssetDatabase.CreateAsset(sky, skyPath);
            RenderSettings.skybox = AssetDatabase.LoadAssetAtPath<Material>(skyPath);
            RenderSettings.ambientMode = AmbientMode.Skybox;
            RenderSettings.defaultReflectionMode = DefaultReflectionMode.Skybox;
            RenderSettings.fog = false;

            // Sun through the windows (mixed: baked indirect + realtime highlights/shadows).
            var sun = new GameObject("Sun").AddComponent<Light>();
            sun.transform.SetParent(root, false);
            sun.type = LightType.Directional;
            sun.lightmapBakeType = LightmapBakeType.Mixed;
            sun.shadows = LightShadows.Soft;
            sun.color = new Color(1f, 0.96f, 0.9f);
            sun.intensity = dark ? 0.15f : 1.1f;
            sun.transform.rotation = Quaternion.Euler(38, -60, 0);
            RenderSettings.sun = sun;

            // Ceiling LED panels: emissive geometry + baked area lights.
            int rows = Mathf.Max(2, Mathf.RoundToInt(D / 2.6f)), cols = Mathf.Max(2, Mathf.RoundToInt(W / 3.2f));
            for (int r = 0; r < rows; r++)
                for (int c = 0; c < cols; c++)
                {
                    var pos = new Vector3(Mathf.Lerp(-W / 2 + 1.6f, W / 2 - 1.6f, cols == 1 ? 0.5f : c / (cols - 1f)), H - 0.02f, Mathf.Lerp(-D / 2 + 1.4f, D / 2 - 1.4f, rows == 1 ? 0.5f : r / (rows - 1f)));
                    Static(Box(root, "LedPanel", new Vector3(1.2f, 0.02f, 0.3f), 0.005f, dark ? MaterialLibrary.AccentBlue : MaterialLibrary.LightPanel, pos));
                    var area = new GameObject("PanelLight").AddComponent<Light>();
                    area.transform.SetParent(root, false);
                    area.transform.position = pos + Vector3.down * 0.03f;
                    area.transform.rotation = Quaternion.Euler(90, 0, 0);
                    area.type = LightType.Rectangle;
                    area.areaSize = new Vector2(1.2f, 0.3f);
                    area.lightmapBakeType = LightmapBakeType.Baked;
                    area.intensity = dark ? 7f : 5.5f;
                    area.color = dark ? new Color(0.82f, 0.9f, 1f) : new Color(1f, 0.98f, 0.95f);
                }
            // Realtime spots over the work areas for crisp specular on glass.
            foreach (var x in new[] { -1.5f, 1.5f })
            {
                var spot = new GameObject("WorkSpot").AddComponent<Light>();
                spot.transform.SetParent(root, false);
                spot.transform.position = new Vector3(x, H - 0.3f, -0.4f);
                spot.transform.rotation = Quaternion.Euler(70, 0, 0);
                spot.type = LightType.Spot;
                spot.spotAngle = 70;
                spot.range = 5;
                spot.intensity = dark ? 4.5f : 3.5f;
                spot.lightmapBakeType = LightmapBakeType.Mixed;
                spot.shadows = LightShadows.Soft;
                spot.color = new Color(1f, 0.97f, 0.92f);
            }

            var settings = new LightingSettings
            {
                name = "ECH Lighting",
                lightmapper = LightingSettings.Lightmapper.ProgressiveGPU,
                bakedGI = true,
                realtimeGI = false,
                mixedBakeMode = MixedLightingMode.Shadowmask,
                lightmapResolution = 24,
                lightmapPadding = 2,
                lightmapMaxSize = 2048,
                directionalityMode = LightmapsMode.CombinedDirectional,
                indirectSampleCount = 256,
                directSampleCount = 64,
                maxBounces = 3,
                ao = true,
                aoMaxDistance = 0.6f,
                filteringMode = LightingSettings.FilterMode.Auto,
            };
            Directory.CreateDirectory("Assets/ECHLabs/Rendering/Lighting");
            string lsPath = $"Assets/ECHLabs/Rendering/Lighting/{root.name}.lighting";
            AssetDatabase.DeleteAsset(lsPath);
            AssetDatabase.CreateAsset(settings, lsPath);
            Lightmapping.lightingSettings = settings;
        }

        static void Architecture(Transform root, float W, float H, float D, bool dark)
        {
            var wallMat = dark ? MaterialLibrary.WallSlate : MaterialLibrary.WallPaint;
            Static(Box(root, "Floor", new Vector3(W, 0.1f, D), 0.002f, dark ? MaterialLibrary.FloorDark : MaterialLibrary.FloorTerrazzo, new Vector3(0, -0.05f, 0)));
            Static(Box(root, "Ceiling", new Vector3(W, 0.1f, D), 0.002f, MaterialLibrary.Ceiling, new Vector3(0, H + 0.05f, 0)));
            Static(Box(root, "Wall_N", new Vector3(W, H, 0.16f), 0.002f, wallMat, new Vector3(0, H / 2, D / 2 + 0.08f)));
            Static(Box(root, "Wall_S", new Vector3(W, H, 0.16f), 0.002f, wallMat, new Vector3(0, H / 2, -D / 2 - 0.08f)));
            Static(Box(root, "Wall_W", new Vector3(0.16f, H, D), 0.002f, wallMat, new Vector3(-W / 2 - 0.08f, H / 2, 0)));
            Static(Box(root, "Wall_E", new Vector3(0.16f, H, D), 0.002f, wallMat, new Vector3(W / 2 + 0.08f, H / 2, 0)));
            // Emerald accent line + skirting, the ECH signature.
            foreach (var (n, size, pos) in new[]
            {
                ("Accent_N", new Vector3(W, 0.03f, 0.01f), new Vector3(0, 1.1f, D / 2 - 0.005f)),
                ("Accent_S", new Vector3(W, 0.03f, 0.01f), new Vector3(0, 1.1f, -D / 2 + 0.005f)),
                ("Accent_W", new Vector3(0.01f, 0.03f, D), new Vector3(-W / 2 + 0.005f, 1.1f, 0)),
            })
                Static(Box(root, n, size, 0.003f, MaterialLibrary.AccentEmerald, pos));
            Static(Box(root, "Skirting_N", new Vector3(W, 0.1f, 0.015f), 0.003f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.05f, D / 2 - 0.008f)));
            Static(Box(root, "Skirting_S", new Vector3(W, 0.1f, 0.015f), 0.003f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.05f, -D / 2 + 0.008f)));
            // Door
            Static(Box(root, "Door", new Vector3(1.0f, 2.15f, 0.05f), 0.01f, MaterialLibrary.PlasticGraphite, new Vector3(-W / 2 + 1.6f, 1.075f, -D / 2 + 0.02f)));
            Static(Box(root, "DoorPanel", new Vector3(0.3f, 0.9f, 0.01f), 0.004f, MaterialLibrary.GlassLens, new Vector3(-W / 2 + 1.6f, 1.45f, -D / 2 + 0.05f)));
        }

        static void Bench(Transform root, string id, Vector3 pos, float yaw, float length, bool riser, bool slots)
        {
            var b = new GameObject(id).transform;
            b.SetParent(root, false);
            b.localPosition = pos;
            b.rotation = Facing(yaw);
            Static(Box(b, "Cabinet", new Vector3(length, BenchTop - 0.06f, 0.72f), 0.012f, MaterialLibrary.CabinetWhite, new Vector3(0, (BenchTop - 0.06f) / 2 + 0.04f, 0.02f)));
            Static(Box(b, "Plinth", new Vector3(length - 0.06f, 0.08f, 0.66f), 0.004f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.04f, 0.04f)));
            Static(Box(b, "Worktop", new Vector3(length + 0.04f, 0.035f, 0.8f), 0.006f, MaterialLibrary.EpoxyBlack, new Vector3(0, BenchTop - 0.0175f, 0)));
            int drawers = Mathf.Max(2, Mathf.RoundToInt(length / 0.6f));
            for (int i = 0; i < drawers; i++)
            {
                float x = Mathf.Lerp(-length / 2 + length / drawers / 2, length / 2 - length / drawers / 2, drawers == 1 ? 0.5f : i / (drawers - 1f));
                Static(Box(b, "Drawer", new Vector3(length / drawers - 0.02f, 0.2f, 0.012f), 0.004f, MaterialLibrary.CabinetWhite, new Vector3(x, BenchTop - 0.18f, -0.345f)));
                Static(Box(b, "Handle", new Vector3(0.14f, 0.012f, 0.02f), 0.005f, MaterialLibrary.SteelBrushed, new Vector3(x, BenchTop - 0.12f, -0.36f)));
            }
            if (riser)
            {
                Static(Box(b, "RiserBack", new Vector3(length, 0.45f, 0.03f), 0.006f, MaterialLibrary.CabinetWhite, new Vector3(0, BenchTop + 0.225f, 0.38f)));
                Static(Box(b, "Socket", new Vector3(0.12f, 0.07f, 0.02f), 0.006f, MaterialLibrary.PlasticWhite, new Vector3(length / 2 - 0.25f, BenchTop + 0.12f, 0.36f)));
                Static(Box(b, "SocketLed", new Vector3(0.01f, 0.01f, 0.005f), 0.002f, MaterialLibrary.LedGreen, new Vector3(length / 2 - 0.2f, BenchTop + 0.14f, 0.348f)));
            }
            if (!slots) return;
            string[] names = { "left", "center", "right" };
            for (int i = 0; i < 3; i++)
                Slot(b, $"{id}.{names[i]}", new Vector3((i - 1) * length / 3f, BenchTop, -0.1f), 0.22f);
        }

        static void Shelf(Transform root, string id, Vector3 pos, float yaw, int count, float spacing)
        {
            var s = new GameObject(id + "_unit").transform;
            s.SetParent(root, false);
            s.position = pos;
            s.rotation = Facing(yaw);
            float len = count * spacing + 0.3f;
            Static(Box(s, "Glass", new Vector3(len, 0.012f, 0.26f), 0.003f, MaterialLibrary.GlassLens, new Vector3(0, -0.006f, 0)));
            Static(Box(s, "Rail", new Vector3(len, 0.02f, 0.01f), 0.003f, MaterialLibrary.SteelBrushed, new Vector3(0, 0.01f, -0.13f)));
            foreach (float x in new[] { -len / 2 + 0.04f, len / 2 - 0.04f })
                Static(Box(s, "Upright", new Vector3(0.025f, pos.y + 0.1f, 0.025f), 0.004f, MaterialLibrary.SteelBrushed, new Vector3(x, -pos.y / 2 + 0.05f, 0.1f)));
            for (int i = 0; i < count; i++)
                Slot(s, $"shelf.{i + 1}", new Vector3((i - (count - 1) / 2f) * spacing, 0, -0.02f), 0.16f);
        }

        static void Station(Transform root, string slotId, string kind, Vector3 pos, float yaw, float length, bool dark)
        {
            var t = new GameObject("Station_" + slotId).transform;
            t.SetParent(root, false);
            t.position = pos;
            t.rotation = Facing(yaw);
            switch (kind)
            {
                case "bench":
                    Bench(t, "bench_" + slotId, Vector3.zero, 180, length, false, false);
                    Slot(t, slotId, new Vector3(0, BenchTop, -0.1f), 0.3f);
                    break;
                case "ppe":
                    Static(Box(t, "Counter", new Vector3(1.2f, PpeTop - 0.03f, 0.5f), 0.01f, MaterialLibrary.CabinetWhite, new Vector3(0, (PpeTop - 0.03f) / 2, 0)));
                    Static(Box(t, "Top", new Vector3(1.24f, 0.03f, 0.54f), 0.006f, MaterialLibrary.EpoxyBlack, new Vector3(0, PpeTop - 0.015f, 0)));
                    Static(Box(t, "Board", new Vector3(1.2f, 0.9f, 0.02f), 0.01f, MaterialLibrary.PlasticWhite, new Vector3(0, PpeTop + 0.65f, 0.26f)));
                    Static(Box(t, "Sign", new Vector3(0.5f, 0.12f, 0.01f), 0.01f, MaterialLibrary.AccentEmerald, new Vector3(0, PpeTop + 1.0f, 0.245f)));
                    Label(t, "SAFETY FIRST · PPE", new Vector3(0, PpeTop + 1.0f, 0.238f), 0.6f, Color.white);
                    Slot(t, slotId, new Vector3(0, PpeTop, -0.05f), 0.38f);
                    break;
                case "fumehood":
                    Static(Box(t, "Base", new Vector3(1.6f, BenchTop, 0.8f), 0.01f, MaterialLibrary.CabinetWhite, new Vector3(0, BenchTop / 2, 0)));
                    Static(Box(t, "Hood", new Vector3(1.6f, 1.3f, 0.8f), 0.012f, MaterialLibrary.PlasticWhite, new Vector3(0, BenchTop + 0.65f + 0.4f, 0.05f)));
                    Static(Box(t, "Interior", new Vector3(1.5f, 1.0f, 0.7f), 0.004f, MaterialLibrary.Ceramic, new Vector3(0, BenchTop + 0.5f, 0.05f)));
                    Static(Box(t, "Sash", new Vector3(1.5f, 0.55f, 0.01f), 0.004f, MaterialLibrary.GlassLens, new Vector3(0, BenchTop + 0.75f, -0.36f)));
                    Static(Box(t, "HoodLight", new Vector3(1.3f, 0.02f, 0.08f), 0.004f, MaterialLibrary.LightPanel, new Vector3(0, BenchTop + 0.98f, 0.1f)));
                    Slot(t, slotId, new Vector3(0, BenchTop, 0.05f), 0.3f);
                    break;
                case "sink":
                    Static(Box(t, "Cabinet", new Vector3(1.4f, BenchTop - 0.04f, 0.65f), 0.01f, MaterialLibrary.CabinetWhite, new Vector3(0, (BenchTop - 0.04f) / 2, 0)));
                    Static(Box(t, "Top", new Vector3(1.44f, 0.035f, 0.7f), 0.006f, MaterialLibrary.EpoxyBlack, new Vector3(0, BenchTop - 0.0175f, 0)));
                    Static(Box(t, "Basin", new Vector3(0.55f, 0.02f, 0.4f), 0.03f, MaterialLibrary.SteelBrushed, new Vector3(0.3f, BenchTop - 0.01f, 0)));
                    Static(Cyl(t, "Tap", 0.012f, 0.32f, MaterialLibrary.SteelBrushed, new Vector3(0.3f, BenchTop, 0.26f)));
                    Static(Box(t, "Spout", new Vector3(0.02f, 0.02f, 0.18f), 0.008f, MaterialLibrary.SteelBrushed, new Vector3(0.3f, BenchTop + 0.32f, 0.18f)));
                    Slot(t, slotId, new Vector3(-0.35f, BenchTop, 0), 0.2f);
                    break;
                case "desk":
                    Static(Box(t, "Top", new Vector3(1.6f, 0.035f, 0.8f), 0.008f, dark ? MaterialLibrary.PlasticGraphite : MaterialLibrary.Wood, new Vector3(0, DeskTop - 0.0175f, 0)));
                    foreach (float x in new[] { -0.75f, 0.75f })
                        Static(Box(t, "Leg", new Vector3(0.05f, DeskTop - 0.035f, 0.7f), 0.01f, MaterialLibrary.SteelDark, new Vector3(x, (DeskTop - 0.035f) / 2, 0)));
                    Static(Box(t, "Edge", new Vector3(1.6f, 0.006f, 0.01f), 0.002f, MaterialLibrary.AccentEmerald, new Vector3(0, DeskTop - 0.02f, -0.4f)));
                    Static(Cyl(t, "Chair", 0.25f, 0.48f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0, -0.75f)));
                    Slot(t, slotId, new Vector3(0, DeskTop, 0.05f), 0.5f);
                    break;
                case "rack":
                    // Open-frame 19" rack: 1U devices (firewall, switch) mount at chest height.
                    foreach (float x in new[] { -0.27f, 0.27f })
                        foreach (float z in new[] { -0.3f, 0.3f })
                            Static(Box(t, "Post", new Vector3(0.04f, 2.0f, 0.04f), 0.006f, MaterialLibrary.SteelDark, new Vector3(x, 1.0f, z)));
                    Static(Box(t, "Top", new Vector3(0.6f, 0.04f, 0.66f), 0.006f, MaterialLibrary.SteelDark, new Vector3(0, 2.0f, 0)));
                    Static(Box(t, "Base", new Vector3(0.6f, 0.06f, 0.66f), 0.006f, MaterialLibrary.SteelDark, new Vector3(0, 0.03f, 0)));
                    for (int i = 0; i < 6; i++)
                        Static(Box(t, "Unit", new Vector3(0.48f, 0.04f, 0.3f), 0.004f, MaterialLibrary.PlasticGraphite, new Vector3(0, 0.4f + i * 0.12f, 0.08f)));
                    Static(Box(t, "Accent", new Vector3(0.6f, 0.015f, 0.01f), 0.004f, MaterialLibrary.AccentEmerald, new Vector3(0, 1.97f, -0.335f)));
                    Slot(t, slotId, new Vector3(0, 1.15f, 0.0f), 0.5f);
                    break;
                case "wall":
                case "floor":
                default:
                    Slot(t, slotId, Vector3.zero, 1.0f);
                    break;
            }
        }

        static void Prop(Transform root, JObject p, float W, float H, float D, bool dark)
        {
            string kind = (string)p["kind"];
            Vector3 pos = p["pos"] != null ? V3(p["pos"]) : Vector3.zero;
            var rot = p["yaw"] != null ? Facing((float)p["yaw"]) : Quaternion.identity;
            var t = new GameObject("Prop_" + kind).transform;
            t.SetParent(root, false);
            t.SetPositionAndRotation(pos, rot);
            switch (kind)
            {
                case "display":
                    Static(Box(t, "Frame", new Vector3(2.2f, 1.2f, 0.05f), 0.01f, MaterialLibrary.PlasticGraphite, new Vector3(0, 1.85f, 0)));
                    Static(Box(t, "Screen", new Vector3(2.14f, 1.14f, 0.005f), 0.004f, MaterialLibrary.Screen, new Vector3(0, 1.85f, -0.027f)));
                    Label(t, "ECH", new Vector3(0, 2.05f, -0.032f), 3.2f, new Color(0.2f, 0.9f, 0.6f));
                    Label(t, (string)p["text"] ?? "ECH Virtual Lab", new Vector3(0, 1.72f, -0.032f), 1.3f, Color.white);
                    Label(t, "Excellence Coaching Hub · Virtual Laboratory", new Vector3(0, 1.5f, -0.032f), 0.6f, new Color(0.6f, 0.7f, 0.8f));
                    break;
                case "windows":
                    // Frosted daylight windows along the east wall (bright, soft, bake-friendly).
                    for (float z = -D / 2 + 1.2f; z < D / 2 - 0.8f; z += 1.6f)
                    {
                        Static(Box(t, "Window", new Vector3(0.02f, 1.6f, 1.3f), 0.004f, MaterialLibrary.LightPanel, new Vector3(W / 2 - 0.01f, 1.7f, z + 0.65f)));
                        Static(Box(t, "Mullion", new Vector3(0.04f, 1.66f, 0.05f), 0.004f, MaterialLibrary.SteelDark, new Vector3(W / 2 - 0.02f, 1.7f, z - 0.02f)));
                    }
                    break;
                case "stools":
                    {
                        var bench = root.Find((string)p["bench"]);
                        if (!bench) break;
                        foreach (float x in new[] { -0.8f, 0f, 0.8f })
                        {
                            var s = bench.TransformPoint(new Vector3(x, 0, -0.75f));
                            Static(Cyl(t, "StoolSeat", 0.18f, 0.05f, MaterialLibrary.PlasticGraphite, s + Vector3.up * 0.62f));
                            Static(Cyl(t, "StoolPole", 0.025f, 0.6f, MaterialLibrary.SteelBrushed, s + Vector3.up * 0.02f));
                            Static(Cyl(t, "StoolBase", 0.22f, 0.02f, MaterialLibrary.SteelDark, s));
                        }
                        break;
                    }
                case "cabinet":
                    Static(Box(t, "Tall", new Vector3(1.0f, 2.0f, 0.5f), 0.01f, MaterialLibrary.CabinetWhite, new Vector3(0, 1.0f, 0)));
                    Static(Box(t, "Glass", new Vector3(0.9f, 1.1f, 0.01f), 0.004f, MaterialLibrary.GlassLens, new Vector3(0, 1.35f, -0.255f)));
                    Static(Box(t, "Accent", new Vector3(1.0f, 0.02f, 0.01f), 0.004f, MaterialLibrary.AccentEmerald, new Vector3(0, 1.98f, -0.255f)));
                    break;
                case "plant":
                    Static(Cyl(t, "Pot", 0.17f, 0.4f, MaterialLibrary.PlasticGraphite, Vector3.zero));
                    for (int i = 0; i < 7; i++)
                    {
                        float a = i * 51f * Mathf.Deg2Rad;
                        var leaf = Box(t, "Leaf", new Vector3(0.06f, 0.5f, 0.012f), 0.006f, MaterialLibrary.BoardGreen, new Vector3(Mathf.Cos(a) * 0.06f, 0.65f, Mathf.Sin(a) * 0.06f), new Vector3(Mathf.Sin(a) * 18f, i * 51f, Mathf.Cos(a) * 18f));
                        Static(leaf);
                    }
                    break;
                case "safetyshower":
                    Static(Cyl(t, "Pipe", 0.025f, 2.3f, MaterialLibrary.AccentEmerald, Vector3.zero));
                    Static(Cyl(t, "Head", 0.15f, 0.04f, MaterialLibrary.AccentEmerald, new Vector3(0, 2.25f, -0.25f)));
                    Static(Box(t, "Arm", new Vector3(0.05f, 0.05f, 0.3f), 0.01f, MaterialLibrary.AccentEmerald, new Vector3(0, 2.3f, -0.12f)));
                    Label(t, "SAFETY SHOWER", new Vector3(0, 1.8f, -0.05f), 0.5f, new Color(0.06f, 0.72f, 0.5f));
                    break;
                case "ledstrip":
                    foreach (var (n, size, ps) in new[]
                    {
                        ("Strip_N", new Vector3(W, 0.02f, 0.02f), new Vector3(0, H - 0.05f, D / 2 - 0.02f)),
                        ("Strip_S", new Vector3(W, 0.02f, 0.02f), new Vector3(0, H - 0.05f, -D / 2 + 0.02f)),
                        ("Strip_E", new Vector3(0.02f, 0.02f, D), new Vector3(W / 2 - 0.02f, H - 0.05f, 0)),
                        ("Strip_W", new Vector3(0.02f, 0.02f, D), new Vector3(-W / 2 + 0.02f, H - 0.05f, 0)),
                    })
                        Static(Box(root, n, size, 0.004f, MaterialLibrary.AccentEmerald, ps));
                    break;
                case "raisedfloor":
                    for (float x = -W / 2 + 0.3f; x < W / 2; x += 0.6f)
                        Static(Box(t, "Seam", new Vector3(0.004f, 0.002f, D), 0.001f, MaterialLibrary.PlasticGraphite, new Vector3(x, 0.001f, 0)));
                    break;
            }
        }

        static void Probes(Transform root, float W, float H, float D)
        {
            var rp = new GameObject("ReflectionProbe").AddComponent<ReflectionProbe>();
            rp.transform.SetParent(root, false);
            rp.transform.position = new Vector3(0, 1.4f, 0);
            rp.mode = ReflectionProbeMode.Baked;
            rp.boxProjection = true;
            rp.size = new Vector3(W, H, D);
            rp.center = new Vector3(0, H / 2 - 1.4f, 0);
            rp.resolution = 256;
            rp.hdr = true;
            // Close-up probe over the benches (glass reflections).
            var rp2 = new GameObject("ReflectionProbe_Benches").AddComponent<ReflectionProbe>();
            rp2.transform.SetParent(root, false);
            rp2.transform.position = new Vector3(0, 1.1f, 0);
            rp2.mode = ReflectionProbeMode.Baked;
            rp2.boxProjection = true;
            rp2.size = new Vector3(W * 0.6f, 1.6f, 2.5f);
            rp2.importance = 2;
            rp2.resolution = 256;

            var lpg = new GameObject("LightProbes").AddComponent<LightProbeGroup>();
            lpg.transform.SetParent(root, false);
            var pts = new List<Vector3>();
            for (float x = -W / 2 + 0.5f; x <= W / 2 - 0.5f; x += 1f)
                for (float z = -D / 2 + 0.5f; z <= D / 2 - 0.5f; z += 1f)
                    foreach (float y in new[] { 0.4f, 1.0f, 1.3f, 2.2f })
                        pts.Add(new Vector3(x, y, z));
            lpg.probePositions = pts.ToArray();
        }

        // ─── Helpers ─────────────────────────────────────────────────────────

        static void Slot(Transform parent, string id, Vector3 localPos, float spacing)
        {
            var go = new GameObject("Slot_" + id);
            go.transform.SetParent(parent, false);
            go.transform.localPosition = localPos;
            var a = go.AddComponent<SlotAnchor>();
            a.slotId = id;
            a.spacing = spacing;
            var vp = new GameObject("Viewpoint").transform;
            vp.SetParent(go.transform, false);
            vp.localPosition = new Vector3(0, 0.7f, -0.75f);
            vp.LookAt(go.transform.position + Vector3.up * 0.1f);
            a.viewpoint = vp;
        }

        static GameObject Box(Transform p, string name, Vector3 size, float bevel, Material m, Vector3 pos, Vector3 euler = default)
        {
            var go = new GameObject(name);
            go.transform.SetParent(p, false);
            go.transform.localPosition = pos;
            go.transform.localEulerAngles = euler;
            go.AddComponent<MeshFilter>().sharedMesh = SaveMesh(MeshKit.RoundedBox($"arch_{size.x:0.###}x{size.y:0.###}x{size.z:0.###}_{bevel:0.####}".Replace(',', '.'), size, bevel, bevel < 0.005f ? 1 : 3));
            go.AddComponent<MeshRenderer>().sharedMaterial = m;
            go.AddComponent<BoxCollider>();
            return go;
        }

        static GameObject Cyl(Transform p, string name, float r, float h, Material m, Vector3 pos)
        {
            var go = new GameObject(name);
            go.transform.SetParent(p, false);
            go.transform.localPosition = pos;
            go.AddComponent<MeshFilter>().sharedMesh = SaveMesh(MeshKit.Cylinder($"archcyl_{r:0.###}_{h:0.###}".Replace(',', '.'), r, h));
            go.AddComponent<MeshRenderer>().sharedMaterial = m;
            return go;
        }

        static Mesh SaveMesh(Mesh m)
        {
            const string dir = "Assets/ECHLabs/Art/Generated/Architecture";
            Directory.CreateDirectory(dir);
            string path = $"{dir}/{m.name}.asset";
            var existing = AssetDatabase.LoadAssetAtPath<Mesh>(path);
            if (existing) return existing;
            Unwrapping.GenerateSecondaryUVSet(m); // lightmap UVs
            AssetDatabase.CreateAsset(m, path);
            return m;
        }

        static void Label(Transform parent, string text, Vector3 localPos, float size, Color color)
        {
            var go = new GameObject("Label");
            go.transform.SetParent(parent, false);
            go.transform.localPosition = localPos;
            // TextMeshPro reads correctly from −Z, which is every generated object's front.
            var t = go.AddComponent<TextMeshPro>();
            t.text = text;
            t.fontSize = size;
            t.color = color;
            t.alignment = TextAlignmentOptions.Center;
            t.textWrappingMode = TextWrappingModes.NoWrap;
            if (TMP_Settings.defaultFontAsset) t.font = TMP_Settings.defaultFontAsset;
            t.fontStyle = FontStyles.Bold;
        }

        static GameObject Static(GameObject go)
        {
            GameObjectUtility.SetStaticEditorFlags(go, StaticEditorFlags.ContributeGI | StaticEditorFlags.ReflectionProbeStatic | StaticEditorFlags.BatchingStatic | StaticEditorFlags.OccluderStatic | StaticEditorFlags.OccludeeStatic);
            return go;
        }

        /// <summary>Layout yaw = the direction the object's FRONT faces; generated geometry fronts face local −Z.</summary>
        static Quaternion Facing(float yaw) => Quaternion.Euler(0, yaw + 180f, 0);

        static Vector3 V3(JToken t) => new Vector3((float)t[0], (float)t[1], (float)t[2]);
    }
}
