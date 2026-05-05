import 'package:eduforge_core/eduforge_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notebook.dart';
import '../models/note_page.dart';

class NotesRemoteRepository {
  SupabaseClient get _client => Supabase.instance.client;

  // ── Notebooks ─────────────────────────────────────────────────────────────

  Future<List<Notebook>> fetchNotebooks(String userId) async {
    try {
      final data = await RetryPolicy.run(() => _client
          .from('notebooks')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false));
      return (data as List)
          .map((row) => Notebook.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message);
    } catch (_) {
      throw const NetworkException('Could not fetch notebooks.');
    }
  }

  Future<List<Notebook>> fetchNotebooksUpdatedAfter(
    String userId,
    DateTime since,
  ) async {
    try {
      final data = await RetryPolicy.run(() => _client
          .from('notebooks')
          .select()
          .eq('user_id', userId)
          .gt('updated_at', since.toIso8601String())
          .order('updated_at', ascending: false));
      return (data as List)
          .map((row) => Notebook.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message);
    } catch (_) {
      throw const NetworkException('Could not fetch remote notebooks.');
    }
  }

  Future<void> upsertNotebook(Notebook notebook) async {
    try {
      await RetryPolicy.run(() => _client
          .from('notebooks')
          .upsert(notebook.toJson(), onConflict: 'id'));
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message);
    } catch (_) {
      throw const NetworkException('Could not save notebook.');
    }
  }

  Future<void> deleteNotebook(String id) async {
    try {
      await RetryPolicy.run(
          () => _client.from('notebooks').delete().eq('id', id));
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message);
    } catch (_) {
      throw const NetworkException('Could not delete notebook.');
    }
  }

  // ── Note Pages ────────────────────────────────────────────────────────────

  Future<List<NotePage>> fetchPages(String notebookId) async {
    try {
      final data = await RetryPolicy.run(() => _client
          .from('note_pages')
          .select()
          .eq('notebook_id', notebookId)
          .order('page_number'));
      return (data as List)
          .map((row) => NotePage.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message);
    } catch (_) {
      throw const NetworkException('Could not fetch pages.');
    }
  }

  Future<List<NotePage>> fetchPagesUpdatedAfter(DateTime since) async {
    try {
      final data = await RetryPolicy.run(() => _client
          .from('note_pages')
          .select()
          .gt('updated_at', since.toIso8601String())
          .order('updated_at', ascending: false));
      return (data as List)
          .map((row) => NotePage.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message);
    } catch (_) {
      throw const NetworkException('Could not fetch remote pages.');
    }
  }

  Future<void> upsertPage(NotePage page) async {
    try {
      await RetryPolicy.run(() => _client
          .from('note_pages')
          .upsert(page.toRemoteJson(), onConflict: 'id'));
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message);
    } catch (_) {
      throw const NetworkException('Could not save page.');
    }
  }

  Future<void> deletePage(String id) async {
    try {
      await RetryPolicy.run(
          () => _client.from('note_pages').delete().eq('id', id));
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message);
    } catch (_) {
      throw const NetworkException('Could not delete page.');
    }
  }

  // ── Sync metadata ─────────────────────────────────────────────────────────

  Future<void> upsertSyncMeta(String userId) async {
    try {
      await _client.from('sync_metadata').upsert(
        {'user_id': userId, 'last_sync_at': DateTime.now().toIso8601String()},
        onConflict: 'user_id',
      );
    } catch (_) {
      // non-critical; ignore
    }
  }
}
