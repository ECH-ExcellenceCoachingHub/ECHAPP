using System;
using System.Collections;
using System.Collections.Generic;
using ECHLabs.Core;
using ECHLabs.Runtime.Equipment;
using UnityEngine;
using UnityEngine.Rendering;

namespace ECHLabs.Runtime.Interaction
{
    /// <summary>
    /// The student's own first-person arms and hands (flat screens and phone VR).
    /// Hands rest at the bottom of the view and act out every action for real: they reach to the
    /// equipment's grip point, wrap round a bottle and carry it while it pours, pinch and turn the
    /// burette tap or a knob, press switches with a finger, type on keyboards and put on PPE.
    /// Skin turns into blue nitrile gloves once gloves are worn; sleeves follow the lab coat.
    /// The science is already done by the runtime — this is pure presentation, so it never blocks input.
    /// </summary>
    [DefaultExecutionOrder(200)] // after the camera director has moved the camera
    public sealed class HandsRig : MonoBehaviour
    {
        public Camera cam;
        /// <summary>Leans the student's view toward far-away equipment so arms never over-stretch.</summary>
        public CameraDirector director;
        public Func<bool> GlovesOn, CoatOn;

        // Real arm proportions (adult): shoulder→elbow and elbow→wrist, in metres.
        const float UpperArm = 0.31f, Forearm = 0.27f;
        static readonly Vector3 ShoulderLocal = new Vector3(0.2f, -0.36f, -0.06f);
        /// <summary>Moments that deserve a sound / vibration: "grip", "press", "release", "key", "twist".</summary>
        public event Action<string, Vector3> Cue;

        public bool Busy => routine != null;
        public bool ShowHands { get => showHands; set { showHands = value; ApplyVisible(); } }

        Hand right, left;
        Coroutine routine;
        Material skinMat, gloveMat, coatMat, sweaterMat;
        bool gloves, coat, showHands = true, visible = true;
        float matCheck;
        static Mesh capsule, sphere;

        // Joint flexion (degrees) at full curl: fingers [proximal, middle, distal], thumb.
        static readonly float[] FingerFlex = { 65, 85, 55 };
        static readonly float[] ThumbFlex = { 18, 32, 38 };

        sealed class Hand
        {
            public float s; // +1 right, -1 left
            public Transform root, forearm, sleeve, upperArm, gloveCuff;
            public readonly Transform[,] joints = new Transform[5, 3];
            public readonly Quaternion[] baseRot = new Quaternion[5];
            public readonly List<Renderer> skin = new List<Renderer>(), cloth = new List<Renderer>();
            public readonly float[] curl = new float[5], curlTarget = new float[5];
            public Func<Pose> target;        // null → resting at the bottom of the view
            public Vector3 localPos;         // smoothed, camera space
            public Quaternion localRot = Quaternion.identity;
            public bool placed;
            public float speed = 9f, roll, rollTarget;
            public bool typing;
        }

        public static HandsRig Create()
        {
            var rig = new GameObject("First-person hands").AddComponent<HandsRig>();
            rig.Build();
            return rig;
        }

        // ─── Build (procedural, so it costs no download and works on every platform) ──

        void Build()
        {
            if (!capsule) capsule = PrimitiveMesh(PrimitiveType.Capsule);
            if (!sphere) sphere = PrimitiveMesh(PrimitiveType.Sphere);
            skinMat = Mat("FX/HandSkin", new Color(0.46f, 0.31f, 0.22f), 0.38f);
            gloveMat = Mat("FX/HandGlove", new Color(0.27f, 0.47f, 0.86f), 0.55f);
            coatMat = Mat("FX/SleeveCoat", new Color(0.93f, 0.94f, 0.95f), 0.12f);
            sweaterMat = Mat("FX/SleeveSweater", new Color(0.13f, 0.17f, 0.29f), 0.15f);
            right = BuildHand(1);
            left = BuildHand(-1);
        }

        static Mesh PrimitiveMesh(PrimitiveType t)
        {
            var go = GameObject.CreatePrimitive(t);
            var m = go.GetComponent<MeshFilter>().sharedMesh;
            Destroy(go);
            return m;
        }

