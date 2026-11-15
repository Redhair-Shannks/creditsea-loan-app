import 'package:flutter/widgets.dart';

/// Layout breakpoints (logical pixels). Phones < 600 <= tablets (iPad portrait) < 840 <= wide.
abstract final class Breakpoints {
  static const double medium = 600;
  static const double wide = 840;

  static bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= wide;
  static bool isMedium(BuildContext context) => MediaQuery.sizeOf(context).width >= medium;
}

/// Keeps content at a readable width on tablets and desktops, centred horizontally.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 560});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}
