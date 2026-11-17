using System.Collections.Generic;
using System.Globalization;
using ECHLabs.Core;
using UnityEngine;
using UnityEngine.UIElements;

namespace ECHLabs.Runtime.UI
{
    /// <summary>What a live graph plots and how it looks.</summary>
    public sealed class GraphSpec
    {
        public string Title, XLabel, YLabel, XUnit, YUnit;
        public float XMin, XMax, YMin, YMax;
        public bool Scatter;          // points (I–V) instead of a line (titration curve)
        public bool BestFitThroughOrigin;
        public bool RollingX;         // time traces keep the last XMax − XMin seconds
        public float? RefY;           // e.g. pH 8.2 end point
        public string RefLabel;
        public string FitLabel;       // "gradient = 1/R" style caption
    }

    /// <summary>
    /// A small, crisp chart drawn with UI Toolkit's vector painter (works on every platform and in
    /// the VR HUD). Axes auto-extend when data runs past them; the newest point pulses.
    /// </summary>
    public sealed class LiveGraph : VisualElement
    {
        static readonly Color Grid = new Color(1, 1, 1, 0.07f), Axis = new Color(1, 1, 1, 0.35f);
        static readonly Color Line = new Color(0.2f, 0.85f, 0.6f), Fit = new Color(0.4f, 0.65f, 1f, 0.9f), Ref = new Color(0.98f, 0.55f, 0.8f, 0.85f);
        const float PadL = 58, PadB = 40, PadT = 10, PadR = 14;

        GraphSpec spec;
        readonly List<Vector2> pts = new List<Vector2>();
        readonly Label xLabel, yLabel, refLabel, fitLabel, emptyLabel;
        readonly List<Label> ticks = new List<Label>();
        float xMin, xMax, yMin, yMax;

        public int Count => pts.Count;
        public GraphSpec Spec => spec;

        public LiveGraph()
        {
            AddToClassList("graph-canvas");
            pickingMode = PickingMode.Ignore;
            generateVisualContent += Draw;
            xLabel = Text("graph-axis"); yLabel = Text("graph-axis"); refLabel = Text("graph-ref"); fitLabel = Text("graph-fit");
            emptyLabel = Text("graph-empty");
            // Axis tick labels are created once and only re-positioned / re-labelled when the axes change.
            for (int i = 0; i < 10; i++) { var t = Text("graph-tick"); t.SendToBack(); ticks.Add(t); }
            RegisterCallback<GeometryChangedEvent>(_ => Layout());
        }

        Label Text(string cls)
        {
            var l = new Label();
            l.AddToClassList(cls);
            l.pickingMode = PickingMode.Ignore;
            l.style.position = Position.Absolute;
            Add(l);
            return l;
        }

        public void Configure(GraphSpec s)
        {
            spec = s;
            pts.Clear();
            xMin = s.XMin; xMax = s.XMax; yMin = s.YMin; yMax = s.YMax;
            xLabel.text = s.XLabel + (string.IsNullOrEmpty(s.XUnit) ? "" : $" ({s.XUnit})");
            yLabel.text = s.YLabel + (string.IsNullOrEmpty(s.YUnit) ? "" : $" ({s.YUnit})");
            refLabel.text = s.RefLabel ?? "";
            fitLabel.text = "";
            emptyLabel.text = "Waiting for data…";
            Layout();
            MarkDirtyRepaint();
        }

        public void ResetData()
        {
            pts.Clear();
            if (spec != null) { xMin = spec.XMin; xMax = spec.XMax; yMin = spec.YMin; yMax = spec.YMax; }
            fitLabel.text = "";
            Layout();
            MarkDirtyRepaint();
        }

