import 'package:shared_preferences/shared_preferences.dart';

/// Handles secure (SharedPreferences-based) storage for the JWT token
/// and the current user's ID. This is the only remaining use of local
/// storage after the backend migration — all CRM data lives in PostgreSQL.
class TokenStorageService {
  static const _keyToken = 'jwt_token';
  static const _keyUserId = 'current_user_id';
  static const _keyUserRole = 'current_user_role';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    if (_prefs == null) throw Exception('TokenStorageService not initialized');
    return _prefs!;
  }

  // ─── Token ────────────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    await _instance.setString(_keyToken, token);
  }

  static Future<String?> getToken() async {
    // Ensure prefs loaded (lazy init in case called before explicit init)
    _prefs ??= await SharedPreferences.getInstance();
    return _instance.getString(_keyToken);
  }

  static Future<void> clearToken() async {
    await _instance.remove(_keyToken);
  }

  // ─── Current user session ─────────────────────────────────────────────────

  static Future<void> saveSession({
    required String userId,
    required String role,
  }) async {
    await _instance.setString(_keyUserId, userId);
    await _instance.setString(_keyUserRole, role);
  }

  static String? getSavedUserId() => _instance.getString(_keyUserId);

  static String? getSavedUserRole() => _instance.getString(_keyUserRole);

  static bool isLoggedIn() {
    final token = _instance.getString(_keyToken);
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearSession() async {
    await _instance.remove(_keyToken);
    await _instance.remove(_keyUserId);
    await _instance.remove(_keyUserRole);
  }
}
