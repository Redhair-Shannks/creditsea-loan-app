import 'package:get/get.dart';

import 'splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // `put` (not lazyPut): the view never reads the controller, but it must start routing.
    Get.put(SplashController(Get.find()));
  }
}
