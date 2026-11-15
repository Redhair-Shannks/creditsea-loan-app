import '../material.dart';

import '../theme/app_colors.dart';

/// Pulsing grey placeholder (the "Details" skeleton frame in Figma).
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = 6});

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 0.45, end: 1).animate(_pulse),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(color: AppColors.skeleton, borderRadius: BorderRadius.circular(widget.radius)),
        ),
      );
}

/// A generic form-shaped skeleton used while a screen loads.
class FormSkeleton extends StatelessWidget {
  const FormSkeleton({super.key, this.rows = 3});

  final int rows;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(width: 140, height: 18),
          const SizedBox(height: 24),
          const Row(
            children: [
              Expanded(child: Skeleton(height: 14)),
              SizedBox(width: 8),
              Expanded(child: Skeleton(height: 14)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(child: Skeleton(height: 44)),
              SizedBox(width: 8),
              Expanded(child: Skeleton(height: 44)),
            ],
          ),
          for (var i = 0; i < rows; i++) ...const [
            SizedBox(height: 20),
            Skeleton(height: 14),
            SizedBox(height: 8),
            Skeleton(height: 44),
          ],
        ],
      );
}