        static Material Mat(string resource, Color color, float smoothness)
        {
            var m = Resources.Load<Material>(resource);
            if (m) return m;
            m = new Material(Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard"));
            m.SetColor("_BaseColor", color);
            m.color = color;
            m.SetFloat("_Smoothness", smoothness);
            return m;
        }

        Transform Part(Transform parent, Mesh mesh, Material mat, string name, List<Renderer> group)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            go.AddComponent<MeshFilter>().sharedMesh = mesh;
            var mr = go.AddComponent<MeshRenderer>();
            mr.sharedMaterial = mat;
            mr.shadowCastingMode = ShadowCastingMode.Off;
            mr.receiveShadows = false;
            mr.lightProbeUsage = LightProbeUsage.BlendProbes;
            mr.reflectionProbeUsage = ReflectionProbeUsage.Off;
            group?.Add(mr);
            return go.transform;
        }

        Hand BuildHand(float s)
        {
            var h = new Hand { s = s };
            h.root = new GameObject(s > 0 ? "RightHand" : "LeftHand").transform;
            h.root.SetParent(transform, false);

            var palm = Part(h.root, sphere, skinMat, "Palm", h.skin);
            palm.localPosition = new Vector3(0, 0, 0.048f);
            palm.localScale = new Vector3(0.084f, 0.03f, 0.1f);
            var heel = Part(h.root, sphere, skinMat, "Heel", h.skin);
            heel.localPosition = new Vector3(s * 0.004f, -0.003f, 0.012f);
            heel.localScale = new Vector3(0.068f, 0.035f, 0.06f);
            var wrist = Part(h.root, capsule, skinMat, "Wrist", h.skin);
            wrist.localPosition = new Vector3(0, -0.002f, -0.01f);
            wrist.localRotation = Quaternion.Euler(90, 0, 0);
            wrist.localScale = new Vector3(0.058f, 0.025f, 0.042f);

            float[] xs = { -0.027f, -0.009f, 0.009f, 0.026f };
            float[] zs = { 0.090f, 0.094f, 0.090f, 0.082f };
            float[] splay = { -5f, 0f, 4f, 9f };
            float[] radii = { 0.0092f, 0.0095f, 0.009f, 0.0078f };
            float[][] lengths = { new[] { 0.044f, 0.026f, 0.021f }, new[] { 0.048f, 0.029f, 0.023f }, new[] { 0.045f, 0.027f, 0.021f }, new[] { 0.035f, 0.021f, 0.018f } };
            for (int f = 0; f < 4; f++)
                Finger(h, f + 1, new Vector3(s * xs[f], 0.002f, zs[f]), Quaternion.Euler(0, s * splay[f], 0), lengths[f], radii[f]);
            // Thumb: forward and out from the palm's side, rolled so it closes across the palm.
            Finger(h, 0, new Vector3(s * -0.031f, -0.008f, 0.028f), Quaternion.Euler(8, s * -40f, s * 50f), new[] { 0.040f, 0.031f, 0.026f }, 0.0112f);

            // Arm pieces live in rig space and are re-spanned every frame.
            h.forearm = Part(transform, capsule, skinMat, "Forearm", h.skin);
            h.gloveCuff = Part(transform, capsule, gloveMat, "GloveCuff", null);
            h.sleeve = Part(transform, capsule, sweaterMat, "Sleeve", h.cloth);
            h.upperArm = Part(transform, capsule, sweaterMat, "UpperArm", h.cloth);
            for (int i = 0; i < 5; i++) h.curl[i] = h.curlTarget[i] = 0.35f;
            return h;
        }

        void Finger(Hand h, int f, Vector3 basePos, Quaternion baseRot, float[] len, float r)
        {
            Transform p = h.root;
            h.baseRot[f] = baseRot;
            for (int i = 0; i < 3; i++)
            {
                var j = new GameObject($"f{f}_{i}").transform;
                j.SetParent(p, false);
                j.localPosition = i == 0 ? basePos : new Vector3(0, 0, len[i - 1]);
                j.localRotation = i == 0 ? baseRot : Quaternion.identity;
                float ri = r * (1f - 0.09f * i);
                var seg = Part(j, capsule, skinMat, "seg", h.skin);
                seg.localPosition = new Vector3(0, 0, len[i] * 0.5f);
                seg.localRotation = Quaternion.Euler(90, 0, 0);
                seg.localScale = new Vector3(2 * ri, len[i] * 0.5f + ri, 2 * ri);
                h.joints[f, i] = j;
                p = j;
            }
        }

