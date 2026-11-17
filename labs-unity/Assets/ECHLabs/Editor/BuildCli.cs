using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEditor.XR.Management;
using UnityEditor.XR.Management.Metadata;
using UnityEngine.XR.Management;
using UnityEngine;

namespace ECHLabs.EditorTools
{
    /// <summary>
    /// Player builds for every ECH platform:
    ///   -executeMethod ECHLabs.EditorTools.BuildCli.Windows   → Builds/Windows/ECHLabs.exe   (bundled into the MSIX)
    ///   -executeMethod ECHLabs.EditorTools.BuildCli.WebGL     → Builds/WebGL                  (hosted, iframe in Flutter web)
    ///   -executeMethod ECHLabs.EditorTools.BuildCli.AndroidLibrary → ../frontend/android/unityLibrary (Unity as a Library for Flutter)
    ///   -executeMethod ECHLabs.EditorTools.BuildCli.Quest     → Builds/Quest/ECHLabs-Quest.apk (standalone headset app)
    ///   -executeMethod ECHLabs.EditorTools.BuildCli.iOS       → Builds/iOS (Xcode project; build on a Mac)
    /// </summary>
    public static class BuildCli
    {
        static string[] Scenes => EditorBuildSettings.scenes.Where(s => s.enabled).Select(s => s.path).ToArray();
        static string Root => Path.GetFullPath(Path.Combine(Application.dataPath, ".."));

        [MenuItem("ECH Labs/Build/Windows")] public static void Windows() => Build(BuildTarget.StandaloneWindows64, "Builds/Windows/ECHLabs.exe", BuildOptions.None);
        [MenuItem("ECH Labs/Build/WebGL")]
        public static void WebGL()
        {
            PlayerSettings.WebGL.template = "PROJECT:ECHLabs"; // full-screen, phone-friendly page (Assets/WebGLTemplates/ECHLabs)
            Build(BuildTarget.WebGL, "Builds/WebGL", BuildOptions.None);
        }
        [MenuItem("ECH Labs/Build/iOS (Xcode)")] public static void iOS() => Build(BuildTarget.iOS, "Builds/iOS", BuildOptions.None);

        [MenuItem("ECH Labs/Build/Quest APK")]
        public static void Quest()
        {
            SetAndroidXR(true);
            EditorUserBuildSettings.exportAsGoogleAndroidProject = false;
            PlayerSettings.SetApplicationIdentifier(UnityEditor.Build.NamedBuildTarget.Android, "com.excellencecoachinghub.labs.vr");
            Build(BuildTarget.Android, "Builds/Quest/ECHLabs-Quest.apk", BuildOptions.None);
            PlayerSettings.SetApplicationIdentifier(UnityEditor.Build.NamedBuildTarget.Android, "com.excellencecoachinghub.labs");
        }

        /// <summary>Exports a Gradle project; its unityLibrary module is what flutter_embed_unity uses.</summary>
        [MenuItem("ECH Labs/Build/Android library for Flutter")]
        public static void AndroidLibrary()
        {
            // Embedded in the ECH Flutter app: classic Activity entry, phones + x86_64 emulators/Chromebooks,
            // and a minSdk the Flutter app can merge.
            ConfigureAndroidTools();
            // Phones never use OpenXR (that is the Quest build). A failed OpenXR start on a phone can leave
            // Unity presenting to a dead XR display (black screen), so the phone library ships without XR.
            SetAndroidXR(false);
            PlayerSettings.Android.applicationEntry = AndroidApplicationEntry.Activity;
            // OpenGL ES 3 first: most reliable on budget phones (and emulators); Vulkan as fallback.
            PlayerSettings.SetUseDefaultGraphicsAPIs(BuildTarget.Android, false);
            PlayerSettings.SetGraphicsAPIs(BuildTarget.Android, new[] { UnityEngine.Rendering.GraphicsDeviceType.OpenGLES3, UnityEngine.Rendering.GraphicsDeviceType.Vulkan });
            PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64 | AndroidArchitecture.X86_64;
            PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel26; // Unity 6.6 minimum (Android 8.0)
            PlayerSettings.SetScriptingBackend(UnityEditor.Build.NamedBuildTarget.Android, ScriptingImplementation.IL2CPP);
            EditorUserBuildSettings.exportAsGoogleAndroidProject = true;
            string export = "Builds/AndroidExport";
            Build(BuildTarget.Android, export, BuildOptions.None);
            EditorUserBuildSettings.exportAsGoogleAndroidProject = false;
            string src = Path.Combine(Root, export, "unityLibrary");
            string dst = Path.GetFullPath(Path.Combine(Root, "../frontend/android/unityLibrary"));
            if (Directory.Exists(src))
            {
                if (Directory.Exists(dst)) Directory.Delete(dst, true);
                CopyDir(src, dst);
                PatchLibraryManifest(Path.Combine(dst, "src", "main", "AndroidManifest.xml"));
                // unityLibrary's build.gradle applies ../shared/*.gradle
                string sharedSrc = Path.Combine(Root, export, "shared"), sharedDst = Path.GetFullPath(Path.Combine(Root, "../frontend/android/shared"));
                if (Directory.Exists(sharedSrc)) { if (Directory.Exists(sharedDst)) Directory.Delete(sharedDst, true); CopyDir(sharedSrc, sharedDst); }
                Debug.Log("[ECHLabs] unityLibrary copied to " + dst);
            }
        }

