import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/base/api_guard.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/session_service.dart';
import '../../../routes/app_routes.dart';
import '../create_password/create_password_controller.dart';

class OtpArgs {
  const OtpArgs({required this.phone, required this.challenge, this.resetPassword = false});

  final String phone;
  final OtpChallenge challenge;
  final bool resetPassword;
}

/// Figma "OTP": 4-digit code, resend timer, verification.
class OtpController extends GetxController with ApiGuard {
  OtpController(this._auth, this._session);

  final AuthRepository _auth;
  final SessionService _session;

  late final OtpArgs args = Get.arguments as OtpArgs;

  final codeController = TextEditingController();
  final secondsLeft = 0.obs;
  final devOtp = RxnString();
  final hasError = false.obs;
  Timer? _countdown;

  int get length => args.challenge.length;

  @override
  void onInit() {
    super.onInit();
    _startCountdown(args.challenge);
    codeController.addListener(() {
      if (hasError.value && codeController.text.isNotEmpty) hasError.value = false;
    });
  }

  @override
  void onClose() {
    _countdown?.cancel();
    codeController.dispose();
    super.onClose();
  }

  void _startCountdown(OtpChallenge challenge) {
    devOtp.value = challenge.devOtp;
    secondsLeft.value = challenge.resendAfterSec;
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft.value <= 1) {
        secondsLeft.value = 0;
        timer.cancel();
      } else {
        secondsLeft.value--;
      }
    });
  }

  /// Demo mode only: fills the code returned by the backend (verification then runs automatically).
  void useDevOtp() {
    final code = devOtp.value;
    if (code != null) codeController.text = code;
  }

  Future<void> resend() => guard(() async {
        final challenge = await _auth.sendOtp(args.phone);
        codeController.clear();
        _startCountdown(challenge);
        AppSnackbar.success('OTP sent', challenge.message);
      });

  Future<void> verify() async {
    final code = codeController.text;
    if (code.length != length) {
      hasError.value = true;
      return;
    }
    await guard(
      () async {
        final result = await _auth.verifyOtp(args.phone, code);
        await _session.start(result);
        if (args.resetPassword && result.user.hasPassword) {
          await Get.offAllNamed(Routes.createPassword, arguments: const CreatePasswordArgs(reset: true));
        } else {
          await Get.offAllNamed(_session.homeRoute());
        }
      },
      onError: (error) {
        hasError.value = true;
        codeController.clear();
        AppSnackbar.error(error.message, title: 'Verification failed');
      },
    );
  }
}
