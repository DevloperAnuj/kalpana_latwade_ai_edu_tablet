part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
}

class LoadProfile extends ProfileEvent {
  final String userId;

  const LoadProfile(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateProfile extends ProfileEvent {
  final String userId;
  final String displayName;
  final String? rollNumber;

  const UpdateProfile({
    required this.userId,
    required this.displayName,
    this.rollNumber,
  });

  @override
  List<Object?> get props => [userId, displayName, rollNumber];
}
