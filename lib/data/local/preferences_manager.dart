import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized; override in main()');
});

final preferencesManagerProvider = Provider<PreferencesManager>((ref) {
  return PreferencesManager(ref.watch(sharedPreferencesProvider));
});

class PreferencesManager {
  final SharedPreferences _prefs;

  PreferencesManager(this._prefs);

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';

  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
  }

  Future<void> saveUserId(int id) async {
    await _prefs.setInt(_userIdKey, id);
  }

  int? getUserId() {
    return _prefs.getInt(_userIdKey);
  }
}
