import 'package:creditsea_loan_app/app/core/utils/formatters.dart';
import 'package:creditsea_loan_app/app/core/utils/loan_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoanMath.price (mirrors backend pricing)', () {
    test('1% interest per day and a 10% processing fee', () {
      final pricing = LoanMath.price(principal: 30000, tenureDays: 40, interestPerDayPct: 1, processingFeePct: 10);
      expect(pricing.interest, 12000);
      expect(pricing.totalPayable, 42000);
      expect(pricing.processingFee, 3000);
      expect(pricing.disbursalAmount, 27000);
    });

    test('snap rounds slider values to the step', () {
      expect(LoanMath.snap(30499, 1000), 30000);
      expect(LoanMath.snap(30500, 1000), 31000);
    });
  });

  group('Fmt', () {
    test('uses Indian digit grouping', () {
      expect(Fmt.inr(100000), '₹1,00,000');
      expect(Fmt.grouped(1234567), '12,34,567');
    });

    test('formats percents, countdowns and initials', () {
      expect(Fmt.percent(1), '1%');
      expect(Fmt.percent(0.5), '0.5%');
      expect(Fmt.countdown(28), '00:28');
      expect(Fmt.initials('Asha Verma'), 'AV');
      expect(Fmt.initials(null), 'CS');
    });
  });
}
