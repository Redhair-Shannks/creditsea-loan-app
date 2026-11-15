import 'package:get/get.dart';

/// Navigation helpers.
abstract final class Nav {
  /// Pops the top route or dialog.
  ///
  /// Prefer this to `Get.back()`: in GetX 4, `Get.back()` only closes the snackbar
  /// when one is visible, which would leave the dialog/screen open.
  static void pop<T extends Object?>([T? result]) => Get.key.currentState?.pop<T>(result);
}
