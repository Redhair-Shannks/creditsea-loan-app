import 'package:get/get.dart';

/// Tells screens that loan data changed elsewhere (applied, a step completed, status moved,
/// repaid). Screens that show loans react with a GetX `ever` worker on [version], so they
/// are fresh when the user comes back, however they navigated.
class LoanSyncService extends GetxService {
  final RxInt version = 0.obs;

  void notifyChanged() => version.value++;
}
