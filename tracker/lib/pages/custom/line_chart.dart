import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tracker/analytics/analytics.dart';

/// Minimal dependency-free line chart for [ProgressionPoint] series
/// (Milestone 6 analytics). A plain [CustomPainter] — no charting package —
/// plotting a polyline + point dots with min/max value labels.
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
          labelColor: theme.colors.mutedForeground,
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
    required this.labelColor,
  });

  static const double _leftPad = 40;
  static const double _topPad = 8;
  static const double _rightPad = 12;
  static const double _bottomPad = 18;

  final List<ProgressionPoint> points;
  final String unit;
  final Color lineColor;
  final Color dotColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final chartWidth = size.width - _leftPad - _rightPad;
    final chartHeight = size.height - _topPad - _bottomPad;
    if (chartWidth <= 0 || chartHeight <= 0) return;

    var minY = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    var maxY = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    if (maxY - minY < 1e-9) {
      // Flat series: give the line vertical room.
      minY -= 1;
      maxY += 1;
    }

    double yFor(double value) =>
        _topPad + chartHeight * (1 - (value - minY) / (maxY - minY));
    double xFor(int i) => chartWidth == 1
        ? _leftPad
        : _leftPad +
              (points.length == 1
                  ? chartWidth / 2
                  : chartWidth * i / (points.length - 1));

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..color = dotColor;

    // Horizontal mid gridline.
    final gridPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    final midY = yFor((minY + maxY) / 2);
    canvas.drawLine(
      Offset(_leftPad, midY),
      Offset(size.width - _rightPad, midY),
      gridPaint,
    );

    // Polyline.
    final path = Path()..moveTo(xFor(0), yFor(points[0].value));
    for (var i = 1; i < points.length; i++) {
      path.lineTo(xFor(i), yFor(points[i].value));
    }
    canvas.drawPath(path, linePaint);

    // Dots + value labels.
    for (var i = 0; i < points.length; i++) {
      final o = Offset(xFor(i), yFor(points[i].value));
      canvas.drawCircle(o, 3, dotPaint);
    }

    _label(
      canvas,
      '$_fmt(maxY) $unit',
      _leftPad - 4,
      _topPad,
      alignRight: true,
    );
    _label(
      canvas,
      '$_fmt(minY) $unit',
      _leftPad - 4,
      size.height - _bottomPad,
      alignRight: true,
    );
    _label(
      canvas,
      _fmt(points.first.value),
      _leftPad,
      size.height - 2,
      alignRight: false,
    );
  }

  void _label(
    Canvas canvas,
    String text,
    double x,
    double y, {
    required bool alignRight,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 9, color: labelColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = alignRight
        ? Offset(x - painter.width, y)
        : Offset(x, y - painter.height);
    painter.paint(canvas, offset);
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.dotColor != dotColor ||
      oldDelegate.labelColor != labelColor;
}
