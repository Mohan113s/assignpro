import 'package:flutter/foundation.dart';
import '../network/api_service.dart';
import '../storage/token_storage.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/leads/models/lead_model.dart';
import '../../features/notes/models/note_model.dart';
import '../../features/settings/models/app_settings.dart';

class AppProvider extends ChangeNotifier {
  UserModel? _currentUser;
  List<UserModel> _users = [];
  List<LeadModel> _leads = [];
  List<NoteModel> _notes = [];
  AppSettings _settings = AppSettings();
  bool _isLoading = false;

  // ─── Getters ───────────────────────────────────────────────────────────────

  UserModel? get currentUser => _currentUser;
  List<UserModel> get users => _users;
  List<LeadModel> get leads => _leads;
  List<NoteModel> get notes => _notes;
  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  List<UserModel> get regularUsers =>
      _users.where((u) => u.role == UserRole.user).toList();

  List<LeadModel> get myLeads => _currentUser == null
      ? []
      : _leads.where((l) => l.assignedUserId == _currentUser!.id).toList();

  List<LeadModel> get assignedLeads =>
      _leads.where((l) => l.isAssigned).toList();

  List<LeadModel> get unassignedLeads =>
      _leads.where((l) => !l.isAssigned).toList();

  // Dashboard stats
  int get totalLeads => _leads.length;
  int get totalAssignedLeads => assignedLeads.length;
  int get totalUnassignedLeads => unassignedLeads.length;
  int get totalUsers => regularUsers.length;
  int get myPendingLeads => myLeads.where((l) => l.status == 'Pending').length;
  int get myCompletedLeads =>
      myLeads.where((l) => l.status == 'Completed').length;

  // ─── Init ─────────────────────────────────────────────────────────────────

