import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import '../storage/token_storage.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/leads/models/lead_model.dart';
import '../../features/notes/models/note_model.dart';
import '../../features/settings/models/app_settings.dart';

// ─── Exception ────────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

// ─── ApiService ───────────────────────────────────────────────────────────────
/// Single, canonical API service for the entire AssignPro application.
/// Used by Flutter Web, Flutter Android, and GitHub Pages — ALL point to the
/// same Render backend via [ApiConstants.baseUrl].
///
/// Authentication: JWT stored in SharedPreferences via [TokenStorage].
/// Multiple device login is FULLY supported — JWT is stateless.

class ApiService {
  // ── URI builder ────────────────────────────────────────────────────────────

  static Uri _uri(String path, [Map<String, String>? queryParams]) {
    final base = Uri.parse('${ApiConstants.baseUrl}$path');
    if (queryParams == null || queryParams.isEmpty) return base;
    return base.replace(queryParameters: queryParams);
  }

  // ── Headers ────────────────────────────────────────────────────────────────

  static Map<String, String> _headers({bool includeAuth = true}) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (includeAuth) {
      final token = TokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        h['Authorization'] = 'Bearer $token';
      }
    }
    return h;
  }

  // ── Response helpers ───────────────────────────────────────────────────────

  static dynamic _decode(http.Response res) {
    if (res.body.isEmpty) return null;
    try {
      return jsonDecode(res.body);
    } catch (_) {
      return null;
    }
  }

  static void _assertOk(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    final body = _decode(res);
    String msg;
    if (body is Map) {
      msg = (body['message'] ?? body['error'] ?? '').toString();
    } else {
      msg = body?.toString() ?? '';
    }
    if (msg.isEmpty) msg = 'Server error (${res.statusCode})';
    throw ApiException(msg, statusCode: res.statusCode);
  }

  static ApiException _wrap(dynamic e) {
    if (e is ApiException) return e;
    if (!kIsWeb && e is SocketException) {
      return ApiException('No internet connection. Please check your network.');
    }
    if (e is TimeoutException) {
      return ApiException('Request timed out. Please try again.');
    }
    return ApiException('Unexpected error: $e');
  }

  static List<dynamic> _extractList(dynamic body, List<String> keys) {
    if (body is List) return body;
    if (body is Map) {
      for (final k in keys) {
        if (body[k] is List) return body[k] as List;
      }
    }
    return [];
  }

  static Map<String, dynamic> _extractMap(dynamic body, List<String> keys) {
    if (body is Map<String, dynamic>) {
      for (final k in keys) {
        if (body[k] is Map<String, dynamic>) {
          return body[k] as Map<String, dynamic>;
        }
      }
      return body;
    }
    return {};
  }

  // ── HTTP verbs ─────────────────────────────────────────────────────────────

  static Future<http.Response> _get(
    String path, [
    Map<String, String>? q,
  ]) async {
    try {
      return await http
          .get(_uri(path, q), headers: _headers())
          .timeout(ApiConstants.receiveTimeout);
    } catch (e) {
      throw _wrap(e);
    }
  }

  static Future<http.Response> _post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      return await http
          .post(
            _uri(path),
            headers: _headers(includeAuth: auth),
            body: jsonEncode(body),
          )
          .timeout(ApiConstants.receiveTimeout);
    } catch (e) {
      throw _wrap(e);
    }
  }

  static Future<http.Response> _put(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      return await http
          .put(_uri(path), headers: _headers(), body: jsonEncode(body))
          .timeout(ApiConstants.receiveTimeout);
    } catch (e) {
      throw _wrap(e);
    }
  }

  static Future<http.Response> _putRaw(Uri uri) async {
    try {
      return await http
          .put(uri, headers: _headers())
          .timeout(ApiConstants.receiveTimeout);
    } catch (e) {
      throw _wrap(e);
    }
  }

  static Future<http.Response> _patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      return await http
          .patch(_uri(path), headers: _headers(), body: jsonEncode(body))
          .timeout(ApiConstants.receiveTimeout);
    } catch (e) {
      throw _wrap(e);
    }
  }

  static Future<http.Response> _delete(String path) async {
    try {
      return await http
          .delete(_uri(path), headers: _headers())
          .timeout(ApiConstants.receiveTimeout);
    } catch (e) {
      throw _wrap(e);
    }
  }

  // ── Multipart upload ───────────────────────────────────────────────────────

  /// POST /api/leads/import — multipart file upload (CSV or Excel).
  /// Supports both .csv and .xlsx files.
  /// Returns an import summary map with keys:
  ///   totalRecords, imported, duplicates, failed, invalid
  static Future<Map<String, dynamic>> importLeadsFromFile(
    String filePath,
  ) async {
    try {
      final token = TokenStorage.getToken();
      final req = http.MultipartRequest('POST', _uri(ApiConstants.leadsImport));
      if (token != null && token.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $token';
      }
      req.headers['Accept'] = 'application/json';

      req.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamed = await req.send().timeout(ApiConstants.receiveTimeout);
      final res = await http.Response.fromStream(streamed);
      _assertOk(res);

      final body = _decode(res);
      if (body is Map<String, dynamic>) {
        return body;
      }
      // If backend returns a list (older API style), wrap it
      if (body is List) {
        return {
          'totalRecords': body.length,
          'imported': body.length,
          'duplicates': 0,
          'failed': 0,
          'invalid': 0,
          'leads': body,
        };
      }
      return {'imported': 0, 'totalRecords': 0};
    } catch (e) {
      throw _wrap(e);
    }
  }

  /// POST /api/leads/import — multipart upload using raw bytes (Flutter Web).
  /// On web, FilePicker returns bytes instead of a file path.
  static Future<Map<String, dynamic>> importLeadsFromBytes({
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      final token = TokenStorage.getToken();
      final req = http.MultipartRequest('POST', _uri(ApiConstants.leadsImport));
      if (token != null && token.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $token';
      }
      req.headers['Accept'] = 'application/json';

      req.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

      final streamed = await req.send().timeout(ApiConstants.receiveTimeout);
      final res = await http.Response.fromStream(streamed);
      _assertOk(res);

      final body = _decode(res);
      if (body is Map<String, dynamic>) return body;
      if (body is List) {
        return {
          'totalRecords': body.length,
          'imported': body.length,
          'duplicates': 0,
          'failed': 0,
          'invalid': 0,
          'leads': body,
        };
      }
      return {'imported': 0, 'totalRecords': 0};
    } catch (e) {
      throw _wrap(e);
    }
  }

  /// POST /api/leads/import — sends parsed leads as JSON body (fallback).
  /// Used for web where file paths are not available.
  static Future<Map<String, dynamic>> importLeadsFromJson(
    List<Map<String, String>> leads,
  ) async {
    try {
      final res = await _post(ApiConstants.leadsImport, {'leads': leads});
      _assertOk(res);
      final body = _decode(res);
      if (body is Map<String, dynamic>) return body;
      if (body is List) {
        return {
          'totalRecords': body.length,
          'imported': body.length,
          'duplicates': 0,
          'failed': 0,
          'invalid': 0,
        };
      }
      return {'imported': 0, 'totalRecords': 0};
    } catch (e) {
      throw _wrap(e);
    }
  }

  // ─── AUTH ──────────────────────────────────────────────────────────────────

  /// POST /api/auth/login → { token, role, message, user }
  /// Works on unlimited devices simultaneously (JWT is stateless).
  static Future<UserModel> login(String email, String password) async {
    final res = await _post(ApiConstants.login, {
      'email': email,
      'password': password,
    }, auth: false);
    _assertOk(res);
    final body = _decode(res) as Map<String, dynamic>;
    // Check for error message in response body (backend returns 200 with error message)
    final msg = body['message'] as String? ?? '';
    final token = body['token'] as String?;
    if (token == null || token.isEmpty) {
      throw ApiException(
        msg.isNotEmpty ? msg : 'Login failed. Incorrect email or password.',
      );
    }
    await TokenStorage.saveToken(token);
    // User data may be nested under 'user' key or at root level
    final userMap = _extractMap(body, ['user']);
    return UserModel.fromJson(userMap.isNotEmpty ? userMap : body);
  }

  /// POST /api/auth/register → { token, role, message, user }
  /// Backend saves user to AWS PostgreSQL and returns JWT immediately.
  static Future<UserModel> register({
    required String name,
    required String mobile,
    required String email,
    required String password,
    required UserRole role,
    String? securityKey,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'phone': mobile,
      'email': email,
      'password': password,
      'role': role.name.toUpperCase(),
    };
    // Include security key for admin registration
    if (securityKey != null && securityKey.isNotEmpty) {
      payload['securityKey'] = securityKey;
    }
    final res = await _post(ApiConstants.register, payload, auth: false);
    _assertOk(res);
    final body = _decode(res) as Map<String, dynamic>;
    // Check for error message in response body
    final msg = body['message'] as String? ?? '';
    final token = body['token'] as String?;
    if (token == null || token.isEmpty) {
      // Backend returned an error (e.g., email already exists)
      throw ApiException(
        msg.isNotEmpty
            ? msg
            : 'Registration failed. Please check your details and try again.',
      );
    }
    await TokenStorage.saveToken(token);
    // User data may be nested under 'user' key or at root level
    final userMap = _extractMap(body, ['user']);
    return UserModel.fromJson(userMap.isNotEmpty ? userMap : body);
  }

  /// GET /api/auth/me — fetch current user from token
  static Future<UserModel> getMe() async {
    final res = await _get(ApiConstants.me);
    _assertOk(res);
    final body = _decode(res) as Map<String, dynamic>?;
    return UserModel.fromJson(_extractMap(body ?? {}, ['user']));
  }

  /// Alias for getMe() — used by AppProvider.initialize()
  static Future<UserModel> getUserProfile() => getMe();

  /// POST /api/auth/logout — best-effort server logout
  static Future<void> logoutOnServer() async {
    try {
      await _post(ApiConstants.logout, {});
    } catch (_) {
      // Ignore errors — local token cleared regardless
    }
  }

  // ─── USERS ─────────────────────────────────────────────────────────────────

  /// GET /api/users
  static Future<List<UserModel>> getUsers() async {
    final res = await _get(ApiConstants.users);
    _assertOk(res);
    return _extractList(_decode(res), [
      'users',
      'data',
    ]).map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /api/users
  static Future<UserModel> createUser(UserModel user) async {
    final res = await _post(ApiConstants.users, user.toJson());
    _assertOk(res);
    return UserModel.fromJson(_extractMap(_decode(res), ['user', 'data']));
  }

  /// PUT /api/users/{id}
  static Future<UserModel> updateUser(UserModel user) async {
    final res = await _put(ApiConstants.userById(user.id), user.toJson());
    _assertOk(res);
    return UserModel.fromJson(_extractMap(_decode(res), ['user', 'data']));
  }

  /// DELETE /api/users/{id}
  static Future<void> deleteUser(String userId) async {
    final res = await _delete(ApiConstants.userById(userId));
    _assertOk(res);
  }

  /// PATCH /api/users/{id}/status
  static Future<UserModel> toggleUserStatus(
    String userId,
    bool isActive,
  ) async {
    final res = await _patch(ApiConstants.userToggleStatus(userId), {
      'isActive': isActive,
    });
    _assertOk(res);
    return UserModel.fromJson(_extractMap(_decode(res), ['user', 'data']));
  }

  // ─── DASHBOARD ─────────────────────────────────────────────────────────────

  /// GET /api/dashboard/admin
  static Future<Map<String, dynamic>> getAdminDashboard() async {
    final res = await _get(ApiConstants.adminDashboard);
    _assertOk(res);
    return (_decode(res) as Map<String, dynamic>?) ?? {};
  }

  // ─── LEADS ─────────────────────────────────────────────────────────────────

  /// GET /api/leads
  static Future<List<LeadModel>> getAllLeads() async {
    final res = await _get(ApiConstants.leads);
    _assertOk(res);
    return _extractList(_decode(res), [
      'leads',
      'data',
    ]).map((e) => LeadModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/leads/unassigned
  static Future<List<LeadModel>> getUnassignedLeads() async {
    final res = await _get(ApiConstants.leadsUnassigned);
    _assertOk(res);
    return _extractList(_decode(res), [
      'leads',
      'data',
    ]).map((e) => LeadModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/leads/my-leads
  static Future<List<LeadModel>> getMyLeads() async {
    final res = await _get(ApiConstants.leadsMyLeads);
    _assertOk(res);
    return _extractList(_decode(res), [
      'leads',
      'data',
    ]).map((e) => LeadModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/leads/{id}
  static Future<LeadModel> getLeadById(String id) async {
    final res = await _get(ApiConstants.leadById(id));
    _assertOk(res);
    return LeadModel.fromJson(_extractMap(_decode(res), ['lead', 'data']));
  }

  /// GET /api/leads/user/{userId}
  static Future<List<LeadModel>> getLeadsForUser(String userId) async {
    final res = await _get(ApiConstants.leadsForUser(userId));
    _assertOk(res);
    return _extractList(_decode(res), [
      'leads',
      'data',
    ]).map((e) => LeadModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /api/leads — create a single lead
  static Future<LeadModel> createLead(LeadModel lead) async {
    final res = await _post(ApiConstants.leads, lead.toJson());
    _assertOk(res);
    return LeadModel.fromJson(_extractMap(_decode(res), ['lead', 'data']));
  }

  /// PUT /api/leads/{id}
  static Future<LeadModel> updateLead(LeadModel lead) async {
    final res = await _put(ApiConstants.leadById(lead.id), lead.toJson());
    _assertOk(res);
    return LeadModel.fromJson(_extractMap(_decode(res), ['lead', 'data']));
  }

  /// DELETE /api/leads/{id}
  static Future<void> deleteLead(String id) async {
    final res = await _delete(ApiConstants.leadById(id));
    _assertOk(res);
  }

  /// DELETE /api/leads/all — delete all leads
  static Future<void> deleteAllLeads() async {
    final res = await _delete(ApiConstants.leadsClear);
    _assertOk(res);
  }

  /// PUT /api/leads/{leadId}/assign/{userId}
  static Future<LeadModel> assignLead(String leadId, String userId) async {
    final res = await _put(ApiConstants.leadAssign(leadId, userId), {});
    _assertOk(res);
    return LeadModel.fromJson(_extractMap(_decode(res), ['lead', 'data']));
  }

  /// PUT /api/leads/assign-bulk
  static Future<void> assignLeadsBulk(
    List<String> leadIds,
    String userId,
  ) async {
    final res = await _put(ApiConstants.leadsAssignBulk, {
      'leadIds': leadIds,
      'userId': userId,
    });
    _assertOk(res);
  }

  /// PATCH /api/leads/{id}/assign — assign a lead to a user
  static Future<LeadModel> assignLeadToUser(
    String leadId,
    String userId,
  ) async {
    final res = await _patch(ApiConstants.leadAssignPatch(leadId), {
      'userId': userId,
    });
    _assertOk(res);
    return LeadModel.fromJson(_extractMap(_decode(res), ['lead', 'data']));
  }

  /// PUT /api/leads/{id}/unassign
  static Future<LeadModel> unassignLead(String leadId) async {
    final res = await _put(ApiConstants.leadUnassign(leadId), {});
    _assertOk(res);
    return LeadModel.fromJson(_extractMap(_decode(res), ['lead', 'data']));
  }

  /// PUT /api/leads/{leadId}/status?status=value
  static Future<LeadModel> updateLeadStatus(
    String leadId,
    String status,
  ) async {
    final res = await _putRaw(
      _uri(ApiConstants.leadStatus(leadId), {'status': status}),
    );
    _assertOk(res);
    return LeadModel.fromJson(_extractMap(_decode(res), ['lead', 'data']));
  }

  /// PUT /api/leads/{leadId}/notes?notes=value
  static Future<LeadModel> updateLeadNotes(String leadId, String notes) async {
    final res = await _putRaw(
      _uri(ApiConstants.leadNotes(leadId), {'notes': notes}),
    );
    _assertOk(res);
    return LeadModel.fromJson(_extractMap(_decode(res), ['lead', 'data']));
  }

  /// POST /api/leads/distribute — trigger server-side round-robin distribution
  static Future<int> distributeLeads() async {
    final res = await _post(ApiConstants.leadsDistribute, {});
    _assertOk(res);
    final body = _decode(res);
    if (body is Map) {
      return (body['count'] ?? body['distributed'] ?? 0) as int;
    }
    return 0;
  }

  // ─── NOTES ─────────────────────────────────────────────────────────────────

  /// POST /api/notes
  static Future<NoteModel> createNote(NoteModel note) async {
    final res = await _post(ApiConstants.notes, note.toJson());
    _assertOk(res);
    return NoteModel.fromJson(_extractMap(_decode(res), ['note', 'data']));
  }

  /// GET /api/notes/lead/{leadId}
  static Future<List<NoteModel>> getNotesByLead(String leadId) async {
    final res = await _get(ApiConstants.notesByLead(leadId));
    _assertOk(res);
    return _extractList(_decode(res), [
      'notes',
      'data',
    ]).map((e) => NoteModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/notes/user/{userId}
  static Future<List<NoteModel>> getNotesForUser(String userId) async {
    try {
      final res = await _get(ApiConstants.notesForUser(userId));
      _assertOk(res);
      return _extractList(_decode(res), [
        'notes',
        'data',
      ]).map((e) => NoteModel.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      return [];
    }
  }

  /// PUT /api/notes/{id}
  static Future<NoteModel> updateNote(NoteModel note) async {
    final res = await _put(ApiConstants.noteById(note.id), note.toJson());
    _assertOk(res);
    return NoteModel.fromJson(_extractMap(_decode(res), ['note', 'data']));
  }

  /// DELETE /api/notes/{id}
  static Future<void> deleteNote(String noteId) async {
    final res = await _delete(ApiConstants.noteById(noteId));
    _assertOk(res);
  }

  // ─── SETTINGS ──────────────────────────────────────────────────────────────

  /// GET /api/settings
  static Future<AppSettings> getSettings() async {
    final res = await _get(ApiConstants.settings);
    _assertOk(res);
    return AppSettings.fromJson(
      _extractMap(_decode(res), ['settings', 'data']),
    );
  }

  /// PUT /api/settings
  static Future<AppSettings> updateSettings(AppSettings settings) async {
    final res = await _put(ApiConstants.settings, settings.toJson());
    _assertOk(res);
    return AppSettings.fromJson(
      _extractMap(_decode(res), ['settings', 'data']),
    );
  }
}
