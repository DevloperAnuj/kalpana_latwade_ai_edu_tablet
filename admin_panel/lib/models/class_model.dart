import 'package:equatable/equatable.dart';

class ClassModel extends Equatable {
  final String id;
  final String teacherId;
  final String name;
  final String joinCode;
  final DateTime createdAt;
  final int studentCount;

  const ClassModel({
    required this.id,
    required this.teacherId,
    required this.name,
    required this.joinCode,
    required this.createdAt,
    this.studentCount = 0,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    // PostgREST returns class_students(count) as [{count: N}]
    final countRaw = json['class_students'] as List<dynamic>?;
    final count = countRaw != null && countRaw.isNotEmpty
        ? (countRaw.first as Map<String, dynamic>)['count'] as int? ?? 0
        : 0;

    return ClassModel(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      name: json['name'] as String,
      joinCode: json['join_code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      studentCount: count,
    );
  }

  @override
  List<Object?> get props => [id, teacherId, name, joinCode, createdAt, studentCount];
}
