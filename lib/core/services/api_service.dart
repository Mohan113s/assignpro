import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'token_storage_service.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/leads/models/lead_model.dart';
import '../../features/notes/models/note_model.dart';
import '../../features/settings/models/app_settings.dart';

/// Thrown when the server returns a non-2xx status code.
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Central service for all backend REST API calls.
/// All methods throw [ApiException] on failure.
class ApiService {
  // ─── HTTP helpers ──────────────────────────────────────────────────────────

  static Uri _uri(String path) => Uri.parse('${ApiConstants.baseUrl}$path');

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await TokenStorageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Map<String, dynamic> _parseBody(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    } catch (_) {
      return {};
    }
  }

  static void _checkStatus(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    final body = _parseBody(res);
    final msg =
        body['message'] ??
        body['error'] ??
        'Request failed (${res.statusCode})';
    throw ApiException(msg.toString(), statusCode: res.statusCode);
  }

  static Future<http.Response> _get(String path) async {
    try {
      final res = await http
          .get(_uri(path), headers: await _headers())
          .timeout(ApiConstants.receiveTimeout);
      _checkStatus(res);
      return res;
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on HttpException {
      throw ApiException('Could not reach the server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e');
    }
  }

  static Future<http.Response> _post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final res = await http
          .post(
            _uri(path),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(ApiConstants.receiveTimeout);
      _checkStatus(res);
      return res;
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on HttpException {
      throw ApiException('Could not reach the server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e');
    }
  }

  static Future<http.Response> _put(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http
          .put(_uri(path), headers: await _headers(), body: jsonEncode(body))
          .timeout(ApiConstants.receiveTimeout);
      _checkStatus(res);
      return res;
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on HttpException {
      throw ApiException('Could not reach the server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e');
    }
  }

  static Future<http.Response> _patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http
          .patch(_uri(path), headers: await _headers(), body: jsonEncode(body))
          .timeout(ApiConstants.receiveTimeout);
      _checkStatus(res);
      return res;
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on HttpException {
      throw ApiException('Could not reach the server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e');
    }
  }

  static Future<http.Response> _delete(String path) async {
    try {
      final res = await http
          .delete(_uri(path), headers: await _headers())
          .timeout(ApiConstants.receiveTimeout);
      _checkStatus(res);
      return res;
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on HttpException {
      throw ApiException('Could not reach the server.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e');
    }
  }

  // ─── AUTH ──────────────────────────────────────────────────────────────────

  /// Login and return a [UserModel]. Persists the JWT token.
  static Future<UserModel> login(String email, String password) async {
    final res = await _post(ApiConstants.login, {
      'email': email,
      'password': password,
    }, auth: false);
    final body = _parseBody(res);
    // Expecting: { token: '...', user: { ... } }
    final token = body['token'] as String?;
    if (token != null) await TokenStorageService.saveToken(token);

    final userJson = body['user'] as Map<String, dynamic>? ?? body;
    return UserModel.fromJson(userJson);
  }

  /// Register a new user and return the created [UserModel].
  static Future<UserModel> register({
    required String name,
    required String mobile,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final res = await _post(ApiConstants.register, {
      'name': name,
      'phone': mobile,
      'email': email,
      'password': password,
      'role': role.name,
    }, auth: false);
    final body = _parseBody(res);
    // Some backends return token on register too
    final token = body['token'] as String?;
    if (token != null) await TokenStorageService.saveToken(token);

    final userJson = body['user'] as Map<String, dynamic>? ?? body;
    return UserModel.fromJson(userJson);
  }

  /// Fetch the currently authenticated user profile.
  static Future<UserModel> getMe() async {
    final res = await _get(ApiConstants.me);
    final body = _parseBody(res);
    final userJson = body['user'] as Map<String, dynamic>? ?? body;
    return UserModel.fromJson(userJson);
  }

  /// Best-effort server-side logout (invalidates token on server).
  static Future<void> logoutOnServer() async {
    await _post(ApiConstants.logout, {});
  }

  // ─── USERS ─────────────────────────────────────────────────────────────────

  static Future<List<UserModel>> getUsers() async {
    final res = await _get(ApiConstants.users);
    final body = _parseBody(res);
    final list = (body['users'] ?? body['data'] ?? body) as List<dynamic>;
    return list
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<UserModel> createUser(UserModel user) async {
    final res = await _post(ApiConstants.users, user.toJson());
    final body = _parseBody(res);
    final userJson = body['user'] as Map<String, dynamic>? ?? body;
    return UserModel.fromJson(userJson);
  }

  static Future<UserModel> updateUser(UserModel user) async {
    final res = await _put(ApiConstants.userById(user.id), user.toJson());
    final body = _parseBody(res);
    final userJson = body['user'] as Map<String, dynamic>? ?? body;
    return UserModel.fromJson(userJson);
  }

  static Future<void> deleteUser(String userId) async {
    await _delete(ApiConstants.userById(userId));
  }

  static Future<UserModel> toggleUserStatus(
    String userId,
    bool isActive,
  ) async {
    final res = await _patch(ApiConstants.userToggleStatus(userId), {
      'isActive': isActive,
    });
    final body = _parseBody(res);
    final userJson = body['user'] as Map<String, dynamic>? ?? body;
    return UserModel.fromJson(userJson);
  }

  // ─── LEADS ─────────────────────────────────────────────────────────────────

  static Future<List<LeadModel>> getAllLeads() async {
    final res = await _get(ApiConstants.leads);
    final body = _parseBody(res);
    final list = (body['leads'] ?? body['data'] ?? body) as List<dynamic>;
    return list
        .map((e) => LeadModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<LeadModel>> getLeadsForUser(String userId) async {
    final res = await _get(ApiConstants.leadsForUser(userId));
    final body = _parseBody(res);
    final list = (body['leads'] ?? body['data'] ?? body) as List<dynamic>;
    return list
        .map((e) => LeadModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Import a batch of leads (CSV-parsed on client, sent as JSON list).
  static Future<List<LeadModel>> importLeads(List<LeadModel> leads) async {
    final res = await _post(ApiConstants.leadsImport, {
      'leads': leads
          .map(
            (l) => {
              'customerName': l.customerName,
              'phoneNumber': l.phoneNumber,
            },
          )
          .toList(),
    });
    final body = _parseBody(res);
    final list = (body['leads'] ?? body['data'] ?? []) as List<dynamic>;
    return list
        .map((e) => LeadModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Trigger server-side round-robin distribution. Returns distributed count.
  static Future<int> distributeLeads() async {
    final res = await _post(ApiConstants.leadsDistribute, {});
    final body = _parseBody(res);
    return (body['count'] ?? body['distributed'] ?? 0) as int;
  }

  static Future<LeadModel> updateLead(LeadModel lead) async {
    final res = await _put(ApiConstants.leadById(lead.id), lead.toJson());
    final body = _parseBody(res);
    final leadJson = body['lead'] as Map<String, dynamic>? ?? body;
    return LeadModel.fromJson(leadJson);
  }

  static Future<LeadModel> assignLeadToUser(
    String leadId,
    String userId,
  ) async {
    final res = await _patch(ApiConstants.leadAssign(leadId), {
      'userId': userId,
    });
    final body = _parseBody(res);
    final leadJson = body['lead'] as Map<String, dynamic>? ?? body;
    return LeadModel.fromJson(leadJson);
  }

  static Future<LeadModel> unassignLead(String leadId) async {
    final res = await _patch(ApiConstants.leadUnassign(leadId), {});
    final body = _parseBody(res);
    final leadJson = body['lead'] as Map<String, dynamic>? ?? body;
    return LeadModel.fromJson(leadJson);
  }

  static Future<void> deleteAllLeads() async {
    await _delete(ApiConstants.leadsClear);
  }

  // ─── NOTES ─────────────────────────────────────────────────────────────────

  static Future<List<NoteModel>> getNotesForUser(String userId) async {
    final res = await _get(ApiConstants.notesForUser(userId));
    final body = _parseBody(res);
    final list = (body['notes'] ?? body['data'] ?? body) as List<dynamic>;
    return list
        .map((e) => NoteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<NoteModel> createNote(NoteModel note) async {
    final res = await _post(ApiConstants.notes, note.toJson());
    final body = _parseBody(res);
    final noteJson = body['note'] as Map<String, dynamic>? ?? body;
    return NoteModel.fromJson(noteJson);
  }

  static Future<NoteModel> updateNote(NoteModel note) async {
    final res = await _put(ApiConstants.noteById(note.id), note.toJson());
    final body = _parseBody(res);
    final noteJson = body['note'] as Map<String, dynamic>? ?? body;
    return NoteModel.fromJson(noteJson);
  }

  static Future<void> deleteNote(String noteId) async {
    await _delete(ApiConstants.noteById(noteId));
  }

  // ─── SETTINGS ──────────────────────────────────────────────────────────────

  static Future<AppSettings> getSettings() async {
    final res = await _get(ApiConstants.settings);
    final body = _parseBody(res);
    final settingsJson = body['settings'] as Map<String, dynamic>? ?? body;
    return AppSettings.fromJson(settingsJson);
  }

  static Future<AppSettings> updateSettings(AppSettings settings) async {
    final res = await _put(ApiConstants.settings, settings.toJson());
    final body = _parseBody(res);
    final settingsJson = body['settings'] as Map<String, dynamic>? ?? body;
    return AppSettings.fromJson(settingsJson);
  }
}
