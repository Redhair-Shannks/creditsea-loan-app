import '../../../core/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/nav.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/auth_shell.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/otp_input.dart';
import '../widgets/auth_header.dart';
import 'otp_controller.dart';

/// Figma "OTP".
class OtpView extends GetView<OtpController> {
  const OtpView({super.key});

  @override
  Widget build(BuildContext context) => AuthShell(
        initialSlide: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader('Enter OTP', onBack: () => Nav.pop()),
            const SizedBox(height: 20),
            Text.rich(
              TextSpan(
                text: 'Verify OTP, Sent on ',
                children: [
                  TextSpan(text: Fmt.phone(controller.args.phone), style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Obx(
              () => OtpInput(
                length: controller.length,
                controller: controller.codeController,
                hasError: controller.hasError.value,
                maxBoxSize: 52,
                onCompleted: (_) => controller.verify(),
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => Row(
                children: [
                  if (controller.secondsLeft.value > 0)
                    Text(
                      Fmt.countdown(controller.secondsLeft.value),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    )
                  else ...[
                    const Text("Didn't receive it? ", style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: controller.resend,
                      child: const Text(
                        'Resend OTP',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Obx(() {
              final code = controller.devOtp.value;
              return code == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: DevOtpHint(code: code, onUse: controller.useDevOtp),
                    );
            }),
            const SizedBox(height: 22),
            Obx(() => AppButton(label: 'Verify', loading: controller.busy.value, onPressed: controller.verify)),
          ],
        ),
      );
}
