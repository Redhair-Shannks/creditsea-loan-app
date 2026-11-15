import '../../../core/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/auth_shell.dart';
import '../../../core/widgets/form_fields.dart';
import '../widgets/auth_header.dart';
import '../widgets/phone_field.dart';
import 'sign_in_controller.dart';

/// Figma "Sign in".
class SignInView extends GetView<SignInController> {
  const SignInView({super.key});

  @override
  Widget build(BuildContext context) => AuthShell(
        initialSlide: 2,
        child: Form(
          key: controller.formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader('Please enter your credentials'),
                const SizedBox(height: 20),
                PhoneField(controller: controller.phoneController, textInputAction: TextInputAction.next),
                const SizedBox(height: 16),
                Obx(
                  () => AppTextField(
                    label: 'Enter password',
                    hint: 'Enter password',
                    controller: controller.passwordController,
                    obscureText: controller.hidePassword.value,
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => controller.signIn(),
                    suffix: IconButton(
                      onPressed: controller.hidePassword.toggle,
                      tooltip: controller.hidePassword.value ? 'Show password' : 'Hide password',
                      icon: Icon(
                        controller.hidePassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: controller.forgotPassword, child: const Text('Forgot password?')),
                ),
                const SizedBox(height: 8),
                Obx(() => AppButton(label: 'Sign In', loading: controller.busy.value, onPressed: controller.signIn)),
                const SizedBox(height: 18),
                Center(
                  child: TextButton(
                    onPressed: controller.createAccount,
                    child: const Text.rich(
                      TextSpan(
                        text: 'New to CreditSea? ',
                        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        children: [
                          TextSpan(text: 'Create an account', style: TextStyle(color: AppColors.brandBlue, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
