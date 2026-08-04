/// All backend API constants for AssignPro.
/// Backend is deployed at Render.
class ApiConstants {
  // ─── Base URL ─────────────────────────────────────────────────────────────
  static const String baseUrl = 'https://assignpro-backend.onrender.com';

  // ─── Timeouts ─────────────────────────────────────────────────────────────
  static const Duration timeout = Duration(seconds: 30);

  // ─── Auth ─────────────────────────────────────────────────────────────────
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';

  // ─── Dashboard ────────────────────────────────────────────────────────────
  static const String adminDashboard = '/api/dashboard/admin';

  // ─── Leads ────────────────────────────────────────────────────────────────
  static const String leads = '/api/leads';
  static const String leadsUnassigned = '/api/leads/unassigned';
  static const String leadsMyLeads = '/api/leads/my-leads';
  static const String leadsImport = '/api/leads/import';
  static const String leadsAssignBulk = '/api/leads/assign-bulk';
  static const String leadsManualAssign = '/api/leads/manual-assign';

  static String leadById(String id) => '/api/leads/$id';
  static String leadAssign(String leadId, String userId) =>
      '/api/leads/$leadId/assign/$userId';
  static String leadNotes(String leadId) => '/api/leads/$leadId/notes';
  static String leadStatus(String leadId) => '/api/leads/$leadId/status';
  static String leadsForUser(String userId) => '/api/leads/user/$userId';

  // ─── Notes ────────────────────────────────────────────────────────────────
  static const String notes = '/api/notes';
  static String notesByLead(String leadId) => '/api/notes/$leadId';

  // ─── Users ────────────────────────────────────────────────────────────────
  static const String users = '/api/users';
  static String userById(String id) => '/api/users/$id';

  // ─── User profile ─────────────────────────────────────────────────────────
  static const String userProfile = '/api/user/profile';
}
