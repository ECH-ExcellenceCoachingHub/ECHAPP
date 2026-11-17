using System;
using System.Collections.Generic;
using ECHLabs.Core;
using ECHLabs.Runtime.Equipment;
using ECHLabs.Runtime.UI;
using UnityEngine;

namespace ECHLabs.Runtime.Interaction
{
    /// <summary>
    /// Turns "point + select" from the active rig into Intents:
    ///   select equipment → contextual action menu → (value slider | choose receiver | immediate) → Intent.
    /// Guided mode highlights the action and receiver the current step expects.
    /// </summary>
    public sealed class InteractionController : MonoBehaviour
    {
        public LayerMask equipmentMask = ~0;
        public float maxDistance = 12f;
        public bool guided = true;

        public IPointerSource Rig { get; private set; }
        public EquipmentView Hovered { get; private set; }

        Func<Intent, Feedback> send;
        Func<StepSpec> currentStep;
        LabHud hud;
        Dictionary<string, EquipmentView> views;

        EquipmentView pendingSource;
        IntentType pendingIntent;
        float lastLiveSend;
        double? pendingLiveValue;

        public event Action<EquipmentView, IntentType> ActionPerformed;
        /// <summary>Every successful action with its receiver and feedback (hands, sound, haptics, graphs).</summary>
        public event Action<Intent, EquipmentView, EquipmentView, Feedback> Performed;
        /// <summary>First-person hands (null in headset mode, where the student's real hands are tracked).</summary>
        public HandsRig hands;
        /// <summary>Equipment picked up and waiting for a receiver ("Pour the NaOH into…").</summary>
        public EquipmentView PendingSource => pendingSource;

        float lastSelectTime = -1;
        EquipmentView lastSelected;
        const float DoubleTapSeconds = 0.38f;

        public void Init(Func<Intent, Feedback> sendIntent, Func<StepSpec> step, LabHud labHud, Dictionary<string, EquipmentView> equipmentViews)
        {
            send = sendIntent;
            currentStep = step;
            hud = labHud;
            views = equipmentViews;
            hud.ActionChosen += OnActionChosen;
            hud.Cancelled += CancelPending;
        }

        public void SetRig(IPointerSource rig)
        {
            Rig?.Activate(false);
            Rig = rig;
            Rig.Activate(true);
            hud.SetWorldSpace(rig.WorldSpaceUI, rig.Camera);
            CancelPending();
        }

        void Update()
        {
            if (Rig == null || send == null) return;

            // Throttled live updates from sliders (tap opening, voltage knob).
            if (pendingLiveValue.HasValue && Time.unscaledTime - lastLiveSend > 0.08f && pendingSource)
            {
                send(Intent.Of(pendingIntent, pendingSource.EquipmentId, null, pendingLiveValue));
                pendingLiveValue = null;
                lastLiveSend = Time.unscaledTime;
            }

            EquipmentView hit = null;
            bool overUi = false;
            if (Rig.TryGetRay(out var ray))
            {
                if (Rig.WorldSpaceUI) overUi = hud.RaycastSurface(ray, out _);
                else if (Rig.ScreenPosition.HasValue) overUi = hud.IsOverUi(Rig.ScreenPosition.Value);
                if (!overUi && Physics.Raycast(ray, out var info, maxDistance, equipmentMask, QueryTriggerInteraction.Collide))
                    hit = info.collider.GetComponentInParent<EquipmentView>();
            }

            if (hit != Hovered)
            {
                if (Hovered && Hovered != pendingSource) Hovered.SetHighlight(false);
                Hovered = hit;
                if (Hovered) Hovered.SetHighlight(true);
                hud.SetTooltip(Hovered ? Hovered.Label : null);
            }
            Rig.SetHoverTarget(overUi ? (object)hud : Hovered);

            if (!Rig.SelectPressed) return;
            if (overUi)
            {
                if (Rig.WorldSpaceUI && Rig.TryGetRay(out var r2)) hud.ClickSurface(r2);
                return; // flat-screen UI handles its own clicks
            }
            if (pendingSource)
            {
                CompleteWithReceiver(Hovered);
                return;
            }
            // Double-tap / double-click an object: zoom straight in for a close look.
            if (Hovered && Hovered == lastSelected && Time.unscaledTime - lastSelectTime < DoubleTapSeconds)
            {
                lastSelected = null;
                hud.HideActions();
                hud.RequestInspect(Hovered);
                return;
            }
            lastSelected = Hovered;
            lastSelectTime = Time.unscaledTime;
            if (Hovered) OpenMenu(Hovered);
            else hud.HideActions();
        }

        void OpenMenu(EquipmentView view)
        {
            var step = currentStep();
            IntentType? suggested = null;
            if (guided && step?.Expect != null && step.Expect.Target == view.EquipmentId && Enum.TryParse<IntentType>(step.Expect.Intent, out var s)) suggested = s;
            var items = new List<LabHud.ActionItem>();
            foreach (var t in view.Intents) items.Add(new LabHud.ActionItem { Intent = t, Label = view.ActionLabel(t), Suggested = suggested == t });
            hud.ShowActions(view, items, Rig.ScreenPosition);
        }

