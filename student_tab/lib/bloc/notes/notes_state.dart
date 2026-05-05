import 'package:equatable/equatable.dart';

import '../../data/models/notebook.dart';

sealed class NotesState extends Equatable {
  const NotesState();
  @override
  List<Object?> get props => [];
}

class NotesInitial extends NotesState {
  const NotesInitial();
}

class NotesLoading extends NotesState {
  const NotesLoading();
}

class NotesLoaded extends NotesState {
  final List<Notebook> notebooks;
  final bool syncing;
  const NotesLoaded(this.notebooks, {this.syncing = false});
  @override
  List<Object?> get props => [notebooks, syncing];
}

class NotesError extends NotesState {
  final String message;
  const NotesError(this.message);
  @override
  List<Object?> get props => [message];
}
