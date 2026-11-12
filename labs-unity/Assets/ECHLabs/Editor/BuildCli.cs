using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Build.Reporting;
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
        [MenuItem("ECH Labs/Build/WebGL")] public static void WebGL() => Build(BuildTarget.WebGL, "Builds/WebGL", BuildOptions.None);
        [MenuItem("ECH Labs/Build/iOS (Xcode)")] public static void iOS() => Build(BuildTarget.iOS, "Builds/iOS", BuildOptions.None);

        [MenuItem("ECH Labs/Build/Quest APK")]
        public static void Quest()
        {
            EditorUserBuildSettings.exportAsGoogleAndroidProject = false;
            PlayerSettings.SetApplicationIdentifier(UnityEditor.Build.NamedBuildTarget.Android, "com.excellencecoachinghub.labs.vr");
            Build(BuildTarget.Android, "Builds/Quest/ECHLabs-Quest.apk", BuildOptions.None);
            PlayerSettings.SetApplicationIdentifier(UnityEditor.Build.NamedBuildTarget.Android, "com.excellencecoachinghub.labs");
        }

        /// <summary>Exports a Gradle project; its unityLibrary module is what flutter_embed_unity uses.</summary>
        [MenuItem("ECH Labs/Build/Android library for Flutter")]
        public static void AndroidLibrary()
        {
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
                Debug.Log("[ECHLabs] unityLibrary copied to " + dst);
            }
        }

        static void Build(BuildTarget target, string output, BuildOptions options)
        {
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
