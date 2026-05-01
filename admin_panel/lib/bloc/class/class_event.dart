part of 'class_bloc.dart';

abstract class ClassEvent extends Equatable {
  const ClassEvent();

  @override
  List<Object?> get props => [];
}

class FetchClasses extends ClassEvent {
  const FetchClasses();
}

class CreateClass extends ClassEvent {
  final String name;

  const CreateClass(this.name);

  @override
  List<Object?> get props => [name];
}

class DeleteClass extends ClassEvent {
  final String classId;

  const DeleteClass(this.classId);

  @override
  List<Object?> get props => [classId];
}
