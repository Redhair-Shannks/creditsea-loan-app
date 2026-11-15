import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../data/services/session_service.dart';
import 'app_routes.dart';

/// Route middleware: screens that need a signed-in user redirect to Sign in otherwise.
class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) =>
      Get.find<SessionService>().isLoggedIn ? null : const RouteSettings(name: Routes.signIn);
}
