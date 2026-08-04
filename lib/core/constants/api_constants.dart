/// Central place for all backend API configuration.
/// Replace [baseUrl] with your actual Render deployment URL.
class ApiConstants {
  // ─── Base URL ─────────────────────────────────────────────────────────────
  /// TODO: Replace this with your actual Render backend URL.
  /// Example: 'https://assignpro-api.onrender.com'
  static const String baseUrl = 'https://YOUR_RENDER_BACKEND_URL.onrender.com';

  // ─── Auth ─────────────────────────────────────────────────────────────────
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/me';

  // ─── Users ────────────────────────────────────────────────────────────────
  static const String users = '/api/users';
  static String userById(String id) => '/api/users/$id';
  static String userToggleStatus(String id) => '/api/users/$id/status';

  // ─── Leads ────────────────────────────────────────────────────────────────
  static const String leads = '/api/leads';
  static const String leadsImport = '/api/leads/import';
  static const String leadsDistribute = '/api/leads/distribute';
  static const String leadsClear = '/api/leads/all';
  static String leadById(String id) => '/api/leads/$id';
  static String leadsForUser(String userId) => '/api/leads/user/$userId';
  static String leadAssign(String id) => '/api/leads/$id/assign';
  static String leadUnassign(String id) => '/api/leads/$id/unassign';

  // ─── Notes ────────────────────────────────────────────────────────────────
  static const String notes = '/api/notes';
  static String notesForUser(String userId) => '/api/notes/user/$userId';
  static String noteById(String id) => '/api/notes/$id';

  // ─── Settings ─────────────────────────────────────────────────────────────
  static const String settings = '/api/settings';

  // ─── Timeouts ─────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
