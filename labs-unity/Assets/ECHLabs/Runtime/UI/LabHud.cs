using System;
using System.Collections.Generic;
using System.Globalization;
using ECHLabs.Core;
using ECHLabs.Runtime.Equipment;
using UnityEngine;
using UnityEngine.UIElements;

namespace ECHLabs.Runtime.UI
{
    /// <summary>
    /// The whole lab HUD, built in code with UI Toolkit (styles in Resources/UI/LabHud.uss).
    /// Flat modes: drawn on screen, native mouse/touch input.
    /// Stereo/VR: rendered into a RenderTexture on a floating, lazily head-following panel;
    /// gaze/laser clicks are routed with Pick() to the same buttons.
    /// </summary>
    [RequireComponent(typeof(UIDocument))]
    public sealed class LabHud : MonoBehaviour
    {
        public struct ActionItem { public IntentType Intent; public string Label; public bool Suggested; }

        public event Action<EquipmentView, IntentType> ActionChosen;
        public event Action Cancelled;
        public event Action HintRequested;
        public event Action<string> ModeRequested;     // desktop | touch | cardboard | xr
        public event Action<string> QualityRequested;  // low | medium | ultra
        public event Action<bool> GuidedChanged;
        public event Action ExitRequested, RetryRequested, RecenterRequested, ContinueRequested, FocusRequested;
        public event Action<EquipmentView> InspectRequested;

        UIDocument doc;
        PanelSettings panelSettings;
        VisualElement root;
        RenderTexture surfaceTexture;
        MeshRenderer surface;
        MeshCollider surfaceCollider;
        Camera worldCamera;
        bool worldSpace;

        // Elements
        Label titleLabel, timerLabel, safetyChip, stepBadge, stepTitle, stepText, assistantText, tooltipLabel, promptLabel, hazardLabel;
        VisualElement progress, stepCard, assistant, toasts, hazard, tooltip, prompt, actions, ppeRow, valuePanel, readingPanel, quizPanel, overlay, continueBtn;
        Button hintBtn;
        readonly List<(VisualElement el, float until)> liveToasts = new List<(VisualElement, float)>();
        float hazardUntil;
        string typing; int typed; float typeTimer;

        public bool IsBlockingModal { get; private set; }

        // ─── Setup ───────────────────────────────────────────────────────────

        void Awake()
        {
            doc = GetComponent<UIDocument>();
            panelSettings = doc.panelSettings ? doc.panelSettings : CreatePanelSettings();
            doc.panelSettings = panelSettings;
            Build();
        }

        static PanelSettings CreatePanelSettings()
        {
            var ps = ScriptableObject.CreateInstance<PanelSettings>();
            ps.scaleMode = PanelScaleMode.ScaleWithScreenSize;
            ps.referenceResolution = new Vector2Int(1920, 1080);
            ps.match = 0.5f;
            ps.themeStyleSheet = Resources.Load<ThemeStyleSheet>("UI/ECHTheme");
            ps.sortingOrder = 10;
            return ps;
        }

