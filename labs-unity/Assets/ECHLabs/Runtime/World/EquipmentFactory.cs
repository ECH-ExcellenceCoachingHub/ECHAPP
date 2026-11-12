using System.Collections.Generic;
using System.Linq;
using ECHLabs.Core;
using ECHLabs.Runtime.Equipment;
using Newtonsoft.Json.Linq;
using UnityEngine;

namespace ECHLabs.Runtime.World
{
    /// <summary>
    /// Spawns the scenario's equipment at the room's slot anchors. Prefabs are built by the
    /// editor PrefabFactory into Resources/Equipment/&lt;type&gt;.prefab (Addressables in release builds).
    /// </summary>
    public static class EquipmentFactory
    {
        static JObject catalog;

        /// <summary>Equipment catalog (same file as the backend's), bundled as Resources/catalog.json.</summary>
        public static JObject Catalog
        {
            get
            {
                if (catalog != null) return catalog;
                var asset = Resources.Load<TextAsset>("catalog");
                catalog = asset ? JObject.Parse(asset.text) : new JObject();
                return catalog;
            }
        }

        public static IEnumerable<string> IntentsFor(string type)
            => (Catalog["equipment"]?[type]?["intents"] as JArray)?.Select(t => (string)t) ?? new[] { "Select", "Inspect" };

        public static Dictionary<string, EquipmentView> SpawnAll(LabWorld world, Transform parent)
        {
            var anchors = Object.FindObjectsByType<SlotAnchor>().ToDictionary(a => a.slotId, a => a);
            foreach (var a in anchors.Values) a.ResetUsage();
            var views = new Dictionary<string, EquipmentView>();

            foreach (var spec in world.Definition.Equipment)
            {
                Pose pose;
                if (anchors.TryGetValue(spec.Slot, out var anchor)) pose = anchor.NextPose();
                else
                {
                    Debug.LogWarning($"[ECHLabs] Slot '{spec.Slot}' not found in room; placing {spec.Id} at origin.");
                    pose = new Pose(Vector3.up, Quaternion.identity);
                }
                var view = Spawn(spec.Type, pose, parent);
                view.Bind(spec, world, IntentsFor(spec.Type));
                views[spec.Id] = view;
            }
            Arrange(views);
            return views;
        }

        /// <summary>Real-world arrangement rules: the white tile sits under the burette tip.</summary>
        static void Arrange(Dictionary<string, EquipmentView> views)
        {
            var burette = views.Values.OfType<BuretteView>().FirstOrDefault();
            if (!burette) return;
            foreach (var v in views.Values)
                if (v.Type == "white_tile")
                {
                    var under = burette.Attach.position;
                    v.transform.position = under;
                    if (v is GenericView g) g.Rebase();
                }
        }

        static EquipmentView Spawn(string type, Pose pose, Transform parent)
        {
            var prefab = Resources.Load<GameObject>("Equipment/" + type);
            GameObject go;
            if (prefab) go = Object.Instantiate(prefab, pose.position, pose.rotation, parent);
            else
            {
                // Fallback so a scenario never breaks on a missing prefab: a labelled placeholder.
                Debug.LogWarning($"[ECHLabs] No prefab for '{type}', using placeholder.");
                go = GameObject.CreatePrimitive(PrimitiveType.Cube);
                go.transform.SetPositionAndRotation(pose.position + Vector3.up * 0.05f, pose.rotation);
                go.transform.localScale = Vector3.one * 0.1f;
                go.transform.SetParent(parent, true);
            }
            var view = go.GetComponent<EquipmentView>() ?? go.AddComponent<GenericView>();
            go.layer = LayerMask.NameToLayer("Equipment") >= 0 ? LayerMask.NameToLayer("Equipment") : 0;
            if (!go.GetComponentInChildren<Collider>()) go.AddComponent<BoxCollider>();
            return view;
        }
    }
}
