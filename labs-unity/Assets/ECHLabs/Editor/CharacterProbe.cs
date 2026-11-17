using System.Text;
using UnityEditor;
using UnityEngine;

namespace ECHLabs.EditorTools
{
    /// <summary>Batch-mode report of how the demonstrator character imported (bones, clips, materials).</summary>
    public static class CharacterProbe
    {
        public const string Path = "Assets/ECHLabs/Resources/Characters/Demonstrator.glb";

        public static void Run()
        {
            AssetDatabase.ImportAsset(Path, ImportAssetOptions.ForceUpdate);
            var sb = new StringBuilder("[ECHLabs] Character probe\n");
            var importer = AssetImporter.GetAtPath(Path);
            sb.AppendLine("importer: " + (importer ? importer.GetType().FullName : "none"));
            foreach (var o in AssetDatabase.LoadAllAssetsAtPath(Path))
                sb.AppendLine($"  asset {o.GetType().Name}: {o.name}" + (o is AnimationClip c ? $" legacy={c.legacy} len={c.length:0.00}" : o is Material m ? $" shader={m.shader.name}" : ""));
            var go = AssetDatabase.LoadAssetAtPath<GameObject>(Path);
            if (go) Dump(go.transform, 0, sb);
            if (go)
            {
                var r = go.GetComponentsInChildren<Renderer>();
                var b = r.Length > 0 ? r[0].bounds : default;
                foreach (var x in r) b.Encapsulate(x.bounds);
                sb.AppendLine($"bounds {b.center} size {b.size}");
            }
            Debug.Log(sb.ToString());
        }

        static void Dump(Transform t, int depth, StringBuilder sb)
        {
            if (depth > 4 && t.childCount == 0) return;
            var comps = new StringBuilder();
            foreach (var c in t.GetComponents<Component>()) if (!(c is Transform)) comps.Append(c.GetType().Name).Append(' ');
            sb.AppendLine(new string(' ', depth * 2) + t.name + $" pos={t.localPosition} rot={t.localEulerAngles} scale={t.localScale} [{comps}]");
            for (int i = 0; i < t.childCount; i++) Dump(t.GetChild(i), depth + 1, sb);
        }
    }
}
