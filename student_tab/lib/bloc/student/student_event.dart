part of 'student_bloc.dart';

abstract class StudentEvent extends Equatable {
  const StudentEvent();
}

class LoadJoinedClasses extends StudentEvent {
  const LoadJoinedClasses();

  @override
  List<Object?> get props => [];
}

class JoinClassWithCode extends StudentEvent {
  final String joinCode;

  const JoinClassWithCode(this.joinCode);

  @override
  List<Object?> get props => [joinCode];
}
