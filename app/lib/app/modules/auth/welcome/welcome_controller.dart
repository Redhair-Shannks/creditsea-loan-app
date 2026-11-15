import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/base/api_guard.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../routes/app_routes.dart';
import '../otp/otp_controller.dart';

/// Arguments for the Create-an-account screen. `resetPassword` turns it into
/// the first step of "Forgot password" (OTP, then a new password).
class WelcomeArgs {
  const WelcomeArgs({this.resetPassword = false});

  final bool resetPassword;
}

/// Figma "Create an account": mobile number + consent, then request an OTP.
class WelcomeController extends GetxController with ApiGuard {
  WelcomeController(this._auth);

  final AuthRepository _auth;

  final phoneController = TextEditingController();
  final phone = ''.obs;
  final agreed = false.obs;

  late final bool isPasswordReset = (Get.arguments is WelcomeArgs) && (Get.arguments as WelcomeArgs).resetPassword;

  /// Reactive: the button enables itself as soon as the number is valid and consent is given.
  bool get canSubmit => Validators.isPhone(phone.value) && (agreed.value || isPasswordReset);

  @override
  void onInit() {
    super.onInit();
    phoneController.addListener(() => phone.value = phoneController.text);
  }

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }

  Future<void> requestOtp() async {
    if (!canSubmit) return;
    await guard(() async {
      final challenge = await _auth.sendOtp(phone.value);
      await Get.toNamed(
        Routes.otp,
        arguments: OtpArgs(phone: phone.value, challenge: challenge, resetPassword: isPasswordReset),
      );
    });
  }

  void goToSignIn() => Get.offAllNamed(Routes.signIn);
}
