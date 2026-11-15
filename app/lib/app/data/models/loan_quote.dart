import 'json.dart';

/// Price breakdown of a loan (same formula as the backend).
class LoanPricing {
  const LoanPricing({
    required this.principal,
    required this.tenureDays,
    required this.interestPerDayPct,
    required this.processingFeePct,
    required this.interest,
    required this.processingFee,
    required this.totalPayable,
    required this.disbursalAmount,
  });

  factory LoanPricing.fromJson(Json json) => LoanPricing(
        principal: asInt(json['principal']),
        tenureDays: asInt(json['tenureDays']),
        interestPerDayPct: asDouble(json['interestPerDayPct']),
        processingFeePct: asDouble(json['processingFeePct']),
        interest: asInt(json['interest']),
        processingFee: asInt(json['processingFee']),
        totalPayable: asInt(json['totalPayable']),
        disbursalAmount: asInt(json['disbursalAmount']),
      );

  final int principal;
  final int tenureDays;
  final double interestPerDayPct;
  final double processingFeePct;
  final int interest;
  final int processingFee;
  final int totalPayable;
  final int disbursalAmount;
}

/// One rule of the eligibility policy and whether the applicant meets it.
class EligibilityCheck {
  const EligibilityCheck({required this.key, required this.label, required this.passed, this.message});

  factory EligibilityCheck.fromJson(Json json) => EligibilityCheck(
        key: json['key'] as String? ?? '',
        label: json['label'] as String? ?? '',
        passed: json['passed'] == true,
        message: json['message'] as String?,
      );

  final String key;
  final String label;
  final bool passed;
  final String? message;
}

/// Result of POST /loans/quote: eligibility plus the offer shown on "Our Offerings".
class LoanAssessment {
  const LoanAssessment({
    required this.eligible,
    required this.checks,
    required this.reasons,
    required this.creditScore,
    required this.creditBand,
    required this.maxEligibleAmount,
    required this.requested,
    required this.amountAdjusted,
    this.offer,
  });

  factory LoanAssessment.fromJson(Json json) => LoanAssessment(
        eligible: json['eligible'] == true,
        checks: asJsonList(json['checks']).map(EligibilityCheck.fromJson).toList(),
        reasons: (json['reasons'] as List? ?? const []).whereType<String>().toList(),
        creditScore: asInt(json['creditScore']),
        creditBand: json['creditBand'] as String? ?? '',
        maxEligibleAmount: asInt(json['maxEligibleAmount']),
        requested: LoanPricing.fromJson(asJson(json['requested'])),
        offer: json['offer'] is Map ? LoanPricing.fromJson(asJson(json['offer'])) : null,
        amountAdjusted: json['amountAdjusted'] == true,
      );

  final bool eligible;
  final List<EligibilityCheck> checks;
  final List<String> reasons;
  final int creditScore;
  final String creditBand;
  final int maxEligibleAmount;
  final LoanPricing requested;
  final LoanPricing? offer;
  final bool amountAdjusted;
}
