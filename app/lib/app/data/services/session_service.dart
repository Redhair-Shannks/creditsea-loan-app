import 'package:get/get.dart';

import '../../core/widgets/app_snackbar.dart';
import '../../routes/app_routes.dart';
import '../models/auth_models.dart';
import '../models/user.dart';
import '../providers/api_client.dart';
import '../repositories/auth_repository.dart';
import 'storage_service.dart';

/// App-wide authentication state, registered once as a permanent [GetxService].
///
/// * keeps the signed-in [user] as an observable, so any `Obx` updates automatically
/// * restores the session on launch (users stay signed in until they log out)
/// * decides which onboarding screen comes next via [homeRoute]
class SessionService extends GetxService {
  SessionService(this._storage, this._api, this._auth);

  final StorageService _storage;
  final ApiClient _api;
  final AuthRepository _auth;

  final Rxn<AppUser> user = Rxn<AppUser>();

  bool _restoring = false;
  bool _signingOut = false;

  bool get isLoggedIn => _storage.token != null;

  /// Where a signed-out user starts: Sign in if they have used the app before, otherwise sign-up.
  String get signedOutRoute => _storage.isReturningUser ? Routes.signIn : Routes.welcome;

  @override
  void onInit() {
    super.onInit();
    final cached = _storage.cachedUser;
    if (isLoggedIn && cached != null) user.value = AppUser.fromJson(cached);
    _api.onUnauthorized = _onSessionExpired;
  }

  /// Saves a new session (after OTP or password sign-in).
  Future<void> start(AuthResult result) async {
    await _storage.saveToken(result.token);
    await updateUser(result.user);
  }

  Future<void> updateUser(AppUser value) async {
    user.value = value;
    await _storage.saveUser(value.toJson());
  }

  /// Called on launch: slides the session expiry forward and refreshes the profile.
  /// When offline, the cached profile is kept so the app still opens.
  Future<bool> restore() async {
    if (!isLoggedIn) return false;
    _restoring = true;
    try {
      await start(await _auth.refresh());
      return true;
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await _clear();
        return false;
      }
      return user.value != null;
    } finally {
      _restoring = false;
    }
  }

  /// The screen a user should see next, based on the backend's `onboardingStep`.
  String homeRoute([AppUser? forUser]) {
    final current = forUser ?? user.value;
    if (current == null) return Routes.welcome;
    return switch (current.onboardingStep) {
      OnboardingStep.password => Routes.createPassword,
      OnboardingStep.personal => Routes.personalDetails,
      OnboardingStep.email => Routes.emailVerification,
      OnboardingStep.pan => Routes.panVerification,
      OnboardingStep.employment => Routes.employmentDetails,
      OnboardingStep.complete => Routes.home,
    };
  }

  Future<void> logout() async {
    try {
      await _auth.logout();
    } on ApiException {
      // The session may already be gone on the server; sign out locally anyway.
    }
    await _clear();
    Get.offAllNamed(Routes.signIn);
  }

  Future<void> _onSessionExpired() async {
    if (_restoring || _signingOut) return;
    _signingOut = true;
    await _clear();
    Get.offAllNamed(Routes.signIn);
    AppSnackbar.info('Session ended', 'Please sign in again.');
    _signingOut = false;
  }

  Future<void> _clear() async {
    user.value = null;
    await _storage.clear();
  }
}
