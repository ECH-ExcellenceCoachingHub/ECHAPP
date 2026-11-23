import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// Charts for the super admin analytics dashboard. Drawn with CustomPainter
/// (no chart package), theme-aware, with hover / tap tooltips.

/// Colors shared by the dashboard and its charts, light and dark.
class DashPalette {
  final bool dark;
  const DashPalette(this.dark);

  factory DashPalette.of(BuildContext context) =>
      DashPalette(Theme.of(context).brightness == Brightness.dark);

  Color get page => dark ? const Color(0xFF0B1117) : const Color(0xFFF4F7F6);
  Color get card => dark ? const Color(0xFF151D26) : Colors.white;
  Color get cardAlt => dark ? const Color(0xFF1B2530) : const Color(0xFFF7FAF9);
  Color get border => dark ? const Color(0xFF243140) : const Color(0xFFE6ECEA);
  Color get grid => dark ? const Color(0xFF223040) : const Color(0xFFEDF1F0);
  Color get text => dark ? const Color(0xFFE8EEF2) : const Color(0xFF0F172A);
  Color get muted => dark ? const Color(0xFF93A3B5) : const Color(0xFF64748B);
  Color get faint => dark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  // Series colors: distinct in hue and lightness, readable on both themes.
  static const emerald = Color(0xFF10B981);
  static const blue = Color(0xFF3B82F6);
  static const violet = Color(0xFF8B5CF6);
  static const amber = Color(0xFFF59E0B);
  static const rose = Color(0xFFF43F5E);
  static const cyan = Color(0xFF06B6D4);
  static const slate = Color(0xFF64748B);
  static const lime = Color(0xFF84CC16);

  static const categorical = [emerald, blue, violet, amber, rose, cyan, lime, slate];

  static Color at(int i) => categorical[i % categorical.length];
}

String compactNumber(num v) {
  if (v.abs() < 1000) return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
  return NumberFormat.compact().format(v);
}

String money(num v, {String currency = 'RWF', bool compact = true}) {
  final s = compact && v.abs() >= 10000 ? NumberFormat.compact().format(v) : NumberFormat('#,##0').format(v);
  return '$currency $s';
}

/// Short axis label for a bucket key: "2026-11-03" → "Nov 3", "2026-11" → "Nov".
String bucketLabel(String key, {bool long = false}) {
  try {
    if (key.length == 7) {
      final d = DateTime.parse('$key-01');
      return DateFormat(long ? 'MMMM yyyy' : 'MMM').format(d);
    }
    final d = DateTime.parse(key);
    return DateFormat(long ? 'EEE, MMM d yyyy' : 'MMM d').format(d);
  } catch (_) {
    return key;
  }
}

double _niceMax(double v) {
  if (v <= 0) return 4;
  final exp = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
  final f = v / exp;
  final nice = f <= 1 ? 1 : f <= 2 ? 2 : f <= 2.5 ? 2.5 : f <= 5 ? 5 : 10;
  return nice * exp;
}

class ChartSeries {
  final String name;
  final Color color;
  final List<double> values;
  final bool filled;
  const ChartSeries({required this.name, required this.color, required this.values, this.filled = true});
}

/// Line / area chart over date buckets with gridlines, y labels and a hover
/// crosshair that lists every series at that point.
class TrendChart extends StatefulWidget {
  final List<String> labels;
  final List<ChartSeries> series;
  final double height;
  final String Function(double)? format;
  final bool bars;

  const TrendChart({
    super.key,
    required this.labels,
    required this.series,
    this.height = 240,
    this.format,
    this.bars = false,
  });

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  int? _hover;

  static const _left = 44.0;
  static const _bottom = 26.0;
  static const _top = 8.0;

