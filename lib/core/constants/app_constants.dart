class AppConstants {
  static const String appName = 'AssignPro';
  static const String appVersion = '1.0.0';

  // Security
  static const String adminSecurityKey = '707586';

  // SharedPreferences Keys
  static const String keyUsers = 'users';
  static const String keyLeads = 'leads';
  static const String keyNotes = 'notes';
  static const String keySettings = 'settings';
  static const String keyCurrentUser = 'current_user';
  static const String keyIsLoggedIn = 'is_logged_in';

  // Lead statuses
  static const List<String> leadStatuses = [
    'Pending',
    'Follow Up',
    'Interested',
    'Not Interested',
    'Busy',
    'No Response',
    'Wrong Number',
    'Completed',
  ];

  // Default admin credentials
  static const String defaultAdminEmail = 'admin@assignpro.com';
  static const String defaultAdminPassword = 'Admin@123';
  static const String defaultAdminName = 'System Administrator';
  static const String defaultAdminPhone = '+91 9000000000';
}
