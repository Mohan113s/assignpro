class AppConstants {
  static const String appName = 'AssignPro';
  static const String appVersion = '1.0.0';

  // Admin security key for registration (frontend validation only)
  static const String adminSecurityKey = '707586';

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
}
