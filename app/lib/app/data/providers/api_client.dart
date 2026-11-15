import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/config/app_config.dart';
import '../models/json.dart';
import '../services/storage_service.dart';

/// Error raised for any failed API call. `message` is safe to show to the user.
class ApiException implements Exception {
  const ApiException(this.message, {this.code, this.statusCode, this.details});

  final String message;
  final String? code;
  final int? statusCode;
  final Object? details;

  bool get isUnauthorized => statusCode == 401;
  bool get isNetworkError => code == 'NETWORK_ERROR';

  @override
  String toString() => message;
}

/// HTTP client built on GetX's [GetConnect].
///
/// * adds the `Authorization: Bearer <token>` header to every request
/// * unwraps `{ error: { code, message } }` responses into [ApiException]
/// * reports an expired session through [onUnauthorized] so the app can sign out
class ApiClient extends GetConnect {
  ApiClient(this._storage);

  final StorageService _storage;

  /// Set by SessionService: called when the backend rejects the stored token.
  void Function()? onUnauthorized;

  @override
  void onInit() {
    super.onInit();
    httpClient
      ..baseUrl = AppConfig.apiBaseUrl
      ..timeout = AppConfig.requestTimeout
      ..defaultContentType = 'application/json'
      ..addRequestModifier<Object?>((request) {
        final token = _storage.token;
        if (token != null) request.headers['Authorization'] = 'Bearer $token';
        // Browsers forbid setting Content-Length themselves (GetConnect sets it; harmless
        // but noisy "unsafe header" console errors on web).
        if (kIsWeb) request.headers.remove('content-length');
        return request;
      });
  }

  Future<Json> getJson(String path) => _send(() => get<Object?>(path));

  Future<Json> postJson(String path, [Json body = const {}]) => _send(() => post<Object?>(path, body));

  Future<Json> putJson(String path, Json body) => _send(() => put<Object?>(path, body));

  Future<Json> _send(Future<Response<Object?>> Function() request) async {
    final Response<Object?> response;
    try {
      response = await request();
    } catch (_) {
      throw _networkError;
    }

    final status = response.statusCode;
    if (status == null || response.status.connectionError) throw _networkError;

    final body = response.body;
    if (status >= 200 && status < 300) return body is Map ? asJson(body) : <String, dynamic>{};

    final error = body is Map && body['error'] is Map ? asJson(body['error']) : const <String, dynamic>{};
    if (status == 401 && _storage.token != null) onUnauthorized?.call();
    throw ApiException(
      error['message'] as String? ?? 'Something went wrong (HTTP $status). Please try again.',
      code: error['code'] as String?,
      statusCode: status,
      details: error['details'],
    );
  }

  static const _networkError = ApiException(
    'Could not reach CreditSea. Check your internet connection and try again.',
    code: 'NETWORK_ERROR',
  );
}
