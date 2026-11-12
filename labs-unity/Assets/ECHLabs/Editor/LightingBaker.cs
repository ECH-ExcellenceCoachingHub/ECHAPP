using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace ECHLabs.EditorTools
{
    /// <summary>
    /// Bakes global illumination, shadowmasks, light probes and reflection probes for every room
    /// (GPU progressive lightmapper; falls back to CPU automatically when no GPU is available).
    /// batch: -executeMethod ECHLabs.EditorTools.LightingBaker.BakeAll   (add -room ChemLab for one)
    /// </summary>
    public static class LightingBaker
    {
        [MenuItem("ECH Labs/Bake lighting (all rooms)")]
        public static void BakeAll()
        {
            string only = CommandLineArg("-room");
            var rooms = Directory.GetFiles(SceneBuilder.SceneDir, "*.unity")
                .Where(p => !p.EndsWith("Bootstrap.unity"))
                .Where(p => only == null || Path.GetFileNameWithoutExtension(p) == only)
                .ToArray();
            foreach (var path in rooms)
            {
                var scene = EditorSceneManager.OpenScene(path.Replace('\\', '/'), OpenSceneMode.Single);
                var started = System.DateTime.Now;
                Debug.Log($"[ECHLabs] Baking {scene.name}…");
                bool ok = Lightmapping.Bake(); // synchronous
                Debug.Log($"[ECHLabs] {scene.name}: bake {(ok ? "OK" : "FAILED")} in {(System.DateTime.Now - started).TotalSeconds:0}s");
                EditorSceneManager.SaveScene(scene);
            }
        }

        public static string CommandLineArg(string name)
        {
            var args = System.Environment.GetCommandLineArgs();
            for (int i = 0; i < args.Length - 1; i++) if (args[i] == name) return args[i + 1];
            return null;
        }
    }
}
