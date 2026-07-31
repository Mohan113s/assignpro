import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/leads/models/lead_model.dart';
import '../../features/notes/models/note_model.dart';
import '../../features/settings/models/app_settings.dart';
import '../constants/app_constants.dart';

class LocalStorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _seedDefaultData();
  }

  static SharedPreferences get _instance {
    if (_prefs == null) throw Exception('LocalStorageService not initialized');
    return _prefs!;
  }

  // ─── SEED ────────────────────────────────────────────────────────────────
  static Future<void> _seedDefaultData() async {
    final users = getUsers();
    if (users.isEmpty) {
      final admin = UserModel(
        name: AppConstants.defaultAdminName,
        email: AppConstants.defaultAdminEmail,
        password: AppConstants.defaultAdminPassword,
        phone: AppConstants.defaultAdminPhone,
        role: UserRole.admin,
      );
      await saveUsers([admin]);
    }
  }

  // ─── USERS ───────────────────────────────────────────────────────────────
  static List<UserModel> getUsers() {
    final raw = _instance.getString(AppConstants.keyUsers);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveUsers(List<UserModel> users) async {
    await _instance.setString(
      AppConstants.keyUsers,
      jsonEncode(users.map((u) => u.toJson()).toList()),
    );
  }

  static Future<void> addUser(UserModel user) async {
    final users = getUsers();
    users.add(user);
    await saveUsers(users);
  }

  static Future<void> updateUser(UserModel updated) async {
    final users = getUsers();
    final idx = users.indexWhere((u) => u.id == updated.id);
    if (idx != -1) {
      users[idx] = updated;
      await saveUsers(users);
    }
  }

  static Future<void> deleteUser(String userId) async {
    final users = getUsers();
    users.removeWhere((u) => u.id == userId);
    await saveUsers(users);
  }

  static UserModel? getUserById(String id) {
    return getUsers().where((u) => u.id == id).firstOrNull;
  }

  static UserModel? getUserByEmail(String email) {
    return getUsers().where((u) => u.email == email).firstOrNull;
  }

  // ─── LEADS ───────────────────────────────────────────────────────────────
  static List<LeadModel> getLeads() {
    final raw = _instance.getString(AppConstants.keyLeads);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => LeadModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveLeads(List<LeadModel> leads) async {
    await _instance.setString(
      AppConstants.keyLeads,
      jsonEncode(leads.map((l) => l.toJson()).toList()),
    );
  }

  static Future<void> addLeads(List<LeadModel> newLeads) async {
    final leads = getLeads();
    leads.addAll(newLeads);
    await saveLeads(leads);
  }

  static Future<void> updateLead(LeadModel updated) async {
    final leads = getLeads();
    final idx = leads.indexWhere((l) => l.id == updated.id);
    if (idx != -1) {
      leads[idx] = updated;
      await saveLeads(leads);
    }
  }

  static Future<void> deleteAllLeads() async {
    await _instance.remove(AppConstants.keyLeads);
  }

  static List<LeadModel> getLeadsForUser(String userId) {
    return getLeads().where((l) => l.assignedUserId == userId).toList();
  }

  static List<LeadModel> getUnassignedLeads() {
    return getLeads().where((l) => !l.isAssigned).toList();
  }

  // ─── AUTO DISTRIBUTION ───────────────────────────────────────────────────
  static Future<int> distributeLeads() async {
    final leads = getLeads();
    final users = getUsers()
        .where((u) => u.role == UserRole.user && u.isActive)
        .toList();

    if (users.isEmpty) return 0;

    // Reset all assignments first
    final unassigned = leads
        .map(
          (l) => LeadModel(
            id: l.id,
            customerName: l.customerName,
            phoneNumber: l.phoneNumber,
            status: 'Pending',
            notes: '',
            createdAt: l.createdAt,
          ),
        )
        .toList();

    // Round-robin distribution
    for (int i = 0; i < unassigned.length; i++) {
      unassigned[i].assignedUserId = users[i % users.length].id;
    }

    await saveLeads(unassigned);
    return unassigned.length;
  }

  // ─── NOTES ───────────────────────────────────────────────────────────────
  static List<NoteModel> getNotesForUser(String userId) {
    final raw = _instance.getString('${AppConstants.keyNotes}_$userId');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => NoteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveNotesForUser(
    String userId,
    List<NoteModel> notes,
  ) async {
    await _instance.setString(
      '${AppConstants.keyNotes}_$userId',
      jsonEncode(notes.map((n) => n.toJson()).toList()),
    );
  }

  static Future<void> addNote(NoteModel note) async {
    final notes = getNotesForUser(note.userId);
    notes.insert(0, note);
    await saveNotesForUser(note.userId, notes);
  }

  static Future<void> updateNote(NoteModel updated) async {
    final notes = getNotesForUser(updated.userId);
    final idx = notes.indexWhere((n) => n.id == updated.id);
    if (idx != -1) {
      notes[idx] = updated;
      await saveNotesForUser(updated.userId, notes);
    }
  }

  static Future<void> deleteNote(String userId, String noteId) async {
    final notes = getNotesForUser(userId);
    notes.removeWhere((n) => n.id == noteId);
    await saveNotesForUser(userId, notes);
  }

  // ─── SETTINGS ────────────────────────────────────────────────────────────
  static AppSettings getSettings() {
    final raw = _instance.getString(AppConstants.keySettings);
    if (raw == null) return AppSettings();
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> saveSettings(AppSettings settings) async {
    await _instance.setString(
      AppConstants.keySettings,
      jsonEncode(settings.toJson()),
    );
  }

  // ─── SESSION ─────────────────────────────────────────────────────────────
  static Future<void> saveCurrentUser(String userId) async {
    await _instance.setString(AppConstants.keyCurrentUser, userId);
    await _instance.setBool(AppConstants.keyIsLoggedIn, true);
  }

  static String? getCurrentUserId() {
    return _instance.getString(AppConstants.keyCurrentUser);
  }

  static bool isLoggedIn() {
    return _instance.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }

  static Future<void> logout() async {
    await _instance.remove(AppConstants.keyCurrentUser);
    await _instance.setBool(AppConstants.keyIsLoggedIn, false);
  }
}
