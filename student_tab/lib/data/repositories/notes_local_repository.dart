import 'dart:math';

import '../local/notes_local_database.dart';
import '../models/notebook.dart';
import '../models/note_page.dart';

class NotesLocalRepository {
  // ── Notebooks ─────────────────────────────────────────────────────────────

  List<Notebook> getNotebooks(String userId) {
    return NotesLocalDatabase.notebooks.values
        .map((v) => Notebook.fromJson(_toStringMap(v)))
        .where((n) => n.userId == userId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Notebook? getNotebook(String id) {
    final raw = NotesLocalDatabase.notebooks.get(id);
    if (raw == null) return null;
    return Notebook.fromJson(_toStringMap(raw));
  }

  Future<void> saveNotebook(Notebook notebook) async {
    await NotesLocalDatabase.notebooks.put(notebook.id, notebook.toJson());
  }

  Future<void> deleteNotebook(String id) async {
    await NotesLocalDatabase.notebooks.delete(id);
    // cascade: remove pages belonging to this notebook
    final pageIds = NotesLocalDatabase.notePages.values
        .map((v) => NotePage.fromJson(_toStringMap(v)))
        .where((p) => p.notebookId == id)
        .map((p) => p.id)
        .toList();
    for (final pid in pageIds) {
      await NotesLocalDatabase.notePages.delete(pid);
    }
  }

  List<Notebook> getDirtyNotebooks() {
    return NotesLocalDatabase.notebooks.values
        .map((v) => Notebook.fromJson(_toStringMap(v)))
        .where((n) => n.isDirty)
        .toList();
  }

  // ── Note Pages ────────────────────────────────────────────────────────────

  List<NotePage> getPages(String notebookId) {
    return NotesLocalDatabase.notePages.values
        .map((v) => NotePage.fromJson(_toStringMap(v)))
        .where((p) => p.notebookId == notebookId)
        .toList()
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
  }

  NotePage? getPage(String id) {
    final raw = NotesLocalDatabase.notePages.get(id);
    if (raw == null) return null;
    return NotePage.fromJson(_toStringMap(raw));
  }

  Future<void> savePage(NotePage page) async {
    await NotesLocalDatabase.notePages.put(page.id, page.toJson());
  }

  Future<void> deletePage(String id) async {
    await NotesLocalDatabase.notePages.delete(id);
  }

  List<NotePage> getDirtyPages() {
    return NotesLocalDatabase.notePages.values
        .map((v) => NotePage.fromJson(_toStringMap(v)))
        .where((p) => p.isDirty)
        .toList();
  }

  // ── Sync meta ─────────────────────────────────────────────────────────────

  DateTime? getLastSyncAt(String userId) {
    final raw = NotesLocalDatabase.meta.get('last_sync_$userId');
    if (raw == null) return null;
    return DateTime.tryParse(raw as String);
  }

  Future<void> setLastSyncAt(String userId, DateTime time) async {
    await NotesLocalDatabase.meta.put('last_sync_$userId', time.toIso8601String());
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}'
        '-${hex.substring(12, 16)}-${hex.substring(16, 20)}'
        '-${hex.substring(20)}';
  }

  static Map<String, dynamic> _toStringMap(dynamic data) =>
      Map<String, dynamic>.from(data as Map);
}
