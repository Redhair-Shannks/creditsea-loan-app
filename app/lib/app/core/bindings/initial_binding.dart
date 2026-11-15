import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../data/providers/api_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/loan_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/services/loan_sync_service.dart';
import '../../data/services/session_service.dart';
import '../../data/services/storage_service.dart';

/// App-wide dependencies, created once at startup and kept alive (`permanent: true`).
/// Screen controllers are created per route by their own bindings.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final storage = Get.put(StorageService(GetStorage()), permanent: true);
    final api = Get.put(ApiClient(storage), permanent: true);

    final auth = Get.put(AuthRepository(api), permanent: true);
    Get.put(ProfileRepository(api), permanent: true);
    Get.put(LoanRepository(api), permanent: true);

    Get.put(SessionService(storage, api, auth), permanent: true);
    Get.put(LoanSyncService(), permanent: true);
  }
}