        // ─── Public API ──────────────────────────────────────────────────────

        public void SetCamera(Camera c)
        {
            cam = c;
            right.placed = left.placed = false;
            ApplyVisible();
        }

        /// <summary>Acts out an action the student (or the demonstrator) just performed.</summary>
        public void Play(Intent intent, EquipmentView src, EquipmentView receiver)
        {
            if (!cam || !src || !isActiveAndEnabled) return;
            StopRoutine();
            routine = StartCoroutine(Act(intent, src, receiver));
        }

        /// <summary>Hand on a control while the student drags its slider (tap, knob, focus).</summary>
        public void BeginAdjust(EquipmentView v, IntentType intent)
        {
            if (!cam || !v || !isActiveAndEnabled) return;
            StopRoutine();
            var hs = EquipmentGeometry.For(v, intent, cam.transform.position);
            if (hs.Kind == GripKind.Side) { Hold(right, SideGrip(right, hs), GripCurl(right, hs.Radius)); return; }
            Hold(right, PinchAt(right, hs.Point), PinchCurl(right));
            Emit("grip", hs.Point);
        }

        /// <summary>0..1 position of the control being adjusted → wrist roll.</summary>
        public void AdjustValue(float v01) => right.rollTarget = Mathf.Lerp(-10f, 80f, Mathf.Clamp01(v01)) * right.s;

        public void EndAdjust()
        {
            if (routine != null) return;
            Rest(right);
        }

        public void StopAll()
        {
            StopRoutine();
            Rest(right);
            Rest(left);
        }

        void StopRoutine()
        {
            if (routine != null) StopCoroutine(routine);
            routine = null;
            right.typing = left.typing = false;
        }

        void Emit(string cue, Vector3 at) => Cue?.Invoke(cue, at);

        // ─── Choreography ────────────────────────────────────────────────────

