import '../material.dart';

import '../theme/app_colors.dart';

enum LogoTone { onDark, onLight }

/// CreditSea logo: a round mark with two rising "wings" plus the wordmark.
/// Drawn in code (CustomPainter) so it stays sharp at any size and needs no asset.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 32,
    this.tone = LogoTone.onDark,
    this.vertical = false,
    this.showWordmark = true,
  });

  final double size;
  final LogoTone tone;
  final bool vertical;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final mark = CustomPaint(size: Size.square(size), painter: _LogoMarkPainter(tone));
    if (!showWordmark) return Semantics(label: 'CreditSea', child: mark);

    final wordmark = Text.rich(
      const TextSpan(
        children: [
          TextSpan(text: 'Credit', style: TextStyle(fontWeight: FontWeight.w500)),
          TextSpan(text: 'Sea', style: TextStyle(fontWeight: FontWeight.w300)),
        ],
      ),
      style: TextStyle(
        color: tone == LogoTone.onDark ? Colors.white : AppColors.primary,
        fontSize: size * (vertical ? 0.9 : 0.85),
        height: 1,
        letterSpacing: -0.4,
      ),
    );

    return Semantics(
      label: 'CreditSea',
      excludeSemantics: true,
      child: vertical
          ? Column(mainAxisSize: MainAxisSize.min, children: [mark, SizedBox(height: size * 0.2), wordmark])
          : Row(mainAxisSize: MainAxisSize.min, children: [mark, SizedBox(width: size * 0.25), wordmark]),
    );
  }
}

class _LogoMarkPainter extends CustomPainter {
  const _LogoMarkPainter(this.tone);

  final LogoTone tone;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final onDark = tone == LogoTone.onDark;

    canvas.drawCircle(Offset(44 * s, 56 * s), 40 * s, Paint()..color = onDark ? Colors.white : AppColors.primary);

    final upper = Path()
      ..moveTo(28 * s, 63 * s)
      ..lineTo(100 * s, 8 * s)
      ..lineTo(61 * s, 50 * s)
      ..close();
    final lower = Path()
      ..moveTo(18 * s, 79 * s)
      ..lineTo(92 * s, 31 * s)
      ..lineTo(55 * s, 67 * s)
      ..close();

    final fill = Paint()..color = AppColors.mint;
    final edge = Paint()
      ..color = onDark ? AppColors.brandBlue : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.4 * s;

    for (final wing in [lower, upper]) {
      canvas
        ..drawPath(wing, fill)
        ..drawPath(wing, edge);
    }
  }

  @override
  bool shouldRepaint(_LogoMarkPainter oldDelegate) => oldDelegate.tone != tone;
}
