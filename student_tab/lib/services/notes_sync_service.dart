import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/notes_local_repository.dart';
import '../data/repositories/notes_remote_repository.dart';

/// Bidirectional offline-first sync.
/// Last-write-wins based on updated_at timestamp.
class NotesSyncService {
  NotesSyncService({
    required NotesLocalRepository local,
    required NotesRemoteRepository remote,
  })  : _local = local,
        _remote = remote;

  final NotesLocalRepository _local;
  final NotesRemoteRepository _remote;

  bool _syncing = false;

  /// Runs a full sync for the authenticated user.
  /// Safe to call multiple times — concurrent calls are no-ops.
  Future<SyncResult> sync() async {
    if (_syncing) return const SyncResult(uploaded: 0, downloaded: 0);
    _syncing = true;
    try {
      return await _doSync();
    } finally {
      _syncing = false;
    }
  }

  Future<SyncResult> _doSync() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return const SyncResult(uploaded: 0, downloaded: 0);

    int uploaded = 0;
    int downloaded = 0;

    // ── Upload dirty notebooks ──────────────────────────────────────────────
    final dirtyNotebooks = _local.getDirtyNotebooks();
    for (final nb in dirtyNotebooks) {
      await _remote.upsertNotebook(nb);
      await _local.saveNotebook(nb.copyWith(isDirty: false));
      uploaded++;
    }

    // ── Upload dirty pages ──────────────────────────────────────────────────
    final dirtyPages = _local.getDirtyPages();
    for (final page in dirtyPages) {
      await _remote.upsertPage(page);
      await _local.savePage(page.copyWith(isDirty: false));
      uploaded++;
    }

    // ── Download remote changes ─────────────────────────────────────────────
    final lastSync = _local.getLastSyncAt(userId);

    if (lastSync == null) {
      // First sync: download everything
      final remoteNotebooks = await _remote.fetchNotebooks(userId);
      for (final nb in remoteNotebooks) {
        await _local.saveNotebook(nb);
        downloaded++;
        final pages = await _remote.fetchPages(nb.id);
        for (final page in pages) {
          await _local.savePage(page);
          downloaded++;
        }
      }
    } else {
      // Incremental sync: only changed items
      final remoteNotebooks =
          await _remote.fetchNotebooksUpdatedAfter(userId, lastSync);
      for (final remote in remoteNotebooks) {
        final local = _local.getNotebook(remote.id);
        if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
          await _local.saveNotebook(remote.copyWith(isDirty: false));
          downloaded++;
        }
      }

      final remotePages = await _remote.fetchPagesUpdatedAfter(lastSync);
      for (final remote in remotePages) {
        final local = _local.getPage(remote.id);
        if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
          await _local.savePage(remote.copyWith(isDirty: false));
          downloaded++;
        }
      }
    }

    final now = DateTime.now();
    await _local.setLastSyncAt(userId, now);
    await _remote.upsertSyncMeta(userId);

    return SyncResult(uploaded: uploaded, downloaded: downloaded);
  }
}

class SyncResult {
  final int uploaded;
  final int downloaded;
  const SyncResult({required this.uploaded, required this.downloaded});

  bool get hadActivity => uploaded > 0 || downloaded > 0;
}
