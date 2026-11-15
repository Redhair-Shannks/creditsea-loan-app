import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/base/api_guard.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/session_service.dart';
import '../onboarding_flow.dart';

/// Figma "Personal Details": name, gender, date of birth, marital status.
class PersonalDetailsController extends GetxController with ApiGuard, OnboardingFlow {
  PersonalDetailsController(this._profile, this.session);

  final ProfileRepository _profile;
  @override
  final SessionService session;

  final formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final gender = Rxn<Gender>();
  final dob = Rxn<DateTime>();
  final maritalStatus = Rxn<MaritalStatus>();

  /// Applicants must be at least 18 (the loan policy itself needs 21-60).
  DateTime get latestDob {
    final now = DateTime.now();
    return DateTime(now.year - 18, now.month, now.day);
  }

  DateTime get earliestDob => DateTime(DateTime.now().year - 100);

  @override
  void onInit() {
    super.onInit();
    final user = session.user.value;
    if (user != null) {
      firstNameController.text = user.firstName ?? '';
      lastNameController.text = user.lastName ?? '';
      gender.value = user.gender;
      dob.value = user.dob;
      maritalStatus.value = user.maritalStatus;
    }
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    super.onClose();
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    await guard(() async {
      final user = await _profile.updatePersonalDetails(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        gender: gender.value!,
        dob: dob.value!,
        maritalStatus: maritalStatus.value!,
      );
      await proceed(user);
    });
  }
}
