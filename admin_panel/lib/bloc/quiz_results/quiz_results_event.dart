part of 'quiz_results_bloc.dart';

abstract class QuizResultsEvent extends Equatable {
  const QuizResultsEvent();

  @override
  List<Object?> get props => [];
}

class LoadQuizResults extends QuizResultsEvent {
  final String topicId;
  final String classId;

  const LoadQuizResults({required this.topicId, required this.classId});

  @override
  List<Object?> get props => [topicId, classId];
}

class RefreshQuizResults extends QuizResultsEvent {
  const RefreshQuizResults();
}

/// Fired by the Supabase Realtime callback when a new quiz_attempt is inserted.
class RealtimeAttemptReceived extends QuizResultsEvent {
  final Map<String, dynamic> record;

  const RealtimeAttemptReceived(this.record);

  @override
  List<Object?> get props => [record];
}
