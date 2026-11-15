import '../../data/models/loan_quote.dart';

/// Mirrors the backend pricing (backend/src/services/pricing.js) so the calculator
/// updates instantly while the slider moves. The server re-prices on submit.
abstract final class LoanMath {
  static LoanPricing price({
    required int principal,
    required int tenureDays,
    required double interestPerDayPct,
    required double processingFeePct,
  }) {
    final interest = (principal * (interestPerDayPct / 100) * tenureDays).round();
    final processingFee = (principal * (processingFeePct / 100)).round();
    return LoanPricing(
      principal: principal,
      tenureDays: tenureDays,
      interestPerDayPct: interestPerDayPct,
      processingFeePct: processingFeePct,
      interest: interest,
      processingFee: processingFee,
      totalPayable: principal + interest,
      disbursalAmount: principal - processingFee,
    );
  }

  /// Snaps a slider value to the configured step.
  static int snap(double value, int step) => (value / step).round() * step;
}
