import 'dart:async';

import 'package:eduforge_core/eduforge_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/notebook.dart';
import '../../data/repositories/notes_local_repository.dart';
import '../../data/repositories/notes_remote_repository.dart';
import '../../services/notes_sync_service.dart';
import 'notes_event.dart';
import 'notes_state.dart';

class NotebooksBloc extends Bloc<NotesEvent, NotesState> {
  NotebooksBloc()
      : _local = NotesLocalRepository(),
        _remote = NotesRemoteRepository(),
        super(const NotesInitial()) {
    _sync = NotesSyncService(local: _local, remote: _remote);
    on<LoadNotebooks>(_onLoad);
    on<CreateNotebook>(_onCreate);
    on<UpdateNotebook>(_onUpdate);
    on<DeleteNotebook>(_onDelete);
    on<ArchiveNotebook>(_onArchive);
    on<SyncNotes>(_onSync);
  }

  final NotesLocalRepository _local;
  final NotesRemoteRepository _remote;
  late final NotesSyncService _sync;

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onLoad(LoadNotebooks event, Emitter<NotesState> emit) async {
    emit(const NotesLoading());
    try {
      final userId = _userId;
      if (userId == null) {
        emit(const NotesError('Not authenticated.'));
        return;
      }
      emit(NotesLoaded(_local.getNotebooks(userId)));
      add(const SyncNotes()); // background sync
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'NotebooksBloc.load');
      emit(const NotesError('Could not load notebooks.'));
    }
  }

  Future<void> _onCreate(CreateNotebook event, Emitter<NotesState> emit) async {
    final userId = _userId;
    if (userId == null) return;

    final now = DateTime.now();
    final notebook = Notebook(
      id: NotesLocalRepository.generateId(),
      userId: userId,
      title: event.title,
      description: event.description,
      parentId: event.parentId,
      type: event.type,
      topicId: event.topicId,
      createdAt: now,
      updatedAt: now,
      isDirty: true,
    );

    try {
      await _local.saveNotebook(notebook);
      _emitLoaded(emit);
      unawaited(_remote.upsertNotebook(notebook).then((_) async {
        await _local.saveNotebook(notebook.copyWith(isDirty: false));
      }).catchError((_) {/* stays dirty; syncs later */}));
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'NotebooksBloc.create');
    }
  }

  Future<void> _onUpdate(UpdateNotebook event, Emitter<NotesState> emit) async {
    final existing = _local.getNotebook(event.id);
    if (existing == null) return;

    final updated = existing.copyWith(
      title: event.title,
      description: event.description,
      tags: event.tags,
      updatedAt: DateTime.now(),
      isDirty: true,
    );

    try {
      await _local.saveNotebook(updated);
      _emitLoaded(emit);
      unawaited(_remote.upsertNotebook(updated).then((_) async {
        await _local.saveNotebook(updated.copyWith(isDirty: false));
      }).catchError((_) {}));
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'NotebooksBloc.update');
    }
  }

  Future<void> _onDelete(DeleteNotebook event, Emitter<NotesState> emit) async {
    try {
      await _local.deleteNotebook(event.id);
      _emitLoaded(emit);
      unawaited(_remote.deleteNotebook(event.id).catchError((_) {}));
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'NotebooksBloc.delete');
    }
  }

  Future<void> _onArchive(ArchiveNotebook event, Emitter<NotesState> emit) async {
    final existing = _local.getNotebook(event.id);
    if (existing == null) return;
    final updated = existing.copyWith(
      isArchived: event.archive,
      updatedAt: DateTime.now(),
      isDirty: true,
    );
    try {
      await _local.saveNotebook(updated);
      _emitLoaded(emit);
      unawaited(_remote.upsertNotebook(updated).then((_) async {
        await _local.saveNotebook(updated.copyWith(isDirty: false));
      }).catchError((_) {}));
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'NotebooksBloc.archive');
    }
  }

  Future<void> _onSync(SyncNotes event, Emitter<NotesState> emit) async {
    final current = state;
    if (current is NotesLoaded) {
      emit(NotesLoaded(current.notebooks, syncing: true));
    }
    try {
      await _sync.sync();
    } catch (_) {
      // Sync failure is silent — local data is still available
    }
    _emitLoaded(emit);
  }

  void _emitLoaded(Emitter<NotesState> emit) {
    final userId = _userId;
    if (userId == null) return;
    emit(NotesLoaded(_local.getNotebooks(userId)));
  }
}
