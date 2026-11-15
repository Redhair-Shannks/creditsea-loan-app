import '../../core/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/nav.dart';
import '../../data/models/user.dart';
import '../../data/services/session_service.dart';
import '../onboarding/onboarding_flow.dart';

/// "Manage their profile": view details, edit any onboarding section, log out.
class ProfileController extends GetxController {
  ProfileController(this._session);

  final SessionService _session;

  Rxn<AppUser> get user => _session.user;

  /// Opens an onboarding screen in edit mode (it returns here after saving).
  void edit(String route) => Get.toNamed(route, arguments: OnboardingMode.edit);

  Future<void> logout() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need your mobile number and password (or an OTP) to sign in again.'),
        actions: [
          TextButton(onPressed: () => Nav.pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Nav.pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await _session.logout();
  }
}
