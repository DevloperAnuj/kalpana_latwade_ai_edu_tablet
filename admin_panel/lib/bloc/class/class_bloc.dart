import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:eduforge_core/eduforge_core.dart';

import '../../data/repositories/class_repository.dart';
import '../../models/class_model.dart';

part 'class_event.dart';
part 'class_state.dart';

class ClassBloc extends Bloc<ClassEvent, ClassState> {
  ClassBloc({ClassRepository? repository})
      : _repo = repository ??
            ClassRepository(Supabase.instance.client),
        super(const ClassInitial()) {
    on<FetchClasses>(_onFetchClasses);
    on<CreateClass>(_onCreateClass);
    on<DeleteClass>(_onDeleteClass);
  }

  final ClassRepository _repo;

  Future<void> _onFetchClasses(
    FetchClasses event,
    Emitter<ClassState> emit,
  ) async {
    emit(const ClassLoading());
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        emit(const ClassError('Not authenticated'));
        return;
      }
      final classes = await _repo.fetchClasses(userId);
      emit(ClassesLoaded(classes));
    } on AppException catch (e) {
      ErrorLogger.instance.logError(e, null, context: 'ClassBloc.FetchClasses');
      emit(ClassError(e.message));
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'ClassBloc.FetchClasses');
      emit(ClassError(e.toString()));
    }
  }

  Future<void> _onCreateClass(
    CreateClass event,
    Emitter<ClassState> emit,
  ) async {
    emit(const ClassLoading());
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        emit(const ClassError('Not authenticated'));
        return;
      }
      await _repo.createClass(userId, event.name);
      emit(const ClassOperationSuccess('Class created!'));
      add(const FetchClasses());
    } on AppException catch (e) {
      ErrorLogger.instance.logError(e, null, context: 'ClassBloc.CreateClass');
      emit(ClassError(e.message));
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'ClassBloc.CreateClass');
      emit(ClassError(e.toString()));
    }
  }

  Future<void> _onDeleteClass(
    DeleteClass event,
    Emitter<ClassState> emit,
  ) async {
    emit(const ClassLoading());
    try {
      await _repo.deleteClass(event.classId);
      emit(const ClassOperationSuccess('Class deleted.'));
      add(const FetchClasses());
    } on AppException catch (e) {
      ErrorLogger.instance.logError(e, null, context: 'ClassBloc.DeleteClass');
      emit(ClassError(e.message));
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'ClassBloc.DeleteClass');
      emit(ClassError(e.toString()));
    }
  }
}
