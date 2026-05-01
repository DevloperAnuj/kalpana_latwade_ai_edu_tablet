part of 'student_bloc.dart';

abstract class StudentState extends Equatable {
  const StudentState();
}

class StudentInitial extends StudentState {
  const StudentInitial();

  @override
  List<Object?> get props => [];
}

class StudentLoading extends StudentState {
  const StudentLoading();

  @override
  List<Object?> get props => [];
}

class StudentClassesLoaded extends StudentState {
  final List<Map<String, dynamic>> classes;
  final String? justJoinedClassName;

  const StudentClassesLoaded(this.classes, {this.justJoinedClassName});

  @override
  List<Object?> get props => [classes, justJoinedClassName];
}

class StudentError extends StudentState {
  final String message;

  const StudentError(this.message);

  @override
  List<Object?> get props => [message];
}
