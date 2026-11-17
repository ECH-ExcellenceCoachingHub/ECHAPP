using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Animations;
using UnityEngine.Playables;
using UnityEngine.Rendering;

namespace ECHLabs.Runtime.Demo
{
    /// <summary>
    /// The full-body lab demonstrator ("Amani") who introduces each activity in the real lab: walks in,
    /// waves, explains, then turns and points at each piece of equipment (arm and head aimed by IK)
    /// before the first-person demo. Model: Quaternius "Animated Woman" (CC0), dressed at runtime in a
    /// lab coat, safety goggles and an ECH badge. Animations are played through the Playables API, so
    /// no Animator Controller asset is needed.
    /// </summary>
    [DefaultExecutionOrder(150)] // IK after the animation pass
    public sealed class Demonstrator : MonoBehaviour
    {
        public const string Name = "Amani";
        const float Height = 1.66f;

        Animator animator;
        PlayableGraph graph;
        AnimationMixerPlayable mixer;
        readonly Dictionary<string, int> slots = new Dictionary<string, int>();
        readonly List<AnimationClip> clipList = new List<AnimationClip>();
        readonly List<bool> loops = new List<bool>();
        int active = -1;
        float[] weights;

        Transform model, head, upperR, lowerR, wristR, footL, footLEnd, hips, chest;
        Vector3 headFwdLocal, hipsFwdLocal;
        Quaternion modelBaseLocal;
        float yawFix;
        float pointW, lookW;
        Vector3 pointTarget, lookTarget;
        bool pointing, looking;
        Renderer[] renderers;

        public Transform Head => head;

        /// <summary>Returns null when the character asset is not in this build (the intro is then skipped).</summary>
        public static Demonstrator Spawn()
        {
            var prefab = Resources.Load<GameObject>("Characters/Demonstrator");
            var clips = Resources.LoadAll<AnimationClip>("Characters/Demonstrator");
            if (!prefab || clips == null || clips.Length == 0) return null;
            var root = new GameObject("Demonstrator " + Name);
            var model = Instantiate(prefab, root.transform);
            model.name = "Model";
            var d = root.AddComponent<Demonstrator>();
            d.Setup(model.transform, clips);
            return d;
        }

        void Setup(Transform m, AnimationClip[] clips)
        {
            model = m;
            animator = m.GetComponentInChildren<Animator>() ?? m.gameObject.AddComponent<Animator>();
            animator.applyRootMotion = false;
            head = Find("Head"); upperR = Find("UpperArm.R"); lowerR = Find("LowerArm.R"); wristR = Find("Wrist.R");
            footL = Find("Foot.L"); footLEnd = Find("Foot.L_end"); hips = Find("Hips"); chest = Find("Chest") ?? Find("Torso");

            // Real-world size and facing (+Z forward on the root).
            renderers = m.GetComponentsInChildren<Renderer>();
            var b = Bounds();
            if (b.size.y > 0.1f) m.localScale *= Height / b.size.y;
            b = Bounds();
            m.position += new Vector3(transform.position.x - b.center.x, transform.position.y - b.min.y, transform.position.z - b.center.z);
            if (footL && footLEnd)
            {
                var fwd = footLEnd.position - footL.position; fwd.y = 0;
                if (fwd.sqrMagnitude > 1e-6f) m.rotation = Quaternion.FromToRotation(fwd.normalized, transform.forward) * m.rotation;
            }
            if (head) headFwdLocal = Quaternion.Inverse(head.rotation) * transform.forward;
            if (hips) hipsFwdLocal = Quaternion.Inverse(hips.rotation) * transform.forward;
            modelBaseLocal = m.localRotation;


            // Playables: every clip we use on one mixer, cross-faded by weight.
            graph = PlayableGraph.Create("Demonstrator");
            graph.SetTimeUpdateMode(DirectorUpdateMode.GameTime);
            var output = AnimationPlayableOutput.Create(graph, "anim", animator);
            var wanted = new[] { ("Idle", "|Idle_Neutral", true), ("Walk", "|Walk", true), ("Wave", "|Wave", false), ("Interact", "|Interact", false) };
            foreach (var (key, suffix, loop) in wanted)
                foreach (var c in clips)
                    if (c.name.EndsWith(suffix)) { slots[key] = clipList.Count; clipList.Add(c); loops.Add(loop); break; }
            mixer = AnimationMixerPlayable.Create(graph, clipList.Count);
            for (int i = 0; i < clipList.Count; i++)
            {
                var p = AnimationClipPlayable.Create(graph, clipList[i]);
                graph.Connect(p, 0, mixer, i);
            }
            weights = new float[clipList.Count];
            output.SetSourcePlayable(mixer);
            Play("Idle", 0f);
            mixer.SetInputWeight(slots.TryGetValue("Idle", out int idle) ? idle : 0, 1f);
            // Pose her in the idle stance and face her forward, then tailor the coat to that pose
            // (the clip's skeleton differs from the file's rest pose, so measuring at rest misplaces it).
            graph.Evaluate(0f);
            for (int i = 0; i < 4; i++) { CorrectYaw(1f); graph.Evaluate(0f); }
            Dress();
            foreach (var r in renderers) { r.shadowCastingMode = ShadowCastingMode.On; if (r is SkinnedMeshRenderer s) s.updateWhenOffscreen = true; }
            graph.Play();
        }