        IEnumerator Act(Intent intent, EquipmentView src, EquipmentView receiver)
        {
            var viewer = cam.transform.position;
            var hs = EquipmentGeometry.For(src, intent.Type, viewer);
            var h = right;
            switch (intent.Type)
            {
                case IntentType.Inspect:
                    break;

                case IntentType.Type:
                    yield return Typing(hs, 1.3f);
                    break;

                case IntentType.Toggle:
                    yield return Press(h, hs.Point);
                    break;

                case IntentType.Rotate:
                    if (src is FlaskView flask)
                    {
                        yield return Reach(h, Follow(src.transform, SideGrip(h, hs)), GripCurl(h, hs.Radius), 0.45f);
                        Emit("grip", hs.Point);
                        AttachTo(h, src.transform);
                        flask.Swirl();
                        yield return Wait(1.7f);
                    }
                    else
                    {
                        yield return Reach(h, PinchAt(h, hs.Point), PinchCurl(h), 0.45f);
                        Emit("twist", hs.Point);
                        float v = (float)(intent.Value ?? 0.5);
                        float max = src.TryGetValueRange(IntentType.Rotate, out var range) && range.Max > range.Min ? Mathf.InverseLerp(range.Min, range.Max, v) : Mathf.Clamp01(v);
                        h.rollTarget = Mathf.Lerp(-10f, 80f, max) * h.s;
                        yield return Wait(0.75f);
                    }
                    break;

                case IntentType.Release:
                    if (src.TryGetComponent<CableRenderer>(out _))
                    {
                        yield return Reach(h, PinchAt(h, hs.Point), PinchCurl(h), 0.4f);
                        Emit("release", hs.Point);
                        yield return Wait(0.2f);
                        break;
                    }
                    // Pendulum: pinch the bob, then let go cleanly.
                    yield return Reach(h, PinchAt(h, hs.Point), PinchCurl(h), 0.45f);
                    Emit("grip", hs.Point);
                    yield return Wait(0.35f);
                    SetCurl(h, 0.05f, 0.05f);
                    Emit("release", hs.Point);
                    var open = h.target();
                    Hold(h, () => new Pose(open.position - Flat(hs.Point - viewer) * 0.08f + Vector3.up * 0.02f, open.rotation), null, keepCurl: true);
                    yield return Wait(0.45f);
                    break;

                case IntentType.Connect:
                    bool lead = receiver && src.TryGetComponent<CableRenderer>(out _);
                    yield return Reach(h, lead ? PinchAt(h, hs.Point) : Follow(src.transform, PinchAt(h, hs.Point)), PinchCurl(h), 0.45f);
                    Emit("grip", hs.Point);
                    if (lead)
                    {
                        // Leads: carry the plug to the receiving terminal.
                        var to = receiver.Attach.position;
                        Hold(h, PinchAt(h, to), null, keepCurl: true);
                        yield return Wait(0.7f);
                    }
                    else
                    {
                        AttachTo(h, src.transform); // the part glides into its socket with the hand
                        yield return Wait(1.0f);
                    }
                    Emit("press", src.transform.position);
                    break;

                case IntentType.Grab:
                    if (src is WearableView)
                    {
                        yield return Reach(h, hs.Kind == GripKind.Side ? SideGrip(h, hs) : PinchAt(h, hs.Point), hs.Kind == GripKind.Side ? GripCurl(h, hs.Radius) : PinchCurl(h), 0.45f);
                        Emit("grip", hs.Point);
                        yield return Wait(0.15f);
                        // Bring it up to the face / body as it is put on.
                        Hold(h, () => new Pose(cam.transform.TransformPoint(new Vector3(h.s * 0.07f, -0.04f, 0.2f)), cam.transform.rotation * Quaternion.Euler(-10, -h.s * 30, -h.s * 70)), null, keepCurl: true);
                        Hold(left, () => new Pose(cam.transform.TransformPoint(new Vector3(left.s * 0.08f, -0.05f, 0.21f)), cam.transform.rotation * Quaternion.Euler(-10, -left.s * 30, -left.s * 70)), PinchCurl(left));
                        yield return Wait(0.55f);
                        Rest(left);
                    }
                    else
                    {
                        yield return Reach(h, Follow(src.transform, hs.Kind == GripKind.Side ? SideGrip(h, hs) : PinchAt(h, hs.Point)), hs.Kind == GripKind.Side ? GripCurl(h, hs.Radius) : PinchCurl(h), 0.45f);
                        Emit("grip", hs.Point);
                        AttachTo(h, src.transform); // flask to the tile, funnel to the burette, slide to the stage…
                        yield return Wait(1.15f);
                        Emit("release", src.transform.position);
                    }
                    break;

                case IntentType.Pour:
                    var carrier = src is ContainerView cv && cv.tiltPivot ? cv.tiltPivot : src.transform;
                    yield return Reach(h, Follow(carrier, hs.Kind == GripKind.Side ? SideGrip(h, hs) : PinchAt(h, hs.Point)), hs.Kind == GripKind.Side ? GripCurl(h, hs.Radius) : PinchCurl(h), 0.4f);
                    Emit("grip", hs.Point);
                    AttachTo(h, carrier);
                    // The container carries itself to the receiver, tilts and pours (ContainerView).
                    float t = 0;
                    while (t < 3.2f && (t < 0.3f || src is ContainerView c2 && c2.Pouring)) { t += Time.deltaTime; yield return null; }
                    Emit("release", src.transform.position);
                    break;
            }
            yield return Wait(0.15f);
            right.typing = left.typing = false;
            Rest(right);
            Rest(left);
            routine = null;
        }

        IEnumerator Press(Hand h, Vector3 point)
        {
            var dir = Approach(point, 0.25f);
            var poke = PokeCurl(h);
            yield return Reach(h, () => PokeAt(h, point - dir * 0.035f, dir), poke, 0.4f);
            Hold(h, () => PokeAt(h, point + dir * 0.004f, dir), null, keepCurl: true);
            yield return Wait(0.12f);
            Emit("press", point);
            Hold(h, () => PokeAt(h, point - dir * 0.03f, dir), null, keepCurl: true);
            yield return Wait(0.25f);
        }

