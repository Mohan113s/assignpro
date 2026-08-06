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
  /// JWT is stateless — works on unlimited devices simultaneously.
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
  /// Multiple device login: JWT is stateless — same account works on any device.
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
    } catch (e) {
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
    String? securityKey,
  }) async {
    _setLoading(true);
    try {
      _currentUser = await ApiService.register(
        name: name,
        mobile: mobile,
        email: email,
        password: password,
        role: role,
        securityKey: securityKey,
      );
      await TokenStorage.saveSession(
        userId: _currentUser!.id,
        role: _currentUser!.role.name,
      );
      await _loadDataForRole();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Registration failed. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    // Best-effort server-side logout (doesn't block)
    try {
      await ApiService.logoutOnServer();
    } catch (_) {}
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
    final toggled = user.copyWith(isActive: !user.isActive);
    try {
      await ApiService.toggleUserStatus(user.id, toggled.isActive);
    } catch (_) {
      // Fallback to updateUser if toggle endpoint not available
      await ApiService.updateUser(toggled);
    }
    _users = _users.map((u) => u.id == toggled.id ? toggled : u).toList();
    notifyListeners();
  }

  // ─── LEADS ─────────────────────────────────────────────────────────────────

  /// Import leads from a pre-parsed list (used when multipart upload is done
  /// directly from the screen via [ApiService.importLeadsFromFile]).
  Future<void> importLeads(List<LeadModel> parsedLeads) async {
    for (final lead in parsedLeads) {
      final created = await ApiService.createLead(lead);
      _leads = [..._leads, created];
    }
    notifyListeners();
  }

  /// Reload all leads from the backend (after import).
  Future<int> refreshLeads() async {
    _leads = await ApiService.getAllLeads();
    notifyListeners();
    return _leads.length;
  }

  /// Trigger server-side round-robin lead distribution, then reload.
  Future<int> distributeLeads() async {
    try {
      await ApiService.distributeLeads();
    } catch (_) {
      // If distribution endpoint doesn't exist, just reload
    }
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

  /// Unassign a lead — calls dedicated unassign endpoint
  Future<void> unassignLead(LeadModel lead) async {
    try {
      final updated = await ApiService.unassignLead(lead.id);
      _leads = _leads.map((l) => l.id == updated.id ? updated : l).toList();
    } catch (_) {
      // Fallback: update lead with null assignedUserId
      final unassigned = lead.copyWith(assignedUserId: null, status: 'Pending');
      await ApiService.updateLead(unassigned);
      _leads = _leads
          .map((l) => l.id == unassigned.id ? unassigned : l)
          .toList();
    }
    notifyListeners();
  }

  Future<void> updateLead(LeadModel lead) async {
    // Try dedicated status/notes endpoints first, fall back to full PUT
    LeadModel updated = lead;
    try {
      updated = await ApiService.updateLeadStatus(lead.id, lead.status);
    } catch (_) {}
    try {
      updated = await ApiService.updateLeadNotes(lead.id, lead.notes);
    } catch (_) {
      try {
        updated = await ApiService.updateLead(lead);
      } catch (_) {}
    }
    _leads = _leads.map((l) => l.id == updated.id ? updated : l).toList();
    notifyListeners();
  }

  Future<void> clearAllLeads() async {
    // Use bulk delete endpoint if available, otherwise delete individually
    try {
      await ApiService.deleteAllLeads();
    } catch (_) {
      for (final lead in List<LeadModel>.from(_leads)) {
        try {
          await ApiService.deleteLead(lead.id);
        } catch (_) {}
      }
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
    try {
      final updated = await ApiService.updateNote(note);
      _notes = _notes.map((n) => n.id == updated.id ? updated : n).toList();
    } catch (_) {
      _notes = _notes.map((n) => n.id == note.id ? note : n).toList();
    }
    notifyListeners();
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await ApiService.deleteNote(noteId);
    } catch (_) {}
    _notes = _notes.where((n) => n.id != noteId).toList();
    notifyListeners();
  }

  // ─── SETTINGS ──────────────────────────────────────────────────────────────

  Future<void> updateSettings(AppSettings newSettings) async {
    try {
      _settings = await ApiService.updateSettings(newSettings);
    } catch (_) {
      _settings = newSettings; // Local fallback
    }
    notifyListeners();
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  UserModel? getUserById(String id) =>
      _users.where((u) => u.id == id).firstOrNull;

  List<LeadModel> getLeadsForUser(String userId) =>
      _leads.where((l) => l.assignedUserId == userId).toList();

  void refreshCurrentUser() => notifyListeners();
}
