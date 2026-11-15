import 'package:flutter/foundation.dart';

/// Build-time configuration.
///
/// Point the app at a backend with:
/// `flutter run --dart-define=API_BASE_URL=https://your-api.onrender.com/api/v1`
abstract final class AppConfig {
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
    // Local development defaults. The Android emulator reaches the host machine via 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000/api/v1';
    }
    return 'http://localhost:4000/api/v1';
  }

  /// Generous because free hosting tiers (e.g. Render) can take ~50s to wake up.
  static const Duration requestTimeout = Duration(seconds: 60);

  /// How often the status screen refreshes while the backend is still moving the loan.
  static const Duration statusPollInterval = Duration(seconds: 5);
}
