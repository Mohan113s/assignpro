import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class LeadModel {
  final String id;
  String customerName;
  String phoneNumber;
  String status;
  String? assignedUserId;
  String notes;
  final DateTime createdAt;
  DateTime updatedAt;

  LeadModel({
    String? id,
    required this.customerName,
    required this.phoneNumber,
    this.status = 'Pending',
    this.assignedUserId,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? _uuid.v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isAssigned => assignedUserId != null && assignedUserId!.isNotEmpty;
  bool get isCompleted => status == 'Completed';

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerName': customerName,
    'phoneNumber': phoneNumber,
    'status': status,
    'assignedUserId': assignedUserId,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Safely parses a LeadModel from JSON with null-safe date handling.
  factory LeadModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    // Parse assignedUserId — backend may return it as int, long, or string
    final rawAssignedUserId = json['assignedUserId'];
    String? assignedUserId;
    if (rawAssignedUserId != null && rawAssignedUserId.toString().isNotEmpty) {
      assignedUserId = rawAssignedUserId.toString();
    }

    return LeadModel(
      id: (json['id'] ?? _uuid.v4()).toString(),
      customerName:
          json['customerName'] as String? ?? json['name'] as String? ?? '',
      phoneNumber:
          json['phoneNumber'] as String? ??
          json['phone'] as String? ??
          json['mobile'] as String? ??
          '',
      status: json['status'] as String? ?? 'Pending',
      assignedUserId: assignedUserId,
      notes: json['notes'] as String? ?? '',
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  /// copyWith supports explicitly setting assignedUserId to null (unassign).
  LeadModel copyWith({
    String? customerName,
    String? phoneNumber,
    String? status,
    Object? assignedUserId = _sentinel, // Use sentinel to allow null-setting
    String? notes,
  }) => LeadModel(
    id: id,
    customerName: customerName ?? this.customerName,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    status: status ?? this.status,
    assignedUserId: assignedUserId == _sentinel
        ? this.assignedUserId
        : assignedUserId as String?,
    notes: notes ?? this.notes,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );
}

// Sentinel value to distinguish "not provided" from "null" in copyWith
const Object _sentinel = Object();
