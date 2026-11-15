import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/base/api_guard.dart';
import '../../core/utils/nav.dart';
import '../../data/models/loan_quote.dart';
import '../../data/repositories/loan_repository.dart';
import '../../data/services/loan_sync_service.dart';
import '../../routes/app_routes.dart';

class OfferArgs {
  const OfferArgs({required this.assessment, required this.purpose});

  final LoanAssessment assessment;
  final String purpose;
}

/// Figma "Offer" ("Our Offerings"): accept to submit the application.
class LoanOfferController extends GetxController with ApiGuard {
  LoanOfferController(this._loans, this._sync);

  final LoanRepository _loans;
  final LoanSyncService _sync;

  late final OfferArgs args = Get.arguments as OfferArgs;

  LoanAssessment get assessment => args.assessment;

  /// "Accept Offer": submits the application and opens its status tracker
  /// (replacing calculator + offer in the back stack, so Back returns Home).
  Future<void> accept() async {
    final offer = assessment.offer;
    if (offer == null) return;
    await guard(() async {
      final loan = await _loans.apply(principal: offer.principal, tenureDays: offer.tenureDays, purpose: args.purpose);
      _sync.notifyChanged();
      await Get.offNamedUntil(Routes.loanStatus, ModalRoute.withName(Routes.home), arguments: loan.id);
    });
  }

  /// "Modify Offer": back to the calculator to pick another amount or tenure.
  void modify() => Nav.pop();

  void completeProfile() => Get.toNamed(Routes.profile);
}