        Transform Find(string bone) => FindDeep(model, bone);

        static Transform FindDeep(Transform t, string n)
        {
            if (t.name == n) return t;
            for (int i = 0; i < t.childCount; i++) { var r = FindDeep(t.GetChild(i), n); if (r) return r; }
            return null;
        }

        Bounds Bounds()
        {
            var b = renderers[0].bounds;
            foreach (var r in renderers) b.Encapsulate(r.bounds);
            return b;
        }

        // ─── Wardrobe: recolour + lab coat, goggles and badge attached to the bones ──

        void Dress()
        {
            var skin = Mat("FX/CharSkin", new Color(0.36f, 0.23f, 0.16f));
            var hair = Mat("FX/CharHair", new Color(0.06f, 0.05f, 0.05f));
            var top = Mat("FX/CharTop", new Color(0.55f, 0.75f, 0.9f));
            var trousers = Mat("FX/CharTrousers", new Color(0.12f, 0.15f, 0.25f));
            var shoes = Mat("FX/CharShoes", new Color(0.08f, 0.08f, 0.09f));
            var coat = Mat("FX/CharCoat", new Color(0.96f, 0.96f, 0.97f));
            var goggles = Mat("FX/CharGoggles", new Color(0.25f, 0.5f, 0.9f));
            var badge = Mat("FX/GuideGlow", new Color(0.1f, 0.8f, 0.55f));
            foreach (var r in renderers)
            {
                var mats = r.sharedMaterials;
                for (int i = 0; i < mats.Length; i++)
                {
                    string n = mats[i] ? mats[i].name : "";
                    if (n.StartsWith("Skin")) mats[i] = skin;
                    else if (n.StartsWith("Hair") || n.StartsWith("Brown")) mats[i] = hair;
                    else if (n.StartsWith("White")) mats[i] = top;
                    else if (n.StartsWith("Orange")) mats[i] = trousers;
                    else if (n.StartsWith("Grey")) mats[i] = shoes;
                }
                r.sharedMaterials = mats;
            }

            // Measurements from the skeleton in its rest pose.
            var upperL = Find("UpperArm.L"); var lowerL = Find("LowerArm.L"); var wristL = Find("Wrist.L");
            var kneeL = Find("LowerLeg.L"); var neck = Find("Neck");
            if (!hips || !chest || !upperR || !upperL) return;
            float shoulderW = Vector3.Distance(upperL.position, upperR.position);
            float hipY = hips.position.y, kneeY = kneeL ? kneeL.position.y : hipY - 0.42f;
            float neckY = neck ? neck.position.y : upperR.position.y + 0.05f;
            var fwd = transform.forward; var right = transform.right;
            var c = hips.position;

            // Coat body (chest → hips) and skirt (hips → just below the knee), slightly flared.
            Part("CoatBody", Tube(0.5f, 0.56f, 1f, 18), coat, chest,
                new Vector3(c.x, (hipY + neckY) * 0.5f - 0.02f, c.z), Quaternion.LookRotation(fwd), new Vector3(shoulderW * 1.22f, neckY - hipY + 0.06f, shoulderW * 0.95f));
            Part("CoatSkirt", Tube(0.66f, 0.74f, 1f, 18), coat, hips,
                new Vector3(c.x, (hipY + kneeY) * 0.5f - 0.04f, c.z), Quaternion.LookRotation(fwd), new Vector3(shoulderW * 1.3f, hipY - kneeY + 0.16f, shoulderW * 1.2f));
            Part("Collar", Tube(0.42f, 0.5f, 1f, 18), coat, chest,
                new Vector3(c.x, neckY - 0.02f, c.z) + fwd * 0.005f, Quaternion.LookRotation(fwd), new Vector3(shoulderW * 0.75f, 0.06f, shoulderW * 0.6f));
            // Sleeves follow the arms.
            Sleeve(upperR, lowerR, coat, 0.052f); Sleeve(lowerR, wristR, coat, 0.045f, 0.85f);
            Sleeve(upperL, lowerL, coat, 0.052f); Sleeve(lowerL, wristL, coat, 0.045f, 0.85f);
            // ECH badge on the chest pocket.
            var chestFront = new Vector3(c.x, neckY - 0.13f, c.z) + fwd * (shoulderW * 0.45f) + right * (-shoulderW * 0.22f);
            Part("Badge", PrimitiveMesh(PrimitiveType.Cube), badge, chest, chestFront, Quaternion.LookRotation(fwd), new Vector3(0.06f, 0.035f, 0.006f));
            // Safety goggles.
            if (head)
            {
                float headY = head.position.y + 0.11f;
                var gp = new Vector3(head.position.x, headY, head.position.z) + fwd * 0.085f;
                Part("Goggles", PrimitiveMesh(PrimitiveType.Cube), goggles, head, gp, Quaternion.LookRotation(fwd), new Vector3(0.15f, 0.045f, 0.03f));
                Part("GoggleStrap", Tube(0.5f, 0.5f, 1f, 18), Mat("FX/CharHair", Color.black), head,
                    new Vector3(head.position.x, headY, head.position.z), Quaternion.LookRotation(fwd), new Vector3(0.165f, 0.022f, 0.19f));
            }
        }

