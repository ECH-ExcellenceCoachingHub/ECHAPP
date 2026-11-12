// ECH Labs — microscope optics model.
using System;

namespace ECHLabs.Sim
{
    public static class Biology
    {
        public const double EyepieceMagnification = 10;

        public static double TotalMagnification(double objective) => EyepieceMagnification * objective;

        /// <summary>
        /// Depth of field shrinks as magnification grows, so focusing gets harder at 40×/100×.
        /// focus and idealFocus are knob positions in [0,1]. Returns 1 = sharp … 0 = fully blurred.
        /// </summary>
        public static double FocusQuality(double focus, double idealFocus, double objective)
        {
            double width = 0.25 / Math.Sqrt(Math.Max(objective, 1)); // 4× → 0.125, 40× → 0.040
            double d = (focus - idealFocus) / width;
            return Math.Exp(-d * d);
        }

        /// <summary>Blur radius in pixels for the microscope view post-effect.</summary>
        public static double BlurRadiusPx(double focusQuality, double maxRadius = 24) => (1 - focusQuality) * maxRadius;
    }
}
