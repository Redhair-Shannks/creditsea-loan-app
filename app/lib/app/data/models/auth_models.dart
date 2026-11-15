import 'json.dart';
import 'user.dart';

/// Response to "send OTP". `devOtp` is only present while the backend runs in demo mode.
class OtpChallenge {
  const OtpChallenge({
    required this.message,
    required this.length,
    required this.expiresInSec,
    required this.resendAfterSec,
    this.devOtp,
  });

  factory OtpChallenge.fromJson(Json json) => OtpChallenge(
        message: json['message'] as String? ?? 'OTP sent',
        length: asInt(json['length'], 4),
        expiresInSec: asInt(json['expiresInSec'], 300),
        resendAfterSec: asInt(json['resendAfterSec'], 30),
        devOtp: json['devOtp'] as String?,
      );

  final String message;
  final int length;
  final int expiresInSec;
  final int resendAfterSec;
  final String? devOtp;
}

/// A signed-in session.
class AuthResult {
  const AuthResult({required this.token, required this.user, this.isNewUser = false});

  factory AuthResult.fromJson(Json json) => AuthResult(
        token: json['token'] as String,
        user: AppUser.fromJson(asJson(json['user'])),
        isNewUser: json['isNewUser'] == true,
      );

  final String token;
  final AppUser user;
  final bool isNewUser;
}
