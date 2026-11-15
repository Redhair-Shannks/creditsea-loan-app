import 'package:get/get.dart';

import 'repayment_controller.dart';

class RepaymentBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => RepaymentController(Get.find(), Get.find(), Get.find()));
}