        IEnumerator Typing(EquipmentGeometry.Hotspot hs, float seconds)
        {
            if (hs.Kind != GripKind.Type) { yield return Press(right, hs.Point); yield break; }
            var f = Flat(hs.Point - cam.transform.position);
            var r = Vector3.Cross(Vector3.up, f).normalized;
            var rot = Quaternion.LookRotation(f, Vector3.up) * Quaternion.Euler(14, 0, 0);
            foreach (var h in new[] { right, left })
            {
                var hand = h;
                Hold(hand, () => new Pose(hs.Point - f * 0.15f + r * hand.s * 0.075f + Vector3.up * 0.035f, rot * Quaternion.Euler(0, -hand.s * 8, 0)), null);
                hand.typing = true;
            }
            float t = 0, next = 0.4f;
            while (t < seconds)
            {
                t += Time.deltaTime;
                if (t > next) { next += UnityEngine.Random.Range(0.08f, 0.16f); Emit("key", hs.Point); }
                yield return null;
            }
            right.typing = left.typing = false;
        }

        IEnumerator Reach(Hand h, Func<Pose> pose, float[] curl, float seconds)
        {
            Hold(h, pose, curl);
            yield return Wait(seconds);
        }

        static IEnumerator Wait(float s)
        {
            float t = 0;
            while (t < s) { t += Time.deltaTime; yield return null; }
        }

        // ─── Poses ───────────────────────────────────────────────────────────

        void Hold(Hand h, Func<Pose> pose, float[] curl, bool keepCurl = false)
        {
            h.target = pose;
            h.speed = 9f;
            if (!keepCurl && curl != null) for (int i = 0; i < 5; i++) h.curlTarget[i] = curl[i];
        }

        void Rest(Hand h)
        {
            h.target = null;
            h.speed = 7f;
            h.rollTarget = 0;
            for (int i = 0; i < 5; i++) h.curlTarget[i] = i == 0 ? 0.3f : 0.32f + i * 0.04f;
        }

        void SetCurl(Hand h, float thumb, float fingers)
        {
            h.curlTarget[0] = thumb;
            for (int i = 1; i < 5; i++) h.curlTarget[i] = fingers;
        }

        /// <summary>A grip pinned to the object from the start, so the hand meets it even while it moves.</summary>
        static Func<Pose> Follow(Transform obj, Func<Pose> pose)
        {
            var p = pose();
            var lp = obj.InverseTransformPoint(p.position);
            var lr = Quaternion.Inverse(obj.rotation) * p.rotation;
            return () => obj ? new Pose(obj.TransformPoint(lp), obj.rotation * lr) : p;
        }

        /// <summary>Keeps the hand exactly where it is relative to a moving object (carry, pour, swirl).</summary>
        void AttachTo(Hand h, Transform obj)
        {
            if (h.target == null) return;
            var p = h.target();
            var lp = obj.InverseTransformPoint(p.position);
            var lr = Quaternion.Inverse(obj.rotation) * p.rotation;
            h.target = () => obj ? new Pose(obj.TransformPoint(lp), obj.rotation * lr) : p;
            h.speed = 30f;
        }

        Pose RestPose(Hand h)
        {
            var t = cam.transform;
            float breathe = Mathf.Sin(Time.time * 1.2f + h.s) * 0.004f;
            var local = new Vector3(h.s * 0.19f, -0.24f + breathe, 0.34f);
            return new Pose(t.TransformPoint(local), t.rotation * Quaternion.Euler(30, -h.s * 12, -h.s * 22));
        }

        /// <summary>Palm against the side of a vessel, fingers wrapping round its far side, thumb up.</summary>
        Func<Pose> SideGrip(Hand h, EquipmentGeometry.Hotspot hs)
        {
            var point = hs.Point;
            float radius = hs.Radius;
            return () =>
            {
                var f = Flat(point - cam.transform.position);
                var r = Vector3.Cross(Vector3.up, f).normalized;
                var outward = r * h.s;
                var rot = Quaternion.LookRotation(f, outward);
                return new Pose(point + outward * (radius + 0.017f) - f * 0.05f, rot);
            };
        }

