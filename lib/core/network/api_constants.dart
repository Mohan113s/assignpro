/// ─── SINGLE SOURCE OF TRUTH ───────────────────────────────────────────────
/// All backend API constants for AssignPro.
/// Backend is deployed on Render.
/// This is the ONLY file that defines the base URL.
/// Do NOT create another ApiConstants file.
class ApiConstants {
  // ─── Base URL ─────────────────────────────────────────────────────────────
  /// Production Render URL — used by Flutter Web, Android, and GitHub Pages.
  static const String baseUrl = 'https://assignpro-backend.onrender.com';

  // ─── Timeouts ─────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  // Alias for backward compat
  static const Duration timeout = Duration(seconds: 60);

  // ─── Auth ─────────────────────────────────────────────────────────────────
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/me';

  // ─── Users ────────────────────────────────────────────────────────────────
  static const String users = '/api/users';
  static String userById(String id) => '/api/users/$id';
  static String userToggleStatus(String id) => '/api/users/$id/status';

  // ─── Dashboard ────────────────────────────────────────────────────────────
  static const String adminDashboard = '/api/dashboard/admin';

  // ─── Leads ────────────────────────────────────────────────────────────────
  static const String leads = '/api/leads';
  static const String leadsUnassigned = '/api/leads/unassigned';
  static const String leadsMyLeads = '/api/leads/my-leads';
  static const String leadsImport = '/api/leads/import';
  static const String leadsAssignBulk = '/api/leads/assign-bulk';
  static const String leadsDistribute = '/api/leads/distribute';
  static const String leadsClear = '/api/leads/all';

  static String leadById(String id) => '/api/leads/$id';
  static String leadAssign(String leadId, String userId) =>
      '/api/leads/$leadId/assign/$userId';
  static String leadAssignPatch(String leadId) => '/api/leads/$leadId/assign';
  static String leadUnassign(String leadId) => '/api/leads/$leadId/unassign';
  static String leadNotes(String leadId) => '/api/leads/$leadId/notes';
  static String leadStatus(String leadId) => '/api/leads/$leadId/status';
  static String leadsForUser(String userId) => '/api/leads/user/$userId';

  // ─── Notes ────────────────────────────────────────────────────────────────
  static const String notes = '/api/notes';
  static String notesByLead(String leadId) => '/api/notes/lead/$leadId';
  static String notesForUser(String userId) => '/api/notes/user/$userId';
  static String noteById(String id) => '/api/notes/$id';

  // ─── Settings ─────────────────────────────────────────────────────────────
  static const String settings = '/api/settings';

  // ─── User Profile ─────────────────────────────────────────────────────────
  static const String userProfile = '/api/auth/me';
}
