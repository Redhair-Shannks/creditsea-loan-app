import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/base/api_guard.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/session_service.dart';

class CreatePasswordArgs {
  const CreatePasswordArgs({this.reset = false});

  final bool reset;
}

/// Figma "Password": create (or reset) the account password.
class CreatePasswordController extends GetxController with ApiGuard {
  CreatePasswordController(this._auth, this._session);

  final AuthRepository _auth;
  final SessionService _session;

  final formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final hidePassword = true.obs;
  final hideConfirm = true.obs;

  late final bool isReset = (Get.arguments is CreatePasswordArgs) && (Get.arguments as CreatePasswordArgs).reset;

  String? validateConfirm(String? value) =>
      value == passwordController.text ? null : 'Passwords do not match';

  @override
  void onClose() {
    passwordController.dispose();
    confirmController.dispose();
    super.onClose();
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    await guard(() async {
      final user = await _auth.setPassword(passwordController.text);
      await _session.updateUser(user);
      if (isReset) AppSnackbar.success('Password updated', 'Use your new password the next time you sign in.');
      await Get.offAllNamed(_session.homeRoute(user));
    });
  }
}