        public void AddPoint(float x, float y)
        {
            if (spec == null || float.IsNaN(x) || float.IsNaN(y) || float.IsInfinity(x) || float.IsInfinity(y)) return;
            pts.Add(new Vector2(x, y));
            if (spec.RollingX)
            {
                float window = spec.XMax - spec.XMin;
                xMax = Mathf.Max(spec.XMax, x);
                xMin = xMax - window;
                while (pts.Count > 2 && pts[0].x < xMin) pts.RemoveAt(0);
            }
            else
            {
                if (x > xMax) xMax = Nice(x * 1.15f);
                if (y > yMax) yMax = Nice(y * 1.15f);
                if (y < yMin) yMin = -Nice(-y * 1.15f);
            }
            if (spec.BestFitThroughOrigin && pts.Count >= 2)
            {
                float k = Slope();
                fitLabel.text = string.Format(CultureInfo.InvariantCulture, spec.FitLabel ?? "gradient = {0:0.###}", k);
            }
            // Re-layout only when the axes moved (cheap on phones); otherwise just redraw the line.
            if (xMin != laidX0 || xMax != laidX1 || yMin != laidY0 || yMax != laidY1 || pts.Count == 1) Layout();
            MarkDirtyRepaint();
        }

        /// <summary>Least-squares slope of y = kx (Ohm's law: k = 1/R).</summary>
        public float Slope()
        {
            double sxy = 0, sxx = 0;
            foreach (var p in pts) { sxy += p.x * p.y; sxx += p.x * p.x; }
            return sxx > 1e-9 ? (float)(sxy / sxx) : 0;
        }

        static float Nice(float v)
        {
            if (v <= 0) return 1;
            float mag = Mathf.Pow(10, Mathf.Floor(Mathf.Log10(v)));
            foreach (var m in new[] { 1f, 2f, 2.5f, 5f, 10f }) if (m * mag >= v) return m * mag;
            return 10 * mag;
        }

        Rect Plot => new Rect(PadL, PadT, Mathf.Max(10, layout.width - PadL - PadR), Mathf.Max(10, layout.height - PadT - PadB));

        Vector2 ToPx(Vector2 p)
        {
            var r = Plot;
            float x = r.x + (p.x - xMin) / Mathf.Max(xMax - xMin, 1e-6f) * r.width;
            float y = r.yMax - (p.y - yMin) / Mathf.Max(yMax - yMin, 1e-6f) * r.height;
            return new Vector2(Mathf.Clamp(x, r.x, r.xMax), Mathf.Clamp(y, r.y, r.yMax));
        }

        float laidX0 = float.NaN, laidX1, laidY0, laidY1;

        void Layout()
        {
            if (spec == null || float.IsNaN(layout.width)) return;
            laidX0 = xMin; laidX1 = xMax; laidY0 = yMin; laidY1 = yMax;
            var r = Plot;
            for (int i = 0; i <= 4; i++)
            {
                float xv = Mathf.Lerp(xMin, xMax, i / 4f), yv = Mathf.Lerp(yMin, yMax, i / 4f);
                var tx = ticks[i * 2]; tx.text = Fmt(xv); tx.style.left = r.x + r.width * i / 4f - 20; tx.style.top = r.yMax + 4; tx.style.width = 40; tx.style.unityTextAlign = TextAnchor.UpperCenter;
                var ty = ticks[i * 2 + 1]; ty.text = Fmt(yv); ty.style.left = 0; ty.style.width = PadL - 6; ty.style.top = r.yMax - r.height * i / 4f - 9; ty.style.unityTextAlign = TextAnchor.MiddleRight;
            }
            xLabel.style.left = r.x; xLabel.style.width = r.width; xLabel.style.top = r.yMax + 20; xLabel.style.unityTextAlign = TextAnchor.UpperCenter;
            yLabel.style.left = r.x + 6; yLabel.style.top = r.y;
            if (spec.RefY.HasValue)
            {
                var y = ToPx(new Vector2(xMin, spec.RefY.Value)).y;
                refLabel.style.left = r.xMax - 150; refLabel.style.width = 148; refLabel.style.top = y - 20; refLabel.style.unityTextAlign = TextAnchor.LowerRight;
            }
            fitLabel.style.left = r.x + 8; fitLabel.style.top = r.y + 22;
            emptyLabel.style.left = r.x; emptyLabel.style.width = r.width; emptyLabel.style.top = r.center.y - 10; emptyLabel.style.unityTextAlign = TextAnchor.MiddleCenter;
            emptyLabel.style.display = pts.Count == 0 ? DisplayStyle.Flex : DisplayStyle.None;
        }