        void OnActionChosen(EquipmentView view, IntentType intent)
        {
            if (intent == IntentType.Type)
            {
                // Terminals: commands as large buttons (works with gaze and VR, no keyboard needed).
                hud.ShowCommands(view.Label, view.Commands, cmd => Perform(new Intent { Type = IntentType.Type, Target = view.EquipmentId, Text = cmd }, view, null));
                return;
            }
            if (view.TryGetValueRange(intent, out var range))
            {
                pendingSource = view;
                pendingIntent = intent;
                if (range.Live) hands?.BeginAdjust(view, intent);
                hands?.AdjustValue(Mathf.InverseLerp(range.Min, range.Max, range.Default));
                hud.ShowValue(view.Label, range, v =>
                {
                    if (range.Live) pendingLiveValue = v;
                    hands?.AdjustValue(Mathf.InverseLerp(range.Min, range.Max, (float)v));
                }, v =>
                {
                    hands?.EndAdjust();
                    Perform(Intent.Of(intent, view.EquipmentId, null, v), view, null, animate: !range.Live);
                    pendingSource = null;
                    pendingLiveValue = null;
                });
                return;
            }
            bool needsReceiver = view.NeedsReceiver(intent) || intent == IntentType.Grab && view.GrabPlacesSomewhere;
            if (needsReceiver)
            {
                pendingSource = view;
                pendingIntent = intent;
                view.SetHighlight(true);
                var step = currentStep();
                string suggestion = guided && step?.Expect != null && step.Expect.Target == view.EquipmentId && step.Expect.Into != null && views.TryGetValue(step.Expect.Into, out var into) ? into.Label : null;
                hud.ShowPrompt(intent == IntentType.Pour ? $"Pour the {view.Label} into…" : intent == IntentType.Connect ? $"Connect the {view.Label} to…" : $"Place the {view.Label} on…", suggestion);
                if (suggestion != null) views[step.Expect.Into].SetHighlight(true);
                return;
            }
            Perform(Intent.Of(intent, view.EquipmentId), view, null);
        }

        void CompleteWithReceiver(EquipmentView receiver)
        {
            var src = pendingSource;
            var intent = pendingIntent;
            CancelPending();
            if (!src) return;
            if (receiver == src) receiver = null;
            Perform(Intent.Of(intent, src.EquipmentId, receiver ? receiver.EquipmentId : null), src, receiver);
        }

        /// <summary>
        /// The demonstrator (and tests) act through exactly the same path as the student, so the demo
        /// shows the real hands, pours and animations. <paramref name="sendTo"/> is the demo's runtime.
        /// </summary>
        public Feedback PerformScripted(Intent intent, Func<Intent, Feedback> sendTo, bool animate = true)
        {
            if (views == null || !views.TryGetValue(intent.Target, out var src)) return sendTo(intent);
            EquipmentView receiver = intent.Into != null && views.TryGetValue(intent.Into, out var r) ? r : null;
            return Perform(intent, src, receiver, animate, sendTo);
        }

        Feedback Perform(Intent intent, EquipmentView src, EquipmentView receiver, bool animate = true, Func<Intent, Feedback> sendTo = null)
        {
            var fb = (sendTo ?? send)(intent);
            if (fb.Kind != FeedbackKind.Impossible)
            {
                // Visual follow-through (the science already happened in LabWorld).
                if (animate) hands?.Play(intent, src, receiver);
                if (intent.Type == IntentType.Pour && src is ContainerView c) c.PlayPour(receiver);
                if (intent.Type == IntentType.Grab && src is FlaskView f && receiver) f.PlaceAt(receiver.Attach);
                if (intent.Type == IntentType.Connect && src is GenericView g && receiver) g.ConnectTo(receiver.Attach);
                if (intent.Type == IntentType.Grab && src is GenericView g2 && receiver) g2.ConnectTo(receiver.Attach);
                if (intent.Type == IntentType.Grab && src.Type == "funnel" && receiver == null && views != null)
                    foreach (var v in views.Values) if (v is BuretteView bv && src is GenericView gf) gf.ConnectTo(bv.topPoint ? bv.topPoint : bv.transform);
                if (intent.Type == IntentType.Connect && receiver && src.TryGetComponent<CableRenderer>(out var cable)) cable.ConnectTo(receiver.Attach);
                if (intent.Type == IntentType.Release && src.TryGetComponent<CableRenderer>(out var cable2)) cable2.ConnectTo(null);
                if (intent.Type == IntentType.Inspect) hud.RequestInspect(src);
                ActionPerformed?.Invoke(src, intent.Type);
                Performed?.Invoke(intent, src, receiver, fb);
            }
            hud.HideActions();
            return fb;
        }

        public void CancelPending()
        {
            if (pendingSource) hands?.EndAdjust();
            if (pendingSource) pendingSource.SetHighlight(false);
            if (views != null) foreach (var v in views.Values) if (v != Hovered) v.SetHighlight(false);
            pendingSource = null;
            pendingLiveValue = null;
            hud?.HidePrompt();
        }
    }
}
