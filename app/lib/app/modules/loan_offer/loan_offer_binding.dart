import 'package:get/get.dart';

import 'loan_offer_controller.dart';

class LoanOfferBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => LoanOfferController(Get.find(), Get.find()));
}
