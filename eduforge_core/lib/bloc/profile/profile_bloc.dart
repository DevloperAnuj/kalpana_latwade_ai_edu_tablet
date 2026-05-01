import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/error_logger.dart';
import '../../data/repositories/profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({ProfileRepository? repository})
      : _repo = repository ?? ProfileRepository(Supabase.instance.client),
        super(const ProfileInitial()) {
    on<LoadProfile>(_onLoad);
    on<UpdateProfile>(_onUpdate);
  }

  final ProfileRepository _repo;

  Future<void> _onLoad(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      final (:displayName, :role, :rollNumber, :email) =
          await _repo.fetchProfile(event.userId);
      emit(ProfileLoaded(
        displayName: displayName,
        role: role,
        rollNumber: rollNumber,
        email: email,
      ));
    } on AppException catch (e) {
      ErrorLogger.instance.logError(e, null, context: 'ProfileBloc.Load');
      emit(ProfileError(e.message));
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'ProfileBloc.Load');
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state;
    if (current is! ProfileLoaded) return;
    emit(const ProfileLoading());
    try {
      await _repo.updateProfile(
        event.userId,
        displayName: event.displayName,
        rollNumber: event.rollNumber,
      );
      final trimmedRoll = event.rollNumber?.trim();
      emit(ProfileUpdateSuccess(
        displayName: event.displayName.trim(),
        role: current.role,
        rollNumber: (trimmedRoll?.isEmpty ?? true) ? null : trimmedRoll,
        email: current.email,
      ));
    } on AppException catch (e) {
      ErrorLogger.instance.logError(e, null, context: 'ProfileBloc.Update');
      emit(ProfileError(e.message));
      emit(current);
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'ProfileBloc.Update');
      emit(ProfileError(e.toString()));
      emit(current);
    }
  }
}
