using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ECHLabs.Core;
using ECHLabs.Runtime.Bridge;
using ECHLabs.Runtime.Demo;
using ECHLabs.Runtime.FX;
using ECHLabs.Runtime.Equipment;
using ECHLabs.Runtime.Interaction;
using ECHLabs.Runtime.Net;
using ECHLabs.Runtime.Rendering;
using ECHLabs.Runtime.UI;
using ECHLabs.Runtime.World;
using Newtonsoft.Json.Linq;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace ECHLabs.Runtime
{
    /// <summary>
    /// Orchestrates one lab run (lives in the Bootstrap scene):
    /// launch params → (pairing) → download scenario → load room → spawn equipment → pick mode
    /// and quality → play → autosave → results → report to host app.
    /// </summary>
    public sealed class LabSession : MonoBehaviour
    {
        public const string DefaultPracticeScenario = "chem-titration-hcl-naoh";
        const float AutosaveSeconds = 15f;

        [Header("Scene wiring (created by SceneBuilder)")]
        public LabHud hud;
        public InteractionController interaction;
        public CameraDirector director;
        public QualityManager quality;
        public DesktopRig desktopRig;
        public TouchRig touchRig;
        public StereoRig stereoRig;
        public XRRig xrRig;
        public Camera flatCamera;

        public ScenarioRuntime Runtime { get; private set; }
        public LabWorld World { get; private set; }
        public LaunchParams Params { get; private set; }

        // Presentation layer added at runtime (no scene changes needed).
        [NonSerialized] public HandsRig hands;
        [NonSerialized] public LabFx fx;
        GuideArrow guide;
        GraphFeed graphFeed;
        DemoDirector demo;
        ScenarioDefinition demoTemplate;
        readonly Dictionary<EquipmentView, (Pose root, Pose pivot)> initialPoses = new Dictionary<EquipmentView, (Pose, Pose)>();
        readonly Dictionary<string, Bounds> stationBounds = new Dictionary<string, Bounds>();
        readonly Dictionary<string, Vector3> stationFront = new Dictionary<string, Vector3>();
        Pose spawnPose;
        bool hasSpawn;

        /// <summary>The world on the bench right now: the demo's while it runs, else the student's.</summary>
        LabWorld ActiveWorld => demo && demo.Running && demo.World != null ? demo.World : World;

        LabApiClient api;
        Dictionary<string, EquipmentView> views = new Dictionary<string, EquipmentView>();
        public IReadOnlyDictionary<string, EquipmentView> Views => views;
        public GuideArrow guideArrowPublic => guide;
        string scenarioServerId;
        float autosaveTimer;
        bool paused, running, completing;
        Transform roomRoot;

        // ─── Startup ─────────────────────────────────────────────────────────

        void Awake()
        {
            HostBridge.Ensure();
            HostBridge.CommandReceived += OnHostCommand;
            Params = HostBridge.ReadStartupParams();
            DevTools.AutoPlay.AttachIfRequested(this);
#if UNITY_ANDROID && !UNITY_EDITOR
            gameObject.AddComponent<DevTools.Diagnostics>();
#endif
        }

        void OnDestroy() => HostBridge.CommandReceived -= OnHostCommand;

        IEnumerator Start()
        {
            WireHud();
            hud.ShowLoading("Preparing your laboratory…", "Checking your device", 0.05f);

            // Embedded in the ECH app on phones: the app sends a "launch" message once Unity is up.
            bool embedded = (Application.platform == RuntimePlatform.Android || Application.platform == RuntimePlatform.IPhonePlayer) && !PlatformInfo.IsHeadset;
            if (embedded && !Params.HasToken)
            {
                LaunchParams received = null;
                void OnLaunch(LaunchParams p) => received = p;
                HostBridge.LaunchReceived += OnLaunch;
                HostBridge.Send("ready");
                float waited = 0;
                while (received == null && waited < 4f) { waited += Time.unscaledDeltaTime; yield return null; }
                HostBridge.LaunchReceived -= OnLaunch;
                if (received != null) Params = received.Merge(Params);
            }

            var task = Run();
            while (!task.IsCompleted) yield return null;
            if (task.Exception != null)
            {
                Debug.LogException(task.Exception);
                hud.ShowError("The lab could not start", task.Exception.InnerException?.Message ?? task.Exception.Message, () => SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex));
            }
        }

        async Task Run()
        {
            api = new LabApiClient(Params.Api, Params.Token);
            Speech.Init(Params.Lang);
            _ = api.FlushAll(); // send anything left from an offline session

            // Headsets have no ECH login: pair with the student's phone/PC.
            if (!Params.HasToken && PlatformInfo.IsHeadset) await PairHeadset();

            hud.ShowLoading("Preparing your laboratory…", "Downloading the experiment", 0.2f);
            ScenarioDefinition def = null;
            string scenarioRef = Params.Scenario ?? DefaultPracticeScenario;
            if (Params.HasToken)
            {
                try
                {
                    var (d, card) = await api.GetScenario(scenarioRef);
                    def = d;
                    scenarioServerId = card?["id"]?.ToString();
                }
                catch (Exception e)
                {
                    Debug.LogWarning("[ECHLabs] Download failed, trying offline copy: " + e.Message);
                    def = ScenarioCache.Load(scenarioRef);
                    if (def == null) throw new Exception("You're offline and this lab hasn't been downloaded yet. Connect to the internet once and try again.");
                }
            }
            else def = ScenarioCache.Load(scenarioRef) ?? ScenarioCache.Load(DefaultPracticeScenario);
            if (def == null) throw new Exception("Lab not found: " + scenarioRef);
            def.Localize(Params.Lang);

            hud.ShowLoading(def.Title, "Building the " + def.Environment + "…", 0.45f);
            await LoadRoom(def.Environment);

            var resume = ScenarioCache.LoadResume(def.Id);
            if (resume != null && Params.ResumeClientId != null && resume.ClientId != Params.ResumeClientId) resume = null;
            string clientId = resume?.ClientId ?? Guid.NewGuid().ToString();
            // New values every try. A lab session gets them from the server (so it can grade them);
            // practice/offline picks them here, seeded by the attempt so a resumed attempt keeps them.
            demoTemplate = def.Clone();
            if (!def.VariantApplied) Variants.ApplyRandom(def, new System.Random(StableHash(clientId)));
            else Variants.Apply(def, null);
            World = new LabWorld(def);
            Runtime = new ScenarioRuntime(def, World, clientId);

            hud.ShowLoading(def.Title, "Placing equipment", 0.75f);
            views = EquipmentFactory.SpawnAll(World, roomRoot);
            CapturePoses();
            HookRuntimeEvents();
            interaction.Init(i => Runtime.Handle(i), () => Runtime.Current, hud, views);
            hud.SetLab(def);
            SetupPresentation(def);

            quality.Apply(QualityManager.Parse(Params.Quality, QualityManager.Detect()));
            SetMode(ParseMode(Params.Mode) ?? AutoMode());

            if (Params.HasToken)
            {
                var r = await api.StartAttempt(Runtime.Progress.ClientId, scenarioServerId ?? def.Id, Params.Lesson, PlatformInfo.Platform, ModeName(interaction.Rig.Mode), quality.Tier.ToString().ToLowerInvariant(), Params.Lang);
                if (!r.Ok && api.Online && r.Status == 401) throw new Exception("Your lab session has expired. Please open the lab again from the ECH app.");
            }

            hud.HideOverlay();
            running = true;
            if (resume != null && resume.CompletedSteps.Count > 0)
            {
                Runtime.Resume(resume);
                hud.Toast("Welcome back — continuing where you left off.", true);
            }
            else
            {
                // Watch how it's done first (one tap to skip).
                if (await AskForDemo(def)) await RunDemo();
                Runtime.Start();
            }
            HostBridge.Send("started", new { scenario = def.Id, clientId = Runtime.Progress.ClientId });
        }

        async Task LoadRoom(string environment)
        {
            var existing = SceneManager.GetSceneByName(environment);
            if (!existing.isLoaded)
            {
                var op = SceneManager.LoadSceneAsync(environment, LoadSceneMode.Additive);
                if (op == null) throw new Exception($"Room '{environment}' is not in this build.");
                while (!op.isDone) { hud.ShowLoading("Preparing your laboratory…", "Building the " + environment, 0.45f + op.progress * 0.25f); await Task.Yield(); }
                existing = SceneManager.GetSceneByName(environment);
            }
            SceneManager.SetActiveScene(existing); // room lighting / skybox / probes
            roomRoot = existing.GetRootGameObjects().FirstOrDefault()?.transform;

            // Stand the student at the room's entrance view (all rigs).
            var spawn = existing.GetRootGameObjects().Select(g => g.transform.Find("SpawnPoint") ?? (g.name == "SpawnPoint" ? g.transform : null)).FirstOrDefault(t => t);
            if (spawn)
            {
                spawnPose = new Pose(spawn.position, spawn.rotation);
                hasSpawn = true;
                if (flatCamera) flatCamera.transform.SetPositionAndRotation(spawn.position, spawn.rotation);
                if (stereoRig) stereoRig.Root.SetPositionAndRotation(new Vector3(spawn.position.x, spawn.position.y, spawn.position.z), Quaternion.Euler(0, spawn.eulerAngles.y, 0));
                if (xrRig && xrRig.origin) xrRig.origin.SetPositionAndRotation(new Vector3(spawn.position.x, 0, spawn.position.z), Quaternion.Euler(0, spawn.eulerAngles.y, 0));
            }
        }

        async Task PairHeadset()
        {
            var start = await api.PairStart(SystemInfo.deviceModel);
            if (!start.Ok) throw new Exception("Could not reach ECH to connect this headset: " + start.Message);
            string code = start.Data.Value<string>("code");
            string secret = start.Data.Value<string>("deviceSecret");
            hud.ShowPairing(code.Substring(0, 3) + " " + code.Substring(3), "The code expires in 10 minutes.");
            for (int i = 0; i < 300; i++)
            {
                await Task.Delay(2000);
                var poll = await api.PairPoll(secret);
                if (poll.Status == 404 || poll.Status == 410) throw new Exception("The pairing code expired. Restart the lab to get a new one.");
                if (poll.Ok && poll.Data?.Value<string>("status") == "paired")
                {
                    Params.Token = poll.Data.Value<string>("labToken");
                    Params.Scenario ??= poll.Data.Value<string>("scenarioId");
                    Params.Lesson ??= poll.Data.Value<string>("lessonId");
                    api.SetToken(Params.Token);
                    hud.Toast("Connected — welcome " + poll.Data.Value<string>("studentName"), true);
                    return;
                }
            }
            throw new Exception("Pairing timed out.");
        }

        // ─── Modes ───────────────────────────────────────────────────────────

        LabMode AutoMode()
        {
            if (PlatformInfo.IsHeadset) return LabMode.XR;
            if (Application.isMobilePlatform || (UnityEngine.InputSystem.Touchscreen.current != null && UnityEngine.InputSystem.Mouse.current == null)) return LabMode.Touch;
            return LabMode.Desktop;
        }

        static LabMode? ParseMode(string s)
        {
            switch ((s ?? "").ToLowerInvariant())
            {
                case "desktop": return LabMode.Desktop;
                case "touch": return LabMode.Touch;
                case "cardboard": return LabMode.Cardboard;
                case "xr": return LabMode.XR;
                default: return null;
            }
        }

        static string ModeName(LabMode m) => m == LabMode.Cardboard ? "cardboard" : m == LabMode.XR ? "xr" : m == LabMode.Touch ? "touch" : "desktop";

        public void SetMode(LabMode mode)
        {
            IPointerSource rig;
            switch (mode)
            {
                case LabMode.Touch: rig = touchRig; break;
                case LabMode.Cardboard: rig = stereoRig; break;
                case LabMode.XR: rig = xrRig; break;
                default: rig = desktopRig; break;
            }
            foreach (var r in new MonoBehaviour[] { desktopRig, touchRig, stereoRig, xrRig }) if (r) r.gameObject.SetActive(ReferenceEquals(r, rig));
            if (flatCamera) flatCamera.gameObject.SetActive(!rig.WorldSpaceUI);
            interaction.SetRig(rig);
            director.cameraTransform = rig.WorldSpaceUI ? null : rig.Camera.transform;
            // Headsets track the student's real hands; every other mode shows first-person hands.
            bool handsOn = mode != LabMode.XR && hands;
            interaction.hands = handsOn ? hands : null;
            if (hands) hands.SetCamera(handsOn ? rig.Camera : null);
            if (guide) guide.cam = rig.Camera;
            hud.SetControlsMode(mode == LabMode.Touch ? "touch" : mode == LabMode.Desktop ? "desktop" : "stereo");
            if (Runtime?.Current != null) FocusStep(Runtime.Current);
        }

        // ─── Runtime events → presentation ───────────────────────────────────

        void HookRuntimeEvents()
        {
            Runtime.StepStarted += (step, index) =>
            {
                hud.HideTaskPanels();
                interaction.CancelPending();
                hud.ShowStep(step, index, Runtime.Def.Steps.Count);
                FocusStep(step);
                if (step.Kind == StepKind.Measure && step.Record != null) hud.ShowReading(step.Record, v => Runtime.SubmitReading(v));
                if (step.Kind == StepKind.Checkpoint && step.Checkpoint?.Question != null) hud.ShowQuestion(step.Checkpoint.Question, i => Runtime.AnswerCheckpoint(i));
                Save(false);
            };
            Runtime.StepCompleted += step => { hud.Toast("✓ " + (step.Title ?? "Step complete"), true); fx?.StepDone(); };
            Runtime.Say += text => { hud.Say(text); Speech.Say(text, Params.Lang); };
            Runtime.HazardTriggered += h => { hud.ShowHazard(h.Message); fx?.Hazard(); };
            Runtime.OnFeedback += fb =>
            {
                if (fb.Kind == FeedbackKind.WrongAction || fb.Kind == FeedbackKind.Impossible) { hud.Toast(fb.Message, false); fx?.Mistake(); }
            };
            Runtime.Completed += score => _ = Complete(score);
            // Things the student would notice (fizzing, precipitates, splint tests, overflows, spills).
            Runtime.World.OnEvent += e =>
            {
                if (e == null || string.IsNullOrEmpty(e.Message)) return;
                if (e.Type == "observe" || e.Type == "info") hud.Toast(e.Message, true);
                else if (e.Type == "overflow" || e.Type == "spill" || e.Type == "empty") hud.Toast(e.Message, false);
            };
        }

        public void FocusStepPublic(StepSpec step) => FocusStep(step);

        Coroutine pendingFocus;

        void FocusStep(StepSpec step)
        {
            if (step?.Focus == null || !views.ContainsKey(step.Focus)) return;
            if (pendingFocus != null) StopCoroutine(pendingFocus);
            pendingFocus = StartCoroutine(FocusWhenSettled(step));
        }

        /// <summary>A reading shot waits until a bottle that is still pouring has been put back.</summary>
        IEnumerator FocusWhenSettled(StepSpec step)
        {
            if (step.Kind == StepKind.Measure)
            {
                hands?.StopAll(); // no more leaning in: we stand back to read
                float waited = 0;
                while (waited < 3f && AnyPouring()) { waited += Time.deltaTime; yield return null; }
            }
            pendingFocus = null;
            FocusNow(step);
        }

        bool AnyPouring()
        {
            foreach (var x in views.Values) if (x is ContainerView c && c.Pouring) return true;
            return false;
        }

        void FocusNow(StepSpec step)
        {
            if (step?.Focus == null || !views.TryGetValue(step.Focus, out var v)) return;
            var rig = interaction.Rig;
            bool measuring = step.Kind == StepKind.Measure;
            // Scales (burette, rule) are read at eye level, without parallax; meters from slightly above.
            bool eyeLevel = measuring && !(v is InstrumentView);
            float dist = measuring ? (eyeLevel ? v.inspectDistance : v.inspectDistance * 1.5f) : -1f;
            if (rig != null && !rig.WorldSpaceUI) director.FocusOn(v.SettledFocusPosition, dist, eyeLevel, -v.transform.forward);
            else if (rig is XRRig xr)
            {
                var toCam = Vector3.ProjectOnPlane(xr.Camera.transform.position - v.FocusPosition, Vector3.up);
                if (toCam.magnitude > 1.6f) xr.TeleportTo(v.FocusPosition + toCam.normalized * 0.75f, v.FocusPosition);
            }
            if (eyeLevel) quality.SetInspectFocus(true, v.inspectDistance); else quality.SetInspectFocus(false, 1);
            if (measuring && !eyeLevel) quality.SetInspectFocus(true, dist);
        }

        void WireHud()
        {
            hud.HintRequested += () => Runtime?.RequestHint();
            hud.ContinueRequested += () => Runtime?.Continue();
            hud.FocusRequested += () =>
            {
                var step = demo && demo.Running ? demo.Runtime?.Current : Runtime?.Current;
                if (step != null) FocusStep(step);
                guide?.Flash();
            };
            hud.StationRequested += GoToStation;
            hud.SoundToggled += v => LabFx.SoundOn = v;
            hud.HapticsToggled += v => LabFx.HapticsOn = v;
            hud.HandsToggled += v => { if (hands) hands.ShowHands = v; };
            hud.DemoRequested += () => { if (running && !(demo && demo.Running) && Runtime != null && !Runtime.IsComplete) _ = RunDemo(); };
            hud.ModeRequested += m => { var mode = ParseMode(m); if (mode.HasValue) SetMode(mode.Value); };
            hud.QualityRequested += q => quality.Apply(QualityManager.Parse(q, quality.Tier), byUser: true);
            hud.GuidedChanged += g => interaction.guided = g;
            hud.RecenterRequested += () => stereoRig?.Recenter();
            hud.InspectRequested += v => { director.FocusOn(v.FocusPosition, v.inspectDistance, eyeLevel: true, front: -v.transform.forward); quality.SetInspectFocus(true, v.inspectDistance); };
            hud.ExitRequested += Exit;
            hud.RetryRequested += () =>
            {
                if (World != null) ScenarioCache.ClearResume(World.Definition.Id);
                SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
            };
        }

        // ─── Presentation: hands, guide, stations, sound, graphs, demo ─────────

        void SetupPresentation(ScenarioDefinition def)
        {
            fx = LabFx.Create();
            fx.Track(views.Values);
            if (!hands)
            {
                hands = HandsRig.Create();
                hands.director = director;
                hands.GlovesOn = () => AnyWorn("gloves");
                hands.CoatOn = () => AnyWorn("labcoat");
                hands.Cue += (cue, at) => fx?.OnHandCue(cue, at, Nearest(at));
            }
            if (!guide) guide = GuideArrow.Create();
            if (touchRig)
            {
                touchRig.moveInput = () => hud.MoveInput;
                touchRig.isOverControls = hud.IsOverJoystick;
            }
            graphFeed = new GraphFeed(hud.Graph);
            var spec = graphFeed.Setup(def);
            hud.ShowGraph(spec);
            if (spec == null) graphFeed = null;
            BuildStations(def);
            if (!demo) { demo = gameObject.AddComponent<DemoDirector>(); demo.session = this; }
        }

        bool AnyWorn(string type)
        {
            var w = ActiveWorld;
            if (w == null) return false;
            foreach (var e in w.OfType(type)) if (w.Bool(e.Id, "worn")) return true;
            return false;
        }

        EquipmentView Nearest(Vector3 at)
        {
            EquipmentView best = null;
            float bestD = 0.35f;
            foreach (var v in views.Values)
            {
                float d = Vector3.Distance(EquipmentGeometry.BoundsOf(v).ClosestPoint(at), at);
                if (d < bestD) { bestD = d; best = v; }
            }
            return best;
        }

        static readonly Dictionary<string, string> StationNames = new Dictionary<string, string>
        {
            { "benchA", "Bench A" }, { "benchB", "Bench B" }, { "ppe", "Safety gear" }, { "shelf", "Shelf" }, { "desk", "Desk" },
            { "wall", "Screen" }, { "scope", "Microscope" }, { "prep", "Prep table" }, { "rack", "Server rack" }, { "patch", "Patch panel" },
        };

        /// <summary>Work areas used by this activity (from the equipment's slots) → GO TO buttons.</summary>
        void BuildStations(ScenarioDefinition def)
        {
            stationBounds.Clear();
            stationFront.Clear();
            var order = new List<(string, string)>();
            foreach (var e in def.Equipment)
            {
                if (!views.TryGetValue(e.Id, out var v)) continue;
                string key = (e.Slot ?? "").Split('.')[0];
                if (key == "rack" || key == "shelf") key = (e.Slot ?? "").Replace('.', '_'); // each shelf/rack its own stop
                var b = EquipmentGeometry.BoundsOf(v);
                if (stationBounds.TryGetValue(key, out var sb)) { sb.Encapsulate(b); stationBounds[key] = sb; stationFront[key] += -v.transform.forward; }
                else
                {
                    stationBounds[key] = b;
                    stationFront[key] = -v.transform.forward;
                    string root = key.Split('_')[0];
                    string label = StationNames.TryGetValue(root, out var n) ? n : char.ToUpperInvariant(root[0]) + root.Substring(1);
                    if (key.Contains("_")) label += " " + key.Split('_')[1];
                    order.Add((key, label));
                }
            }
            hud.SetStations(order);
        }

        void GoToStation(string id)
        {
            fx?.Whoosh();
            var rig = interaction.Rig;
            if (string.IsNullOrEmpty(id))
            {
                if (!hasSpawn) return;
                if (rig != null && !rig.WorldSpaceUI) director.GlideTo(spawnPose.position, spawnPose.rotation);
                else if (rig is XRRig xr0) xr0.TeleportTo(spawnPose.position, spawnPose.position + spawnPose.forward);
                return;
            }
            if (!stationBounds.TryGetValue(id, out var b)) return;
            var front = stationFront[id]; front.y = 0;
            if (front.sqrMagnitude < 1e-4f) front = Vector3.back;
            if (rig != null && !rig.WorldSpaceUI) director.FocusOnArea(b, front.normalized);
            else if (rig is XRRig xr) xr.TeleportTo(b.center + front.normalized * 0.8f, b.center);
            quality.SetInspectFocus(false, 1);
        }

        void UpdateGuide(StepSpec step)
        {
            if (!guide) return;
            if (!interaction.guided || step == null || step.Kind != StepKind.Action || step.Expect == null || hud.IsBlockingModal || (hands && hands.Busy))
            {
                guide.Hide();
                return;
            }
            // Picked the bottle already? Point at where it goes.
            var pending = interaction.PendingSource;
            if (pending && pending.EquipmentId == step.Expect.Target && step.Expect.Into != null && views.TryGetValue(step.Expect.Into, out var into))
            {
                guide.Point(into, IntentType.Inspect);
                return;
            }
            if (views.TryGetValue(step.Expect.Target, out var v) && Enum.TryParse<IntentType>(step.Expect.Intent, out var intent)) guide.Point(v, intent);
            else guide.Hide();
        }

        void CapturePoses()
        {
            initialPoses.Clear();
            foreach (var v in views.Values)
            {
                var pivot = v is ContainerView c && c.tiltPivot ? c.tiltPivot : v.transform;
                initialPoses[v] = (new Pose(v.transform.position, v.transform.rotation), new Pose(pivot.position, pivot.rotation));
            }
        }

        /// <summary>Puts every piece of equipment back where it started and binds it to a world (demo ↔ student).</summary>
        public void BindViews(LabWorld world)
        {
            foreach (var kv in views)
            {
                var v = kv.Value;
                if (initialPoses.TryGetValue(v, out var p))
                {
                    v.transform.SetPositionAndRotation(p.root.position, p.root.rotation);
                    if (v is ContainerView c && c.tiltPivot && c.tiltPivot != v.transform) c.tiltPivot.SetPositionAndRotation(p.pivot.position, p.pivot.rotation);
                }
                var spec = world.Spec(kv.Key);
                if (spec != null) v.Bind(spec, world, EquipmentFactory.IntentsFor(spec.Type));
            }
            EquipmentFactory.Arrange(views);
            CapturePosesAfterArrange();
        }

        void CapturePosesAfterArrange()
        {
            foreach (var v in views.Values) if (v is GenericView g) g.Rebase();
        }

        Task<bool> AskForDemo(ScenarioDefinition def)
        {
            var tcs = new TaskCompletionSource<bool>();
            if (DevTools.AutoPlay.Active) { tcs.SetResult(DevTools.AutoPlay.WantsDemo); return tcs.Task; }
            hud.ShowDemoOffer(def.Title, DemoDirector.EstimateMinutes(def), () => tcs.TrySetResult(true), () => tcs.TrySetResult(false));
            return tcs.Task;
        }

        /// <summary>Runs the narrated demo on its own world, then hands the bench back to the student.</summary>
        async Task RunDemo()
        {
            var done = new TaskCompletionSource<bool>();
            void OnDone() => done.TrySetResult(true);
            bool inputWas = interaction.enabled;
            interaction.CancelPending();
            interaction.enabled = false;
            guide?.Hide();
            demo.Finished += OnDone;
            demo.Begin(demoTemplate, World.Definition);
            await done.Task;
            demo.Finished -= OnDone;
            BindViews(World);
            hud.Graph.ResetData();
            interaction.enabled = inputWas && !DevTools.AutoPlay.Active;
            if (Runtime.Current != null)
            {
                hud.ShowStep(Runtime.Current, Runtime.StepIndex, Runtime.Def.Steps.Count);
                FocusStep(Runtime.Current);
            }
            else if (hasSpawn && interaction.Rig != null && !interaction.Rig.WorldSpaceUI) director.GlideTo(spawnPose.position, spawnPose.rotation);
            hud.Say("Your turn! Take your time. Tap \u201cWhere do I go?\u201d whenever you need a pointer.");
        }

        static int StableHash(string s)
        {
            unchecked
            {
                int h = (int)2166136261;
                foreach (char c in s ?? "") h = (h ^ c) * 16777619;
                return h & 0x7fffffff;
            }
        }

        // ─── Loop ────────────────────────────────────────────────────────────

        void Update()
        {
#if UNITY_ANDROID && !UNITY_EDITOR
            if (UnityEngine.InputSystem.Keyboard.current != null && UnityEngine.InputSystem.Keyboard.current.escapeKey.wasPressedThisFrame) { Exit(); return; }
#endif
            if (!running || Runtime == null) return;
            float dt = Time.deltaTime;
            bool demoOn = demo && demo.Running;
            if (demoOn) { if (!paused && demo.Runtime != null && !demo.Runtime.IsComplete) demo.Runtime.Tick(dt); }
            else if (!paused && !Runtime.IsComplete && Runtime.Current != null) Runtime.Tick(dt);
            foreach (var v in views.Values) v.Render(dt);
            var shownRt = demoOn && demo.Runtime != null ? demo.Runtime : Runtime;
            hud.UpdateLive(ActiveWorld, shownRt.LiveScore);
            graphFeed?.Tick(ActiveWorld, dt);
            if (!(demoOn && demo.Runtime == null)) UpdateGuide(shownRt.Current); // the intro drives the arrow itself
            if (demoOn) return;
            autosaveTimer += Time.unscaledDeltaTime;
            if (autosaveTimer >= AutosaveSeconds) { autosaveTimer = 0; Save(false); }
        }

        void Save(bool final)
        {
            if (Runtime == null || (Runtime.Current == null && !Runtime.IsComplete)) return;
            var snap = Runtime.Snapshot(includeWorld: true);
            if (!Runtime.IsComplete) ScenarioCache.SaveResume(snap);
            if (Params.HasToken && !final)
            {
                snap.Complete = null;
                _ = api.SaveProgress(snap); // perf stats are attached only on completion, to keep autosaves small
            }
        }

        async Task Complete(ScoreBreakdown local)
        {
            if (completing) return;
            completing = true;
            hud.HideTaskPanels();
            ScenarioCache.ClearResume(World.Definition.Id);
            int? xp = null;
            IEnumerable<string> badges = null;
            var shown = local;
            if (Params.HasToken)
            {
                hud.ShowLoading("Saving your results…", "Your teacher will see this attempt", 0.9f);
                var payload = JObject.FromObject(Runtime.Snapshot(includeWorld: false));
                payload["complete"] = true;
                payload["perf"] = JObject.FromObject(new { avgFps = quality.AvgFps, minFps = quality.MinFps, gpu = SystemInfo.graphicsDeviceName, deviceModel = SystemInfo.deviceModel });
                OfflineQueue.Put(Runtime.Progress.ClientId, payload.ToString());
                var r = await api.FlushOne(Runtime.Progress.ClientId);
                if (r.Ok && r.Data?["outcome"] is JObject outcome)
                {
                    xp = outcome.Value<int?>("xpAwarded");
                    badges = (outcome["newBadges"] as JArray)?.Select(b => (string)b).ToList();
                    var s = outcome["score"];
                    if (s != null) { shown.Accuracy = s.Value<int>("accuracy"); shown.Procedure = s.Value<int>("procedure"); shown.Safety = s.Value<int>("safety"); shown.Total = s.Value<int>("total"); }
                    shown.Passed = outcome.Value<bool>("passed");
                }
                else if (!api.Online) hud.Toast("You're offline — your result will be sent automatically when you reconnect.", true);
            }
            hud.ShowResults(World.Definition, shown, xp, badges, Params.IsPractice);
            HostBridge.Send("completed", new { scenario = World.Definition.Id, clientId = Runtime.Progress.ClientId, score = shown.Total, passed = shown.Passed, xp });
            Speech.Say(shown.Passed ? "Excellent work! Experiment complete." : "Experiment finished. Review your results and try again.", Params.Lang);
        }

        void Exit()
        {
            Save(false);
            HostBridge.Send("exit", new { completed = Runtime?.IsComplete ?? false });
#if UNITY_STANDALONE && !UNITY_EDITOR
            Application.Quit();
#endif
        }

        void OnHostCommand(string cmd)
        {
            if (cmd == "pause") { paused = true; Save(false); }
            else if (cmd == "resume") paused = false;
            else if (cmd == "exit") Exit();
        }

        void OnApplicationPause(bool pause) { if (pause) Save(false); }
        void OnApplicationQuit() => Save(false);
    }
}
