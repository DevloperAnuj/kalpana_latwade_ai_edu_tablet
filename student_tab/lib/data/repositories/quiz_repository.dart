import 'package:eduforge_core/eduforge_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentQuizRepository {
  StudentQuizRepository(this._supabase);
  final SupabaseClient _supabase;

  /// Submits a quiz attempt. Throws [DatabaseException] on failure.
  Future<void> submitAttempt({
    required String studentId,
    required String materialId,
    required Map<String, int> answersJson,
    required int score,
  }) async {
    try {
      await RetryPolicy.run(() => _supabase.from('quiz_attempts').insert({
            'student_id': studentId,
            'material_id': materialId,
            'answers_json': answersJson,
            'score': score,
          }));
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }

  /// Returns the most recent attempt score for this student + material, or null.
  Future<int?> fetchLastScore({
    required String studentId,
    required String materialId,
  }) async {
    try {
      final data = await _supabase
          .from('quiz_attempts')
          .select('score')
          .eq('student_id', studentId)
          .eq('material_id', materialId)
          .order('submitted_at', ascending: false)
          .limit(1);

      final list = data as List;
      if (list.isEmpty) return null;
      return (list.first as Map<String, dynamic>)['score'] as int?;
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }
}
