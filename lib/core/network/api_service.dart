import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import '../storage/token_storage.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/leads/models/lead_model.dart';
import '../../features/notes/models/note_model.dart';

// ─── Exception ────────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

// ─── ApiService ───────────────────────────────────────────────────────────────

class ApiService {
  // ── Helpers ────────────────────────────────────────────────────────────────

  static Uri _uri(String path, [Map<String, String>? queryParams]) {
    final base = Uri.parse('${ApiConstants.baseUrl}$path');
    if (queryParams == null || queryParams.isEmpty) return base;
    return base.replace(queryParameters: queryParams);
  }

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
    if (e is SocketException) {
      return ApiException('No internet connection. Please check your network.');
    }
    if (e is TimeoutException) {
      return ApiException('Request timed out. Please try again.');
    }
    return ApiException('Unexpected error: $e');
  }

  // ── HTTP verbs ─────────────────────────────────────────────────────────────

  static Future<http.Response> _get(
    String path, [
    Map<String, String>? q,
  ]) async {
    try {
      return await http
          .get(_uri(path, q), headers: _headers())
          .timeout(ApiConstants.timeout);
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
          .timeout(ApiConstants.timeout);
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
          .timeout(ApiConstants.timeout);
    } catch (e) {
      throw _wrap(e);
    }
  }

  static Future<http.Response> _putRaw(Uri uri) async {
    try {
      return await http
          .put(uri, headers: _headers())
          .timeout(ApiConstants.timeout);
    } catch (e) {
      throw _wrap(e);
    }
  }

  static Future<http.Response> _delete(String path) async {
    try {
      return await http
          .delete(_uri(path), headers: _headers())
          .timeout(ApiConstants.timeout);
    } catch (e) {
      throw _wrap(e);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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

  // ── Multipart upload ───────────────────────────────────────────────────────

  /// POST /api/leads/import  — multipart CSV file upload
  static Future<List<LeadModel>> importLeadsFromFile(String filePath) async {
    try {
      final token = TokenStorage.getToken();
      final req = http.MultipartRequest('POST', _uri(ApiConstants.leadsImport));
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      req.files.add(await http.MultipartFile.fromPath('file', filePath));
      final streamed = await req.send().timeout(ApiConstants.timeout);
      final res = await http.Response.fromStream(streamed);
      _assertOk(res);
      return _extractList(_decode(res), [
        'leads',
        'data',
      ]).map((e) => LeadModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw _wrap(e);
    }
  }

  // ─── AUTH ──────────────────────────────────────────────────────────────────

  /// POST /api/auth/login → { token, user }
  static Future<UserModel> login(String email, String password) async {
    final res = await _post(ApiConstants.login, {
      'email': email,
      'password': password,
    }, auth: false);
    _assertOk(res);
    final body = _decode(res) as Map<String, dynamic>;
    final token = body['token'] as String?;
    if (token != null && token.isNotEmpty) await TokenStorage.saveToken(token);
    return UserModel.fromJson(_extractMap(body, ['user']));
  }

  /// POST /api/auth/register → { token, user }
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
    _assertOk(res);
    final body = _decode(res) as Map<String, dynamic>;
    final token = body['token'] as String?;
    if (token != null && token.isNotEmpty) await TokenStorage.saveToken(token);
    return UserModel.fromJson(_extractMap(body, ['user']));
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

  /// GET /api/user/profile
  static Future<UserModel> getUserProfile() async {
    final res = await _get(ApiConstants.userProfile);
    _assertOk(res);
    return UserModel.fromJson(_extractMap(_decode(res), ['user', 'data']));
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

  /// POST /api/leads
  static Future<LeadModel> createLead(LeadModel lead) async {
    final res = await _post(ApiConstants.leads, lead.toJson());
    _assertOk(res);
    return LeadModel.fromJson(_extractMap(_decode(res), ['lead', 'data']));
  }

  /// DELETE /api/leads/{id}
  static Future<void> deleteLead(String id) async {
    final res = await _delete(ApiConstants.leadById(id));
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

  /// PUT /api/leads/{leadId}/notes?notes=value
  static Future<LeadModel> updateLeadNotes(String leadId, String notes) async {
    final res = await _putRaw(
      _uri(ApiConstants.leadNotes(leadId), {'notes': notes}),
    );
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

  /// Convenience: update both status AND notes for a lead.
  static Future<LeadModel> updateLead(LeadModel lead) async {
    LeadModel updated = lead;
    try {
      updated = await updateLeadStatus(lead.id, lead.status);
    } catch (_) {}
    try {
      updated = await updateLeadNotes(lead.id, lead.notes);
    } catch (_) {}
    return updated;
  }

  // ─── NOTES ─────────────────────────────────────────────────────────────────

  /// POST /api/notes
  static Future<NoteModel> createNote(NoteModel note) async {
    final res = await _post(ApiConstants.notes, note.toJson());
    _assertOk(res);
    return NoteModel.fromJson(_extractMap(_decode(res), ['note', 'data']));
  }

  /// GET /api/notes/{leadId}
  static Future<List<NoteModel>> getNotesByLead(String leadId) async {
    final res = await _get(ApiConstants.notesByLead(leadId));
    _assertOk(res);
    return _extractList(_decode(res), [
      'notes',
      'data',
    ]).map((e) => NoteModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Attempt GET /api/notes/user/{userId}; returns [] if endpoint missing.
  static Future<List<NoteModel>> getNotesForUser(String userId) async {
    try {
      final res = await _get('/api/notes/user/$userId');
      _assertOk(res);
      return _extractList(_decode(res), [
        'notes',
        'data',
      ]).map((e) => NoteModel.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      return [];
    }
  }
}
