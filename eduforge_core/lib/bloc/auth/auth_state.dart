part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
  @override
  List<Object?> get props => [];
}

class AuthLoading extends AuthState {
  const AuthLoading();
  @override
  List<Object?> get props => [];
}

class Authenticated extends AuthState {
  final String userId;
  final String role;
  final String? displayName;

  const Authenticated({
    required this.userId,
    required this.role,
    this.displayName,
  });

  @override
  List<Object?> get props => [userId, role, displayName];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
  @override
  List<Object?> get props => [];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
