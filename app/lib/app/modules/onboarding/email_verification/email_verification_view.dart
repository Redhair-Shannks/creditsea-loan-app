import '../../../core/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/flow_scaffold.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/illustrations.dart';
import '../../../core/widgets/otp_input.dart';
import 'email_verification_controller.dart';

/// Figma "Details" -> "Personal Email ID".
class EmailVerificationView extends GetView<EmailVerificationController> {
  const EmailVerificationView({super.key});

  @override
  Widget build(BuildContext context) => FlowScaffold(
        stage: FlowStage.register,
        title: 'Personal Email ID',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: IconIllustration(icon: Icons.laptop_mac_outlined, accent: Icons.mail_outline_rounded)),
            const SizedBox(height: 24),
            const FieldLabel('Email ID', required: true),
            Obx(
              () => TextField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                onSubmitted: (_) => controller.sendCode(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Enter your email ID',
                  errorText: controller.emailError.value,
                  // Values are read here (inside Obx) so the button rebuilds when they change.
                  suffixIcon: _SendCodeButton(
                    sending: controller.sending.value,
                    sent: controller.codeSent,
                    onSend: controller.sendCode,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const FieldLabel('OTP Verification'),
            Obx(
              () => OtpInput(
                length: controller.codeLength.value,
                controller: controller.codeController,
                enabled: controller.codeSent,
                hasError: controller.codeError.value,
                autofocus: false,
                spacing: 8,
                onCompleted: (_) => controller.submit(),
              ),
            ),
            const SizedBox(height: 10),
            Obx(
              () => Row(
                children: [
                  const Text("Didn't receive it? ", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: controller.codeSent && controller.secondsLeft.value == 0 ? controller.sendCode : null,
                    child: Text(
                      'Resend Code',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: controller.codeSent && controller.secondsLeft.value == 0
                            ? AppColors.primary
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (controller.secondsLeft.value > 0)
                    Text(Fmt.countdown(controller.secondsLeft.value), style: const TextStyle(fontSize: 12)),
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
          ],
        ),
        bottom: Obx(
          () => AppButton(
            label: controller.codeSent ? (controller.isEditing ? 'Verify & Save' : 'Verify') : 'Send OTP',
            loading: controller.busy.value || controller.sending.value,
            onPressed: controller.submit,
          ),
        ),
      );
}

class _SendCodeButton extends StatelessWidget {
  const _SendCodeButton({required this.sending, required this.sent, required this.onSend});

  final bool sending;
  final bool sent;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    if (sending) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return TextButton(onPressed: sent ? null : onSend, child: Text(sent ? 'Sent' : 'Get OTP'));
  }
}
