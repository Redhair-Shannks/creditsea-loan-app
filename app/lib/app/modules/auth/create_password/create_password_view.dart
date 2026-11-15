import '../../../core/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/auth_shell.dart';
import '../../../core/widgets/form_fields.dart';
import '../widgets/auth_header.dart';
import 'create_password_controller.dart';

/// Figma "Password".
class CreatePasswordView extends GetView<CreatePasswordController> {
  const CreatePasswordView({super.key});

  @override
  Widget build(BuildContext context) => AuthShell(
        initialSlide: 2,
        child: Form(
          key: controller.formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHeader(controller.isReset ? 'Set a new password' : 'Create a password'),
                const SizedBox(height: 20),
                Obx(
                  () => AppTextField(
                    label: 'Enter password',
                    hint: 'Enter password',
                    controller: controller.passwordController,
                    obscureText: controller.hidePassword.value,
                    validator: Validators.password,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.next,
                    suffix: _VisibilityToggle(hidden: controller.hidePassword),
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => AppTextField(
                    label: 'Re enter password',
                    hint: 'Re enter password',
                    controller: controller.confirmController,
                    obscureText: controller.hideConfirm.value,
                    validator: controller.validateConfirm,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => controller.submit(),
                    suffix: _VisibilityToggle(hidden: controller.hideConfirm),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '*your password must include at least 8 characters, inclusive of at least 1 special character',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 22),
                Obx(() => AppButton(label: 'Proceed', loading: controller.busy.value, onPressed: controller.submit)),
              ],
            ),
          ),
        ),
      );
}

/// Eye icon that flips an observable bool.
class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.hidden});

  final RxBool hidden;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: hidden.toggle,
        tooltip: hidden.value ? 'Show password' : 'Hide password',
        icon: Icon(hidden.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20, color: AppColors.textSecondary),
      );
}
