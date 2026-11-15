import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/base/api_guard.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/session_service.dart';
import '../onboarding_flow.dart';

/// Employment type and monthly income. Not a separate Figma frame: it is added (in the
/// same style) because the eligibility rules need income to calculate the loan limit.
class EmploymentDetailsController extends GetxController with ApiGuard, OnboardingFlow {
  EmploymentDetailsController(this._profile, this.session);

  final ProfileRepository _profile;
  @override
  final SessionService session;

  final formKey = GlobalKey<FormState>();
  final employmentType = Rxn<EmploymentType>();
  final incomeController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final user = session.user.value;
    employmentType.value = user?.employmentType;
    if (user?.monthlyIncome != null) incomeController.text = '${user!.monthlyIncome}';
  }

  @override
  void onClose() {
    incomeController.dispose();
    super.onClose();
  }

  String? validateIncome(String? value) {
    final income = int.tryParse(value ?? '');
    if (income == null) return 'Enter your monthly income';
    if (income > 10000000) return 'Enter a realistic monthly income';
    return null;
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    await guard(() async => proceed(
          await _profile.updateEmployment(employmentType.value!, int.parse(incomeController.text)),
        ));
  }
}