        void Build()
        {
            root = doc.rootVisualElement;
            root.Clear();
            var uss = Resources.Load<StyleSheet>("UI/LabHud");
            if (uss) root.styleSheets.Add(uss);
            root.AddToClassList("root");
            root.pickingMode = PickingMode.Ignore;

            // Top bar
            var top = El("topbar", root);
            top.Add(new Label("ECH LABS") { name = "brand" }.With("brand"));
            titleLabel = new Label("").With("lab-title"); top.Add(titleLabel);
            progress = El("progress", top);
            timerLabel = new Label("00:00").With("chip"); top.Add(timerLabel);
            safetyChip = new Label("Safety 100").With("chip", "chip-ok"); top.Add(safetyChip);
            hintBtn = Btn("Hint", () => HintRequested?.Invoke(), top, "btn");
            Btn("☰", ShowMenu, top, "btn", "btn-icon");

            // Step card
            stepCard = El("step-card", root, "glass");
            stepBadge = new Label("STEP 1 OF 1").With("step-badge"); stepCard.Add(stepBadge);
            stepTitle = new Label("").With("step-title"); stepCard.Add(stepTitle);
            stepText = new Label("").With("step-text"); stepCard.Add(stepText);
            ppeRow = El("ppe-row", stepCard);
            var stepActions = El("row", stepCard);
            Btn("Show me", () => FocusRequested?.Invoke(), stepActions, "btn", "btn-ghost", "small");
            continueBtn = Btn("Continue", () => ContinueRequested?.Invoke(), stepActions, "btn", "btn-primary");
            continueBtn.AddToClassList("hidden");

            // Assistant
            assistant = El("assistant", root, "glass");
            assistant.Add(new Label("E").With("avatar"));
            var aCol = El("col", assistant, "grow");
            aCol.Add(new Label("DR. ECH · LAB ASSISTANT").With("assistant-name"));
            assistantText = new Label("").With("assistant-text"); aCol.Add(assistantText);

            toasts = El("toasts", root); toasts.pickingMode = PickingMode.Ignore;
            hazard = El("hazard", root, "hidden");
            hazard.Add(new Label("⚠").With("hazard-icon"));
            hazardLabel = new Label("").With("grow", "assistant-text"); hazard.Add(hazardLabel);

            tooltip = El("tooltip", root, "hidden"); tooltip.pickingMode = PickingMode.Ignore;
            tooltipLabel = new Label("").With("tooltip-label"); tooltip.Add(tooltipLabel);

            prompt = El("prompt", root, "glass", "hidden");
            promptLabel = new Label("").With("grow"); prompt.Add(promptLabel);
            Btn("Cancel", () => { HidePrompt(); Cancelled?.Invoke(); }, prompt, "btn");

            actions = El("actions", root, "glass", "hidden");
            valuePanel = El("value", root, "glass", "hidden");
            readingPanel = El("reading", root, "glass", "hidden");
            quizPanel = El("quiz", root, "glass", "glass-strong", "hidden");
            overlay = El("overlay", root, "hidden");

            foreach (var e in new[] { stepCard, assistant, prompt, actions, valuePanel, readingPanel, quizPanel, overlay, hazard }) e.pickingMode = PickingMode.Position;
        }

        // ─── World-space (stereo/VR) surface ─────────────────────────────────

        public void SetWorldSpace(bool on, Camera cam)
        {
            worldSpace = on;
            worldCamera = cam;
            if (on)
            {
                if (!surfaceTexture) surfaceTexture = new RenderTexture(1920, 1080, 0, RenderTextureFormat.ARGB32) { name = "ECH HUD", useMipMap = true, autoGenerateMips = true };
                panelSettings.targetTexture = surfaceTexture;
                if (!surface) CreateSurface();
                surface.gameObject.SetActive(true);
                PlaceSurface(true);
            }
            else
            {
                panelSettings.targetTexture = null;
                if (surface) surface.gameObject.SetActive(false);
            }
        }

        void CreateSurface()
        {
            var go = GameObject.CreatePrimitive(PrimitiveType.Quad);
            go.name = "ECH HUD Surface";
            Destroy(go.GetComponent<Collider>());
            surfaceCollider = go.AddComponent<MeshCollider>();
            surface = go.GetComponent<MeshRenderer>();
            var shader = Shader.Find("ECH/HudSurface") ?? Shader.Find("Universal Render Pipeline/Unlit");
            var mat = new Material(shader) { mainTexture = surfaceTexture };
            if (mat.HasProperty("_BaseMap")) mat.SetTexture("_BaseMap", surfaceTexture);
            mat.renderQueue = 3100;
            surface.sharedMaterial = mat;
            go.transform.localScale = new Vector3(1.6f, 0.9f, 1);
        }

