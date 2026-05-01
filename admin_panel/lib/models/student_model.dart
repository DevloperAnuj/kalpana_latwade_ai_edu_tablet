import 'package:equatable/equatable.dart';

class StudentModel extends Equatable {
  final String id;
  final String? displayName;
  final DateTime joinedAt;

  const StudentModel({
    required this.id,
    required this.displayName,
    required this.joinedAt,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    // PostgREST returns profiles as {display_name: ...}
    final profile = json['profiles'] as Map<String, dynamic>?;
    return StudentModel(
      id: json['student_id'] as String,
      displayName: profile?['display_name'] as String?,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, displayName, joinedAt];
}
