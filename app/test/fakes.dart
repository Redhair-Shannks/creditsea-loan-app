import 'package:creditsea_loan_app/app/data/models/auth_models.dart';
import 'package:creditsea_loan_app/app/data/models/loan_config.dart';
import 'package:creditsea_loan_app/app/data/models/loan_quote.dart';
import 'package:creditsea_loan_app/app/data/repositories/auth_repository.dart';
import 'package:creditsea_loan_app/app/data/repositories/loan_repository.dart';

/// In-memory stand-ins for the repositories. GetX dependency injection lets tests
/// hand these to controllers instead of the real HTTP-backed versions.
class FakeLoanRepository implements LoanRepository {
  int quoteCalls = 0;
  int limit = 32000;

  static const testConfig = LoanConfig(
    minAmount: 5000,
    maxAmount: 100000,
    amountStep: 1000,
    minTenureDays: 20,
    maxTenureDays: 45,
    interestPerDayPct: 1,
    processingFeePct: 10,
    purposes: ['Personal', 'Medical'],
  );

  @override
  Future<LoanConfig> config() async => testConfig;

  @override
  Future<LoanAssessment> quote({required int principal, required int tenureDays}) async {
    quoteCalls++;
    LoanPricing price(int p) => LoanPricing(
          principal: p,
          tenureDays: tenureDays,
          interestPerDayPct: 1,
          processingFeePct: 10,
          interest: p * tenureDays ~/ 100,
          processingFee: p ~/ 10,
          totalPayable: p + p * tenureDays ~/ 100,
          disbursalAmount: p - p ~/ 10,
        );
    final offered = principal < limit ? principal : limit;
    return LoanAssessment(
      eligible: true,
      checks: const [],
      reasons: const [],
      creditScore: 650,
      creditBand: 'Fair',
      maxEligibleAmount: limit,
      requested: price(principal),
      offer: price(offered),
      amountAdjusted: offered < principal,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthRepository implements AuthRepository {
  final List<String> otpRequests = [];

  @override
  Future<OtpChallenge> sendOtp(String phone) async {
    otpRequests.add(phone);
    return const OtpChallenge(message: 'OTP sent', length: 4, expiresInSec: 300, resendAfterSec: 30, devOtp: '1234');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
