import '../../../core/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/flow_scaffold.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/illustrations.dart';
import 'pan_verification_controller.dart';

/// Figma "Details" -> "Verify PAN Number".
class PanVerificationView extends GetView<PanVerificationController> {
  const PanVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final masked = controller.session.user.value?.panMasked;
    return FlowScaffold(
      stage: FlowStage.register,
      title: 'Verify PAN Number',
      body: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: PanCardIllustration()),
            const SizedBox(height: 28),
            AppTextField(
              label: 'Enter Your PAN Number',
              required: true,
              hint: masked ?? 'e.g., ABCPE1234F',
              controller: controller.panController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                UpperCaseTextFormatter(),
                LengthLimitingTextInputFormatter(10),
              ],
              validator: Validators.pan,
              onSubmitted: (_) => controller.submit(),
            ),
            const SizedBox(height: 12),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'We use your PAN to check your credit history. It is stored securely and only ever shown masked.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottom: Obx(
        () => AppButton(
          label: controller.isEditing ? 'Verify & Save' : 'Verify',
          loading: controller.busy.value,
          onPressed: controller.submit,
        ),
      ),
    );
  }
}
