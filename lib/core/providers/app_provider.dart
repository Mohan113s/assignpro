import 'package:flutter/foundation.dart';
import '../services/local_storage_service.dart';
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

  Future<void> initialize() async {
    _setLoading(true);
    await _loadAll();
    _setLoading(false);
  }

  Future<void> _loadAll() async {
    final userId = LocalStorageService.getCurrentUserId();
    if (userId != null) {
      _currentUser = LocalStorageService.getUserById(userId);
    }
    _users = LocalStorageService.getUsers();
    _leads = LocalStorageService.getLeads();
    _settings = LocalStorageService.getSettings();
    if (_currentUser != null) {
      _notes = LocalStorageService.getNotesForUser(_currentUser!.id);
    }
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  // ─── AUTH ─────────────────────────────────────────────────────────────────
  Future<String?> register({
    required String name,
    required String mobile,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final existing = LocalStorageService.getUserByEmail(email);
    if (existing != null) return 'An account with this email already exists.';

    final newUser = UserModel(
      name: name,
      email: email,
      password: password,
      phone: mobile,
      role: role,
    );
    await LocalStorageService.addUser(newUser);
    _users = LocalStorageService.getUsers();
    notifyListeners();
    return null;
  }

  Future<String?> login(String email, String password) async {
    final user = LocalStorageService.getUserByEmail(email);
    if (user == null) return 'No account found with this email.';
    if (user.password != password) return 'Incorrect password.';
    if (!user.isActive) return 'Your account has been deactivated.';

    await LocalStorageService.saveCurrentUser(user.id);
    _currentUser = user;
    _leads = LocalStorageService.getLeads();
    _users = LocalStorageService.getUsers();
    _settings = LocalStorageService.getSettings();
    _notes = LocalStorageService.getNotesForUser(user.id);
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    await LocalStorageService.logout();
    _currentUser = null;
    _leads = [];
    _notes = [];
    notifyListeners();
  }

  // ─── USERS ────────────────────────────────────────────────────────────────
  Future<String?> addUser(UserModel user) async {
    final existing = LocalStorageService.getUserByEmail(user.email);
    if (existing != null) return 'Email already in use.';
    await LocalStorageService.addUser(user);
    _users = LocalStorageService.getUsers();
    notifyListeners();
    return null;
  }

  Future<String?> updateUser(UserModel user) async {
    final existing = LocalStorageService.getUserByEmail(user.email);
    if (existing != null && existing.id != user.id) {
      return 'Email already in use.';
    }
    await LocalStorageService.updateUser(user);
    _users = LocalStorageService.getUsers();
    notifyListeners();
    return null;
  }

  Future<void> deleteUser(String userId) async {
    await LocalStorageService.deleteUser(userId);
    _users = LocalStorageService.getUsers();
    notifyListeners();
  }

  Future<void> toggleUserStatus(UserModel user) async {
    final updated = user.copyWith(isActive: !user.isActive);
    await LocalStorageService.updateUser(updated);
    _users = LocalStorageService.getUsers();
    notifyListeners();
  }

  // ─── LEADS ────────────────────────────────────────────────────────────────
  Future<void> importLeads(List<LeadModel> newLeads) async {
    await LocalStorageService.addLeads(newLeads);
    _leads = LocalStorageService.getLeads();
    notifyListeners();
  }

  Future<int> distributeLeads() async {
    final count = await LocalStorageService.distributeLeads();
    _leads = LocalStorageService.getLeads();
    notifyListeners();
    return count;
  }

  /// Manually assign a list of leads to a specific user
  Future<void> assignLeadsToUser(List<LeadModel> leads, String userId) async {
    for (final lead in leads) {
      final updated = lead.copyWith(
        assignedUserId: userId,
        status: lead.status == 'Pending' ? 'Pending' : lead.status,
      );
      await LocalStorageService.updateLead(updated);
    }
    _leads = LocalStorageService.getLeads();
    notifyListeners();
  }

  /// Remove assignment from a lead (make it unassigned)
  Future<void> unassignLead(LeadModel lead) async {
    final updated = LeadModel(
      id: lead.id,
      customerName: lead.customerName,
      phoneNumber: lead.phoneNumber,
      status: 'Pending',
      notes: lead.notes,
      createdAt: lead.createdAt,
    );
    await LocalStorageService.updateLead(updated);
    _leads = LocalStorageService.getLeads();
    notifyListeners();
  }

  Future<void> updateLead(LeadModel lead) async {
    await LocalStorageService.updateLead(lead);
    _leads = LocalStorageService.getLeads();
    notifyListeners();
  }

  Future<void> clearAllLeads() async {
    await LocalStorageService.deleteAllLeads();
    _leads = [];
    notifyListeners();
  }

  // ─── NOTES ────────────────────────────────────────────────────────────────
  Future<void> addNote(NoteModel note) async {
    await LocalStorageService.addNote(note);
    _notes = LocalStorageService.getNotesForUser(note.userId);
    notifyListeners();
  }

  Future<void> updateNote(NoteModel note) async {
    await LocalStorageService.updateNote(note);
    _notes = LocalStorageService.getNotesForUser(note.userId);
    notifyListeners();
  }

  Future<void> deleteNote(String noteId) async {
    if (_currentUser == null) return;
    await LocalStorageService.deleteNote(_currentUser!.id, noteId);
    _notes = LocalStorageService.getNotesForUser(_currentUser!.id);
    notifyListeners();
  }

  // ─── SETTINGS ─────────────────────────────────────────────────────────────
  Future<void> updateSettings(AppSettings settings) async {
    await LocalStorageService.saveSettings(settings);
    _settings = settings;
    notifyListeners();
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────
  UserModel? getUserById(String id) =>
      _users.where((u) => u.id == id).firstOrNull;

  List<LeadModel> getLeadsForUser(String userId) =>
      _leads.where((l) => l.assignedUserId == userId).toList();

  void refreshCurrentUser() {
    if (_currentUser != null) {
      _currentUser = LocalStorageService.getUserById(_currentUser!.id);
      notifyListeners();
    }
  }
}
