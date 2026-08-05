import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum UserRole { admin, user }

class UserModel {
  final String id;
  String name;
  String email;
  // Password is NEVER stored from API responses — only used during registration.
  // Backend never returns password in JSON for security reasons.
  String password;
  String phone;
  UserRole role;
  bool isActive;
  final DateTime createdAt;

  UserModel({
    String? id,
    required this.name,
    required this.email,
    this.password = '', // Always empty from API — backend never returns it
    this.phone = '',
    this.role = UserRole.user,
    this.isActive = true,
    DateTime? createdAt,
  }) : id = id ?? _uuid.v4(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    // Do NOT send empty password on update — only when it's meaningful
    if (password.isNotEmpty) 'password': password,
    'phone': phone,
    'role': role.name.toUpperCase(), // Backend expects ADMIN / USER
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };

  /// Safely parses a UserModel from JSON.
  /// Defensive: handles missing/null fields — backend never returns password.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parse role case-insensitively — backend may return ADMIN, admin, Admin
    final rawRole = (json['role'] as String? ?? 'user').toLowerCase();
    final role = UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == rawRole,
      orElse: () => UserRole.user,
    );

    // Parse dates safely
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return UserModel(
      id: (json['id'] ?? json['userId'] ?? _uuid.v4()).toString(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: '', // Never populated from API for security
      phone: json['phone'] as String? ?? json['mobile'] as String? ?? '',
      role: role,
      isActive: json['isActive'] as bool? ?? json['active'] as bool? ?? true,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? password,
    String? phone,
    UserRole? role,
    bool? isActive,
  }) => UserModel(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    password: password ?? this.password,
    phone: phone ?? this.phone,
    role: role ?? this.role,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
  );
}
