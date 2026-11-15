import 'package:get/get.dart';

import '../../core/utils/nav.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/user.dart';
import '../../data/services/session_service.dart';
import '../../routes/app_routes.dart';

/// Pass as the route argument to open an onboarding screen from Profile for editing.
enum OnboardingMode { edit }

/// Shared "what happens after Save" logic for the Details screens.
mixin OnboardingFlow on GetxController {
  SessionService get session;

  late final bool isEditing = Get.arguments == OnboardingMode.edit;

  String get primaryActionLabel => isEditing ? 'Save' : 'Continue';

  /// Saves the updated user, then returns to Profile (edit mode) or opens the next sign-up step.
  Future<void> proceed(AppUser user) async {
    await session.updateUser(user);
    if (isEditing) {
      Nav.pop();
      AppSnackbar.success('Saved', 'Your profile has been updated.');
      return;
    }
    final next = session.homeRoute(user);
    if (next == Routes.home) {
      await Get.offAllNamed(next);
    } else {
      await Get.toNamed(next);
    }
  }
}