        Func<Pose> PinchAt(Hand h, Vector3 point)
        {
            return () =>
            {
                var rot = Quaternion.LookRotation(Approach(point, 0.35f), Vector3.up) * Quaternion.Euler(0, 0, -h.s * 20f);
                return new Pose(point - rot * new Vector3(h.s * -0.03f, -0.06f, 0.13f), rot);
            };
        }

        Pose PokeAt(Hand h, Vector3 tip, Vector3 dir)
        {
            var rot = Quaternion.LookRotation(dir, Vector3.up);
            return new Pose(tip - rot * new Vector3(h.s * -0.027f, 0.0f, 0.183f), rot);
        }

        Vector3 Approach(Vector3 point, float down)
        {
            var d = point - cam.transform.position;
            return Vector3.Slerp(Flat(d), Vector3.down, down).normalized;
        }

        static Vector3 Flat(Vector3 v)
        {
            v.y = 0;
            return v.sqrMagnitude < 1e-6f ? Vector3.forward : v.normalized;
        }

        static float[] GripCurl(Hand h, float radius)
        {
            float c = Mathf.Lerp(0.9f, 0.45f, Mathf.InverseLerp(0.012f, 0.05f, radius));
            return new[] { 0.4f, c, c + 0.03f, c + 0.06f, c + 0.1f };
        }

        static float[] PinchCurl(Hand h) => new[] { 0.65f, 0.45f, 0.75f, 0.85f, 0.9f };
        static float[] PokeCurl(Hand h) => new[] { 0.6f, 0.03f, 0.85f, 0.9f, 0.95f };

        // ─── Per frame ───────────────────────────────────────────────────────

        void LateUpdate()
        {
            bool should = showHands && cam && cam.isActiveAndEnabled;
            if (should != visible) { visible = should; ApplyVisible(); }
            if (!visible) return;

            matCheck -= Time.unscaledDeltaTime;
            if (matCheck <= 0)
            {
                matCheck = 0.3f;
                bool g = GlovesOn != null && GlovesOn(), c = CoatOn != null && CoatOn();
                if (g != gloves || c != coat) { gloves = g; coat = c; ApplyMaterials(); }
            }
            float dt = Time.deltaTime;
            UpdateHand(right, dt);
            UpdateHand(left, dt);
            RequestLean();
        }

        /// <summary>
        /// Out of reach? Like a real person, step in / rise on tiptoe: ask the camera to lean so the
        /// shoulder comes within arm's length of the target, instead of stretching the arm.
        /// </summary>
        void RequestLean()
        {
            if (!director) return;
            Vector3 want = Vector3.zero;
            foreach (var h in new[] { right, left })
            {
                if (h.target == null) continue;
                var t = h.target().position;
                var shoulder0 = cam.transform.TransformPoint(new Vector3(h.s * ShoulderLocal.x, ShoulderLocal.y, ShoulderLocal.z)) - director.Lean;
                var d = t - shoulder0;
                float excess = d.magnitude - (UpperArm + Forearm - 0.06f);
                if (excess <= 0) continue;
                var lean = d.normalized * excess;
                lean.y = Mathf.Clamp(lean.y, -0.3f, 0.3f); // crouch / tiptoe
                if (lean.sqrMagnitude > want.sqrMagnitude) want = lean;
            }
            director.LeanRequest = Vector3.ClampMagnitude(want, 0.7f);
        }

