part of 'profile_bloc.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final String displayName;
  final String role;
  final String? rollNumber;
  final String email;

  const ProfileLoaded({
    required this.displayName,
    required this.role,
    this.rollNumber,
    required this.email,
  });

  @override
  List<Object?> get props => [displayName, role, rollNumber, email];
}

// Extends ProfileLoaded so the builder sees normal form data while the
// listener can trigger a success snackbar.
class ProfileUpdateSuccess extends ProfileLoaded {
  const ProfileUpdateSuccess({
    required super.displayName,
    required super.role,
    super.rollNumber,
    required super.email,
  });
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
