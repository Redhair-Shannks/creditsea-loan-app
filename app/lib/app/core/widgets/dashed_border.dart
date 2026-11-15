import '../material.dart';

/// Rounded dashed outline (the "Interest Per Day 1%" chips in the design).
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.child,
    this.color = const Color(0xFF0075FF),
    this.radius = 4,
    this.dash = 4,
    this.gap = 3,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
  });

  final Widget child;
  final Color color;
  final double radius;
  final double dash;
  final double gap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DashedPainter(color: color, radius: radius, dash: dash, gap: gap),
        child: Padding(padding: padding, child: child),
      );
}

class _DashedPainter extends CustomPainter {
  const _DashedPainter({required this.color, required this.radius, required this.dash, required this.gap});

  final Color color;
  final double radius;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final outline = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(0.5));
    for (final metric in outline.computeMetrics()) {
      for (double d = 0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius || oldDelegate.dash != dash || oldDelegate.gap != gap;
}