  void _setHover(Offset p, double width) {
    final n = widget.labels.length;
    if (n == 0) return;
    final plotW = width - _left - 8;
    final step = widget.bars ? plotW / n : (n > 1 ? plotW / (n - 1) : plotW);
    final x = p.dx - _left;
    final i = widget.bars ? (x / step).floor() : (x / step).round();
    final clamped = i.clamp(0, n - 1);
    if (clamped != _hover) setState(() => _hover = clamped);
  }

  @override
  Widget build(BuildContext context) {
    final pal = DashPalette.of(context);
    final fmt = widget.format ?? (v) => compactNumber(v);
    return LayoutBuilder(builder: (context, c) {
      final width = c.maxWidth;
      return SizedBox(
        height: widget.height,
        child: MouseRegion(
          onHover: (e) => _setHover(e.localPosition, width),
          onExit: (_) => setState(() => _hover = null),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _setHover(d.localPosition, width),
            onHorizontalDragUpdate: (d) => _setHover(d.localPosition, width),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TrendPainter(
                      labels: widget.labels,
                      series: widget.series,
                      hover: _hover,
                      pal: pal,
                      fmt: fmt,
                      bars: widget.bars,
                    ),
                  ),
                ),
                if (_hover != null) _tooltip(pal, fmt, width),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _tooltip(DashPalette pal, String Function(double) fmt, double width) {
    final i = _hover!;
    final n = widget.labels.length;
    final plotW = width - _left - 8;
    final x = widget.bars
        ? _left + plotW / n * (i + 0.5)
        : _left + (n > 1 ? plotW / (n - 1) * i : plotW / 2);
    const tipW = 168.0;
    final left = (x + 12 + tipW > width) ? x - 12 - tipW : x + 12;
    return Positioned(
      left: left.clamp(0, math.max(0, width - tipW)).toDouble(),
      top: _top,
      child: IgnorePointer(
        child: Container(
          width: tipW,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: pal.dark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: pal.border),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(bucketLabel(widget.labels[i], long: true),
                  style: TextStyle(fontSize: 11, color: pal.muted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              for (final s in widget.series)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(s.name,
                          overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: pal.muted)),
                    ),
                    Text(fmt(i < s.values.length ? s.values[i] : 0),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: pal.text)),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<String> labels;
  final List<ChartSeries> series;
  final int? hover;
  final DashPalette pal;
  final String Function(double) fmt;
  final bool bars;

  _TrendPainter({
    required this.labels,
    required this.series,
    required this.hover,
    required this.pal,
    required this.fmt,
    required this.bars,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = _TrendChartState._left;
    const bottom = _TrendChartState._bottom;
    const top = _TrendChartState._top;
    final plot = Rect.fromLTRB(left, top, size.width - 8, size.height - bottom);
    final n = labels.length;
    if (n == 0 || plot.width <= 0) return;

    var maxV = 0.0;
    for (final s in series) {
      for (final v in s.values) {
        if (v > maxV) maxV = v;
      }
    }
    final yMax = _niceMax(maxV);

    // Grid + y labels
    final grid = Paint()
      ..color = pal.grid
      ..strokeWidth = 1;
    for (var g = 0; g <= 4; g++) {
      final y = plot.bottom - plot.height * g / 4;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      _text(canvas, fmt(yMax * g / 4), Offset(plot.left - 6, y), pal.faint, 10, align: TextAlign.right);
    }

    double xAt(int i) => bars
        ? plot.left + plot.width / n * (i + 0.5)
        : plot.left + (n > 1 ? plot.width / (n - 1) * i : plot.width / 2);
    double yAt(double v) => plot.bottom - (v / yMax) * plot.height;

    // x labels: at most ~7, evenly spaced
    final every = math.max(1, (n / 7).ceil());
    for (var i = 0; i < n; i += every) {
      _text(canvas, bucketLabel(labels[i]), Offset(xAt(i), plot.bottom + 14), pal.faint, 10,
          align: TextAlign.center);
    }

    if (hover != null) {
      final hx = xAt(hover!);
      if (bars) {
        final w = plot.width / n;
        canvas.drawRect(Rect.fromLTWH(hx - w / 2, plot.top, w, plot.height),
            Paint()..color = pal.grid.withOpacity(0.7));
      } else {
        canvas.drawLine(Offset(hx, plot.top), Offset(hx, plot.bottom),
            Paint()
              ..color = pal.faint.withOpacity(0.6)
              ..strokeWidth = 1);
      }
    }

    if (bars) {
      final group = plot.width / n;
      final inner = math.min(group * 0.72, 36.0);
      final bw = math.max(1.5, inner / series.length - (series.length > 1 ? 2 : 0));
      for (var si = 0; si < series.length; si++) {
        final s = series[si];
        final paint = Paint()..color = s.color;
        for (var i = 0; i < n && i < s.values.length; i++) {
          final v = s.values[i];
          if (v <= 0) continue;
          final x0 = xAt(i) - inner / 2 + si * (bw + (series.length > 1 ? 2 : 0));
          final rect = Rect.fromLTRB(x0, yAt(v), x0 + bw, plot.bottom);
          canvas.drawRRect(
            RRect.fromRectAndCorners(rect, topLeft: const Radius.circular(3), topRight: const Radius.circular(3)),
            paint..color = hover == null || hover == i ? s.color : s.color.withOpacity(0.55),
          );
        }
      }
      return;
    }

    for (final s in series) {
      if (s.values.isEmpty) continue;
      final pts = [for (var i = 0; i < n && i < s.values.length; i++) Offset(xAt(i), yAt(s.values[i]))];
      final path = _smooth(pts);
      if (s.filled) {
        final area = Path.from(path)
          ..lineTo(pts.last.dx, plot.bottom)
          ..lineTo(pts.first.dx, plot.bottom)
          ..close();
        canvas.drawPath(
          area,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [s.color.withOpacity(pal.dark ? 0.32 : 0.22), s.color.withOpacity(0.0)],
            ).createShader(plot),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      if (hover != null && hover! < pts.length) {
        final p = pts[hover!];
        canvas.drawCircle(p, 5.5, Paint()..color = pal.card);
        canvas.drawCircle(p, 4, Paint()..color = s.color);
      }
    }
  }

  Path _smooth(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    if (pts.length < 3) {
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      return path;
    }
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = i > 0 ? pts[i - 1] : pts[i];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : p2;
      // Catmull-Rom → Bezier, tension kept low so peaks don't overshoot much
      final c1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
      final c2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
      final bottomY = math.max(p1.dy, p2.dy);
      path.cubicTo(c1.dx, math.min(c1.dy, bottomY), c2.dx, math.min(c2.dy, bottomY), p2.dx, p2.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.hover != hover || old.series != series || old.labels != labels || old.pal.dark != pal.dark;
}

void _text(Canvas canvas, String s, Offset at, Color color, double size,
    {TextAlign align = TextAlign.left, FontWeight weight = FontWeight.w500}) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: TextStyle(color: color, fontSize: size, fontWeight: weight)),
    textDirection: TextDirection.ltr,
  )..layout();
  final dx = align == TextAlign.right
      ? at.dx - tp.width
      : align == TextAlign.center
          ? at.dx - tp.width / 2
          : at.dx;
  tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
}

/// Tiny trend line for KPI tiles.
class Sparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double height;
  const Sparkline({super.key, required this.values, required this.color, this.height = 34});

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: height, child: CustomPaint(painter: _SparkPainter(values, color), size: Size.infinite));
}

class _SparkPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _SparkPainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.reduce(math.max);
    final minV = values.reduce(math.min);
    final span = (maxV - minV) == 0 ? 1 : (maxV - minV);
    final pts = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(size.width * i / (values.length - 1),
            size.height - 2 - (values[i] - minV) / span * (size.height - 4)),
    ];
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.25), color.withOpacity(0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(pts.last, 2.8, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.values != values || old.color != color;
}

class DonutSlice {
  final String label;
  final double value;
  final Color color;
  const DonutSlice(this.label, this.value, this.color);
}

/// Donut with center total and a legend showing value and share.
class DonutChart extends StatefulWidget {
  final List<DonutSlice> slices;
  final String centerLabel;
  final String Function(double)? format;
  final double size;

  const DonutChart({super.key, required this.slices, this.centerLabel = 'Total', this.format, this.size = 150});

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> {
  int? _active;

  @override
  Widget build(BuildContext context) {
    final pal = DashPalette.of(context);
    final fmt = widget.format ?? (v) => compactNumber(v);
    final slices = widget.slices.where((s) => s.value > 0).toList();
    final total = slices.fold<double>(0, (s, x) => s + x.value);
    if (total == 0) return EmptyChart(height: widget.size);

    final focus = _active != null && _active! < slices.length ? slices[_active!] : null;
    final ring = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(size: Size.square(widget.size), painter: _DonutPainter(slices, _active, pal)),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(fmt(focus?.value ?? total),
              style: TextStyle(fontSize: widget.size * 0.15, fontWeight: FontWeight.w800, color: pal.text)),
          SizedBox(
            width: widget.size * 0.6,
            child: Text(focus?.label ?? widget.centerLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: pal.muted)),
          ),
        ]),
      ]),
    );

    final legend = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < slices.length; i++)
          MouseRegion(
            onEnter: (_) => setState(() => _active = i),
            onExit: (_) => setState(() => _active = null),
            child: GestureDetector(
              onTap: () => setState(() => _active = _active == i ? null : i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: slices[i].color, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(slices[i].label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12.5,
                            color: _active == i ? pal.text : pal.muted,
                            fontWeight: _active == i ? FontWeight.w700 : FontWeight.w500)),
                  ),
                  const SizedBox(width: 8),
                  Text(fmt(slices[i].value),
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: pal.text)),
                  const SizedBox(width: 6),
                  Text('${(slices[i].value / total * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 11, color: pal.faint)),
                ]),
              ),
            ),
          ),
      ],
    );

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < widget.size + 170) {
        return Column(children: [ring, const SizedBox(height: 14), legend]);
      }
      return Row(children: [ring, const SizedBox(width: 24), Flexible(child: legend)]);
    });
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSlice> slices;
  final int? active;
  final DashPalette pal;
  _DonutPainter(this.slices, this.active, this.pal);

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (s, x) => s + x.value);
    final stroke = size.width * 0.13;
    final rect = Offset(stroke / 2 + 4, stroke / 2 + 4) &
        Size(size.width - stroke - 8, size.height - stroke - 8);
    var start = -math.pi / 2;
    const gap = 0.025;
    for (var i = 0; i < slices.length; i++) {
      final sweep = slices[i].value / total * 2 * math.pi;
      final on = active == null || active == i;
      canvas.drawArc(
        active == i ? rect.inflate(3) : rect,
        start + (slices.length > 1 ? gap / 2 : 0),
        math.max(0.001, sweep - (slices.length > 1 ? gap : 0)),
        false,
        Paint()
          ..color = on ? slices[i].color : slices[i].color.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = active == i ? stroke + 4 : stroke
          ..strokeCap = StrokeCap.butt,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.active != active || old.slices != slices;
}

/// Ring gauge for a percentage KPI.
class RingGauge extends StatelessWidget {
  final double percent;
  final Color color;
  final String label;
  final String? caption;
  final double size;

  const RingGauge({
    super.key,
    required this.percent,
    required this.color,
    required this.label,
    this.caption,
    this.size = 92,
  });

  @override
  Widget build(BuildContext context) {
    final pal = DashPalette.of(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: percent.clamp(0, 100) / 100),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => CustomPaint(
            painter: _RingPainter(v, color, pal.grid),
            child: Center(
              child: Text('${(v * 100).toStringAsFixed(v * 100 < 10 && v > 0 ? 1 : 0)}%',
                  style: TextStyle(fontSize: size * 0.2, fontWeight: FontWeight.w800, color: pal.text)),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Text(label,
          textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: pal.text)),
      if (caption != null) ...[
        const SizedBox(height: 2),
        Text(caption!, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: pal.muted)),
      ],
    ]);
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color track;
  _RingPainter(this.value, this.color, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.1;
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    canvas.drawArc(rect, 0, math.pi * 2, false,
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke);
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: [color.withOpacity(0.55), color],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value || old.color != color;
}

class RankedItem {
  final String label;
  final double value;
  final String? valueText;
  final String? sub;
  final VoidCallback? onTap;
  const RankedItem(this.label, this.value, {this.valueText, this.sub, this.onTap});
}

/// Horizontal ranked bars (top courses, categories, provinces...).
class RankedBars extends StatelessWidget {
  final List<RankedItem> items;
  final Color color;
  final String Function(double)? format;

  const RankedBars({super.key, required this.items, required this.color, this.format});

  @override
  Widget build(BuildContext context) {
    final pal = DashPalette.of(context);
    if (items.isEmpty) return const EmptyChart(height: 120);
    final maxV = items.map((e) => e.value).fold<double>(0, math.max);
    final fmt = format ?? (v) => compactNumber(v);
    return Column(children: [
      for (var i = 0; i < items.length; i++)
        InkWell(
          onTap: items[i].onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                SizedBox(
                  width: 22,
                  child: Text('${i + 1}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: i < 3 ? color : pal.faint)),
                ),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(items[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: pal.text)),
                    if (items[i].sub != null)
                      Text(items[i].sub!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: pal.muted)),
                  ]),
                ),
                const SizedBox(width: 8),
                Text(items[i].valueText ?? fmt(items[i].value),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: pal.text)),
              ]),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: maxV == 0 ? 0 : items[i].value / maxV),
                    duration: Duration(milliseconds: 500 + i * 70),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: pal.grid,
                      valueColor: AlwaysStoppedAnimation(color.withOpacity(1 - i * 0.06)),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
    ]);
  }
}

