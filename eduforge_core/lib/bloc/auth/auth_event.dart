part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
}

class AuthCheckStatus extends AuthEvent {
  const AuthCheckStatus();
  @override
  List<Object?> get props => [];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String role;
  final String? displayName;
  final String? rollNumber;

  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.role,
    this.displayName,
    this.rollNumber,
  });

  @override
  List<Object?> get props => [email, password, role, displayName, rollNumber];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
  @override
  List<Object?> get props => [];
}
