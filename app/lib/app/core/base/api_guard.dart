import 'package:get/get.dart';

import '../../data/providers/api_client.dart';
import '../widgets/app_snackbar.dart';

/// Shared loading/error handling for controllers that call the API.
///
/// ```dart
/// await guard(() async { ... });   // busy = true while running, errors -> snackbar
/// ```
mixin ApiGuard on GetxController {
  /// True while a guarded call is running; buttons show a spinner via `Obx`.
  final RxBool busy = false.obs;

  Future<void> guard(Future<void> Function() action, {void Function(ApiException error)? onError}) async {
    if (busy.value) return;
    busy.value = true;
    try {
      await action();
    } on ApiException catch (error) {
      if (onError != null) {
        onError(error);
      } else {
        AppSnackbar.error(error.message);
      }
    } finally {
      if (!isClosed) busy.value = false;
    }
  }
}
