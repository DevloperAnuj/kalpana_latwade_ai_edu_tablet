import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:eduforge_core/eduforge_core.dart';

import '../../data/repositories/class_repository.dart';

part 'student_event.dart';
part 'student_state.dart';

class StudentBloc extends Bloc<StudentEvent, StudentState> {
  StudentBloc({StudentClassRepository? repository})
      : _repo = repository ??
            StudentClassRepository(Supabase.instance.client),
        super(const StudentInitial()) {
    on<LoadJoinedClasses>(_onLoadClasses);
    on<JoinClassWithCode>(_onJoinClass);
  }

  final StudentClassRepository _repo;

  Future<void> _onLoadClasses(
    LoadJoinedClasses event,
    Emitter<StudentState> emit,
  ) async {
    emit(const StudentLoading());
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final classes = await _repo.fetchJoinedClasses(userId);
      emit(StudentClassesLoaded(classes));
    } on AppException catch (e) {
      ErrorLogger.instance.logError(e, null, context: 'StudentBloc.LoadClasses');
      emit(StudentError(e.message));
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'StudentBloc.LoadClasses');
      emit(StudentError(e.toString()));
    }
  }

  Future<void> _onJoinClass(
    JoinClassWithCode event,
    Emitter<StudentState> emit,
  ) async {
    emit(const StudentLoading());
    try {
      final className = await _repo.joinClass(event.joinCode);
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final classes = await _repo.fetchJoinedClasses(userId);
      emit(StudentClassesLoaded(classes, justJoinedClassName: className));
    } on ValidationException catch (e) {
      emit(StudentError(e.message));
    } on AppException catch (e) {
      ErrorLogger.instance.logError(e, null, context: 'StudentBloc.JoinClass');
      emit(StudentError(e.message));
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'StudentBloc.JoinClass');
      emit(StudentError(e.toString()));
    }
  }
}