        static string Fmt(float v)
        {
            float a = Mathf.Abs(v);
            return v.ToString(a >= 100 ? "0" : a >= 10 ? "0.#" : a >= 1 ? "0.##" : "0.###", CultureInfo.InvariantCulture);
        }

        void Draw(MeshGenerationContext ctx)
        {
            if (spec == null) return;
            var p = ctx.painter2D;
            var r = Plot;

            p.lineWidth = 1f;
            p.strokeColor = Grid;
            for (int i = 1; i < 4; i++)
            {
                Seg(p, new Vector2(r.x + r.width * i / 4f, r.y), new Vector2(r.x + r.width * i / 4f, r.yMax));
                Seg(p, new Vector2(r.x, r.y + r.height * i / 4f), new Vector2(r.xMax, r.y + r.height * i / 4f));
            }
            p.strokeColor = Axis;
            p.lineWidth = 1.5f;
            Seg(p, new Vector2(r.x, r.y), new Vector2(r.x, r.yMax));
            Seg(p, new Vector2(r.x, r.yMax), new Vector2(r.xMax, r.yMax));

            if (spec.RefY.HasValue)
            {
                float y = ToPx(new Vector2(xMin, spec.RefY.Value)).y;
                p.strokeColor = Ref;
                p.lineWidth = 1.5f;
                for (float x = r.x; x < r.xMax; x += 12) Seg(p, new Vector2(x, y), new Vector2(Mathf.Min(x + 6, r.xMax), y));
            }

            if (pts.Count == 0) return;
            if (spec.BestFitThroughOrigin && pts.Count >= 2)
            {
                float k = Slope();
                float xEnd = xMax, yEnd = k * xEnd;
                if (yEnd > yMax) { yEnd = yMax; xEnd = k > 0 ? yMax / k : xMax; }
                p.strokeColor = Fit;
                p.lineWidth = 2f;
                Seg(p, ToPx(new Vector2(0, 0)), ToPx(new Vector2(xEnd, yEnd)));
            }

            if (spec.Scatter)
            {
                p.fillColor = Line;
                foreach (var pt in pts) Dot(p, ToPx(pt), 5f);
            }
            else if (pts.Count >= 2)
            {
                p.strokeColor = Line;
                p.lineWidth = 3f;
                p.lineJoin = LineJoin.Round;
                p.BeginPath();
                p.MoveTo(ToPx(pts[0]));
                for (int i = 1; i < pts.Count; i++) p.LineTo(ToPx(pts[i]));
                p.Stroke();
            }
            // Newest value: bright dot with a halo.
            var last = ToPx(pts[pts.Count - 1]);
            p.fillColor = new Color(Line.r, Line.g, Line.b, 0.25f);
            Dot(p, last, 11f);
            p.fillColor = Color.white;
            Dot(p, last, 5f);
        }

        static void Seg(Painter2D p, Vector2 a, Vector2 b)
        {
            p.BeginPath();
            p.MoveTo(a);
            p.LineTo(b);
            p.Stroke();
        }

        static void Dot(Painter2D p, Vector2 c, float radius)
        {
            p.BeginPath();
            p.Arc(c, radius, 0, 360);
            p.Fill();
        }
    }

    /// <summary>
    /// Picks the graph that fits the lab (from its science models) and feeds it from the live
    /// world: titration curve, I–V characteristic, pendulum trace, microscope focus curve.
    /// </summary>
    public sealed class GraphFeed
    {
        enum Kind { None, Titration, Circuit, Pendulum, Microscope }
        Kind kind;
        string var, a, b; // model variable, equipment ids
        float lastX = float.NaN, lastY = float.NaN, settle, candidateX;
        readonly LiveGraph graph;

