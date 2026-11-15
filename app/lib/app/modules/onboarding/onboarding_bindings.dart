import 'package:get/get.dart';

import 'email_verification/email_verification_controller.dart';
import 'employment_details/employment_details_controller.dart';
import 'pan_verification/pan_verification_controller.dart';
import 'personal_details/personal_details_controller.dart';

/// Route bindings for the sign-up detail screens. Each creates its controller lazily
/// with the repositories registered in InitialBinding.
class PersonalDetailsBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => PersonalDetailsController(Get.find(), Get.find()));
}

class EmailVerificationBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => EmailVerificationController(Get.find(), Get.find()));
}

class PanVerificationBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => PanVerificationController(Get.find(), Get.find()));
}

class EmploymentDetailsBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => EmploymentDetailsController(Get.find(), Get.find()));
}
