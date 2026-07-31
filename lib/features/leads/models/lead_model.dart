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

  factory LeadModel.fromJson(Map<String, dynamic> json) => LeadModel(
    id: json['id'],
    customerName: json['customerName'] ?? '',
    phoneNumber: json['phoneNumber'] ?? '',
    status: json['status'] ?? 'Pending',
    assignedUserId: json['assignedUserId'],
    notes: json['notes'] ?? '',
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  LeadModel copyWith({
    String? customerName,
    String? phoneNumber,
    String? status,
    String? assignedUserId,
    String? notes,
  }) => LeadModel(
    id: id,
    customerName: customerName ?? this.customerName,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    status: status ?? this.status,
    assignedUserId: assignedUserId ?? this.assignedUserId,
    notes: notes ?? this.notes,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );
}