        /// <summary>Lazy follow: the panel only re-centres when the student looks well away from it.</summary>
        void PlaceSurface(bool snap)
        {
            if (!surface || !worldCamera) return;
            var head = worldCamera.transform;
            Vector3 fwd = Vector3.ProjectOnPlane(head.forward, Vector3.up).normalized;
            if (fwd.sqrMagnitude < 0.01f) fwd = Vector3.forward;
            Vector3 target = head.position + fwd * 1.4f + Vector3.down * 0.15f;
            Vector3 toPanel = (surface.transform.position - head.position).normalized;
            bool farOff = Vector3.Angle(Vector3.ProjectOnPlane(toPanel, Vector3.up), fwd) > 40f;
            if (snap || farOff)
            {
                float k = snap ? 1f : Time.deltaTime * 3f;
                surface.transform.position = Vector3.Lerp(surface.transform.position, target, k);
            }
            surface.transform.rotation = Quaternion.LookRotation(surface.transform.position - head.position, Vector3.up);
        }

        public bool RaycastSurface(Ray ray, out Vector2 panelPos)
        {
            panelPos = default;
            if (!worldSpace || !surfaceCollider || !surface.gameObject.activeSelf) return false;
            if (!surfaceCollider.Raycast(ray, out var hit, 10f)) return false;
            var uv = hit.textureCoord;
            panelPos = RuntimePanelUtils.ScreenToPanel(root.panel, new Vector2(uv.x * surfaceTexture.width, (1 - uv.y) * surfaceTexture.height));
            var picked = root.panel.Pick(panelPos);
            return picked != null && picked != root;
        }

        public void ClickSurface(Ray ray)
        {
            if (!RaycastSurface(ray, out var pos)) return;
            for (var e = root.panel.Pick(pos); e != null && e != root; e = e.parent)
                if (e.userData is Action a) { a(); return; }
        }

        public bool IsOverUi(Vector2 screenPosYUp)
        {
            if (worldSpace || root?.panel == null) return false;
            var p = RuntimePanelUtils.ScreenToPanel(root.panel, new Vector2(screenPosYUp.x, Screen.height - screenPosYUp.y));
            var picked = root.panel.Pick(p);
            return picked != null && picked != root && picked.pickingMode == PickingMode.Position;
        }

        // ─── Frame update ────────────────────────────────────────────────────

        void Update()
        {
            if (worldSpace) PlaceSurface(false);
            float now = Time.unscaledTime;
            for (int i = liveToasts.Count - 1; i >= 0; i--)
                if (now > liveToasts[i].until) { liveToasts[i].el.RemoveFromHierarchy(); liveToasts.RemoveAt(i); }
            if (hazardUntil > 0 && now > hazardUntil) { hazard.AddToClassList("hidden"); hazardUntil = 0; }
            if (typing != null)
            {
                typeTimer += Time.unscaledDeltaTime;
                int n = Mathf.Min(typing.Length, (int)(typeTimer * 55f));
                if (n != typed) { typed = n; assistantText.text = typing.Substring(0, n); }
                if (n >= typing.Length) typing = null;
            }
        }

        // ─── Lab / step state ────────────────────────────────────────────────

        public void SetLab(ScenarioDefinition def)
        {
            titleLabel.text = def.Title;
            progress.Clear();
            for (int i = 0; i < def.Steps.Count; i++) progress.Add(El("dot", null));
            ppeRow.Clear();
            foreach (var e in def.Equipment)
                if (e.Type == "goggles" || e.Type == "labcoat" || e.Type == "gloves")
                {
                    var l = new Label(Catalog.Title(e.Type)).With("ppe");
                    l.name = "ppe-" + e.Id;
                    ppeRow.Add(l);
                }
        }

