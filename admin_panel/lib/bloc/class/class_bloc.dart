import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/class_model.dart';

part 'class_event.dart';
part 'class_state.dart';

class ClassBloc extends Bloc<ClassEvent, ClassState> {
  ClassBloc() : super(const ClassInitial()) {
    on<FetchClasses>(_onFetchClasses);
    on<CreateClass>(_onCreateClass);
    on<DeleteClass>(_onDeleteClass);
  }

  final _supabase = Supabase.instance.client;

  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static final _rng = Random.secure();

  String _generateCode() =>
      List.generate(6, (_) => _chars[_rng.nextInt(_chars.length)]).join();

  Future<void> _onFetchClasses(
    FetchClasses event,
    Emitter<ClassState> emit,
  ) async {
    emit(const ClassLoading());
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(const ClassError('Not authenticated'));
        return;
      }

      // Single query: classes + embedded student count via PostgREST
      final data = await _supabase
          .from('classes')
          .select('*, class_students(count)')
          .eq('teacher_id', userId)
          .order('created_at', ascending: false);

      final classes = (data as List)
          .map((e) => ClassModel.fromJson(e as Map<String, dynamic>))
          .toList();

      emit(ClassesLoaded(classes));
    } on PostgrestException catch (e) {
      emit(ClassError(e.message));
    } catch (e) {
      emit(ClassError(e.toString()));
    }
  }

  Future<void> _onCreateClass(
    CreateClass event,
    Emitter<ClassState> emit,
  ) async {
    emit(const ClassLoading());
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(const ClassError('Not authenticated'));
        return;
      }

      // Fetch existing codes to avoid collision
      final existing = await _supabase.from('classes').select('join_code');
      final existingCodes = (existing as List)
          .map((e) => (e as Map<String, dynamic>)['join_code'] as String)
          .toSet();

      String code;
      var attempts = 0;
      do {
        code = _generateCode();
        if (++attempts > 10) {
          emit(const ClassError('Could not generate a unique join code. Try again.'));
          return;
        }
      } while (existingCodes.contains(code));

      await _supabase.from('classes').insert({
        'teacher_id': userId,
        'name': event.name.trim(),
        'join_code': code,
      });

      emit(const ClassOperationSuccess('Class created!'));
      add(const FetchClasses());
    } on PostgrestException catch (e) {
      emit(ClassError(e.message));
    } catch (e) {
      emit(ClassError(e.toString()));
    }
  }

  Future<void> _onDeleteClass(
    DeleteClass event,
    Emitter<ClassState> emit,
  ) async {
    emit(const ClassLoading());
    try {
      await _supabase.from('classes').delete().eq('id', event.classId);
      emit(const ClassOperationSuccess('Class deleted.'));
      add(const FetchClasses());
    } on PostgrestException catch (e) {
      emit(ClassError(e.message));
    } catch (e) {
      emit(ClassError(e.toString()));
    }
  }
}
