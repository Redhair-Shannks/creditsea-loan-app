import '../models/auth_models.dart';
import '../models/json.dart';
import '../models/user.dart';
import '../providers/api_client.dart';

/// Sign-up / sign-in endpoints (`/auth/*`).
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<OtpChallenge> sendOtp(String phone) async =>
      OtpChallenge.fromJson(await _api.postJson('/auth/otp/send', {'phone': phone}));

  Future<AuthResult> verifyOtp(String phone, String otp) async =>
      AuthResult.fromJson(await _api.postJson('/auth/otp/verify', {'phone': phone, 'otp': otp}));

  Future<AuthResult> login(String phone, String password) async =>
      AuthResult.fromJson(await _api.postJson('/auth/login', {'phone': phone, 'password': password}));

  Future<AppUser> setPassword(String password) async {
    final json = await _api.postJson('/auth/password', {'password': password});
    return AppUser.fromJson(asJson(json['user']));
  }

  /// Slides the session expiry forward and returns the latest profile.
  Future<AuthResult> refresh() async => AuthResult.fromJson(await _api.postJson('/auth/refresh'));

  Future<void> logout() => _api.postJson('/auth/logout');
}