        void Sleeve(Transform from, Transform to, Material mat, float radius, float length = 1f)
        {
            if (!from || !to) return;
            var a = from.position; var b = Vector3.Lerp(from.position, to.position, length);
            var d = b - a;
            var t = Part("Sleeve_" + from.name, PrimitiveMesh(PrimitiveType.Capsule), mat, from, (a + b) * 0.5f, Quaternion.FromToRotation(Vector3.up, d), Vector3.one);
            t.localScale = Vector3.one;
            var world = new Vector3(radius * 2, d.magnitude * 0.5f + radius, radius * 2);
            var ls = from.lossyScale;
            // Undo the bone's (possibly 100×) scale so the sleeve has its real size.
            t.localScale = new Vector3(world.x / Mathf.Max(ls.x, 1e-5f), world.y / Mathf.Max(ls.y, 1e-5f), world.z / Mathf.Max(ls.z, 1e-5f));
        }

        Transform Part(string name, Mesh mesh, Material mat, Transform bone, Vector3 pos, Quaternion rot, Vector3 worldSize)
        {
            var go = new GameObject(name);
            go.transform.SetPositionAndRotation(pos, rot);
            go.transform.localScale = worldSize;
            go.AddComponent<MeshFilter>().sharedMesh = mesh;
            var r = go.AddComponent<MeshRenderer>();
            r.sharedMaterial = mat;
            go.transform.SetParent(bone, true); // keeps its world size and pose, then follows the bone
            var list = new List<Renderer>(renderers) { r };
            renderers = list.ToArray();
            return go.transform;
        }

        static readonly Dictionary<PrimitiveType, Mesh> prims = new Dictionary<PrimitiveType, Mesh>();
        static Mesh PrimitiveMesh(PrimitiveType t)
        {
            if (prims.TryGetValue(t, out var m) && m) return m;
            var go = GameObject.CreatePrimitive(t);
            m = go.GetComponent<MeshFilter>().sharedMesh;
            Destroy(go);
            return prims[t] = m;
        }

        /// <summary>Open, slightly flared tube of unit height (radii relative to a unit diameter).</summary>
        static Mesh Tube(float rTop, float rBottom, float height, int seg)
        {
            var v = new List<Vector3>(); var tris = new List<int>(); var n = new List<Vector3>();
            for (int i = 0; i <= seg; i++)
            {
                float a = i * Mathf.PI * 2 / seg;
                var d = new Vector3(Mathf.Cos(a), 0, Mathf.Sin(a));
                v.Add(d * rTop + Vector3.up * height * 0.5f); n.Add(d);
                v.Add(d * rBottom - Vector3.up * height * 0.5f); n.Add(d);
            }
            for (int i = 0; i < seg; i++)
            {
                int k = i * 2;
                tris.AddRange(new[] { k, k + 2, k + 1, k + 1, k + 2, k + 3 });
                tris.AddRange(new[] { k, k + 1, k + 2, k + 1, k + 3, k + 2 }); // inside faces too
            }
            // Top cap (shoulders).
            int center = v.Count; v.Add(Vector3.up * height * 0.5f); n.Add(Vector3.up);
            for (int i = 0; i < seg; i++) tris.AddRange(new[] { center, (i + 1) * 2, i * 2 });
            var mesh = new Mesh { name = "CoatTube" };
            mesh.SetVertices(v); mesh.SetNormals(n); mesh.SetTriangles(tris, 0);
            mesh.RecalculateBounds();
            return mesh;
        }

