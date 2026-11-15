import '../material.dart';

/// Full-width button from the design (filled "Request OTP" / outlined "Cancel").
/// While [loading], it shows a spinner and ignores taps.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = outlined ? Theme.of(context).colorScheme.primary : Colors.white;
    final child = loading
        ? SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: color))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );
    // Keep the enabled look while loading (onPressed: no-op) so the button doesn't flash grey.
    final handler = loading ? () {} : onPressed;
    return outlined
        ? OutlinedButton(onPressed: handler, child: child)
        : ElevatedButton(onPressed: handler, child: child);
  }
}