        public void ShowStep(StepSpec step, int index, int total)
        {
            stepBadge.text = $"STEP {index + 1} OF {total}" + (string.IsNullOrEmpty(step.Title) ? "" : " · " + step.Title.ToUpperInvariant());
            stepTitle.text = step.Title ?? "";
            stepTitle.EnableInClassList("hidden", string.IsNullOrEmpty(step.Title));
            stepText.text = step.Instruction;
            continueBtn.EnableInClassList("hidden", step.Kind != StepKind.Info);
            hintBtn.SetEnabled(true);
            int i = 0;
            foreach (var dot in progress.Children())
            {
                dot.EnableInClassList("dot-done", i < index);
                dot.EnableInClassList("dot-current", i == index);
                i++;
            }
        }

        public void UpdateLive(LabWorld world, ScoreBreakdown score)
        {
            var t = TimeSpan.FromSeconds(world.Time);
            timerLabel.text = $"{(int)t.TotalMinutes:00}:{t.Seconds:00}";
            safetyChip.text = "Safety " + score.Safety;
            safetyChip.EnableInClassList("chip-ok", score.Safety >= 90);
            safetyChip.EnableInClassList("chip-warn", score.Safety < 90 && score.Safety >= 70);
            safetyChip.EnableInClassList("chip-bad", score.Safety < 70);
            foreach (var l in ppeRow.Children())
                l.EnableInClassList("ppe-on", world.Bool(l.name.Substring(4), "worn"));
        }

        public void Say(string text)
        {
            if (string.IsNullOrEmpty(text)) return;
            typing = text; typed = 0; typeTimer = 0;
            assistantText.text = "";
        }

        public void Toast(string text, bool good)
        {
            if (string.IsNullOrEmpty(text)) return;
            var t = new Label(text).With("toast", good ? "toast-good" : "toast-bad");
            toasts.Add(t);
            liveToasts.Add((t, Time.unscaledTime + 3.2f));
            while (liveToasts.Count > 3) { liveToasts[0].el.RemoveFromHierarchy(); liveToasts.RemoveAt(0); }
        }

        public void ShowHazard(string message)
        {
            hazardLabel.text = message;
            hazard.RemoveFromClassList("hidden");
            hazardUntil = Time.unscaledTime + 6f;
        }

        public void SetTooltip(string text)
        {
            tooltip.EnableInClassList("hidden", string.IsNullOrEmpty(text) || !actions.ClassListContains("hidden"));
            tooltipLabel.text = text ?? "";
        }

        // ─── Action menu / prompt / value ────────────────────────────────────

        public void ShowActions(EquipmentView view, List<ActionItem> items, Vector2? screenPos)
        {
            actions.Clear();
            actions.Add(new Label(view.Label).With("actions-title"));
            foreach (var it in items)
            {
                var item = it;
                var b = Btn(item.Label, () => { HideActions(); ActionChosen?.Invoke(view, item.Intent); }, actions, "btn");
                if (item.Suggested) b.AddToClassList("btn-suggested");
            }
            Btn("Close", HideActions, actions, "btn", "btn-ghost", "small");
            if (screenPos.HasValue && !worldSpace && root.panel != null)
            {
                var p = RuntimePanelUtils.ScreenToPanel(root.panel, new Vector2(screenPos.Value.x, Screen.height - screenPos.Value.y));
                var size = root.layout.size;
                actions.style.left = Mathf.Clamp(p.x + 24, 12, Mathf.Max(12, size.x - 320));
                actions.style.top = Mathf.Clamp(p.y - 60, 80, Mathf.Max(80, size.y - 420));
            }
            else { actions.style.left = new Length(41, LengthUnit.Percent); actions.style.top = new Length(30, LengthUnit.Percent); }
            actions.RemoveFromClassList("hidden");
            tooltip.AddToClassList("hidden");
        }

        public void HideActions() => actions.AddToClassList("hidden");

        public void ShowPrompt(string text, string suggestion)
        {
            promptLabel.text = suggestion != null ? $"{text}  (tip: the {suggestion})" : text + "  — select the receiver";
            prompt.RemoveFromClassList("hidden");
        }

        public void HidePrompt() => prompt?.AddToClassList("hidden");

