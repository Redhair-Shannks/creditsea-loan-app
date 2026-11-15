import 'json.dart';

/// Loan product settings served by GET /loans/config (slider ranges, rates, purposes).
class LoanConfig {
  const LoanConfig({
    required this.minAmount,
    required this.maxAmount,
    required this.amountStep,
    required this.minTenureDays,
    required this.maxTenureDays,
    required this.interestPerDayPct,
    required this.processingFeePct,
    required this.purposes,
  });

  factory LoanConfig.fromJson(Json json) {
    final product = asJson(json['product']);
    return LoanConfig(
      minAmount: asInt(product['minAmount'], 5000),
      maxAmount: asInt(product['maxAmount'], 100000),
      amountStep: asInt(product['amountStep'], 1000),
      minTenureDays: asInt(product['minTenureDays'], 20),
      maxTenureDays: asInt(product['maxTenureDays'], 45),
      interestPerDayPct: asDouble(product['interestPerDayPct'], 1),
      processingFeePct: asDouble(product['processingFeePct'], 10),
      purposes: (product['purposes'] as List? ?? const []).whereType<String>().toList(),
    );
  }

  final int minAmount;
  final int maxAmount;
  final int amountStep;
  final int minTenureDays;
  final int maxTenureDays;
  final double interestPerDayPct;
  final double processingFeePct;
  final List<String> purposes;
}
