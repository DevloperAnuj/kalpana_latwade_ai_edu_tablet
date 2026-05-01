import 'package:eduforge_core/eduforge_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/generation_result.dart';

class MaterialRepository {
  MaterialRepository(this._supabase);
  final SupabaseClient _supabase;

  /// Upserts all five material types for [topicId] in sequence.
  Future<void> upsertMaterials(
    String topicId,
    GenerationResult result,
  ) async {
    final materials = {
      'mindmap': result.mindmap.toJson(),
      'flashcards': {'flashcards': result.flashcards.map((f) => f.toJson()).toList()},
      'infographic': result.infographic.toJson(),
      'table': result.table.toJson(),
      'quiz': result.quiz.toJson(),
    };

    try {
      for (final entry in materials.entries) {
        await RetryPolicy.run(() => _supabase.from('materials').upsert(
              {
                'topic_id': topicId,
                'type': entry.key,
                'json_data': entry.value,
              },
              onConflict: 'topic_id, type',
            ));
      }
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }

  /// Fetches all materials for a topic, keyed by type.
  Future<Map<String, Map<String, dynamic>>> fetchMaterials(
      String topicId) async {
    try {
      final data = await RetryPolicy.run(() => _supabase
          .from('materials')
          .select('type, json_data')
          .eq('topic_id', topicId));

      return {
        for (final m in (data as List))
          m['type'] as String: m['json_data'] as Map<String, dynamic>,
      };
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }
}
