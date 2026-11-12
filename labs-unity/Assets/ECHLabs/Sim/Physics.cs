// ECH Labs — reference physics models (mirrors backend/src/services/labs/sim.js).
using System;
using System.Collections.Generic;

namespace ECHLabs.Sim
{
    public static class Physics
    {
        public const double G = 9.80665;

        /// <summary>Small-angle period 2π√(L/g).</summary>
        public static double PendulumTheoreticalPeriod(double lengthM, double g = G)
            => 2 * Math.PI * Math.Sqrt(lengthM / g);

        /// <summary>Period with the finite-amplitude series correction (accurate to &lt;0.01% below 30°).</summary>
        public static double PendulumPeriod(double lengthM, double amplitudeDeg, double g = G)
        {
            double t0 = PendulumTheoreticalPeriod(lengthM, g);
            double th = amplitudeDeg * Math.PI / 180.0;
            return t0 * (1 + th * th / 16 + 11 * Math.Pow(th, 4) / 3072);
        }

        /// <summary>
        /// Angle of a damped pendulum at time t (seconds since release), for animation.
        /// Uses the corrected period so the animation and the measured period agree.
        /// </summary>
        public static double PendulumAngleDeg(double lengthM, double amplitudeDeg, double t, double dampingPerSecond = 0.004)
        {
            double period = PendulumPeriod(lengthM, amplitudeDeg);
            return amplitudeDeg * Math.Exp(-dampingPerSecond * t) * Math.Cos(2 * Math.PI * t / period);
        }

        public struct CircuitResult
        {
            public double CurrentA, LoadVoltageV, PowerW;
            public bool ShortCircuit;
        }

        /// <summary>Series DC circuit: supply V with internal resistance r and resistors R1..Rn.</summary>
        public static CircuitResult SeriesCircuit(double voltageV, IList<double> resistorsOhm, double internalOhm = 0)
        {
            double load = 0;
            foreach (var r in resistorsOhm) load += r;
            double total = load + internalOhm;
            if (total <= 0) return new CircuitResult { CurrentA = double.PositiveInfinity, ShortCircuit = true };
            double i = voltageV / total;
            return new CircuitResult { CurrentA = i, LoadVoltageV = i * load, PowerW = i * i * load, ShortCircuit = false };
        }

        public static double Parallel(IList<double> resistorsOhm)
        {
            double inv = 0;
            foreach (var r in resistorsOhm) inv += 1.0 / r;
            return 1.0 / inv;
        }

        /// <summary>
        /// General DC solver (modified nodal analysis) for free-form circuits built on the board.
        /// Nodes are 0..n-1 with node 0 = ground. Returns node voltages; null if singular.
        /// </summary>
        public static double[] SolveNodal(int nodeCount, IList<(int a, int b, double ohms)> resistors, IList<(int plus, int minus, double volts)> sources)
        {
            int n = nodeCount - 1, m = sources.Count, size = n + m;
            var A = new double[size, size];
            var z = new double[size];
            foreach (var (a, b, ohms) in resistors)
            {
                double g = 1.0 / Math.Max(ohms, 1e-9);
                if (a > 0) A[a - 1, a - 1] += g;
                if (b > 0) A[b - 1, b - 1] += g;
                if (a > 0 && b > 0) { A[a - 1, b - 1] -= g; A[b - 1, a - 1] -= g; }
            }
            for (int k = 0; k < m; k++)
            {
                var (p, q, v) = sources[k];
                if (p > 0) { A[p - 1, n + k] += 1; A[n + k, p - 1] += 1; }
                if (q > 0) { A[q - 1, n + k] -= 1; A[n + k, q - 1] -= 1; }
                z[n + k] = v;
            }
            var x = Gauss(A, z, size);
            if (x == null) return null;
            var volts = new double[nodeCount];
            for (int i = 1; i < nodeCount; i++) volts[i] = x[i - 1];
            return volts;
        }

        static double[] Gauss(double[,] A, double[] b, int n)
        {
            var M = (double[,])A.Clone();
            var x = (double[])b.Clone();
            for (int col = 0; col < n; col++)
            {
                int piv = col;
                for (int r = col + 1; r < n; r++) if (Math.Abs(M[r, col]) > Math.Abs(M[piv, col])) piv = r;
                if (Math.Abs(M[piv, col]) < 1e-12) return null;
                if (piv != col)
                {
                    for (int c = 0; c < n; c++) { var t = M[col, c]; M[col, c] = M[piv, c]; M[piv, c] = t; }
                    var tb = x[col]; x[col] = x[piv]; x[piv] = tb;
                }
                for (int r = col + 1; r < n; r++)
                {
                    double f = M[r, col] / M[col, col];
                    if (f == 0) continue;
                    for (int c = col; c < n; c++) M[r, c] -= f * M[col, c];
                    x[r] -= f * x[col];
                }
            }
            for (int r = n - 1; r >= 0; r--)
            {
                double s = x[r];
                for (int c = r + 1; c < n; c++) s -= M[r, c] * x[c];
                x[r] = s / M[r, r];
            }
            return x;
        }
    }
}
