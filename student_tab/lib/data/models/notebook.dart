import 'package:equatable/equatable.dart';

import 'notebook_type.dart';

class Notebook extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? parentId;
  final NotebookType type;
  final int orderIndex;
  final List<String> tags;
  final bool isArchived;
  final String? topicId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDirty;

  const Notebook({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.parentId,
    this.type = NotebookType.topic,
    this.orderIndex = 0,
    this.tags = const [],
    this.isArchived = false,
    this.topicId,
    required this.createdAt,
    required this.updatedAt,
    this.isDirty = false,
  });

  Notebook copyWith({
    String? title,
    String? description,
    String? parentId,
    NotebookType? type,
    int? orderIndex,
    List<String>? tags,
    bool? isArchived,
    String? topicId,
    DateTime? updatedAt,
    bool? isDirty,
  }) =>
      Notebook(
        id: id,
        userId: userId,
        title: title ?? this.title,
        description: description ?? this.description,
        parentId: parentId ?? this.parentId,
        type: type ?? this.type,
        orderIndex: orderIndex ?? this.orderIndex,
        tags: tags ?? this.tags,
        isArchived: isArchived ?? this.isArchived,
        topicId: topicId ?? this.topicId,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDirty: isDirty ?? this.isDirty,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'description': description,
        'parent_id': parentId,
        'type': type.value,
        'order_index': orderIndex,
        'tags': tags,
        'is_archived': isArchived,
        'topic_id': topicId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Notebook.fromJson(Map<String, dynamic> json) => Notebook(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        parentId: json['parent_id'] as String?,
        type: NotebookType.fromValue(json['type'] as String?),
        orderIndex: json['order_index'] as int? ?? 0,
        tags: (json['tags'] as List?)?.map((t) => t as String).toList() ?? [],
        isArchived: json['is_archived'] as bool? ?? false,
        topicId: json['topic_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        isDirty: json['is_dirty'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        id, userId, title, description, parentId, type, orderIndex, tags,
        isArchived, topicId, createdAt, updatedAt, isDirty,
      ];
}
