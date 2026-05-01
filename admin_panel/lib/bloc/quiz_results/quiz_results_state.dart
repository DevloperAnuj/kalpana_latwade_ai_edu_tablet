part of 'quiz_results_bloc.dart';

abstract class QuizResultsState extends Equatable {
  const QuizResultsState();

  @override
  List<Object?> get props => [];
}

class QuizResultsInitial extends QuizResultsState {
  const QuizResultsInitial();
}

class QuizResultsLoading extends QuizResultsState {
  const QuizResultsLoading();
}

class QuizResultsError extends QuizResultsState {
  final String message;

  const QuizResultsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Domain models ─────────────────────────────────────────────────────────────

class WrongAnswer {
  final int questionIndex;
  final String questionText;
  final String studentAnswer;
  final String correctAnswer;
  final String explanation;

  const WrongAnswer({
    required this.questionIndex,
    required this.questionText,
    required this.studentAnswer,
    required this.correctAnswer,
    required this.explanation,
  });
}

class StudentResult {
  final String studentId;
  final String studentName;
  final int score;
  final int total;
  final List<WrongAnswer> wrongAnswers;
  final DateTime submittedAt;

  const StudentResult({
    required this.studentId,
    required this.studentName,
    required this.score,
    required this.total,
    required this.wrongAnswers,
    required this.submittedAt,
  });

  double get percentage => total > 0 ? score / total * 100 : 0;
}

// ── Loaded state ──────────────────────────────────────────────────────────────

class QuizResultsLoaded extends QuizResultsState {
  final List<QuizQuestion> questions;
  final List<StudentResult> studentResults;
  final int totalEnrolled;
  final String quizMaterialId;
  final String topicId;
  final String classId;

  const QuizResultsLoaded({
    required this.questions,
    required this.studentResults,
    required this.totalEnrolled,
    required this.quizMaterialId,
    required this.topicId,
    required this.classId,
  });

  int get submittedCount => studentResults.length;

  double get averageScore {
    if (studentResults.isEmpty) return 0;
    return studentResults.map((r) => r.percentage).reduce((a, b) => a + b) /
        studentResults.length;
  }

  @override
  List<Object?> get props => [
        questions,
        studentResults,
        totalEnrolled,
        quizMaterialId,
        topicId,
        classId,
      ];
}
