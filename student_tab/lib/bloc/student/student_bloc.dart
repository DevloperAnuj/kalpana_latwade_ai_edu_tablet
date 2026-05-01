import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'student_event.dart';
part 'student_state.dart';

class StudentBloc extends Bloc<StudentEvent, StudentState> {
  StudentBloc() : super(const StudentInitial()) {
    on<LoadJoinedClasses>(_onLoadClasses);
    on<JoinClassWithCode>(_onJoinClass);
  }

  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _fetchClasses() async {
    final userId = _supabase.auth.currentUser!.id;
    final data = await _supabase
        .from('class_students')
        .select('classes(id, name)')
        .eq('student_id', userId);
    return (data as List)
        .map((row) => row['classes'] as Map<String, dynamic>)
        .toList();
  }

  Future<void> _onLoadClasses(
    LoadJoinedClasses event,
    Emitter<StudentState> emit,
  ) async {
    emit(const StudentLoading());
    try {
      final classes = await _fetchClasses();
      emit(StudentClassesLoaded(classes));
    } catch (e) {
      emit(StudentError(e.toString()));
    }
  }

  Future<void> _onJoinClass(
    JoinClassWithCode event,
    Emitter<StudentState> emit,
  ) async {
    emit(const StudentLoading());
    try {
      final result = await _supabase.rpc(
        'join_class_by_code',
        params: {'p_join_code': event.joinCode.toUpperCase()},
      );
      final className = result['class_name'] as String;
      final classes = await _fetchClasses();
      emit(StudentClassesLoaded(classes, justJoinedClassName: className));
    } on PostgrestException catch (e) {
      emit(StudentError(e.message));
    } catch (e) {
      emit(StudentError(e.toString()));
    }
  }
}
