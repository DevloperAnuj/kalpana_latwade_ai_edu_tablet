import 'package:eduforge_core/eduforge_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentClassRepository {
  StudentClassRepository(this._supabase);
  final SupabaseClient _supabase;

  Future<List<Map<String, dynamic>>> fetchJoinedClasses(
      String studentId) async {
    try {
      final data = await RetryPolicy.run(() => _supabase
          .from('class_students')
          .select('classes(id, name)')
          .eq('student_id', studentId));

      return (data as List)
          .map((row) => row['classes'] as Map<String, dynamic>)
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }

  /// Joins a class by 6-character code. Returns the class name on success.
  Future<String> joinClass(String joinCode) async {
    final code = joinCode.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(code)) {
      throw const ValidationException('Join code must be 6 uppercase letters/digits.');
    }
    try {
      final result = await RetryPolicy.run(() => _supabase.rpc(
            'join_class_by_code',
            params: {'p_join_code': code},
          ));
      return result['class_name'] as String;
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }
}
