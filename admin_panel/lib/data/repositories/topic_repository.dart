import 'package:eduforge_core/eduforge_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TopicRepository {
  TopicRepository(this._supabase);
  final SupabaseClient _supabase;

  /// Creates a new topic row and returns its UUID.
  Future<String> createTopic({
    required String classId,
    required String teacherId,
    required String title,
    required String rawContent,
  }) async {
    if (title.trim().isEmpty) {
      throw const ValidationException('Topic title cannot be empty.');
    }
    try {
      final row = await RetryPolicy.run(() => _supabase
          .from('topics')
          .insert({
            'class_id': classId,
            'teacher_id': teacherId,
            'title': title.trim(),
            'raw_content': rawContent,
            'status': 'published',
          })
          .select('id')
          .single());
      return row['id'] as String;
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }

  /// Updates raw_content on an existing topic.
  Future<void> updateRawContent(String topicId, String rawContent) async {
    try {
      await RetryPolicy.run(() => _supabase
          .from('topics')
          .update({'raw_content': rawContent})
          .eq('id', topicId));
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }

  /// Fetches topics for a class (excluding soft-deleted).
  Future<List<Map<String, dynamic>>> fetchTopics(String classId) async {
    try {
      final data = await RetryPolicy.run(() => _supabase
          .from('topics')
          .select('id, title, status, created_at, raw_content')
          .eq('class_id', classId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false));
      return (data as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }

  /// Soft-deletes a topic.
  Future<void> deleteTopic(String topicId) async {
    try {
      await _supabase
          .from('topics')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', topicId);
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }

  /// Returns soft-deleted topics for the trash screen.
  Future<List<Map<String, dynamic>>> fetchTrashedTopics(
      String classId) async {
    try {
      final data = await _supabase
          .from('topics')
          .select('id, title, status, created_at, deleted_at')
          .eq('class_id', classId)
          .not('deleted_at', 'is', null)
          .order('deleted_at', ascending: false);
      return (data as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }

  /// Restores a soft-deleted topic.
  Future<void> restoreTopic(String topicId) async {
    try {
      await _supabase
          .from('topics')
          .update({'deleted_at': null}).eq('id', topicId);
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException(e.toString(), e);
    }
  }
}