        void UpdateHand(Hand h, float dt)
        {
            var camT = cam.transform;
            var pose = h.target != null ? h.target() : RestPose(h);
            var lp = camT.InverseTransformPoint(pose.position);
            var lr = Quaternion.Inverse(camT.rotation) * pose.rotation;
            if (!h.placed)
            {
                // Enter from below the view instead of popping in.
                h.localPos = lp + Vector3.down * 0.25f;
                h.localRot = lr;
                h.placed = true;
            }
            float k = 1f - Mathf.Exp(-dt * h.speed);
            h.localPos = Vector3.Lerp(h.localPos, lp, k);
            h.localRot = Quaternion.Slerp(h.localRot, lr, k);
            h.roll = Mathf.Lerp(h.roll, h.rollTarget, 1f - Mathf.Exp(-dt * 8f));

            var wristPos = camT.TransformPoint(h.localPos);
            var wristRot = camT.rotation * h.localRot * Quaternion.Euler(0, 0, h.roll);
            h.root.SetPositionAndRotation(wristPos, wristRot);

            // Fingers
            float ck = 1f - Mathf.Exp(-dt * 12f);
            for (int f = 0; f < 5; f++)
            {
                float target = h.curlTarget[f];
                if (h.typing && f > 0) target = 0.3f + 0.35f * Mathf.Max(0, Mathf.Sin(Time.time * 15f + f * 1.9f + h.s * 0.7f));
                h.curl[f] = Mathf.Lerp(h.curl[f], target, ck);
                var flex = f == 0 ? ThumbFlex : FingerFlex;
                for (int i = 0; i < 3; i++)
                {
                    var q = Quaternion.Euler(h.curl[f] * flex[i], 0, 0);
                    h.joints[f, i].localRotation = i == 0 ? h.baseRot[f] * q : q;
                }
            }

            // Arm: two bones of fixed length (no stretching), elbow solved by IK, pointing down and out.
            var shoulder = camT.TransformPoint(new Vector3(h.s * ShoulderLocal.x, ShoulderLocal.y, ShoulderLocal.z));
            var sw = wristPos - shoulder;
            float d = sw.magnitude, reach = UpperArm + Forearm - 0.004f;
            if (d > reach)
            {
                // Still out of reach while the view leans in: the hand stops at full arm's length.
                wristPos = shoulder + sw / d * reach;
                d = reach;
                h.root.position = wristPos;
            }
            d = Mathf.Max(d, Mathf.Abs(UpperArm - Forearm) + 0.01f);
            var axis = (wristPos - shoulder).normalized;
            float along = (UpperArm * UpperArm - Forearm * Forearm + d * d) / (2f * d);
            float bend = Mathf.Sqrt(Mathf.Max(0f, UpperArm * UpperArm - along * along));
            var hint = camT.right * h.s * 0.7f - camT.up - camT.forward * 0.15f;
            var pole = Vector3.ProjectOnPlane(hint, axis);
            if (pole.sqrMagnitude < 1e-6f) pole = -camT.up;
            var elbow = shoulder + axis * along + pole.normalized * bend;
            var dir = (elbow - wristPos).normalized;
            Span(h.forearm, elbow, wristPos + dir * 0.01f, 0.028f);
            Span(h.sleeve, elbow, Vector3.Lerp(elbow, wristPos, coat ? 0.78f : 0.62f), coat ? 0.04f : 0.036f);
            Span(h.upperArm, shoulder, elbow, coat ? 0.048f : 0.044f);
            if (gloves) Span(h.gloveCuff, wristPos + dir * 0.005f, wristPos + dir * 0.065f, 0.031f);
            h.gloveCuff.gameObject.SetActive(gloves);
        }

        static void Span(Transform t, Vector3 a, Vector3 b, float r)
        {
            var d = b - a;
            float len = d.magnitude;
            t.SetPositionAndRotation((a + b) * 0.5f, len > 1e-5f ? Quaternion.FromToRotation(Vector3.up, d / len) : Quaternion.identity);
            t.localScale = new Vector3(2 * r, len * 0.5f + r, 2 * r);
        }

        void ApplyMaterials()
        {
            foreach (var h in new[] { right, left })
            {
                foreach (var r in h.skin) r.sharedMaterial = gloves && r.transform != h.forearm ? gloveMat : skinMat;
                foreach (var r in h.cloth) r.sharedMaterial = coat ? coatMat : sweaterMat;
            }
        }

        void ApplyVisible()
        {
            bool on = showHands && cam && cam.isActiveAndEnabled;
            if (right == null) return;
            foreach (Transform child in transform) child.gameObject.SetActive(on && (child.name != "GloveCuff" || gloves));
        }
    }
}
