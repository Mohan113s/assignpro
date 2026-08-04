import 'package:shared_preferences/shared_preferences.dart';

/// Stores and retrieves the JWT token using SharedPreferences.
/// This is the ONLY thing kept locally — all CRM data lives in the backend.
class TokenStorage {
  static const _keyToken = 'auth_jwt_token';
  static const _keyUserId = 'auth_user_id';
  static const _keyRole = 'auth_user_role';

  static SharedPreferences? _prefs;

  // Call once from main() before runApp
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p {
    _prefs ??= throw StateError('TokenStorage.init() not called');
    return _prefs!;
  }

  // ─── Token ────────────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) async =>
      _p.setString(_keyToken, token);

  static String? getToken() => _p.getString(_keyToken);

  static bool isLoggedIn() {
    final t = _p.getString(_keyToken);
    return t != null && t.isNotEmpty;
  }

  // ─── Session ──────────────────────────────────────────────────────────────

  static Future<void> saveSession({
    required String userId,
    required String role,
  }) async {
    await _p.setString(_keyUserId, userId);
    await _p.setString(_keyRole, role);
  }

  static String? getSavedUserId() => _p.getString(_keyUserId);
  static String? getSavedUserRole() => _p.getString(_keyRole);

  // ─── Clear ────────────────────────────────────────────────────────────────

  static Future<void> clear() async {
    await _p.remove(_keyToken);
    await _p.remove(_keyUserId);
    await _p.remove(_keyRole);
  }
}
