part of 'generation_bloc.dart';

abstract class GenerationEvent extends Equatable {
  const GenerationEvent();

  @override
  List<Object?> get props => [];
}

/// Begin full study-pack generation.
class GenerateStudyPack extends GenerationEvent {
  final String topicTitle;
  final String lessonContent;
  final String classId;

  const GenerateStudyPack({
    required this.topicTitle,
    required this.lessonContent,
    required this.classId,
  });

  @override
  List<Object?> get props => [topicTitle, lessonContent, classId];
}

/// Re-generate a single material type using the stored lesson context.
class RegenerateMaterial extends GenerationEvent {
  final String materialType; // 'mindmap' | 'flashcards' | 'infographic' | 'table' | 'quiz'

  const RegenerateMaterial(this.materialType);

  @override
  List<Object?> get props => [materialType];
}

/// Publish the (possibly edited) result to Supabase.
class PublishTopic extends GenerationEvent {
  final GenerationResult result;

  const PublishTopic(this.result);

  @override
  List<Object?> get props => [result];
}

/// Restore a previously generated result (from draft) without calling the API.
class RestoreResult extends GenerationEvent {
  final GenerationResult result;
  final String topicTitle;
  final String lessonContent;
  final String classId;

  const RestoreResult({
    required this.result,
    required this.topicTitle,
    required this.lessonContent,
    required this.classId,
  });

  @override
  List<Object?> get props => [topicTitle, lessonContent, classId];
}

/// Reset bloc to initial state (called when entering NewTopicScreen).
class ResetGeneration extends GenerationEvent {
  const ResetGeneration();
}
