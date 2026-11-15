import '../models/auth_models.dart';
import '../models/json.dart';
import '../models/user.dart';
import '../providers/api_client.dart';

/// Profile endpoints (`/users/me/*`) used by the onboarding screens and the profile page.
class ProfileRepository {
  ProfileRepository(this._api);

  final ApiClient _api;

  AppUser _user(Json json) => AppUser.fromJson(asJson(json['user']));

  Future<AppUser> me() async => _user(await _api.getJson('/users/me'));

  Future<AppUser> updatePersonalDetails({
    required String firstName,
    required String lastName,
    required Gender gender,
    required DateTime dob,
    required MaritalStatus maritalStatus,
  }) async =>
      _user(await _api.putJson('/users/me/personal', {
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender.apiValue,
        'dob': '${dob.year.toString().padLeft(4, '0')}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}',
        'maritalStatus': maritalStatus.apiValue,
      }));

  Future<OtpChallenge> sendEmailOtp(String email) async =>
      OtpChallenge.fromJson(await _api.postJson('/users/me/email/send-otp', {'email': email}));

  Future<AppUser> verifyEmail(String email, String otp) async =>
      _user(await _api.postJson('/users/me/email/verify', {'email': email, 'otp': otp}));

  Future<AppUser> verifyPan(String pan) async => _user(await _api.postJson('/users/me/pan/verify', {'pan': pan}));

  Future<AppUser> updateEmployment(EmploymentType type, int monthlyIncome) async => _user(
        await _api.putJson('/users/me/employment', {'employmentType': type.apiValue, 'monthlyIncome': monthlyIncome}),
      );
}
