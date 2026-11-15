import 'dart:async';

import 'package:get/get.dart';

import '../../core/base/api_guard.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/nav.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/loan.dart';
import '../../data/providers/api_client.dart';
import '../../data/repositories/loan_repository.dart';
import '../../data/services/loan_sync_service.dart';
import '../../routes/app_routes.dart';
import 'widgets/verification_sheet.dart';

/// Figma "Application Status".
///
/// While the backend is still moving the loan (review, decision, disbursal) the screen
/// polls every few seconds and announces each status change with an in-app notification.
class LoanStatusController extends GetxController with ApiGuard {
  LoanStatusController(this._loans, this._sync);

  final LoanRepository _loans;
  final LoanSyncService _sync;

  late final String loanId = Get.arguments as String;

  final loan = Rxn<Loan>();
  final loadError = RxnString();
  Timer? _poll;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  @override
  void onClose() {
    _poll?.cancel();
    // Whatever happened while this screen was open, screens underneath should refresh.
    _sync.notifyChanged();
    super.onClose();
  }

  Future<void> fetch({bool silent = false}) async {
    _poll?.cancel();
    try {
      _show(await _loans.get(loanId));
      loadError.value = null;
    } on ApiException catch (error) {
      if (!silent || loan.value == null) loadError.value = error.message;
    }
    if (!isClosed && (loan.value?.isProcessing ?? false)) {
      _poll = Timer(AppConfig.statusPollInterval, () => fetch(silent: true));
    }
  }

  void _show(Loan next) {
    final previous = loan.value?.status;
    loan.value = next;
    if (previous != null && previous != next.status) {
      _announce(next);
      _sync.notifyChanged();
    }
  }

  /// In-app notification for loan updates (bonus feature).
  void _announce(Loan l) {
    switch (l.status) {
      case LoanStatus.underReview:
        AppSnackbar.info('Under review', 'Our credit team has started reviewing your application.');
      case LoanStatus.approved:
        AppSnackbar.success('Loan approved', 'Complete E-KYC, E-NACH and E-Sign to receive the money.');
      case LoanStatus.rejected:
        AppSnackbar.error(l.rejectionReasons.firstOrNull ?? 'Your application was not approved.',
            title: 'Application not approved');
      case LoanStatus.disbursed:
        AppSnackbar.success('Money sent', '${Fmt.inr(l.disbursalAmount)} has been credited to your bank account.');
      case LoanStatus.closed:
        AppSnackbar.success('Loan closed', 'Thank you for repaying your loan.');
      case LoanStatus.submitted:
        break;
    }
  }

  String get actionLabel {
    final l = loan.value;
    if (l == null) return 'Continue';
    final step = l.nextVerificationStep;
    if (step != null) return 'Complete ${step.title}';
    if (l.status == LoanStatus.disbursed) return 'Repay ${Fmt.inr(l.outstanding)}';
    return 'Continue';
  }

  /// The single "Continue" button from the design does the next sensible thing.
  Future<void> onPrimaryAction() async {
    final l = loan.value;
    if (l == null) return;
    final step = l.nextVerificationStep;
    if (step != null) {
      await Get.bottomSheet<void>(
        VerificationSheet(step: step, loan: l, controller: this),
        isScrollControlled: true,
        backgroundColor: Get.theme.bottomSheetTheme.backgroundColor,
        shape: Get.theme.bottomSheetTheme.shape,
      );
      return;
    }
    if (l.status == LoanStatus.disbursed) {
      await Get.toNamed(Routes.repayment, arguments: l.id);
      await fetch();
      return;
    }
    leave();
  }

  /// Back / Continue: return to the dashboard.
  void leave() => (Get.key.currentState?.canPop() ?? false) ? Nav.pop() : Get.offAllNamed(Routes.home);

  // ---- post-approval steps (each returns true on success so the sheet can close)

  Future<bool> submitEkyc(String aadhaarNumber) =>
      _completeStep(() => _loans.completeEkyc(loanId, aadhaarNumber), 'E-KYC completed');

  Future<bool> submitEnach(String accountNumber, String ifsc) => _completeStep(
        () => _loans.completeEnach(loanId, accountNumber: accountNumber, ifsc: ifsc),
        'E-NACH mandate registered',
      );

  Future<bool> submitEsign() => _completeStep(() => _loans.completeEsign(loanId), 'Agreement signed');

  Future<bool> _completeStep(Future<Loan> Function() call, String message) async {
    var ok = false;
    await guard(() async {
      _show(await call());
      ok = true;
    });
    if (ok) {
      _sync.notifyChanged();
      AppSnackbar.success(message, 'Step ${_doneSteps()} of 3 complete.');
      unawaited(fetch(silent: true)); // restarts polling once the disbursal is pending
    }
    return ok;
  }

  int _doneSteps() {
    final steps = loan.value?.steps;
    if (steps == null) return 0;
    return [steps.ekycAt, steps.enachAt, steps.esignAt].where((d) => d != null).length;
  }
}
