// Golden values: keep identical to backend/test/labs.test.js so JS and C# never drift.
using System;
using System.Collections.Generic;
using ECHLabs.Core;
using ECHLabs.Sim;
using Xunit;

public class SimAndExprTests
{
    static void Close(double expected, double actual, double eps = 1e-3) => Assert.True(Math.Abs(expected - actual) <= eps, $"{actual} ≉ {expected}");

    sealed class DictScope : IExprScope
    {
        public Dictionary<string, object> Values = new Dictionary<string, object>();
        public HashSet<string> Done = new HashSet<string>();
        public object Resolve(IReadOnlyList<string> path) => Values.TryGetValue(string.Join(".", path), out var v) ? v : null;
        public bool IsDone(string id) => Done.Contains(id);
    }

    [Fact]
    public void Titration_curve_matches_backend()
    {
        Chemistry.TitrationResult T(string acid, double v) => Chemistry.Titration(acid, 0.1, 25, 0.125, v);
        Close(1.000, T("HCl", 0).PH);
        Close(1.447, T("HCl", 10).PH);
        Close(7.000, T("HCl", 20).PH);
        Close(10.443, T("HCl", 20.1).PH);
        Close(12.097, T("HCl", 25).PH);
        Close(20.0, T("HCl", 0).EquivalenceVolumeMl);
        Close(2.875, T("CH3COOH", 0).PH);
        Close(4.745, T("CH3COOH", 10).PH);
        Close(8.745, T("CH3COOH", 20).PH);
        Assert.Equal(0, Chemistry.IndicatorColorIndex("phenolphthalein", 7));
        Assert.Equal(1, Chemistry.IndicatorColorIndex("phenolphthalein", 11));
        Close(0.5, Chemistry.IndicatorColorIndex("phenolphthalein", 9.1));
    }

    [Fact]
    public void Pendulum_and_circuits_match_backend()
    {
        Close(1.7946, Physics.PendulumTheoreticalPeriod(0.8));
        Close(1.7954, Physics.PendulumPeriod(0.8, 5));
        var c = Physics.SeriesCircuit(6, new[] { 47.0 });
        Close(0.12766, c.CurrentA);
        Close(0.76596, c.PowerW);
        Close(50, Physics.Parallel(new[] { 100.0, 100.0 }));
        Assert.True(Physics.SeriesCircuit(6, new double[0]).ShortCircuit);
    }

    [Fact]
    public void Nodal_solver_handles_a_divider_and_a_bridge()
    {
        // 12 V across 1k + 2k: middle node = 8 V.
        var v = Physics.SolveNodal(3, new[] { (1, 2, 1000.0), (2, 0, 2000.0) }, new[] { (1, 0, 12.0) });
        Close(12, v[1]); Close(8, v[2]);
        // Balanced Wheatstone bridge: no voltage across the galvanometer.
        var b = Physics.SolveNodal(4, new[] { (1, 2, 100.0), (1, 3, 200.0), (2, 0, 100.0), (3, 0, 200.0), (2, 3, 50.0) }, new[] { (1, 0, 10.0) });
        Close(b[2], b[3]);
    }

    [Fact]
    public void Microscope_focus_is_harder_at_high_power()
    {
        Close(1, Biology.FocusQuality(0.62, 0.62, 4));
        Assert.True(Biology.FocusQuality(0.70, 0.62, 40) < Biology.FocusQuality(0.70, 0.62, 4));
        Close(400, Biology.TotalMagnification(40));
    }

    [Fact]
    public void Expressions_match_backend_semantics()
    {
        var s = new DictScope();
        s.Values["burette1.volumeMl"] = 49.5; s.Values["burette1.filled"] = true; s.Values["titr.pH"] = 8.4;
        s.Values["record.a"] = 20.1; s.Values["record.b"] = 0.05; s.Done.Add("s1");
        Assert.Equal(7.0, Expr.Evaluate("1 + 2 * 3", s));
        Assert.Equal(9.0, Expr.Evaluate("(1 + 2) * 3", s));
        Assert.Equal(true, Expr.Evaluate("burette1.filled && burette1.volumeMl >= 49", s));
        Assert.Equal(false, Expr.Evaluate("!burette1.filled || titr.pH < 8.2", s));
        Assert.Equal(20.05, (double)Expr.Evaluate("round(record.a - record.b, 2)", s), 6);
        Assert.Equal(true, Expr.Evaluate("between(titr.pH, 8.2, 10)", s));
        Assert.Equal(true, Expr.Evaluate("done('s1') && !done('s2')", s));
        Assert.Equal(false, Expr.Evaluate("missing.value > 0", s));
        Assert.Equal(0.0, Expr.Evaluate("5 / 0", s));
        Assert.Equal(true, Expr.Evaluate("'pink' == 'pink'", s));
        Assert.Equal(6.0, Expr.Evaluate("-2 * -3", s));
    }

    [Theory]
    [InlineData("")] [InlineData("a +")] [InlineData("foo(1)")] [InlineData("a = 1")] [InlineData("a[0]")]
    [InlineData("done(x)")] [InlineData("1..2")] [InlineData("a.")] [InlineData("\"open")] [InlineData("a ? b : c")]
    public void Expressions_reject_anything_outside_the_grammar(string bad)
        => Assert.Throws<ExprException>(() => Expr.Parse(bad));

    [Fact]
    public void Expression_references()
    {
        var (paths, steps) = Expr.References("a.b > 1 && done('s3') || max(c.d, 2)");
        Assert.Equal(new[] { "a.b", "c.d" }, paths);
        Assert.Equal(new[] { "s3" }, steps);
    }

    [Fact]
    public void Result_grading_matches_backend()
    {
        Assert.Equal(100, Scoring.GradeResult(20.3, 20, 1.5));
        Assert.Equal(0, Scoring.GradeResult(21, 20, 1.5));
        Assert.Equal(0, Scoring.GradeResult(null, 20, 1.5));
    }
}
