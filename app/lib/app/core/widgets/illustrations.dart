import '../material.dart';

import '../theme/app_colors.dart';

/// Lightweight vector illustrations for the onboarding and status screens,
/// built from shapes and Material icons (no image assets to ship).
class IconIllustration extends StatelessWidget {
  const IconIllustration({
    super.key,
    required this.icon,
    this.accent,
    this.color = AppColors.primary,
    this.size = 120,
  });

  final IconData icon;
  final IconData? accent;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size * 1.3,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.08)),
            ),
            Icon(icon, size: size * 0.48, color: color),
            if (accent != null)
              Positioned(
                right: size * 0.12,
                top: size * 0.12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10)],
                  ),
                  child: Icon(accent, size: size * 0.2, color: color),
                ),
              ),
          ],
        ),
      );
}

/// The blue card illustration on the "Verify PAN Number" screen.
class PanCardIllustration extends StatelessWidget {
  const PanCardIllustration({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 170,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              right: 10,
              top: 0,
              child: Container(
                width: 120,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(48),
                ),
              ),
            ),
            Container(
              width: 136,
              height: 86,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _bar(46, 5),
                      const Spacer(),
                      Container(
                        width: 26,
                        height: 14,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(7)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 22,
                    height: 18,
                    decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(3)),
                  ),
                  const Spacer(),
                  Row(children: [for (var i = 0; i < 4; i++) ...[if (i > 0) const SizedBox(width: 6), _bar(22, 6)]]),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _bar(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(3)),
      );
}

/// Gold rupee coin from the "Our Offerings" screen.
class RupeeCoin extends StatelessWidget {
  const RupeeCoin({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.08),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF2A600),
          boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.gold,
            border: Border.all(color: const Color(0xFFFFD45A), width: size * 0.04),
          ),
          child: Icon(Icons.currency_rupee_rounded, color: const Color(0xFFFFF4CF), size: size * 0.5),
        ),
      );
}
