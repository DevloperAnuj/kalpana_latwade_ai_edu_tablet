import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SupabaseClient _supabase = Supabase.instance.client;

  AuthBloc() : super(const AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthLoginRequested>(_onLogin);
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        emit(const Unauthenticated());
        return;
      }
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', session.user.id)
          .single();
      emit(Authenticated(
        userId: session.user.id,
        role: profile['role'] as String,
        displayName: profile['display_name'] as String?,
      ));
    } catch (_) {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onSignUp(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await _supabase.auth.signUp(
        email: event.email,
        password: event.password,
        data: {'role': event.role},
      );
      // Profile row is created by the on_auth_user_created DB trigger,
      // which reads the role from raw_user_meta_data.
      final user = response.user;
      if (user == null) {
        emit(const AuthError(
          'Sign-up requires email confirmation. Please check your inbox.',
        ));
        return;
      }

      // Persist display name and optional roll number (non-fatal: user can
      // always update via the profile screen later).
      try {
        final name = event.displayName?.trim() ?? '';
        final update = <String, dynamic>{};
        if (name.isNotEmpty) update['display_name'] = name;
        if (event.role == 'student') {
          final roll = event.rollNumber?.trim() ?? '';
          if (roll.isNotEmpty) update['roll_number'] = roll;
        }
        if (update.isNotEmpty) {
          await _supabase.from('profiles').update(update).eq('id', user.id);
        }
      } catch (_) {
        // non-fatal
      }

      final savedName = event.displayName?.trim();
      emit(Authenticated(
        userId: user.id,
        role: event.role,
        displayName: (savedName?.isEmpty ?? true) ? null : savedName,
      ));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );
      final user = response.user;
      if (user == null) {
        emit(const AuthError('Login failed. Please try again.'));
        return;
      }
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      emit(Authenticated(
        userId: user.id,
        role: profile['role'] as String,
        displayName: profile['display_name'] as String?,
      ));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _supabase.auth.signOut();
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