        public void ShowValue(string title, ValueRange range, Action<double> onChange, Action<double> onConfirm)
        {
            valuePanel.Clear();
            valuePanel.Add(new Label(range.Label ?? title).With("muted", "small"));
            float value = range.Default;
            var number = new Label().With("value-number");
            valuePanel.Add(number);
            var row = El("row", valuePanel);
            var track = new VisualElement().With("track");
            var fill = new VisualElement().With("track-fill");
            var handle = new VisualElement().With("track-handle");
            track.Add(fill); track.Add(handle);

            void Refresh(bool notify)
            {
                value = Mathf.Clamp(Mathf.Round(value / Mathf.Max(range.Step, 1e-4f)) * range.Step, range.Min, range.Max);
                float t = Mathf.InverseLerp(range.Min, range.Max, value);
                fill.style.width = new Length(t * 100, LengthUnit.Percent);
                handle.style.left = new Length(t * 100, LengthUnit.Percent);
                number.text = range.Max <= 1 && string.IsNullOrEmpty(range.Unit) ? Mathf.RoundToInt(t * 100) + " %" : value.ToString(range.Step < 1 ? "0.0" : "0", CultureInfo.InvariantCulture) + " " + range.Unit;
                if (notify) onChange?.Invoke(value);
            }

            float bigStep = (range.Max - range.Min) / 10f;
            Btn("−−", () => { value -= bigStep; Refresh(true); }, row, "btn", "btn-icon");
            Btn("−", () => { value -= range.Step * (range.Max <= 1 ? 2 : 1); Refresh(true); }, row, "btn", "btn-icon");
            row.Add(track);
            Btn("+", () => { value += range.Step * (range.Max <= 1 ? 2 : 1); Refresh(true); }, row, "btn", "btn-icon");
            Btn("++", () => { value += bigStep; Refresh(true); }, row, "btn", "btn-icon");

            // Drag on the track (mouse / touch).
            track.RegisterCallback<PointerDownEvent>(e => { track.CapturePointer(e.pointerId); SetFromPointer(e.localPosition.x); });
            track.RegisterCallback<PointerMoveEvent>(e => { if (track.HasPointerCapture(e.pointerId)) SetFromPointer(e.localPosition.x); });
            track.RegisterCallback<PointerUpEvent>(e => track.ReleasePointer(e.pointerId));
            void SetFromPointer(float x) { value = Mathf.Lerp(range.Min, range.Max, Mathf.Clamp01(x / Mathf.Max(track.layout.width, 1))); Refresh(true); }

            var done = El("row", valuePanel);
            done.style.justifyContent = Justify.FlexEnd;
            Btn("Cancel", () => { valuePanel.AddToClassList("hidden"); if (range.Live) onConfirm?.Invoke(value); Cancelled?.Invoke(); }, done, "btn", "btn-ghost");
            Btn(range.Live ? "Done" : "Release", () => { valuePanel.AddToClassList("hidden"); onConfirm?.Invoke(value); }, done, "btn", "btn-primary");
            Refresh(false);
            valuePanel.RemoveFromClassList("hidden");
        }

        public void ShowCommands(string title, IReadOnlyList<string> commands, Action<string> run)
        {
            valuePanel.Clear();
            valuePanel.Add(new Label("TERMINAL · " + title.ToUpperInvariant()).With("tiny", "emerald", "bold"));
            var grid = El("keypad", valuePanel);
            if (commands.Count == 0) valuePanel.Add(new Label("No commands available.").With("muted"));
            foreach (var c in commands)
            {
                string cmd = c;
                var b = Btn("> " + cmd, () => { run(cmd); Toast("$ " + cmd, true); }, grid, "btn");
                b.style.width = new Length(48, LengthUnit.Percent);
                b.style.unityTextAlign = TextAnchor.MiddleLeft;
            }
            var end = El("row", valuePanel);
            end.style.justifyContent = Justify.FlexEnd;
            Btn("Close terminal", () => valuePanel.AddToClassList("hidden"), end, "btn", "btn-primary");
            valuePanel.RemoveFromClassList("hidden");
        }