/// Stage funnel, e.g. enrolled → in progress → completed.
class FunnelChart extends StatelessWidget {
  final List<RankedItem> stages;
  final List<Color> colors;
  const FunnelChart({super.key, required this.stages, required this.colors});

  @override
  Widget build(BuildContext context) {
    final pal = DashPalette.of(context);
    if (stages.isEmpty || stages.first.value == 0) return const EmptyChart(height: 140);
    final top = stages.first.value;
    return Column(children: [
      for (var i = 0; i < stages.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: LayoutBuilder(builder: (context, c) {
            final f = (stages[i].value / top).clamp(0.0, 1.0);
            final w = math.max(math.min(c.maxWidth, 190.0), c.maxWidth * f);
            return Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                width: w,
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [colors[i % colors.length], colors[i % colors.length].withOpacity(0.75)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Expanded(
                    child: Text(stages[i].label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                  ),
                  Text(compactNumber(stages[i].value),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                  if (i > 0) ...[
                    const SizedBox(width: 6),
                    Text('${(f * 100).toStringAsFixed(0)}%',
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11)),
                  ],
                ]),
              ),
            );
          }),
        ),
      const SizedBox(height: 4),
      Text('Share of all enrollments at each stage', style: TextStyle(fontSize: 11, color: pal.faint)),
    ]);
  }
}

class EmptyChart extends StatelessWidget {
  final double height;
  final String message;
  const EmptyChart({super.key, this.height = 160, this.message = 'No data for this period yet'});

  @override
  Widget build(BuildContext context) {
    final pal = DashPalette.of(context);
    return SizedBox(
      height: height,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.insights_outlined, color: pal.faint, size: 28),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: pal.muted, fontSize: 12.5)),
        ]),
      ),
    );
  }
}
