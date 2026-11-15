import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/base/api_guard.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/session_service.dart';
import '../../../routes/app_routes.dart';
import '../welcome/welcome_controller.dart';

/// Figma "Sign in": mobile number + password.
class SignInController extends GetxController with ApiGuard {
  SignInController(this._auth, this._session);

  final AuthRepository _auth;
  final SessionService _session;

  final formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final hidePassword = true.obs;

  @override
  void onClose() {
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> signIn() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    await guard(() async {
      final result = await _auth.login(phoneController.text.trim(), passwordController.text);
      await _session.start(result);
      await Get.offAllNamed(_session.homeRoute());
    });
  }

  /// "Forgot password": verify the number with an OTP, then set a new password.
  void forgotPassword() => Get.toNamed(Routes.welcome, arguments: const WelcomeArgs(resetPassword: true));

  void createAccount() => Get.offAllNamed(Routes.welcome);
}