        // ─── Measure / checkpoint / info ─────────────────────────────────────

        public void ShowReading(RecordSpec record, Func<double, Feedback> submit)
        {
            readingPanel.Clear();
            readingPanel.Add(new Label("RECORD A MEASUREMENT").With("tiny", "emerald", "bold"));
            readingPanel.Add(new Label(record.Label).With("step-title"));
            string entry = "";
            var display = new Label("—").With("reading-display");
            readingPanel.Add(display);
            var unit = new Label(record.Unit ?? "").With("muted", "small");
            unit.style.unityTextAlign = TextAnchor.MiddleRight;
            readingPanel.Add(unit);
            var feedback = new Label("").With("small");
            void Show() => display.text = entry.Length == 0 ? "—" : entry;
            var pad = El("keypad", readingPanel);
            foreach (var k in new[] { "7", "8", "9", "4", "5", "6", "1", "2", "3", "−", "0", "." })
            {
                string key = k;
                Btn(key, () =>
                {
                    if (key == "−") entry = entry.StartsWith("-") ? entry.Substring(1) : "-" + entry;
                    else if (key == "." && entry.Contains(".")) return;
                    else if (entry.Length < 10) entry += key;
                    Show();
                }, pad, "btn", "key");
            }
            readingPanel.Add(feedback);
            var row = El("row", readingPanel);
            Btn("Delete", () => { if (entry.Length > 0) entry = entry.Substring(0, entry.Length - 1); Show(); }, row, "btn", "grow");
            Btn("Submit", () =>
            {
                if (!double.TryParse(entry, NumberStyles.Float, CultureInfo.InvariantCulture, out var v)) { feedback.text = "Enter a number first."; return; }
                var fb = submit(v);
                if (fb.Kind == FeedbackKind.ReadingWrong) { feedback.text = fb.Message; feedback.EnableInClassList("danger", true); entry = ""; Show(); }
                else readingPanel.AddToClassList("hidden");
            }, row, "btn", "btn-primary", "grow");
            readingPanel.RemoveFromClassList("hidden");
        }

        public void ShowQuestion(QuestionSpec q, Func<int, Feedback> answer)
        {
            IsBlockingModal = true;
            quizPanel.Clear();
            quizPanel.Add(new Label("CHECK YOUR UNDERSTANDING").With("tiny", "emerald", "bold"));
            quizPanel.Add(new Label(q.Prompt).With("quiz-prompt"));
            var buttons = new List<Button>();
            var explain = new Label("").With("step-text");
            for (int i = 0; i < q.Choices.Count; i++)
            {
                int idx = i;
                buttons.Add(Btn($"{(char)('A' + i)}.  {q.Choices[i]}", () =>
                {
                    if (buttons[0].userData == null) return; // already answered
                    foreach (var b in buttons) b.userData = null;
                    var fb = answer(idx);
                    buttons[q.AnswerIndex].AddToClassList("choice-right");
                    if (idx != q.AnswerIndex) buttons[idx].AddToClassList("choice-wrong");
                    explain.text = fb.Message;
                    var next = Btn("Continue", () => { quizPanel.AddToClassList("hidden"); IsBlockingModal = false; }, quizPanel, "btn", "btn-primary");
                    next.style.alignSelf = Align.FlexEnd;
                }, quizPanel, "btn", "choice"));
            }
            quizPanel.Add(explain);
            quizPanel.RemoveFromClassList("hidden");
        }

        public void CloseQuestion() { quizPanel.AddToClassList("hidden"); IsBlockingModal = false; }

        public void HideTaskPanels()
        {
            readingPanel.AddToClassList("hidden");
            valuePanel.AddToClassList("hidden");
            HideActions();
            HidePrompt();
        }

