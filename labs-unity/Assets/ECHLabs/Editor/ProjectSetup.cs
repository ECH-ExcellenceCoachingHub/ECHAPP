using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Build;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ECHLabs.EditorTools
{
    /// <summary>
    /// One-shot project configuration (idempotent):
    ///   batch: Unity -batchmode -projectPath labs-unity -executeMethod ECHLabs.EditorTools.ProjectSetup.Run -quit
    /// Creates URP tiers + quality levels, post-processing profile, layers, player settings for
    /// Android/iOS/Windows/WebGL, XR loaders, TMP resources, and syncs the catalog + built-in
    /// scenarios from the backend so practice mode works offline.
    /// </summary>
    public static class ProjectSetup
    {
        const string RenderDir = "Assets/ECHLabs/Rendering";
        public const string PostProfilePath = RenderDir + "/ECH_PostFX.asset";

        [MenuItem("ECH Labs/1. Configure project")]
        public static void Run()
        {
            EnsureLayer("Equipment", 8);
            EnsureLayer("HUD", 9);
            ImportTmpResources();
            CreateRenderPipelines();
            CreatePostProfile();
            ConfigurePlayer();
            AlwaysIncludeShaders("ECH/Liquid", "ECH/HudSurface", "ECH/Reticle");
            SyncBackendData();
            XRSetup.Configure();
            AssetDatabase.SaveAssets();
            Debug.Log("[ECHLabs] Project configured.");
        }

        /// <summary>Everything, in order — what CI runs before building players.</summary>
        [MenuItem("ECH Labs/Build everything (setup → prefabs → scenes → bake → QA)")]
        public static void All()
        {
            Run();
            PrefabFactory.BuildAll();
            MaterialLibrary.ApplyDownloadedTextures();
            SceneBuilder.BuildAll();
            LightingBaker.BakeAll();
            ScreenshotQA.Run();
        }

        // ─── Rendering ───────────────────────────────────────────────────────

        static void CreateRenderPipelines()
        {
            Directory.CreateDirectory(RenderDir);
            var tiers = new[] { ("Low", 0), ("Medium", 1), ("Ultra", 2) };
            var names = QualitySettings.names.ToList();
            foreach (var (tier, idx) in tiers)
            {
                string rendererPath = $"{RenderDir}/ECH_{tier}_Renderer.asset";
                var rendererData = AssetDatabase.LoadAssetAtPath<UniversalRendererData>(rendererPath);
                if (!rendererData)
                {
                    rendererData = ScriptableObject.CreateInstance<UniversalRendererData>();
                    AssetDatabase.CreateAsset(rendererData, rendererPath);
                    ResourceReloader.TryReloadAllNullIn(rendererData, UniversalRenderPipelineAsset.packagePath);
                }
                rendererData.renderingMode = RenderingMode.Forward;
                if (tier != "Low" && !rendererData.rendererFeatures.OfType<ScreenSpaceAmbientOcclusion>().Any())
                {
                    var ssao = ScriptableObject.CreateInstance<ScreenSpaceAmbientOcclusion>();
                    ssao.name = "SSAO";
                    AssetDatabase.AddObjectToAsset(ssao, rendererData);
                    rendererData.rendererFeatures.Add(ssao);
                    rendererData.SetDirty();
                }

                string assetPath = $"{RenderDir}/ECH_{tier}.asset";
                var urp = AssetDatabase.LoadAssetAtPath<UniversalRenderPipelineAsset>(assetPath);
                if (!urp)
                {
                    urp = UniversalRenderPipelineAsset.Create(rendererData);
                    AssetDatabase.CreateAsset(urp, assetPath);
                }
                urp.supportsHDR = tier != "Low";
                urp.msaaSampleCount = tier == "Ultra" ? 4 : tier == "Medium" ? 2 : 1;
                urp.renderScale = 1f;
                urp.shadowDistance = tier == "Ultra" ? 12 : tier == "Medium" ? 7 : 4;
                urp.shadowCascadeCount = tier == "Ultra" ? 2 : 1;
                urp.supportsCameraDepthTexture = tier != "Low";
                urp.supportsCameraOpaqueTexture = tier == "Ultra";
                EditorUtility.SetDirty(urp);

                // Quality level "ECH <tier>"
                string levelName = "ECH " + tier;
                if (!names.Contains(levelName))
                {
                    // Repurpose existing levels in order; Unity requires editing the QualitySettings asset.
                    var qs = new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/QualitySettings.asset")[0]);
                    var levels = qs.FindProperty("m_QualitySettings");
                    while (levels.arraySize <= idx) levels.InsertArrayElementAtIndex(levels.arraySize);
                    levels.GetArrayElementAtIndex(idx).FindPropertyRelative("name").stringValue = levelName;
                    qs.ApplyModifiedProperties();
                    names = QualitySettings.names.ToList();
                }
                QualitySettings.SetQualityLevel(names.IndexOf(levelName), false);
                QualitySettings.renderPipeline = urp;
                QualitySettings.antiAliasing = 0;
                QualitySettings.vSyncCount = 0;
                QualitySettings.lodBias = tier == "Ultra" ? 2f : tier == "Medium" ? 1.2f : 0.7f;
                QualitySettings.globalTextureMipmapLimit = tier == "Low" ? 1 : 0;
                QualitySettings.anisotropicFiltering = tier == "Low" ? AnisotropicFiltering.Disable : AnisotropicFiltering.ForceEnable;
                QualitySettings.realtimeReflectionProbes = false;
            }
            // Trim extra default levels so only our three exist.
            {
                var qs = new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/QualitySettings.asset")[0]);
                var levels = qs.FindProperty("m_QualitySettings");
                while (levels.arraySize > 3) levels.DeleteArrayElementAtIndex(levels.arraySize - 1);
                qs.ApplyModifiedProperties();
            }
            var medium = AssetDatabase.LoadAssetAtPath<UniversalRenderPipelineAsset>($"{RenderDir}/ECH_Medium.asset");
            GraphicsSettings.defaultRenderPipeline = medium;
            QualitySettings.SetQualityLevel(1, true); // runtime QualityManager picks the real tier per device
        }

        static void CreatePostProfile()
        {
            var profile = AssetDatabase.LoadAssetAtPath<VolumeProfile>(PostProfilePath);
            if (!profile) { profile = ScriptableObject.CreateInstance<VolumeProfile>(); AssetDatabase.CreateAsset(profile, PostProfilePath); }
            T Get<T>() where T : VolumeComponent
            {
                if (!profile.TryGet<T>(out var c)) { c = profile.Add<T>(true); AssetDatabase.AddObjectToAsset(c, profile); }
                c.active = true;
                return c;
            }
            var tm = Get<Tonemapping>(); tm.mode.Override(TonemappingMode.ACES);
            var bloom = Get<Bloom>(); bloom.threshold.Override(1.05f); bloom.intensity.Override(0.35f); bloom.scatter.Override(0.6f); bloom.tint.Override(new Color(0.92f, 1f, 0.97f));
            var ca = Get<ColorAdjustments>(); ca.postExposure.Override(0.15f); ca.contrast.Override(10f); ca.saturation.Override(6f);
            var wb = Get<WhiteBalance>(); wb.temperature.Override(-4f);
            var vig = Get<Vignette>(); vig.intensity.Override(0.18f); vig.smoothness.Override(0.5f);
            var dof = Get<DepthOfField>(); dof.mode.Override(DepthOfFieldMode.Bokeh); dof.focusDistance.Override(0.4f); dof.aperture.Override(4f); dof.active = false;
            EditorUtility.SetDirty(profile);
        }

        // ─── Player / platform ───────────────────────────────────────────────

        static void ConfigurePlayer()
        {
            PlayerSettings.companyName = "Excellence Coaching Hub";
            PlayerSettings.productName = "ECH Labs";
            PlayerSettings.colorSpace = ColorSpace.Linear;
            PlayerSettings.SetApplicationIdentifier(NamedBuildTarget.Android, "com.excellencecoachinghub.labs");
            PlayerSettings.SetApplicationIdentifier(NamedBuildTarget.iOS, "com.excellencecoachinghub.labs");
            PlayerSettings.SetApplicationIdentifier(NamedBuildTarget.Standalone, "com.excellencecoachinghub.labs");
            PlayerSettings.bundleVersion = "1.0.0";
            PlayerSettings.SetScriptingBackend(NamedBuildTarget.Android, ScriptingImplementation.IL2CPP);
            PlayerSettings.SetScriptingBackend(NamedBuildTarget.Standalone, ScriptingImplementation.IL2CPP);
            PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;
            PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel29; // Quest + Cardboard minimum
            PlayerSettings.SetUseDefaultGraphicsAPIs(BuildTarget.Android, false);
            PlayerSettings.SetGraphicsAPIs(BuildTarget.Android, new[] { GraphicsDeviceType.Vulkan, GraphicsDeviceType.OpenGLES3 });
            PlayerSettings.defaultInterfaceOrientation = UIOrientation.AutoRotation;
            PlayerSettings.allowedAutorotateToPortrait = false;
            PlayerSettings.allowedAutorotateToPortraitUpsideDown = false;
            PlayerSettings.allowedAutorotateToLandscapeLeft = true;
            PlayerSettings.allowedAutorotateToLandscapeRight = true;
            PlayerSettings.SetManagedStrippingLevel(NamedBuildTarget.Android, ManagedStrippingLevel.Low);
            PlayerSettings.SetManagedStrippingLevel(NamedBuildTarget.WebGL, ManagedStrippingLevel.Low);
            PlayerSettings.WebGL.compressionFormat = WebGLCompressionFormat.Brotli;
            PlayerSettings.WebGL.decompressionFallback = true;
            PlayerSettings.WebGL.dataCaching = true;
            PlayerSettings.runInBackground = true;
            PlayerSettings.resizableWindow = true;
            PlayerSettings.defaultScreenWidth = 1600;
            PlayerSettings.defaultScreenHeight = 900;
            PlayerSettings.SplashScreen.showUnityLogo = false;
            PlayerSettings.SplashScreen.show = false;
            PlayerSettings.iOS.cameraUsageDescription = "Not used";
            PlayerSettings.iOS.targetOSVersionString = "15.0";
            // Input System only (gyro, touch, XR controllers).
            var ps = new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/ProjectSettings.asset")[0]);
            var handler = ps.FindProperty("activeInputHandler");
            if (handler != null) { handler.intValue = 1; ps.ApplyModifiedProperties(); }
        }

        static void AlwaysIncludeShaders(params string[] shaderNames)
        {
            var gs = new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/GraphicsSettings.asset")[0]);
            var arr = gs.FindProperty("m_AlwaysIncludedShaders");
            foreach (var n in shaderNames)
            {
                var s = Shader.Find(n);
                if (!s) { Debug.LogWarning("[ECHLabs] Shader not found: " + n); continue; }
                bool present = false;
                for (int i = 0; i < arr.arraySize; i++) if (arr.GetArrayElementAtIndex(i).objectReferenceValue == s) present = true;
                if (present) continue;
                arr.InsertArrayElementAtIndex(arr.arraySize);
                arr.GetArrayElementAtIndex(arr.arraySize - 1).objectReferenceValue = s;
            }
            gs.ApplyModifiedProperties();
        }

        static void EnsureLayer(string name, int index)
        {
            var tm = new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/TagManager.asset")[0]);
            var layers = tm.FindProperty("layers");
            var el = layers.GetArrayElementAtIndex(index);
            if (string.IsNullOrEmpty(el.stringValue)) { el.stringValue = name; tm.ApplyModifiedProperties(); }
        }

        static void ImportTmpResources()
        {
            if (AssetDatabase.FindAssets("t:TMP_Settings").Length > 0) return;
            // TextMeshPro ships inside com.unity.ugui; its essential resources are a .unitypackage there.
            var pkg = Directory.GetFiles("Library/PackageCache", "TMP Essential Resources.unitypackage", SearchOption.AllDirectories).FirstOrDefault();
            if (pkg == null) { Debug.LogWarning("[ECHLabs] TMP Essential Resources package not found."); return; }
            // AssetDatabase.ImportPackage is deferred in batch mode, so unpack the package ourselves.
            ExtractUnityPackage(pkg);
            AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
            Debug.Log("[ECHLabs] Imported TMP Essential Resources.");
        }

        /// <summary>Minimal .unitypackage (tar.gz of guid/{asset,asset.meta,pathname}) extractor.</summary>
        static void ExtractUnityPackage(string path)
        {
            var files = new System.Collections.Generic.Dictionary<string, System.Collections.Generic.Dictionary<string, byte[]>>();
            using (var gz = new System.IO.Compression.GZipStream(File.OpenRead(path), System.IO.Compression.CompressionMode.Decompress))
            using (var ms = new MemoryStream())
            {
                gz.CopyTo(ms);
                var data = ms.ToArray();
                int pos = 0;
                while (pos + 512 <= data.Length)
                {
                    string name = System.Text.Encoding.ASCII.GetString(data, pos, 100).TrimEnd('\0');
                    if (string.IsNullOrEmpty(name)) break;
                    string sizeOctal = System.Text.Encoding.ASCII.GetString(data, pos + 124, 12).Trim('\0', ' ');
                    long size = string.IsNullOrEmpty(sizeOctal) ? 0 : System.Convert.ToInt64(sizeOctal, 8);
                    char type = (char)data[pos + 156];
                    pos += 512;
                    var parts = name.TrimStart('.', '/').Split('/');
                    if ((type == '0' || type == '\0') && parts.Length == 2)
                    {
                        if (!files.TryGetValue(parts[0], out var entry)) files[parts[0]] = entry = new System.Collections.Generic.Dictionary<string, byte[]>();
                        var bytes = new byte[size];
                        System.Array.Copy(data, pos, bytes, 0, size);
                        entry[parts[1]] = bytes;
                    }
                    pos += (int)((size + 511) / 512 * 512);
                }
            }
            foreach (var entry in files.Values)
            {
                if (!entry.TryGetValue("pathname", out var pn)) continue;
                string target = System.Text.Encoding.UTF8.GetString(pn).Split('\n')[0].Trim();
                if (entry.TryGetValue("asset", out var asset))
                {
                    Directory.CreateDirectory(Path.GetDirectoryName(target));
                    File.WriteAllBytes(target, asset);
                }
                else Directory.CreateDirectory(target);
                if (entry.TryGetValue("asset.meta", out var meta)) File.WriteAllBytes(target + ".meta", meta);
            }
        }

        /// <summary>Copies catalog.json and built-in scenarios from the backend (single source of truth).</summary>
        public static void SyncBackendData()
        {
            string backend = Path.GetFullPath(Path.Combine(Application.dataPath, "../../backend/src/services/labs"));
            string res = "Assets/ECHLabs/Resources";
            Directory.CreateDirectory(res + "/Scenarios");
            if (!Directory.Exists(backend)) { Debug.LogWarning("[ECHLabs] Backend folder not found: " + backend); return; }
            File.Copy(Path.Combine(backend, "catalog.json"), res + "/catalog.json", true);
            foreach (var f in Directory.GetFiles(Path.Combine(backend, "scenarios"), "*.json"))
                File.Copy(f, $"{res}/Scenarios/{Path.GetFileName(f)}", true);
            AssetDatabase.Refresh();
        }
    }
}
