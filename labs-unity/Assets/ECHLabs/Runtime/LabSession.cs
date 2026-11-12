using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ECHLabs.Core;
using ECHLabs.Runtime.Bridge;
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

        LabApiClient api;
        Dictionary<string, EquipmentView> views = new Dictionary<string, EquipmentView>();
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

            World = new LabWorld(def);
            var resume = ScenarioCache.LoadResume(def.Id);
            if (resume != null && Params.ResumeClientId != null && resume.ClientId != Params.ResumeClientId) resume = null;
            Runtime = new ScenarioRuntime(def, World, resume?.ClientId);

            hud.ShowLoading(def.Title, "Placing equipment", 0.75f);
            views = EquipmentFactory.SpawnAll(World, roomRoot);
            HookRuntimeEvents();
            interaction.Init(i => Runtime.Handle(i), () => Runtime.Current, hud, views);
            hud.SetLab(def);

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
            else Runtime.Start();
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
            Runtime.StepCompleted += step => hud.Toast("✓ " + (step.Title ?? "Step complete"), true);
            Runtime.Say += text => { hud.Say(text); Speech.Say(text, Params.Lang); };
            Runtime.HazardTriggered += h => hud.ShowHazard(h.Message);
            Runtime.OnFeedback += fb =>
            {
                if (fb.Kind == FeedbackKind.WrongAction || fb.Kind == FeedbackKind.Impossible) hud.Toast(fb.Message, false);
            };
            Runtime.Completed += score => _ = Complete(score);
        }

        void FocusStep(StepSpec step)
        {
            if (step?.Focus == null || !views.TryGetValue(step.Focus, out var v)) return;
            var rig = interaction.Rig;
            bool eyeLevel = step.Kind == StepKind.Measure; // read scales without parallax
            if (rig != null && !rig.WorldSpaceUI) director.FocusOn(v.FocusPosition, eyeLevel ? v.inspectDistance : -1f, eyeLevel, -v.transform.forward);
            else if (rig is XRRig xr)
            {
                var toCam = Vector3.ProjectOnPlane(xr.Camera.transform.position - v.FocusPosition, Vector3.up);
                if (toCam.magnitude > 1.6f) xr.TeleportTo(v.FocusPosition + toCam.normalized * 0.75f, v.FocusPosition);
            }
            if (eyeLevel) quality.SetInspectFocus(true, v.inspectDistance); else quality.SetInspectFocus(false, 1);
        }

        void WireHud()
        {
            hud.HintRequested += () => Runtime?.RequestHint();
            hud.ContinueRequested += () => Runtime?.Continue();
            hud.FocusRequested += () => { if (Runtime?.Current != null) FocusStep(Runtime.Current); };
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

        // ─── Loop ────────────────────────────────────────────────────────────

        void Update()
        {
            if (!running || Runtime == null) return;
            float dt = Time.deltaTime;
            if (!paused && !Runtime.IsComplete) Runtime.Tick(dt);
            foreach (var v in views.Values) v.Render(dt);
            hud.UpdateLive(World, Runtime.LiveScore);
            autosaveTimer += Time.unscaledDeltaTime;
            if (autosaveTimer >= AutosaveSeconds) { autosaveTimer = 0; Save(false); }
        }

        void Save(bool final)
        {
            if (Runtime == null) return;
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