        public void RequestInspect(EquipmentView v) => InspectRequested?.Invoke(v);

        // ─── Overlays ────────────────────────────────────────────────────────

        public void ShowLoading(string title, string detail, float progress01)
        {
            overlay.Clear();
            var p = El("panel", overlay, "glass", "glass-strong");
            p.Add(new Label("ECH LABS").With("brand"));
            p.Add(new Label(title).With("big-title"));
            p.Add(new Label(detail).With("muted"));
            var bar = El("bar", p);
            var fill = El("bar-fill", bar);
            fill.style.width = new Length(Mathf.Clamp01(progress01) * 100, LengthUnit.Percent);
            overlay.RemoveFromClassList("hidden");
        }

        public void HideOverlay() { overlay.AddToClassList("hidden"); overlay.Clear(); }

        public void ShowError(string title, string detail, Action retry)
        {
            overlay.Clear();
            var p = El("panel", overlay, "glass", "glass-strong");
            p.Add(new Label(title).With("big-title", "danger"));
            p.Add(new Label(detail).With("step-text"));
            var row = El("row", p);
            if (retry != null) Btn("Try again", retry, row, "btn", "btn-primary");
            Btn("Exit", () => ExitRequested?.Invoke(), row, "btn");
            overlay.RemoveFromClassList("hidden");
        }

        public void ShowPairing(string code, string help)
        {
            overlay.Clear();
            var p = El("panel", overlay, "glass", "glass-strong");
            p.Add(new Label("CONNECT THIS HEADSET").With("tiny", "emerald", "bold"));
            p.Add(new Label("Open the ECH app → Virtual Labs → Connect headset, and enter:").With("step-text"));
            p.Add(new Label(code).With("pair-code"));
            p.Add(new Label(help).With("muted", "small"));
            overlay.RemoveFromClassList("hidden");
        }

