import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/base/api_guard.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/nav.dart';
import '../../data/models/loan.dart';
import '../../data/providers/api_client.dart';
import '../../data/repositories/loan_repository.dart';
import '../../data/services/loan_sync_service.dart';
import '../../data/services/session_service.dart';
import 'widgets/payment_dialogs.dart';

/// Mock UPI repayment (bonus). No real money moves: the backend simulates the
/// payment gateway, and a successful repayment raises the credit score.
class RepaymentController extends GetxController with ApiGuard {
  RepaymentController(this._loans, this._session, this._sync);

  final LoanRepository _loans;
  final SessionService _session;
  final LoanSyncService _sync;

  late final String loanId = Get.arguments as String;

  static const upiHandles = ['@okaxis', '@okhdfcbank', '@oksbi', '@ybl', '@paytm'];

  final loan = Rxn<Loan>();
  final loadError = RxnString();
  final payFull = true.obs;
  final partAmount = 0.obs;

  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final upiController = TextEditingController();

  int get amount => payFull.value ? (loan.value?.outstanding ?? 0) : partAmount.value;

  @override
  void onInit() {
    super.onInit();
    amountController.addListener(() => partAmount.value = int.tryParse(amountController.text) ?? 0);
    fetch();
  }

  @override
  void onClose() {
    amountController.dispose();
    upiController.dispose();
    super.onClose();
  }

  Future<void> fetch() async {
    try {
      loan.value = await _loans.get(loanId);
      loadError.value = null;
    } on ApiException catch (error) {
      loadError.value = error.message;
    }
  }

  String? validateAmount(String? value) {
    if (payFull.value) return null;
    final entered = int.tryParse(value ?? '');
    final outstanding = loan.value?.outstanding ?? 0;
    if (entered == null || entered <= 0) return 'Enter an amount';
    if (entered > outstanding) return 'You only owe ${Fmt.inr(outstanding)}';
    return null;
  }

  /// Fills a common UPI handle after whatever the user typed before the "@".
  void useHandle(String handle) {
    final name = upiController.text.split('@').first.trim();
    upiController.text = '${name.isEmpty ? 'yourname' : name}$handle';
  }

  Future<void> pay() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final payAmount = amount;
    final scoreBefore = _session.user.value?.creditScore;

    await guard(() async {
      Get.dialog<void>(const UpiProcessingDialog(), barrierDismissible: false);
      final RepaymentResult result;
      try {
        // Stand-in for the user approving the collect request in their UPI app.
        await Future<void>.delayed(const Duration(milliseconds: 1800));
        result = await _loans.repay(loanId, amount: payAmount, upiId: upiController.text.trim().toLowerCase());
      } finally {
        Nav.pop(); // close the processing dialog
      }

      loan.value = result.loan;
      await _session.updateUser(result.user);
      _sync.notifyChanged();
      await Get.dialog<void>(
        PaymentSuccessDialog(
          amount: payAmount,
          reference: result.loan.repayments.lastOrNull?.reference ?? '-',
          scoreBefore: scoreBefore,
          scoreAfter: result.user.creditScore,
          loanClosed: result.loan.status == LoanStatus.closed,
        ),
      );
      Nav.pop(true); // back to the status / home screen
    });
  }
}