        static Material Mat(string resource, Color fallback)
        {
            var m = Resources.Load<Material>(resource);
            if (m) return m;
            m = new Material(Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard"));
            m.SetColor("_BaseColor", fallback);
            m.color = fallback;
            return m;
        }

        // ─── Animation ───────────────────────────────────────────────────────

        public void Play(string key, float fade = 0.25f)
        {
            if (!slots.TryGetValue(key, out int i)) return;
            if (i == active) return;
            active = i;
            var p = mixer.GetInput(i);
            p.SetTime(0);
            fadeTime = Mathf.Max(fade, 0.001f);
            if (fade <= 0) for (int k = 0; k < weights.Length; k++) weights[k] = k == i ? 1 : 0;
        }

        public float Length(string key) => slots.TryGetValue(key, out int i) ? clipList[i].length : 1f;

        float fadeTime = 0.25f;

        public void PointAt(Vector3? target) { pointing = target.HasValue; if (target.HasValue) pointTarget = target.Value; }
        public void LookAt(Vector3? target) { looking = target.HasValue; if (target.HasValue) lookTarget = target.Value; }

        /// <summary>Turn smoothly to face a point (on the floor plane).</summary>
        public void Face(Vector3 point, float dt, float speed = 4f)
        {
            var d = point - transform.position; d.y = 0;
            if (d.sqrMagnitude < 1e-4f) return;
            transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(d), 1f - Mathf.Exp(-dt * speed));
        }

        public void SetVisible(bool on) { foreach (var r in renderers) if (r) r.enabled = on; }

        void Update()
        {
            if (!graph.IsValid()) return;
            float dt = Time.deltaTime;
            for (int i = 0; i < weights.Length; i++)
            {
                weights[i] = Mathf.MoveTowards(weights[i], i == active ? 1f : 0f, dt / fadeTime);
                mixer.SetInputWeight(i, weights[i]);
                var p = mixer.GetInput(i);
                double len = clipList[i].length;
                if (len > 0 && p.GetTime() > len) p.SetTime(loops[i] ? p.GetTime() % len : len);
            }
            pointW = Mathf.MoveTowards(pointW, pointing ? 1f : 0f, dt * 2.5f);
            lookW = Mathf.MoveTowards(lookW, looking ? 1f : 0f, dt * 3f);
        }

        void LateUpdate()
        {
            // Some clips turn the whole body inside the animation (Idle_Neutral stands ~70° sideways).
            // Keep the hips facing where the character should face, whatever the clip does.
            CorrectYaw(Mathf.Clamp01(Time.deltaTime * 6f));
            // Arm: point straight at the target (a slightly bent elbow), blended over the animation.
            if (pointW > 0.001f && upperR && lowerR && wristR)
            {
                var a = upperR.position;
                float la = Vector3.Distance(a, lowerR.position), lb = Vector3.Distance(lowerR.position, wristR.position);
                var dir = (pointTarget - a).normalized;
                var elbowGoal = a + dir * la + Vector3.down * 0.03f;
                upperR.rotation = Quaternion.Slerp(upperR.rotation, Quaternion.FromToRotation(lowerR.position - a, elbowGoal - a) * upperR.rotation, pointW);
                var e = lowerR.position;
                var wristGoal = e + (pointTarget - e).normalized * lb;
                lowerR.rotation = Quaternion.Slerp(lowerR.rotation, Quaternion.FromToRotation(wristR.position - e, wristGoal - e) * lowerR.rotation, pointW);
            }
            // Head: look at the student or the equipment (limited, like a real neck).
            if (lookW > 0.001f && head)
            {
                var face = head.rotation * headFwdLocal;
                var to = lookTarget - head.position;
                var turn = Quaternion.FromToRotation(face, to);
                turn.ToAngleAxis(out float ang, out var axis);
                if (ang > 180) ang -= 360;
                turn = Quaternion.AngleAxis(Mathf.Clamp(ang, -60f, 60f), axis);
                head.rotation = Quaternion.Slerp(head.rotation, turn * head.rotation, lookW * 0.8f);
            }
        }

        void CorrectYaw(float gain)
        {
            if (!hips) return;
            var hf = hips.rotation * hipsFwdLocal; hf.y = 0;
            if (hf.sqrMagnitude < 1e-4f) return;
            float err = Vector3.SignedAngle(hf, transform.forward, Vector3.up);
            yawFix = Mathf.Clamp(yawFix + err * gain, -150f, 150f);
            model.localRotation = Quaternion.AngleAxis(yawFix, Vector3.up) * modelBaseLocal;
        }

        void OnDestroy()
        {
            if (graph.IsValid()) graph.Destroy();
        }
    }
}
