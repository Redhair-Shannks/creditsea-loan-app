import 'json.dart';

/// Which sign-up screen comes next. Decided by the backend (`onboardingStep`).
enum OnboardingStep {
  password,
  personal,
  email,
  pan,
  employment,
  complete;

  static OnboardingStep parse(Object? value) => switch (value) {
        'PASSWORD' => OnboardingStep.password,
        'PERSONAL' => OnboardingStep.personal,
        'EMAIL' => OnboardingStep.email,
        'PAN' => OnboardingStep.pan,
        'EMPLOYMENT' => OnboardingStep.employment,
        _ => OnboardingStep.complete,
      };

  String get apiValue => name.toUpperCase();
}

/// Enum shared shape: an API value and a label for the UI.
abstract interface class LabeledOption {
  String get apiValue;
  String get label;
}

enum Gender implements LabeledOption {
  male('MALE', 'Male'),
  female('FEMALE', 'Female'),
  other('OTHER', 'Other');

  const Gender(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;

  static Gender? parse(Object? v) => values.where((e) => e.apiValue == v).firstOrNull;
}

enum MaritalStatus implements LabeledOption {
  single('SINGLE', 'Single'),
  married('MARRIED', 'Married'),
  divorced('DIVORCED', 'Divorced'),
  widowed('WIDOWED', 'Widowed');

  const MaritalStatus(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;

  static MaritalStatus? parse(Object? v) => values.where((e) => e.apiValue == v).firstOrNull;
}

enum EmploymentType implements LabeledOption {
  salaried('SALARIED', 'Salaried'),
  selfEmployed('SELF_EMPLOYED', 'Self-employed'),
  student('STUDENT', 'Student'),
  other('OTHER', 'Other');

  const EmploymentType(this.apiValue, this.label);
  @override
  final String apiValue;
  @override
  final String label;

  static EmploymentType? parse(Object? v) => values.where((e) => e.apiValue == v).firstOrNull;
}

class CreditEvent {
  const CreditEvent({required this.delta, required this.reason, required this.scoreAfter, required this.at});

  factory CreditEvent.fromJson(Json json) => CreditEvent(
        delta: asInt(json['delta']),
        reason: json['reason'] as String? ?? '',
        scoreAfter: asInt(json['scoreAfter']),
        at: asDate(json['at']) ?? DateTime.now(),
      );

  final int delta;
  final String reason;
  final int scoreAfter;
  final DateTime at;

  Json toJson() => {'delta': delta, 'reason': reason, 'scoreAfter': scoreAfter, 'at': at.toIso8601String()};
}

/// The signed-in borrower.
class AppUser {
  const AppUser({
    required this.id,
    required this.phone,
    required this.creditScore,
    required this.onboardingStep,
    this.firstName,
    this.lastName,
    this.gender,
    this.dob,
    this.maritalStatus,
    this.email,
    this.emailVerified = false,
    this.panMasked,
    this.panVerified = false,
    this.employmentType,
    this.monthlyIncome,
    this.creditHistory = const [],
    this.hasPassword = false,
  });

  factory AppUser.fromJson(Json json) => AppUser(
        id: json['id'] as String,
        phone: json['phone'] as String,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        gender: Gender.parse(json['gender']),
        dob: asDate(json['dob']),
        maritalStatus: MaritalStatus.parse(json['maritalStatus']),
        email: json['email'] as String?,
        emailVerified: json['emailVerified'] == true,
        panMasked: json['panMasked'] as String?,
        panVerified: json['panVerified'] == true,
        employmentType: EmploymentType.parse(json['employmentType']),
        monthlyIncome: asIntOrNull(json['monthlyIncome']),
        creditScore: asInt(json['creditScore'], 650),
        creditHistory: asJsonList(json['creditHistory']).map(CreditEvent.fromJson).toList(),
        hasPassword: json['hasPassword'] == true,
        onboardingStep: OnboardingStep.parse(json['onboardingStep']),
      );

  final String id;
  final String phone;
  final String? firstName;
  final String? lastName;
  final Gender? gender;
  final DateTime? dob;
  final MaritalStatus? maritalStatus;
  final String? email;
  final bool emailVerified;
  final String? panMasked;
  final bool panVerified;
  final EmploymentType? employmentType;
  final int? monthlyIncome;
  final int creditScore;
  final List<CreditEvent> creditHistory;
  final bool hasPassword;
  final OnboardingStep onboardingStep;

  String? get fullName {
    final name = [firstName, lastName].whereType<String>().where((s) => s.isNotEmpty).join(' ');
    return name.isEmpty ? null : name;
  }

  String get greetingName => firstName ?? 'there';

  bool get isProfileComplete => onboardingStep == OnboardingStep.complete;

  /// Same score bands as the backend eligibility rules.
  String get creditBand => switch (creditScore) {
        >= 750 => 'Excellent',
        >= 700 => 'Good',
        >= 650 => 'Fair',
        >= 600 => 'Average',
        _ => 'Poor',
      };

  /// Cached locally so the app can open instantly (and offline) on the next launch.
  Json toJson() => {
        'id': id,
        'phone': phone,
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender?.apiValue,
        'dob': dob?.toIso8601String().substring(0, 10),
        'maritalStatus': maritalStatus?.apiValue,
        'email': email,
        'emailVerified': emailVerified,
        'panMasked': panMasked,
        'panVerified': panVerified,
        'employmentType': employmentType?.apiValue,
        'monthlyIncome': monthlyIncome,
        'creditScore': creditScore,
        'creditHistory': creditHistory.map((e) => e.toJson()).toList(),
        'hasPassword': hasPassword,
        'onboardingStep': onboardingStep.apiValue,
      };
}
