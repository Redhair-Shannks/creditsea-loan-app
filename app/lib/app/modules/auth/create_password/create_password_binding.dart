import 'package:get/get.dart';

import 'create_password_controller.dart';

class CreatePasswordBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => CreatePasswordController(Get.find(), Get.find()));
}
