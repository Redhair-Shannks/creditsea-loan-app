import 'package:get/get.dart';

import '../../data/models/loan.dart';
import '../../data/models/loan_config.dart';
import '../../data/models/user.dart';
import '../../data/providers/api_client.dart';
import '../../data/repositories/loan_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/services/loan_sync_service.dart';
import '../../data/services/session_service.dart';
import '../../routes/app_routes.dart';

/// Dashboard: credit score, the active loan, pre-approved limit and loan history.
class HomeController extends GetxController {
  HomeController(this._loans, this._profile, this._session, this._sync);

  final LoanRepository _loans;
  final ProfileRepository _profile;
  final SessionService _session;
  final LoanSyncService _sync;
  late final Worker _syncWorker;

  final loans = <Loan>[].obs;
  final loading = true.obs;
  final loadError = RxnString();

  /// Pre-approved limit from the eligibility API (null = unknown, 0 = not eligible right now).
  final limit = RxnInt();
  final config = Rxn<LoanConfig>();

  Rxn<AppUser> get user => _session.user;

  Loan? get activeLoan => loans.where((loan) => loan.isActive).firstOrNull;

  @override
  void onInit() {
    super.onInit();
    // Reload whenever another screen changes a loan (apply, verification steps, repayment).
    _syncWorker = ever<int>(_sync.version, (_) => load());
    load();
  }

  @override
  void onClose() {
    _syncWorker.dispose();
    super.onClose();
  }

  Future<void> load() async {
    loadError.value = null;
    try {
      // Independent requests run in parallel; Future.wait rethrows the first ApiException.
      final results = await Future.wait<Object>([_loans.list(), _profile.me(), _loans.config()]);
      final me = results[1] as AppUser;
      final config = this.config.value = results[2] as LoanConfig;
      loans.assignAll(results[0] as List<Loan>);
      await _session.updateUser(me);

      if (activeLoan == null && me.isProfileComplete) {
        final quote = await _loans.quote(principal: config.maxAmount, tenureDays: config.minTenureDays);
        limit.value = quote.eligible ? quote.maxEligibleAmount : 0;
      } else {
        limit.value = null;
      }
    } on ApiException catch (error) {
      loadError.value = error.message;
    } finally {
      loading.value = false;
    }
  }

  Future<void> openLoan(Loan loan) async {
    await Get.toNamed(Routes.loanStatus, arguments: loan.id);
    await load();
  }

  Future<void> applyForLoan() async {
    await Get.toNamed(Routes.loanCalculator);
    await load();
  }

  Future<void> repay(Loan loan) async {
    await Get.toNamed(Routes.repayment, arguments: loan.id);
    await load();
  }

  Future<void> openProfile() async {
    await Get.toNamed(Routes.profile);
    await load();
  }
}
