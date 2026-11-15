import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/base/api_guard.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/session_service.dart';
import '../onboarding_flow.dart';

/// Figma "Personal Email ID": enter email, receive a 6-digit code, verify.
class EmailVerificationController extends GetxController with ApiGuard, OnboardingFlow {
  EmailVerificationController(this._profile, this.session);

  final ProfileRepository _profile;
  @override
  final SessionService session;

  final emailController = TextEditingController();
  final codeController = TextEditingController();

  /// Email the current code was sent to ('' = no code yet).
  final sentTo = ''.obs;
  final sending = false.obs;
  final secondsLeft = 0.obs;
  final devOtp = RxnString();
  final codeError = false.obs;
  final emailError = RxnString();
  final codeLength = 6.obs;
  Timer? _countdown;

  bool get codeSent => sentTo.value.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    emailController.text = session.user.value?.email ?? '';
    // Editing the address after a code was sent invalidates that code.
    emailController.addListener(() {
      emailError.value = null;
      if (codeSent && emailController.text.trim().toLowerCase() != sentTo.value) {
        sentTo.value = '';
        codeController.clear();
        devOtp.value = null;
      }
    });
    codeController.addListener(() {
      if (codeError.value && codeController.text.isNotEmpty) codeError.value = false;
    });
  }

  @override
  void onClose() {
    _countdown?.cancel();
    emailController.dispose();
    codeController.dispose();
    super.onClose();
  }

  Future<void> sendCode() async {
    final email = emailController.text.trim().toLowerCase();
    final invalid = Validators.email(email);
    if (invalid != null) {
      emailError.value = invalid;
      return;
    }
    if (sending.value) return;
    sending.value = true;
    try {
      final challenge = await _profile.sendEmailOtp(email);
      sentTo.value = email;
      codeController.clear();
      _startCountdown(challenge);
      AppSnackbar.success('Code sent', challenge.message);
    } on ApiException catch (error) {
      emailError.value = error.message;
    } finally {
      sending.value = false;
    }
  }

  void _startCountdown(OtpChallenge challenge) {
    codeLength.value = challenge.length;
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

  void useDevOtp() {
    final code = devOtp.value;
    if (code != null) codeController.text = code;
  }

  /// Bottom button: sends the code first, then verifies it.
  Future<void> submit() async {
    if (!codeSent) return sendCode();
    if (codeController.text.length != codeLength.value) {
      codeError.value = true;
      return;
    }
    await guard(
      () async => proceed(await _profile.verifyEmail(sentTo.value, codeController.text)),
      onError: (error) {
        codeError.value = true;
        codeController.clear();
        AppSnackbar.error(error.message, title: 'Verification failed');
      },
    );
  }
}
