import '../material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

/// Consistent toast messages built on `Get.snackbar` (no BuildContext needed).
abstract final class AppSnackbar {
  static void success(String title, String message) =>
      _show(title, message, AppColors.success, Icons.check_circle_rounded);

  static void error(String message, {String title = 'Something went wrong'}) =>
      _show(title, message, AppColors.error, Icons.error_rounded);

  static void info(String title, String message) => _show(title, message, AppColors.primary, Icons.info_rounded);

  static void _show(String title, String message, Color color, IconData icon) {
    if (Get.isSnackbarOpen) Get.closeAllSnackbars();
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: AppColors.textPrimary,
      icon: Icon(icon, color: color),
      leftBarIndicatorColor: color,
      margin: const EdgeInsets.all(16),
      borderRadius: 10,
      maxWidth: 520,
      duration: const Duration(seconds: 3),
      boxShadows: const [BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(0, 4))],
    );
  }
}
