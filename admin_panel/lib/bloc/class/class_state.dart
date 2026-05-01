part of 'class_bloc.dart';

abstract class ClassState extends Equatable {
  const ClassState();

  @override
  List<Object?> get props => [];
}

class ClassInitial extends ClassState {
  const ClassInitial();
}

class ClassLoading extends ClassState {
  const ClassLoading();
}

class ClassesLoaded extends ClassState {
  final List<ClassModel> classes;

  const ClassesLoaded(this.classes);

  @override
  List<Object?> get props => [classes];
}

class ClassOperationSuccess extends ClassState {
  final String message;

  const ClassOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ClassError extends ClassState {
  final String message;

  const ClassError(this.message);

  @override
  List<Object?> get props => [message];
}
