import 'json.dart';

/// Backend statuses. Flow: Submitted -> Under review -> Approved / Rejected -> Disbursed -> Closed.
enum LoanStatus {
  submitted('SUBMITTED', 'Submitted'),
  underReview('UNDER_REVIEW', 'Under review'),
  approved('APPROVED', 'Approved'),
  rejected('REJECTED', 'Rejected'),
  disbursed('DISBURSED', 'Disbursed'),
  closed('CLOSED', 'Closed');

  const LoanStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static LoanStatus parse(Object? value) =>
      values.firstWhere((s) => s.apiValue == value, orElse: () => LoanStatus.submitted);
}

/// Post-approval steps from the Figma status screen.
enum VerificationStep {
  ekyc('E-KYC', 'Verify your identity with Aadhaar'),
  enach('E-NACH', 'Set up auto-debit for the repayment'),
  esign('E-Sign', 'Sign the loan agreement');

  const VerificationStep(this.title, this.description);
  final String title;
  final String description;
}

enum TrackerState { done, current, pending, failed }

/// One row of the status tracker.
class TimelineStep {
  const TimelineStep({required this.title, required this.state, this.at});

  final String title;
  final TrackerState state;
  final DateTime? at;

  TimelineStep withState(TrackerState state) => TimelineStep(title: title, state: state, at: at);
}

class StatusEvent {
  const StatusEvent({required this.status, required this.at, this.note});

  factory StatusEvent.fromJson(Json json) => StatusEvent(
        status: LoanStatus.parse(json['status']),
        note: json['note'] as String?,
        at: asDate(json['at']) ?? DateTime.now(),
      );

  final LoanStatus status;
  final String? note;
  final DateTime at;
}

class Repayment {
  const Repayment({required this.amount, required this.reference, required this.paidAt, this.upiId});

  factory Repayment.fromJson(Json json) => Repayment(
        amount: asInt(json['amount']),
        reference: json['reference'] as String? ?? '',
        upiId: json['upiId'] as String?,
        paidAt: asDate(json['paidAt']) ?? DateTime.now(),
      );

  final int amount;
  final String reference;
  final String? upiId;
  final DateTime paidAt;
}

class LoanSteps {
  const LoanSteps({this.ekycAt, this.enachAt, this.esignAt, this.aadhaarMasked, this.bankAccountMasked, this.ifsc});

  factory LoanSteps.fromJson(Json json) => LoanSteps(
        ekycAt: asDate(json['ekycAt']),
        enachAt: asDate(json['enachAt']),
        esignAt: asDate(json['esignAt']),
        aadhaarMasked: json['aadhaarMasked'] as String?,
        bankAccountMasked: json['bankAccountMasked'] as String?,
        ifsc: json['ifsc'] as String?,
      );

  final DateTime? ekycAt;
  final DateTime? enachAt;
  final DateTime? esignAt;
  final String? aadhaarMasked;
  final String? bankAccountMasked;
  final String? ifsc;
}

/// A loan application and everything that happened to it.
class Loan {
  const Loan({
    required this.id,
    required this.applicationNo,
    required this.purpose,
    required this.principal,
    required this.tenureDays,
    required this.interestPerDayPct,
    required this.processingFeePct,
    required this.interest,
    required this.processingFee,
    required this.totalPayable,
    required this.disbursalAmount,
    required this.status,
    required this.statusHistory,
    required this.rejectionReasons,
    required this.steps,
    required this.amountPaid,
    required this.outstanding,
    required this.repayments,
    required this.createdAt,
    this.disbursedAt,
    this.dueDate,
    this.closedAt,
  });

  factory Loan.fromJson(Json json) => Loan(
        id: json['id'] as String,
        applicationNo: json['applicationNo'] as String? ?? '',
        purpose: json['purpose'] as String? ?? '',
        principal: asInt(json['principal']),
        tenureDays: asInt(json['tenureDays']),
        interestPerDayPct: asDouble(json['interestPerDayPct']),
        processingFeePct: asDouble(json['processingFeePct']),
        interest: asInt(json['interest']),
        processingFee: asInt(json['processingFee']),
        totalPayable: asInt(json['totalPayable']),
        disbursalAmount: asInt(json['disbursalAmount']),
        status: LoanStatus.parse(json['status']),
        statusHistory: asJsonList(json['statusHistory']).map(StatusEvent.fromJson).toList(),
        rejectionReasons: (json['rejectionReasons'] as List? ?? const []).whereType<String>().toList(),
        steps: LoanSteps.fromJson(asJson(json['steps'])),
        disbursedAt: asDate(json['disbursedAt']),
        dueDate: asDate(json['dueDate']),
        amountPaid: asInt(json['amountPaid']),
        outstanding: asInt(json['outstanding']),
        repayments: asJsonList(json['repayments']).map(Repayment.fromJson).toList(),
        closedAt: asDate(json['closedAt']),
        createdAt: asDate(json['createdAt']) ?? DateTime.now(),
      );

