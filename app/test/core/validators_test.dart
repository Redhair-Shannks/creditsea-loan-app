import 'package:creditsea_loan_app/app/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators', () {
    test('phone accepts 10-digit Indian mobile numbers only', () {
      expect(Validators.phone('9876543210'), isNull);
      expect(Validators.phone('5876543210'), isNotNull); // must start with 6-9
      expect(Validators.phone('98765'), isNotNull);
    });

    test('password follows the design rule (8+ chars, 1 special)', () {
      expect(Validators.password('Secret@123'), isNull);
      expect(Validators.password('short@1'), 'Use at least 8 characters');
      expect(Validators.password('password1'), 'Include at least 1 special character');
    });

    test('PAN must be a valid personal PAN', () {
      expect(Validators.pan('ABCPE1234F'), isNull);
      expect(Validators.pan('abcpe1234f'), isNull); // case-insensitive input
      expect(Validators.pan('ABCDE1234F'), contains('personal PAN')); // 4th char not P
      expect(Validators.pan('ABC1234'), contains('valid PAN'));
    });

    test('email, UPI, Aadhaar and IFSC', () {
      expect(Validators.email('asha@example.com'), isNull);
      expect(Validators.email('asha@'), isNotNull);
      expect(Validators.upi('asha@okaxis'), isNull);
      expect(Validators.upi('asha'), isNotNull);
      expect(Validators.aadhaar('234567890123'), isNull);
      expect(Validators.aadhaar('123456789012'), isNotNull); // cannot start with 0/1
      expect(Validators.ifsc('HDFC0001234'), isNull);
      expect(Validators.ifsc('HDFC1001234'), isNotNull); // 5th char must be 0
    });
  });
}
