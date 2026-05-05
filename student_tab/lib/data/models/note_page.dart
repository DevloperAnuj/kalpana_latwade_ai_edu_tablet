import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'page_pattern.dart';
import 'stroke_data.dart';

class NotePage extends Equatable {
  final String id;
  final String notebookId;
  final int pageNumber;
  final String? title;
  final List<StrokeData> strokes;
  final String? textContent;
  final PagePattern pattern;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDirty;

  const NotePage({
    required this.id,
    required this.notebookId,
    required this.pageNumber,
    this.title,
    this.strokes = const [],
    this.textContent,
    this.pattern = PagePattern.ruled,
    required this.createdAt,
    required this.updatedAt,
    this.isDirty = false,
  });

  NotePage copyWith({
    String? title,
    List<StrokeData>? strokes,
    String? textContent,
    PagePattern? pattern,
    DateTime? updatedAt,
    bool? isDirty,
  }) =>
      NotePage(
        id: id,
        notebookId: notebookId,
        pageNumber: pageNumber,
        title: title ?? this.title,
        strokes: strokes ?? this.strokes,
        textContent: textContent ?? this.textContent,
        pattern: pattern ?? this.pattern,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDirty: isDirty ?? this.isDirty,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'notebook_id': notebookId,
        'page_number': pageNumber,
        'title': title,
        'strokes': jsonEncode(strokes.map((s) => s.toJson()).toList()),
        'text_content': textContent,
        'pattern': pattern.value,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Map<String, dynamic> toRemoteJson() => {
        'id': id,
        'notebook_id': notebookId,
        'page_number': pageNumber,
        'title': title,
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'text_content': textContent,
        'pattern': pattern.value,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory NotePage.fromJson(Map<String, dynamic> json) {
    final rawStrokes = json['strokes'];
    List<StrokeData> strokes;
    if (rawStrokes == null) {
      strokes = [];
    } else if (rawStrokes is String) {
      final decoded = jsonDecode(rawStrokes) as List;
      strokes = decoded
          .map((s) => StrokeData.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList();
    } else if (rawStrokes is List) {
      strokes = rawStrokes
          .map((s) => StrokeData.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList();
    } else {
      strokes = [];
    }

    return NotePage(
      id: json['id'] as String,
      notebookId: json['notebook_id'] as String,
      pageNumber: json['page_number'] as int,
      title: json['title'] as String?,
      strokes: strokes,
      textContent: json['text_content'] as String?,
      pattern: PagePattern.fromValue(json['pattern'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isDirty: json['is_dirty'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id, notebookId, pageNumber, title, strokes,
        textContent, pattern, createdAt, updatedAt, isDirty,
      ];
}
