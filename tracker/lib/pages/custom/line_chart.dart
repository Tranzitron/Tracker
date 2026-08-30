import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tracker/analytics/analytics.dart';

/// Minimal dependency-free line chart for [ProgressionPoint] series
/// (Milestone 6 analytics). A plain [CustomPainter] — no charting package —
/// plotting a polyline + point dots over a light grid with y-axis tick labels.
class LineChart extends StatelessWidget {
  const LineChart({
    super.key,
    required this.points,
    this.height = 160,
    this.unit = '',
  });

  /// Sorted ascending by date.
  final List<ProgressionPoint> points;
  final double height;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data yet',
            style: theme.typography.body.xs.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _LineChartPainter(
          points: points,
          unit: unit,
          lineColor: theme.colors.primary,
          dotColor: theme.colors.primary,
          // Full theme style (family included) so labels don't fall back to
          // the blocky test/default font.
          labelStyle: theme.typography.body.xs.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.points,
    required this.unit,
    required this.lineColor,
    required this.dotColor,
    required this.labelStyle,
  });

  static const double _minGutter = 32;
  static const double _topPad = 8;
  static const double _rightPad = 12;
  static const double _bottomPad = 18;
  static const int _tickCount = 4;

  final List<ProgressionPoint> points;
  final String unit;
  final Color lineColor;
  final Color dotColor;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    // Labels are painted through a clip so an over-long value can never bleed
    // past the chart bounds.
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    var minY = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    var maxY = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    if (maxY - minY < 1e-9) {
      // Flat series: give the line vertical room.
      minY -= 1;
      maxY += 1;
    }

    // Y-axis ticks: lay out the labels first so the left gutter always fits
    // the widest one.
    final ticks = <(double, TextPainter)>[
      for (var i = 0; i < _tickCount; i++)
        _tickLabel(
          minY + (maxY - minY) * i / (_tickCount - 1),
          withUnit: i == _tickCount - 1,
        ),
    ];
    // Floor at _minGutter (never throws on degenerate widths, unlike a
    // clamp whose bounds can cross) so the early-out below stays safe.
    final gutter = math.max(
      _minGutter,
      math.min(
        ticks.map((t) => t.$2.width).reduce((a, b) => a > b ? a : b) + 8,
        size.width / 3,
      ),
    );

    final chartWidth = size.width - gutter - _rightPad;
    final chartHeight = size.height - _topPad - _bottomPad;
    if (chartWidth <= 0 || chartHeight <= 0) {
      canvas.restore();
      return;
    }

    double yFor(double value) =>
        _topPad + chartHeight * (1 - (value - minY) / (maxY - minY));
    double xFor(int i) => chartWidth == 1
        ? gutter
        : gutter +
              (points.length == 1
                  ? chartWidth / 2
                  : chartWidth * i / (points.length - 1));

    // Gridlines + tick labels.
    final gridPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (final (value, label) in ticks) {
      final y = yFor(value);
      canvas.drawLine(
        Offset(gutter, y),
        Offset(size.width - _rightPad, y),
        gridPaint,
      );
      label.paint(
        canvas,
        Offset(gutter - 8 - label.width, y - label.height / 2),
      );
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..color = dotColor;

    // Polyline.
    final path = Path()..moveTo(xFor(0), yFor(points[0].value));
    for (var i = 1; i < points.length; i++) {
      path.lineTo(xFor(i), yFor(points[i].value));
    }
    canvas.drawPath(path, linePaint);

    // Point dots.
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(Offset(xFor(i), yFor(points[i].value)), 3, dotPaint);
    }

    canvas.restore();
  }

  (double, TextPainter) _tickLabel(double value, {required bool withUnit}) {
    final text = withUnit && unit.isNotEmpty
        ? '${_fmt(value)} $unit'
        : _fmt(value);
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    return (value, painter);
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.dotColor != dotColor ||
      oldDelegate.labelStyle != labelStyle;
}
