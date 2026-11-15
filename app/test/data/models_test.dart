import 'package:creditsea_loan_app/app/data/models/loan.dart';
import 'package:creditsea_loan_app/app/data/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> loanJson({
  String status = 'SUBMITTED',
  Map<String, dynamic> steps = const {},
  List<Map<String, dynamic>> history = const [],
}) =>
    {
      'id': 'l1',
      'applicationNo': 'CS12301',
      'purpose': 'Medical',
      'principal': 30000,
      'tenureDays': 40,
      'interestPerDayPct': 1,
      'processingFeePct': 10,
      'interest': 12000,
      'processingFee': 3000,
      'totalPayable': 42000,
      'disbursalAmount': 27000,
      'status': status,
      'statusHistory': history,
      'rejectionReasons': status == 'REJECTED' ? ['Low bureau score'] : <String>[],
      'steps': steps,
      'amountPaid': 0,
      'outstanding': 42000,
      'repayments': <Object>[],
      'createdAt': '2026-11-15T10:00:00.000Z',
    };

List<TrackerState> states(Loan loan) => loan.timeline.map((s) => s.state).toList();

void main() {
  group('Loan.timeline', () {
    test('a new application: submitted done, review is current', () {
      final loan = Loan.fromJson(loanJson());
      expect(loan.timeline.first.title, 'Application Submitted');
      expect(states(loan).take(3), [TrackerState.done, TrackerState.current, TrackerState.pending]);
      expect(loan.isProcessing, isTrue);
    });

    test('approved: E-KYC is the next action', () {
      final loan = Loan.fromJson(loanJson(status: 'APPROVED'));
      expect(loan.nextVerificationStep, VerificationStep.ekyc);
      expect(loan.timeline[3].title, 'E-KYC');
      expect(loan.timeline[3].state, TrackerState.current);
      expect(loan.isProcessing, isFalse); // waiting for the borrower, not the backend
    });

    test('approved with all steps done is waiting for disbursal', () {
      final loan = Loan.fromJson(loanJson(status: 'APPROVED', steps: {
        'ekycAt': '2026-11-15T10:01:00Z',
        'enachAt': '2026-11-15T10:02:00Z',
        'esignAt': '2026-11-15T10:03:00Z',
      }));
      expect(loan.nextVerificationStep, isNull);
      expect(loan.awaitingDisbursal, isTrue);
      expect(loan.timeline.firstWhere((s) => s.state == TrackerState.current).title, 'Disbursement');
    });

    test('rejected: decision step failed and later steps are hidden', () {
      final loan = Loan.fromJson(loanJson(status: 'REJECTED'));
      expect(loan.timeline.length, 3);
      expect(loan.timeline.last.title, 'Application Rejected');
      expect(loan.timeline.last.state, TrackerState.failed);
      expect(loan.isActive, isFalse);
    });

    test('closed: every step is done', () {
      final loan = Loan.fromJson(loanJson(status: 'CLOSED'));
      expect(states(loan).every((s) => s == TrackerState.done), isTrue);
    });
  });

  group('AppUser', () {
    final json = {
      'id': 'u1',
      'phone': '9876543210',
      'firstName': 'Asha',
      'lastName': 'Verma',
      'gender': 'FEMALE',
      'dob': '1995-04-12',
      'maritalStatus': 'SINGLE',
      'email': 'asha@example.com',
      'emailVerified': true,
      'panMasked': 'AB******4F',
      'panVerified': true,
      'employmentType': 'SALARIED',
      'monthlyIncome': 60000,
      'creditScore': 685,
      'creditHistory': [
        {'delta': 30, 'reason': 'Loan repaid on time', 'scoreAfter': 685, 'at': '2026-11-15T10:00:00Z'},
      ],
      'hasPassword': true,
      'onboardingStep': 'COMPLETE',
    };

    test('parses the API shape and survives a cache round trip', () {
      final user = AppUser.fromJson(json);
      expect(user.fullName, 'Asha Verma');
      expect(user.gender, Gender.female);
      expect(user.employmentType, EmploymentType.salaried);
      expect(user.creditBand, 'Fair');
      expect(user.isProfileComplete, isTrue);

      final copy = AppUser.fromJson(user.toJson());
      expect(copy.dob, user.dob);
      expect(copy.creditHistory.single.delta, 30);
      expect(copy.onboardingStep, OnboardingStep.complete);
    });

    test('unknown onboarding values fall back safely', () {
      expect(OnboardingStep.parse('PAN'), OnboardingStep.pan);
      expect(Gender.parse('UNKNOWN'), isNull);
    });
  });
}
