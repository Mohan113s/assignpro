import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum UserRole { admin, user }

class UserModel {
  final String id;
  String name;
  String email;
  String password;
  String phone;
  UserRole role;
  bool isActive;
  final DateTime createdAt;

  UserModel({
    String? id,
    required this.name,
    required this.email,
    required this.password,
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
    'password': password,
    'phone': phone,
    'role': role.name,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    password: json['password'],
    phone: json['phone'] ?? '',
    role: UserRole.values.firstWhere(
      (e) => e.name == json['role'],
      orElse: () => UserRole.user,
    ),
    isActive: json['isActive'] ?? true,
    createdAt: DateTime.parse(json['createdAt']),
  );

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
