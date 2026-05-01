import 'package:eduforge_core/eduforge_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/generation_result.dart';

class QuizRepository {
  QuizRepository(this._supabase);
  final SupabaseClient _supabase;

  static const int _pageSize = 20;

  /// Fetches the quiz material for a topic.
  Future<({String materialId, List<QuizQuestion> questions})> fetchQuizMaterial(
      String topicId) async {
    try {
      final row = await RetryPolicy.run(() => _supabase
          .from('materials')
          .select('id, json_data')
          .eq('topic_id', topicId)
          .eq('type', 'quiz')
          .single());

      final materialId = row['id'] as String;
      final questions =
          Quiz.fromJson(row['json_data'] as Map<String, dynamic>).questions;
      return (materialId: materialId, questions: questions);
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }

  /// Fetches a page of quiz attempts with student display names.
  /// [page] is 0-indexed.
  Future<List<Map<String, dynamic>>> fetchAttempts(
    String materialId, {
    int page = 0,
    int pageSize = _pageSize,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    try {
      final data = await RetryPolicy.run(() => _supabase
          .from('quiz_attempts')
          .select(
            'student_id, answers_json, score, submitted_at, '
            'profiles(display_name, roll_number)',
          )
          .eq('material_id', materialId)
          .order('submitted_at', ascending: false)
          .range(from, to));

      return (data as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }

  /// Enrolled student count for a class.
  Future<int> fetchEnrolledCount(String classId) async {
    try {
      final data = await RetryPolicy.run(() => _supabase
          .from('class_students')
          .select('student_id')
          .eq('class_id', classId));
      return (data as List).length;
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }

  /// Fetches a single student's name and roll number by id.
  Future<({String name, String? rollNumber})> fetchStudentProfile(
    String studentId,
  ) async {
    try {
      final row = await _supabase
          .from('profiles')
          .select('display_name, roll_number')
          .eq('id', studentId)
          .single();
      final raw = row['display_name'] as String?;
      return (
        name: (raw?.trim().isNotEmpty == true) ? raw! : 'Student',
        rollNumber: row['roll_number'] as String?,
      );
    } catch (_) {
      return (name: 'Student', rollNumber: null);
    }
  }
}
