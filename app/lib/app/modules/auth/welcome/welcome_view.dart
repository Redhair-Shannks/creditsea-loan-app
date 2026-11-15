import '../../../core/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nav.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/auth_shell.dart';
import '../widgets/auth_header.dart';
import '../widgets/phone_field.dart';
import 'welcome_controller.dart';

/// Figma "Create an account".
class WelcomeView extends GetView<WelcomeController> {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) => AuthShell(
        initialSlide: 0,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(
                controller.isPasswordReset ? 'Reset your password' : 'Welcome to Credit Sea!',
                onBack: controller.isPasswordReset ? () => Nav.pop() : null,
              ),
              if (controller.isPasswordReset) ...[
                const SizedBox(height: 8),
                const Text(
                  "We'll send an OTP to your registered mobile number.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 20),
              PhoneField(controller: controller.phoneController, onSubmitted: (_) => controller.requestOtp()),
              if (!controller.isPasswordReset) ...[
                const SizedBox(height: 14),
                Obx(() => _ConsentRow(value: controller.agreed.value, onChanged: (v) => controller.agreed.value = v)),
              ],
              const SizedBox(height: 22),
              Obx(
                () => AppButton(
                  label: 'Request OTP',
                  loading: controller.busy.value,
                  onPressed: controller.canSubmit ? controller.requestOtp : null,
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: controller.goToSignIn,
                  child: const Text.rich(
                    TextSpan(
                      text: 'Existing user? ',
                      style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      children: [TextSpan(text: 'Sign in', style: TextStyle(color: AppColors.brandBlue, fontWeight: FontWeight.w700))],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5);
    const link = TextStyle(
      fontSize: 12,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      height: 1.5,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox.square(
          dimension: 24,
          child: Checkbox(value: value, onChanged: (v) => onChanged(v ?? false), visualDensity: VisualDensity.compact),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            children: [
              GestureDetector(onTap: () => onChanged(!value), child: const Text('By continuing, you agree to our ', style: base)),
              GestureDetector(onTap: () => _showPolicy('Privacy policy'), child: const Text('privacy policies', style: link)),
              const Text(' and ', style: base),
              GestureDetector(onTap: () => _showPolicy('Terms & Conditions'), child: const Text('Terms & Conditions.', style: link)),
            ],
          ),
        ),
      ],
    );
  }

  void _showPolicy(String title) => Get.bottomSheet(
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                const Text(
                  'This is a demo build for the CreditSea assignment. In production this sheet would show the '
                  'full document. Your data is only used to evaluate and service your loan application.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      );
}
