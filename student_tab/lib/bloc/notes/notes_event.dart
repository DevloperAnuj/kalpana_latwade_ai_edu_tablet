import 'package:equatable/equatable.dart';

import '../../data/models/notebook_type.dart';

sealed class NotesEvent extends Equatable {
  const NotesEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotebooks extends NotesEvent {
  const LoadNotebooks();
}

class CreateNotebook extends NotesEvent {
  final String title;
  final String? description;
  final String? parentId;
  final NotebookType type;
  final String? topicId;
  const CreateNotebook({
    required this.title,
    this.description,
    this.parentId,
    this.type = NotebookType.topic,
    this.topicId,
  });
  @override
  List<Object?> get props => [title, description, parentId, type, topicId];
}

class UpdateNotebook extends NotesEvent {
  final String id;
  final String title;
  final String? description;
  final List<String> tags;
  const UpdateNotebook({
    required this.id,
    required this.title,
    this.description,
    this.tags = const [],
  });
  @override
  List<Object?> get props => [id, title, description, tags];
}

class DeleteNotebook extends NotesEvent {
  final String id;
  const DeleteNotebook(this.id);
  @override
  List<Object?> get props => [id];
}

class ArchiveNotebook extends NotesEvent {
  final String id;
  final bool archive;
  const ArchiveNotebook(this.id, {required this.archive});
  @override
  List<Object?> get props => [id, archive];
}

class SyncNotes extends NotesEvent {
  const SyncNotes();
}
