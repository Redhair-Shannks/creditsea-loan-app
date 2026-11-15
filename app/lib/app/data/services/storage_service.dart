import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../models/json.dart';

/// Persists the session token and a copy of the user on the device (GetStorage),
/// which is what keeps people signed in until they log out.
class StorageService extends GetxService {
  StorageService(this._box);

  final GetStorage _box;

  static const _tokenKey = 'auth_token';
  static const _userKey = 'cached_user';
  static const _returningKey = 'returning_user';

  String? get token => _box.read<String>(_tokenKey);

  Future<void> saveToken(String token) async {
    await _box.write(_tokenKey, token);
    await _box.write(_returningKey, true);
  }

  /// True once someone has signed in on this device; logged-out users then land on
  /// "Sign in" instead of "Create an account". Survives logout on purpose.
  bool get isReturningUser => _box.read<bool>(_returningKey) ?? false;

  Json? get cachedUser {
    final raw = _box.read<Object?>(_userKey);
    return raw is Map ? asJson(raw) : null;
  }

  Future<void> saveUser(Json user) => _box.write(_userKey, user);

  Future<void> clear() async {
    await _box.remove(_tokenKey);
    await _box.remove(_userKey);
  }
}
