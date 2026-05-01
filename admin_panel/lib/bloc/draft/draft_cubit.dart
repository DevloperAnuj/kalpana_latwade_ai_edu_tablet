import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../models/generation_result.dart';

class DraftState extends Equatable {
  final String? topicTitle;
  final String? lessonContent;
  final String? classId;
  // Stored as raw JSON map so HydratedBloc can serialise it without a custom adapter.
  final Map<String, dynamic>? resultJson;

  const DraftState({
    this.topicTitle,
    this.lessonContent,
    this.classId,
    this.resultJson,
  });

  bool get isEmpty =>
      topicTitle == null && lessonContent == null && resultJson == null;

  bool matchesClass(String id) => classId == id;

  GenerationResult? get generationResult {
    if (resultJson == null) return null;
    try {
      return GenerationResult.fromJson(resultJson!);
    } catch (_) {
      return null;
    }
  }

  DraftState copyWith({
    String? topicTitle,
    String? lessonContent,
    String? classId,
    Map<String, dynamic>? resultJson,
  }) =>
      DraftState(
        topicTitle: topicTitle ?? this.topicTitle,
        lessonContent: lessonContent ?? this.lessonContent,
        classId: classId ?? this.classId,
        resultJson: resultJson ?? this.resultJson,
      );

  factory DraftState.fromJson(Map<String, dynamic> json) => DraftState(
        topicTitle: json['topicTitle'] as String?,
        lessonContent: json['lessonContent'] as String?,
        classId: json['classId'] as String?,
        resultJson: json['resultJson'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        'topicTitle': topicTitle,
        'lessonContent': lessonContent,
        'classId': classId,
        'resultJson': resultJson,
      };

  @override
  List<Object?> get props => [topicTitle, lessonContent, classId, resultJson];
}

class DraftCubit extends HydratedCubit<DraftState> {
  DraftCubit() : super(const DraftState());

  void saveDraft({
    required String topicTitle,
    required String lessonContent,
    required String classId,
    GenerationResult? result,
  }) {
    emit(DraftState(
      topicTitle: topicTitle,
      lessonContent: lessonContent,
      classId: classId,
      resultJson: result?.toJson(),
    ));
  }

  void clearDraft() => emit(const DraftState());

  @override
  DraftState fromJson(Map<String, dynamic> json) => DraftState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(DraftState state) => state.toJson();
}
