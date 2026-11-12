using UnityEditor;
using UnityEditor.XR.Management;
using UnityEditor.XR.Management.Metadata;
using UnityEngine;
using UnityEngine.XR.Management;

namespace ECHLabs.EditorTools
{
    /// <summary>
    /// XR loaders per platform, never initialised on startup (LabSession starts XR only when the
    /// student picks a VR mode):
    ///   Android: OpenXR (Quest/Pico) + Cardboard (phones)   ·  iOS: Cardboard   ·  Windows: OpenXR (PC VR)
    /// </summary>
    public static class XRSetup
    {
        const string OpenXR = "UnityEngine.XR.OpenXR.OpenXRLoader";
        const string Cardboard = "Google.XR.Cardboard.XRLoader";

        public static void Configure()
        {
            var perTarget = GetOrCreatePerBuildTarget();
            Assign(perTarget, BuildTargetGroup.Android, OpenXR, Cardboard);
            Assign(perTarget, BuildTargetGroup.iOS, Cardboard);
            Assign(perTarget, BuildTargetGroup.Standalone, OpenXR);
            AssetDatabase.SaveAssets();
        }

        static XRGeneralSettingsPerBuildTarget GetOrCreatePerBuildTarget()
        {
            EditorBuildSettings.TryGetConfigObject(XRGeneralSettings.settingsKey, out XRGeneralSettingsPerBuildTarget perTarget);
            if (perTarget) return perTarget;
            perTarget = ScriptableObject.CreateInstance<XRGeneralSettingsPerBuildTarget>();
            System.IO.Directory.CreateDirectory("Assets/XR");
            AssetDatabase.CreateAsset(perTarget, "Assets/XR/XRGeneralSettingsPerBuildTarget.asset");
            EditorBuildSettings.AddConfigObject(XRGeneralSettings.settingsKey, perTarget, true);
            return perTarget;
        }

        static void Assign(XRGeneralSettingsPerBuildTarget perTarget, BuildTargetGroup group, params string[] loaders)
        {
            if (!perTarget.HasSettingsForBuildTarget(group)) perTarget.CreateDefaultSettingsForBuildTarget(group);
            if (!perTarget.HasManagerSettingsForBuildTarget(group)) perTarget.CreateDefaultManagerSettingsForBuildTarget(group);
            var general = perTarget.SettingsForBuildTarget(group);
            general.InitManagerOnStart = false; // XR only when a VR mode is chosen
            foreach (var loader in loaders)
            {
                bool ok = XRPackageMetadataStore.AssignLoader(general.Manager, loader, group);
                if (!ok) Debug.Log($"[ECHLabs] XR loader {loader} not available for {group} (package missing?)");
            }
            EditorUtility.SetDirty(general);
        }
    }
}
