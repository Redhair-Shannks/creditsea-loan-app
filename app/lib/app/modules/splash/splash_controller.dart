import 'dart:async';

import 'package:get/get.dart';

import '../../data/services/session_service.dart';

/// Shows the brand while the saved session is restored, then routes the user.
class SplashController extends GetxController {
  SplashController(this._session);

  final SessionService _session;

  static const _minimumSplash = Duration(milliseconds: 1200);

  @override
  void onReady() {
    super.onReady();
    _route();
  }

  Future<void> _route() async {
    final (signedIn, _) = await (_session.restore(), Future<void>.delayed(_minimumSplash)).wait;
    Get.offAllNamed(signedIn ? _session.homeRoute() : _session.signedOutRoute);
  }
}
