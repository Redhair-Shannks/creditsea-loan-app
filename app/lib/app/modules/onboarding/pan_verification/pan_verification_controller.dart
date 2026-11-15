import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/base/api_guard.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/session_service.dart';
import '../onboarding_flow.dart';

/// Figma "Verify PAN Number".
class PanVerificationController extends GetxController with ApiGuard, OnboardingFlow {
  PanVerificationController(this._profile, this.session);

  final ProfileRepository _profile;
  @override
  final SessionService session;

  final formKey = GlobalKey<FormState>();
  final panController = TextEditingController();

  @override
  void onClose() {
    panController.dispose();
    super.onClose();
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    await guard(() async => proceed(await _profile.verifyPan(panController.text.trim().toUpperCase())));
  }
}