        public bool Active => kind != Kind.None;

        public GraphFeed(LiveGraph g) { graph = g; }

        public GraphSpec Setup(ScenarioDefinition def)
        {
            kind = Kind.None;
            lastX = lastY = float.NaN;
            foreach (var kv in def.Variables)
            {
                var v = kv.Value;
                string In(string k) => v.Inputs != null && v.Inputs.TryGetValue(k, out var id) ? id : null;
                switch (v.Model)
                {
                    case "chem.titration":
                        kind = Kind.Titration; var = kv.Key; a = In("burette"); b = In("flask");
                        return new GraphSpec { Title = "Titration curve", XLabel = "Alkali added", XUnit = "cm³", YLabel = "pH", XMin = 0, XMax = 30, YMin = 0, YMax = 14, RefY = 8.2f, RefLabel = "pink above pH 8.2" };
                    case "phys.circuit":
                        kind = Kind.Circuit; var = kv.Key; a = In("circuit");
                        return new GraphSpec { Title = "Current vs voltage (I–V)", XLabel = "Voltage", XUnit = "V", YLabel = "Current", YUnit = "mA", XMin = 0, XMax = 12, YMin = 0, YMax = 100, Scatter = true, BestFitThroughOrigin = true, FitLabel = "gradient = 1/R = {0:0.###} mA/V" };
                    case "phys.pendulum":
                        kind = Kind.Pendulum; var = kv.Key; a = In("pendulum");
                        return new GraphSpec { Title = "Pendulum swing", XLabel = "Time", XUnit = "s", YLabel = "Angle", YUnit = "°", XMin = 0, XMax = 8, YMin = -12, YMax = 12, RollingX = true };
                    case "bio.microscope":
                        kind = Kind.Microscope; var = kv.Key; a = In("microscope");
                        return new GraphSpec { Title = "Image sharpness", XLabel = "Fine focus", YLabel = "Sharpness", YUnit = "%", XMin = 0, XMax = 1, YMin = 0, YMax = 100, Scatter = true };
                }
            }
            return null;
        }

        public void Tick(LabWorld w, float dt)
        {
            switch (kind)
            {
                case Kind.Titration:
                    {
                        float x = (float)w.Num(a, "dispensedMl"), y = (float)w.Var(var, "pH");
                        if (float.IsNaN(lastX) ? w.Num(b, "volumeMl") > 0 : x - lastX >= 0.05f || x < lastX - 0.01f) Push(x, y);
                        break;
                    }
                case Kind.Circuit:
                    {
                        // A point once the voltage has settled (not every slider tick).
                        float v = (float)w.Num(a, "voltageV"), i = (float)(w.Num(a, "currentA") * 1000.0);
                        if (Mathf.Abs(v - candidateX) > 0.02f) { candidateX = v; settle = 0; break; }
                        settle += dt;
                        if (settle > 0.5f && v > 0.05f && (float.IsNaN(lastX) || Mathf.Abs(v - lastX) > 0.2f)) Push(v, i);
                        break;
                    }
                case Kind.Pendulum:
                    if (w.Bool(a, "swinging"))
                    {
                        float t = (float)w.Time;
                        if (float.IsNaN(lastX) || t - lastX >= 0.05f) Push(t, (float)w.Num(a, "angleDeg"));
                    }
                    break;
                case Kind.Microscope:
                    {
                        float f = (float)w.Num(a, "focus"), q = (float)(w.Var(var, "focusQuality") * 100.0);
                        if (w.Bool(a, "lightOn") && w.Bool(a, "slideLoaded") && (float.IsNaN(lastX) || Mathf.Abs(f - lastX) >= 0.01f)) Push(f, q);
                        break;
                    }
            }
        }

        void Push(float x, float y)
        {
            lastX = x; lastY = y;
            graph.AddPoint(x, y);
        }
    }
}
