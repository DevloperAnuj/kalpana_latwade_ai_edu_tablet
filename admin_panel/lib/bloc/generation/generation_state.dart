part of 'generation_bloc.dart';

abstract class GenerationState extends Equatable {
  const GenerationState();

  @override
  List<Object?> get props => [];
}

class GenerationInitial extends GenerationState {
  const GenerationInitial();
}

class GenerationLoading extends GenerationState {
  final String step;
  final double progress; // 0.0 – 1.0

  const GenerationLoading({required this.step, required this.progress});

  @override
  List<Object?> get props => [step, progress];
}

/// All five materials generated. [updatedType] is null on initial generation;
/// set to the material type when only one material was re-generated.
/// [topicId] is non-null when viewing/editing an already-published topic.
class GenerationSuccess extends GenerationState {
  final GenerationResult result;
  final String topicTitle;
  final String lessonContent;
  final String classId;
  final String? topicId;
  final String? updatedType;

  const GenerationSuccess({
    required this.result,
    required this.topicTitle,
    required this.lessonContent,
    required this.classId,
    this.topicId,
    this.updatedType,
  });

  @override
  List<Object?> get props => [result, topicTitle, lessonContent, classId, topicId, updatedType];
}

class GenerationFailure extends GenerationState {
  final String error;
  final String failedStep;

  const GenerationFailure({required this.error, required this.failedStep});

  @override
  List<Object?> get props => [error, failedStep];
}

/// One material is being re-generated; the rest of the result is still shown.
class RegenerationLoading extends GenerationState {
  final GenerationResult currentResult;
  final String materialType;
  final String topicTitle;
  final String lessonContent;
  final String classId;

  const RegenerationLoading({
    required this.currentResult,
    required this.materialType,
    required this.topicTitle,
    required this.lessonContent,
    required this.classId,
  });

  @override
  List<Object?> get props => [materialType, topicTitle];
}

class PublishLoading extends GenerationState {
  final GenerationResult result;
  final String topicTitle;
  final String lessonContent;
  final String classId;

  const PublishLoading({
    required this.result,
    required this.topicTitle,
    required this.lessonContent,
    required this.classId,
  });

  @override
  List<Object?> get props => [topicTitle];
}

class PublishSuccess extends GenerationState {
  const PublishSuccess();
}

class PublishFailure extends GenerationState {
  final String error;
  final GenerationResult result;
  final String topicTitle;
  final String lessonContent;
  final String classId;

  const PublishFailure({
    required this.error,
    required this.result,
    required this.topicTitle,
    required this.lessonContent,
    required this.classId,
  });

  @override
  List<Object?> get props => [error, topicTitle];
}
