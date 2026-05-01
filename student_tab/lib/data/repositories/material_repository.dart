import 'package:eduforge_core/eduforge_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentMaterialRepository {
  StudentMaterialRepository(this._supabase);
  final SupabaseClient _supabase;

  /// Returns a map of type → json_data plus a separate quiz material id.
  Future<({Map<String, Map<String, dynamic>> byType, String? quizMaterialId})>
      fetchMaterials(String topicId) async {
    try {
      final data = await RetryPolicy.run(() => _supabase
          .from('materials')
          .select('id, type, json_data')
          .eq('topic_id', topicId));

      final byType = <String, Map<String, dynamic>>{};
      String? quizMaterialId;

      for (final m in (data as List)) {
        final type = m['type'] as String;
        byType[type] = m['json_data'] as Map<String, dynamic>;
        if (type == 'quiz') quizMaterialId = m['id'] as String;
      }

      return (byType: byType, quizMaterialId: quizMaterialId);
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }
}