        const string OpenXRLoader = "UnityEngine.XR.OpenXR.OpenXRLoader";

        static void SetAndroidXR(bool enabled)
        {
            EditorBuildSettings.TryGetConfigObject(XRGeneralSettings.settingsKey, out XRGeneralSettingsPerBuildTarget perTarget);
            var general = perTarget ? perTarget.SettingsForBuildTarget(BuildTargetGroup.Android) : null;
            if (general == null || general.Manager == null) return;
            if (enabled) XRPackageMetadataStore.AssignLoader(general.Manager, OpenXRLoader, BuildTargetGroup.Android);
            else foreach (var loader in general.Manager.activeLoaders.ToList()) XRPackageMetadataStore.RemoveLoader(general.Manager, loader.GetType().FullName, BuildTargetGroup.Android);
            EditorUtility.SetDirty(general.Manager);
            AssetDatabase.SaveAssets();
            Debug.Log($"[ECHLabs] Android XR loaders: {(enabled ? "OpenXR" : "none")}");
        }

        /// <summary>
        /// Uses the machine's Android Studio SDK/NDK when Unity's embedded ones are missing
        /// (the Hub's NDK download can silently fail). Env overrides: ECH_ANDROID_SDK, ECH_ANDROID_NDK.
        /// </summary>
        static void ConfigureAndroidTools()
        {
            var type = System.Type.GetType("UnityEditor.Android.AndroidExternalToolsSettings, UnityEditor.Android.Extensions");
            if (type == null) { Debug.LogWarning("[ECHLabs] Android module not loaded"); return; }
            string local = System.Environment.GetFolderPath(System.Environment.SpecialFolder.LocalApplicationData);
            string sdk = System.Environment.GetEnvironmentVariable("ECH_ANDROID_SDK") ?? Path.Combine(local, "Android", "Sdk");
            string ndk = System.Environment.GetEnvironmentVariable("ECH_ANDROID_NDK");
            if (ndk == null && Directory.Exists(Path.Combine(sdk, "ndk")))
                // Unity 6.6 accepts exactly NDK r27c (27.2.12479018).
                ndk = Directory.GetDirectories(Path.Combine(sdk, "ndk")).Where(d => Path.GetFileName(d).StartsWith("27.2.")).OrderByDescending(d => d).FirstOrDefault();
            void Set(string prop, string value)
            {
                var pi = type.GetProperty(prop, System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Static);
                if (pi != null && value != null && Directory.Exists(value)) { pi.SetValue(null, value); Debug.Log($"[ECHLabs] {prop} = {value}"); }
            }
            string embeddedNdk = Path.Combine(EditorApplication.applicationContentsPath, "PlaybackEngines", "AndroidPlayer", "NDK");
            bool embeddedNdkOk = Directory.Exists(embeddedNdk) && Directory.GetFileSystemEntries(embeddedNdk).Length > 0;
            Set("sdkRootPath", sdk);
            if (!embeddedNdkOk) Set("ndkRootPath", ndk);
        }

        /// <summary>
        /// The library must not add a second launcher icon, and the lab runs in its own process
        /// (":unity") so closing it never takes the ECH app down with it.
        /// </summary>
        static void PatchLibraryManifest(string path)
        {
            if (!File.Exists(path)) return;
            var xml = File.ReadAllText(path);
            xml = System.Text.RegularExpressions.Regex.Replace(xml, @"<intent-filter>[\s\S]*?</intent-filter>", "");
            xml = System.Text.RegularExpressions.Regex.Replace(xml, @"<activity(?![^>]*android:process)", "<activity android:process=\":unity\"");
            File.WriteAllText(path, xml);
        }

        static void Build(BuildTarget target, string output, BuildOptions options)
        {
            MaterialLibrary.BuildRuntimeFx(); // hands, guide arrow, pour stream (Resources/FX)
            ProjectSetup.SyncBackendData();   // latest activities (randomized values, etc.)
            var opts = new BuildPlayerOptions
            {
                scenes = Scenes,
                locationPathName = Path.Combine(Root, output),
                target = target,
                targetGroup = BuildPipeline.GetBuildTargetGroup(target),
                options = options,
            };
            var report = BuildPipeline.BuildPlayer(opts);
            var s = report.summary;
            Debug.Log($"[ECHLabs] {target}: {s.result} — {s.totalSize / (1024 * 1024)} MB, {s.totalErrors} errors, {s.totalTime.TotalSeconds:0}s → {opts.locationPathName}");
            if (s.result != BuildResult.Succeeded && Application.isBatchMode) EditorApplication.Exit(1);
        }

        static void CopyDir(string src, string dst)
        {
            Directory.CreateDirectory(dst);
            foreach (var f in Directory.GetFiles(src)) File.Copy(f, Path.Combine(dst, Path.GetFileName(f)), true);
            foreach (var d in Directory.GetDirectories(src)) CopyDir(d, Path.Combine(dst, Path.GetFileName(d)));
        }
    }
}
