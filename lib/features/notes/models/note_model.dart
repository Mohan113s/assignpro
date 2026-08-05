import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class NoteModel {
  final String id;
  final String userId;
  String title;
  String content;
  final DateTime createdAt;
  DateTime updatedAt;

  NoteModel({
    String? id,
    required this.userId,
    required this.title,
    required this.content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? _uuid.v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return NoteModel(
      id: (json['id'] ?? _uuid.v4()).toString(),
      userId: (json['userId'] ?? json['user_id'] ?? '').toString(),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? json['body'] as String? ?? '',
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  NoteModel copyWith({String? title, String? content}) => NoteModel(
    id: id,
    userId: userId,
    title: title ?? this.title,
    content: content ?? this.content,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );
}
