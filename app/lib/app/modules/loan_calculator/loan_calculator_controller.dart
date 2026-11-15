import 'package:get/get.dart';

import '../../core/base/api_guard.dart';
import '../../core/utils/loan_math.dart';
import '../../data/models/loan_config.dart';
import '../../data/models/loan_quote.dart';
import '../../data/providers/api_client.dart';
import '../../data/repositories/loan_repository.dart';
import '../../routes/app_routes.dart';
import '../loan_offer/loan_offer_controller.dart';

/// Figma "Loan Calculator" ("Apply for loan").
///
/// The price breakdown is computed locally on every slider move (instant), while a
/// GetX `debounce` worker asks the API for live eligibility once the user stops dragging.
class LoanCalculatorController extends GetxController with ApiGuard {
  LoanCalculatorController(this._loans);

  final LoanRepository _loans;

  static const defaultAmount = 30000;
  static const defaultTenureDays = 40;

  final config = Rxn<LoanConfig>();
  final loadError = RxnString();

  final principal = defaultAmount.obs;
  final tenureDays = defaultTenureDays.obs;
  final purpose = RxnString();
  final purposeError = RxnString();

  /// Live eligibility for the current selection (null while unknown).
  final preview = Rxn<LoanAssessment>();
  final checking = false.obs;

  final List<Worker> _workers = [];

  LoanPricing get pricing {
    final cfg = config.value!;
    return LoanMath.price(
      principal: principal.value,
      tenureDays: tenureDays.value,
      interestPerDayPct: cfg.interestPerDayPct,
      processingFeePct: cfg.processingFeePct,
    );
  }

  @override
  void onInit() {
    super.onInit();
    const wait = Duration(milliseconds: 600);
    _workers
      ..add(debounce<int>(principal, (_) => _refreshPreview(), time: wait))
      ..add(debounce<int>(tenureDays, (_) => _refreshPreview(), time: wait))
      ..add(ever<String?>(purpose, (_) => purposeError.value = null));
    loadConfig();
  }

  @override
  void onClose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    super.onClose();
  }

  Future<void> loadConfig() async {
    loadError.value = null;
    try {
      final cfg = await _loans.config();
      // Only assign when the value really changes: the first assignment to an Rx always
      // notifies listeners, which would trigger the debounce workers (extra API calls).
      final amount = defaultAmount.clamp(cfg.minAmount, cfg.maxAmount);
      final tenure = defaultTenureDays.clamp(cfg.minTenureDays, cfg.maxTenureDays);
      if (principal.value != amount) principal.value = amount;
      if (tenureDays.value != tenure) tenureDays.value = tenure;
      config.value = cfg;
      await _refreshPreview();
    } on ApiException catch (error) {
      loadError.value = error.message;
    }
  }

  Future<void> _refreshPreview() async {
    if (config.value == null) return;
    checking.value = true;
    try {
      preview.value = await _loans.quote(principal: principal.value, tenureDays: tenureDays.value);
    } on ApiException {
      preview.value = null; // the live hint is optional; "Apply" reports real errors
    } finally {
      checking.value = false;
    }
  }

  void onAmountChanged(double value) {
    final cfg = config.value!;
    principal.value = LoanMath.snap(value, cfg.amountStep).clamp(cfg.minAmount, cfg.maxAmount);
  }

  void onTenureChanged(double value) => tenureDays.value = value.round();

  /// "Apply": confirm eligibility with the API, then show "Our Offerings".
  Future<void> apply() async {
    if (purpose.value == null) {
      purposeError.value = 'Select the purpose of the loan';
      return;
    }
    await guard(() async {
      final assessment = await _loans.quote(principal: principal.value, tenureDays: tenureDays.value);
      await Get.toNamed(Routes.loanOffer, arguments: OfferArgs(assessment: assessment, purpose: purpose.value!));
    });
  }
}