  /// Called once at app startup. Re-hydrates session if a JWT token exists.
  Future<void> initialize() async {
    if (!TokenStorage.isLoggedIn()) return;
    _setLoading(true);
    try {
      _currentUser = await ApiService.getUserProfile();
      await TokenStorage.saveSession(
        userId: _currentUser!.id,
        role: _currentUser!.role.name,
      );
      await _loadDataForRole();
    } on ApiException {
      // Token expired / invalid — clear and force re-login
      await TokenStorage.clear();
      _currentUser = null;
    } catch (_) {
      await TokenStorage.clear();
      _currentUser = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadDataForRole() async {
    if (_currentUser == null) return;

    if (isAdmin) {
      // Admin: all leads + all users (parallel)
      final results = await Future.wait([
        ApiService.getAllLeads(),
        ApiService.getUsers(),
      ]);
      _leads = results[0] as List<LeadModel>;
      _users = results[1] as List<UserModel>;
      _notes = [];
    } else {
      // User: their assigned leads + their notes (parallel)
      final results = await Future.wait([
        ApiService.getMyLeads(),
        ApiService.getNotesForUser(_currentUser!.id),
      ]);
      _leads = results[0] as List<LeadModel>;
      _notes = results[1] as List<NoteModel>;
      _users = [];
    }
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  // ─── AUTH ──────────────────────────────────────────────────────────────────

  /// Returns null on success, or an error message on failure.
  Future<String?> login(String email, String password) async {
    _setLoading(true);
    try {
      _currentUser = await ApiService.login(email, password);
      await TokenStorage.saveSession(
        userId: _currentUser!.id,
        role: _currentUser!.role.name,
      );
      await _loadDataForRole();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Login failed. Please check your connection and try again.';
    } finally {
      _setLoading(false);
    }
  }

  /// Returns null on success, or an error message on failure.
  Future<String?> register({
    required String name,
    required String mobile,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _setLoading(true);
    try {
      _currentUser = await ApiService.register(
        name: name,
        mobile: mobile,
        email: email,
        password: password,
        role: role,
      );
      await TokenStorage.saveSession(
        userId: _currentUser!.id,
        role: _currentUser!.role.name,
      );
      await _loadDataForRole();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Registration failed. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    _currentUser = null;
    _leads = [];
    _notes = [];
    _users = [];
    _settings = AppSettings();
    notifyListeners();
  }

  // ─── USERS ─────────────────────────────────────────────────────────────────

  Future<String?> addUser(UserModel user) async {
    try {
      final created = await ApiService.createUser(user);
      _users = [..._users, created];
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Failed to create user. Please try again.';
    }
  }

  Future<String?> updateUser(UserModel user) async {
    try {
      final updated = await ApiService.updateUser(user);
      _users = _users.map((u) => u.id == updated.id ? updated : u).toList();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Failed to update user. Please try again.';
    }
  }

  Future<void> deleteUser(String userId) async {
    await ApiService.deleteUser(userId);
    _users = _users.where((u) => u.id != userId).toList();
    notifyListeners();
  }

  Future<void> toggleUserStatus(UserModel user) async {
    // Update locally optimistically, backend will confirm
    final toggled = user.copyWith(isActive: !user.isActive);
    await ApiService.updateUser(toggled);
    _users = _users.map((u) => u.id == toggled.id ? toggled : u).toList();
    notifyListeners();
  }

  // ─── LEADS ─────────────────────────────────────────────────────────────────

  /// Import leads from a CSV file path (multipart upload).
  Future<void> importLeads(List<LeadModel> parsedLeads) async {
    // The CSV is parsed on-device; each lead is created individually via bulk.
    // Use assign-bulk or individual POST per lead.
    // Since the backend has POST /api/leads/import as multipart, this method
    // is used when the file-path approach is possible. The screen will call
    // importLeadsFromFile() directly when it has the file path.
    // For the JSON list path (if backend supports), we create each lead:
    for (final lead in parsedLeads) {
      final created = await ApiService.createLead(lead);
      _leads = [..._leads, created];
    }
    notifyListeners();
  }

  Future<int> distributeLeads() async {
    // Reload all leads after distribution (backend handles round-robin)
    _leads = await ApiService.getAllLeads();
    notifyListeners();
    return _leads.length;
  }

  /// Assign multiple leads to a single user via PUT /api/leads/assign-bulk
  Future<void> assignLeadsToUser(List<LeadModel> leads, String userId) async {
    final ids = leads.map((l) => l.id).toList();
    await ApiService.assignLeadsBulk(ids, userId);
    // Reload leads to reflect assignments
    _leads = await ApiService.getAllLeads();
    notifyListeners();
  }

  /// Unassign a lead — set assignedUserId to null via updateLead
  Future<void> unassignLead(LeadModel lead) async {
    // Backend should handle a PUT with null userId or a dedicated endpoint
    final unassigned = lead.copyWith(assignedUserId: null, status: 'Pending');
    await ApiService.updateLead(unassigned);
    _leads = _leads.map((l) => l.id == unassigned.id ? unassigned : l).toList();
    notifyListeners();
  }

  Future<void> updateLead(LeadModel lead) async {
    // Update status and notes separately using the dedicated endpoints
    LeadModel updated = lead;
    try {
      updated = await ApiService.updateLeadStatus(lead.id, lead.status);
    } catch (_) {}
    try {
      updated = await ApiService.updateLeadNotes(lead.id, lead.notes);
    } catch (_) {}
    _leads = _leads.map((l) => l.id == updated.id ? updated : l).toList();
    notifyListeners();
  }

  Future<void> clearAllLeads() async {
    // Delete all leads — cycle through (no bulk-delete endpoint provided)
    for (final lead in List<LeadModel>.from(_leads)) {
      await ApiService.deleteLead(lead.id);
    }
    _leads = [];
    notifyListeners();
  }

  // ─── NOTES ─────────────────────────────────────────────────────────────────

  Future<void> addNote(NoteModel note) async {
    final created = await ApiService.createNote(note);
    _notes = [created, ..._notes];
    notifyListeners();
  }

  Future<void> updateNote(NoteModel note) async {
    // Update in-memory (no dedicated update endpoint listed)
    _notes = _notes.map((n) => n.id == note.id ? note : n).toList();
    notifyListeners();
  }

  Future<void> deleteNote(String noteId) async {
    _notes = _notes.where((n) => n.id != noteId).toList();
    notifyListeners();
  }

  // ─── SETTINGS ──────────────────────────────────────────────────────────────

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings; // local update; extend if backend has endpoint
    notifyListeners();
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  UserModel? getUserById(String id) =>
      _users.where((u) => u.id == id).firstOrNull;

  List<LeadModel> getLeadsForUser(String userId) =>
      _leads.where((l) => l.assignedUserId == userId).toList();

  void refreshCurrentUser() => notifyListeners();
}