        public void ShowResults(ScenarioDefinition def, ScoreBreakdown s, int? xp, IEnumerable<string> badges, bool practice)
        {
            quizPanel.AddToClassList("hidden");
            IsBlockingModal = false;
            HideTaskPanels();
            overlay.Clear();
            var p = El("panel", overlay, "glass", "glass-strong");
            p.Add(new Label(s.Passed ? "EXPERIMENT COMPLETE" : "EXPERIMENT FINISHED").With("tiny", s.Passed ? "emerald" : "danger", "bold"));
            p.Add(new Label(def.Title).With("big-title"));
            var row = El("row", p);
            var ring = El("score-ring", row);
            ring.style.borderTopColor = ring.style.borderRightColor = ring.style.borderBottomColor = ring.style.borderLeftColor = s.Passed ? new Color(0.06f, 0.72f, 0.5f) : new Color(0.97f, 0.44f, 0.44f);
            ring.Add(new Label(s.Total.ToString()).With("score-number"));
            ring.Add(new Label("/ 100").With("muted", "small"));
            var bars = El("col", row, "grow");
            Bar(bars, "Accuracy", s.Accuracy);
            Bar(bars, "Procedure", s.Procedure);
            Bar(bars, "Safety", s.Safety);

            foreach (var r in s.Results)
            {
                var rr = El("result-row", p);
                rr.Add(new Label(r.Label).With("grow"));
                rr.Add(new Label((r.Actual.HasValue ? r.Actual.Value.ToString("0.###", CultureInfo.InvariantCulture) : "—") + " " + r.Unit).With("bold"));
                rr.Add(new Label($"   expected {r.Expected.ToString("0.###", CultureInfo.InvariantCulture)} {r.Unit}").With("muted", "small"));
            }

            var info = El("row", p);
            info.style.flexWrap = Wrap.Wrap;
            info.style.marginTop = 12;
            if (practice) info.Add(new Label("Practice mode — open this lab from your ECH course to save your result.").With("muted", "small"));
            else
            {
                if (xp.HasValue && xp.Value > 0) info.Add(new Label($"+{xp} XP").With("badge"));
                if (badges != null) foreach (var b in badges) info.Add(new Label("🏅 " + BadgeTitle(b)).With("badge"));
            }
            var buttons = El("row", p);
            buttons.style.justifyContent = Justify.FlexEnd;
            buttons.style.marginTop = 16;
            Btn("Try again", () => RetryRequested?.Invoke(), buttons, "btn");
            Btn("Back to course", () => ExitRequested?.Invoke(), buttons, "btn", "btn-primary");
            overlay.RemoveFromClassList("hidden");
        }

        static void Bar(VisualElement parent, string label, int value)
        {
            var r = El("row", parent);
            r.Add(new Label(label).With("grow", "small"));
            r.Add(new Label(value.ToString()).With("bold", "small"));
            var bar = El("bar", parent);
            var fill = El("bar-fill", bar);
            fill.style.width = new Length(value, LengthUnit.Percent);
        }

        static string BadgeTitle(string key)
        {
            switch (key)
            {
                case "first-experiment": return "First Experiment";
                case "safety-champion": return "Safety Champion";
                case "precision-scientist": return "Precision Scientist";
                case "flawless-lab": return "Flawless Lab";
                default: return CultureInfo.InvariantCulture.TextInfo.ToTitleCase(key.Replace('-', ' '));
            }
        }

        void ShowMenu()
        {
            overlay.Clear();
            var p = El("panel", overlay, "glass", "glass-strong");
            p.Add(new Label("Lab settings").With("big-title"));
            p.Add(new Label("VIEW MODE").With("tiny", "muted", "bold"));
            var modes = El("row", p);
            modes.style.flexWrap = Wrap.Wrap;
            foreach (var (key, label) in new[] { ("desktop", "Screen"), ("touch", "Touch"), ("cardboard", "Phone VR viewer"), ("xr", "VR headset") })
                Btn(label, () => { HideOverlay(); ModeRequested?.Invoke(key); }, modes, "btn");
            p.Add(new Label("GRAPHICS").With("tiny", "muted", "bold"));
            var q = El("row", p);
            foreach (var (key, label) in new[] { ("low", "Battery saver"), ("medium", "Balanced"), ("ultra", "Ultra") })
                Btn(label, () => { HideOverlay(); QualityRequested?.Invoke(key); }, q, "btn");
            p.Add(new Label("HELP").With("tiny", "muted", "bold"));
            var h = El("row", p);
            Btn("Guided mode on", () => { HideOverlay(); GuidedChanged?.Invoke(true); }, h, "btn");
            Btn("Exam mode (no tips)", () => { HideOverlay(); GuidedChanged?.Invoke(false); }, h, "btn");
            Btn("Re-centre view", () => { HideOverlay(); RecenterRequested?.Invoke(); }, h, "btn");
            var end = El("row", p);
            end.style.justifyContent = Justify.FlexEnd;
            Btn("Exit lab", () => ExitRequested?.Invoke(), end, "btn");
            Btn("Resume", HideOverlay, end, "btn", "btn-primary");
            overlay.RemoveFromClassList("hidden");
        }

        // ─── Helpers ─────────────────────────────────────────────────────────

        static VisualElement El(string cls, VisualElement parent, params string[] more)
        {
            var e = new VisualElement();
            e.AddToClassList(cls);
            foreach (var m in more) e.AddToClassList(m);
            e.pickingMode = PickingMode.Ignore;
            parent?.Add(e);
            return e;
        }

        static Button Btn(string text, Action onClick, VisualElement parent, params string[] classes)
        {
            var b = new Button(onClick) { text = text, userData = onClick };
            foreach (var c in classes) b.AddToClassList(c);
            parent?.Add(b);
            return b;
        }
    }

    static class UiExt
    {
        public static T With<T>(this T e, params string[] classes) where T : VisualElement
        {
            foreach (var c in classes) e.AddToClassList(c);
            return e;
        }
    }
}
