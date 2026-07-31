class AppSettings {
  String companyName;
  String adminSupportPhone;

  AppSettings({
    this.companyName = 'AssignPro CRM',
    this.adminSupportPhone = '+91 9000000000',
  });

  Map<String, dynamic> toJson() => {
    'companyName': companyName,
    'adminSupportPhone': adminSupportPhone,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    companyName: json['companyName'] ?? 'AssignPro CRM',
    adminSupportPhone: json['adminSupportPhone'] ?? '+91 9000000000',
  );

  AppSettings copyWith({String? companyName, String? adminSupportPhone}) =>
      AppSettings(
        companyName: companyName ?? this.companyName,
        adminSupportPhone: adminSupportPhone ?? this.adminSupportPhone,
      );
}