  final String id;
  final String applicationNo;
  final String purpose;
  final int principal;
  final int tenureDays;
  final double interestPerDayPct;
  final double processingFeePct;
  final int interest;
  final int processingFee;
  final int totalPayable;
  final int disbursalAmount;
  final LoanStatus status;
  final List<StatusEvent> statusHistory;
  final List<String> rejectionReasons;
  final LoanSteps steps;
  final DateTime? disbursedAt;
  final DateTime? dueDate;
  final int amountPaid;
  final int outstanding;
  final List<Repayment> repayments;
  final DateTime? closedAt;
  final DateTime createdAt;

  bool get isActive => switch (status) {
        LoanStatus.submitted || LoanStatus.underReview || LoanStatus.approved || LoanStatus.disbursed => true,
        _ => false,
      };

  /// The borrower's next action after approval (E-KYC, then E-NACH, then E-Sign).
  VerificationStep? get nextVerificationStep {
    if (status != LoanStatus.approved) return null;
    if (steps.ekycAt == null) return VerificationStep.ekyc;
    if (steps.enachAt == null) return VerificationStep.enach;
    if (steps.esignAt == null) return VerificationStep.esign;
    return null;
  }

  bool get awaitingDisbursal => status == LoanStatus.approved && steps.esignAt != null;

  /// True while the backend will move the loan forward on its own, so the app should keep polling.
  bool get isProcessing => status == LoanStatus.submitted || status == LoanStatus.underReview || awaitingDisbursal;

  bool get isOverdue => status == LoanStatus.disbursed && dueDate != null && DateTime.now().isAfter(dueDate!);

  DateTime? timeOf(LoanStatus s) => statusHistory.where((e) => e.status == s).lastOrNull?.at;

  String? get latestNote => statusHistory.lastOrNull?.note;

  /// Status tracker rows: the assignment's flow merged with the Figma steps.
  /// Everything before the first unfinished step is done; that step is "current".
  List<TimelineStep> get timeline {
    final decided = status != LoanStatus.submitted && status != LoanStatus.underReview;
    final rejected = status == LoanStatus.rejected;
    final paidOut = status == LoanStatus.disbursed || status == LoanStatus.closed;

    final rows = <(TimelineStep, bool)>[
      (TimelineStep(title: 'Application Submitted', state: TrackerState.done, at: timeOf(LoanStatus.submitted) ?? createdAt), true),
      (TimelineStep(title: 'Application under Review', state: TrackerState.pending, at: timeOf(LoanStatus.underReview)), decided),
      (
        TimelineStep(
          title: rejected ? 'Application Rejected' : 'Loan Approved',
          state: TrackerState.pending,
          at: timeOf(rejected ? LoanStatus.rejected : LoanStatus.approved),
        ),
        decided && !rejected,
      ),
    ];

    if (!rejected) {
      rows.addAll([
        (TimelineStep(title: 'E-KYC', state: TrackerState.pending, at: steps.ekycAt), steps.ekycAt != null || paidOut),
        (TimelineStep(title: 'E-Nach', state: TrackerState.pending, at: steps.enachAt), steps.enachAt != null || paidOut),
        (TimelineStep(title: 'E-Sign', state: TrackerState.pending, at: steps.esignAt), steps.esignAt != null || paidOut),
        (TimelineStep(title: 'Disbursement', state: TrackerState.pending, at: disbursedAt), paidOut),
        (TimelineStep(title: 'Repayment', state: TrackerState.pending, at: closedAt), status == LoanStatus.closed),
      ]);
    }

    var currentAssigned = false;
    return rows.map((row) {
      final (step, done) = row;
      if (done) return step.withState(TrackerState.done);
      if (rejected && step.title == 'Application Rejected') return step.withState(TrackerState.failed);
      if (!currentAssigned && !rejected) {
        currentAssigned = true;
        return step.withState(TrackerState.current);
      }
      return step.withState(TrackerState.pending);
    }).toList();
  }
}
