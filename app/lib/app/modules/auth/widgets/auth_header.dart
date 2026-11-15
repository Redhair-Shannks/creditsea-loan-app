import '../../../core/material.dart';

/// Card title with an optional back arrow ("← Enter OTP").
class AuthHeader extends StatelessWidget {
  const AuthHeader(this.title, {super.key, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(
            width: 28,
            child: onBack == null
                ? null
                : InkResponse(
                    onTap: onBack,
                    radius: 20,
                    child: const Icon(Icons.arrow_back, size: 22, color: Color(0xFF7A808A), semanticLabel: 'Back'),
                  ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 28),
        ],
      );
}
