import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/generation_result.dart';

part 'quiz_results_event.dart';
part 'quiz_results_state.dart';

class QuizResultsBloc extends Bloc<QuizResultsEvent, QuizResultsState> {
  QuizResultsBloc() : super(const QuizResultsInitial()) {
    on<LoadQuizResults>(_onLoad);
    on<RefreshQuizResults>(_onRefresh);
    on<RealtimeAttemptReceived>(_onRealtimeAttempt);
  }

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<WrongAnswer> _computeWrongAnswers(
    List<int> answers,
    List<QuizQuestion> questions,
  ) {
    final result = <WrongAnswer>[];
    for (var i = 0; i < questions.length && i < answers.length; i++) {
      final chosen = answers[i];
      final q = questions[i];
      if (chosen != q.correct) {
        result.add(WrongAnswer(
          questionIndex: i,
          questionText: q.text,
          studentAnswer: (chosen >= 0 && chosen < q.options.length)
              ? q.options[chosen]
              : '(unknown)',
          correctAnswer: q.options[q.correct],
          explanation: q.explanation,
        ));
      }
    }
    return result;
  }

  List<int> _parseAnswers(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => (e as num).toInt()).toList();
    }
    return [];
  }

  Future<List<StudentResult>> _buildResults(
    List<Map<String, dynamic>> attempts,
    List<QuizQuestion> questions,
  ) async {
    // Keep only the most recent attempt per student (list is already DESC)
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final a in attempts) {
      final sid = a['student_id'] as String;
      if (seen.add(sid)) unique.add(a);
    }

    return unique.map((a) {
      final profile = a['profiles'] as Map<String, dynamic>?;
      final name =
          (profile?['display_name'] as String?)?.trim().isNotEmpty == true
              ? profile!['display_name'] as String
              : 'Student';
      final answers = _parseAnswers(a['answers']);
      final score = (a['score'] as num?)?.toInt() ?? 0;
      return StudentResult(
        studentId: a['student_id'] as String,
        studentName: name,
        score: score,
        total: questions.length,
        wrongAnswers: _computeWrongAnswers(answers, questions),
        submittedAt: DateTime.parse(a['attempted_at'] as String).toLocal(),
      );
    }).toList();
  }

  void _subscribeRealtime(String topicId, String quizMaterialId) {
    _channel = _supabase
        .channel('quiz_results_$topicId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'quiz_attempts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'material_id',
            value: quizMaterialId,
          ),
          callback: (payload) {
            if (!isClosed && payload.newRecord.isNotEmpty) {
              add(RealtimeAttemptReceived(payload.newRecord));
            }
          },
        )
        .subscribe();
  }

  // ── Event handlers ─────────────────────────────────────────────────────────

  Future<void> _onLoad(
    LoadQuizResults event,
    Emitter<QuizResultsState> emit,
  ) async {
    emit(const QuizResultsLoading());
    try {
      // 1. Fetch quiz material
      final matRow = await _supabase
          .from('materials')
          .select('id, json_data')
          .eq('topic_id', event.topicId)
          .eq('type', 'quiz')
          .single();

      final quizMaterialId = matRow['id'] as String;
      final questions =
          Quiz.fromJson(matRow['json_data'] as Map<String, dynamic>).questions;

      // 2. Fetch all attempts with student display names (DESC so most-recent first)
      final attemptsRaw = await _supabase
          .from('quiz_attempts')
          .select('student_id, answers, score, attempted_at, profiles(display_name)')
          .eq('material_id', quizMaterialId)
          .order('attempted_at', ascending: false);

      final attempts = (attemptsRaw as List).cast<Map<String, dynamic>>();

      // 3. Enrolled student count
      final enrolledRaw = await _supabase
          .from('class_students')
          .select('student_id')
          .eq('class_id', event.classId);
      final totalEnrolled = (enrolledRaw as List).length;

      final studentResults = await _buildResults(attempts, questions);

      emit(QuizResultsLoaded(
        questions: questions,
        studentResults: studentResults,
        totalEnrolled: totalEnrolled,
        quizMaterialId: quizMaterialId,
        topicId: event.topicId,
        classId: event.classId,
      ));

      // Subscribe for live updates after emitting the initial state
      _subscribeRealtime(event.topicId, quizMaterialId);
    } catch (e) {
      emit(QuizResultsError(e.toString()));
    }
  }

  Future<void> _onRefresh(
    RefreshQuizResults event,
    Emitter<QuizResultsState> emit,
  ) async {
    final current = state;
    if (current is QuizResultsLoaded) {
      await _onLoad(
        LoadQuizResults(
            topicId: current.topicId, classId: current.classId),
        emit,
      );
    }
  }

  Future<void> _onRealtimeAttempt(
    RealtimeAttemptReceived event,
    Emitter<QuizResultsState> emit,
  ) async {
    final current = state;
    if (current is! QuizResultsLoaded) return;

    final record = event.record;
    final studentId = record['student_id'] as String? ?? '';
    final score = (record['score'] as num?)?.toInt() ?? 0;
    final answers = _parseAnswers(record['answers']);
    final attemptedAt = record['attempted_at'] != null
        ? DateTime.parse(record['attempted_at'] as String).toLocal()
        : DateTime.now();

    // Look up student name from existing results; fetch from DB if new student
    String studentName =
        current.studentResults
            .where((r) => r.studentId == studentId)
            .map((r) => r.studentName)
            .firstOrNull ??
        '';

    if (studentName.isEmpty) {
      try {
        final profile = await _supabase
            .from('profiles')
            .select('display_name')
            .eq('id', studentId)
            .single();
        final raw = profile['display_name'] as String?;
        studentName =
            (raw?.trim().isNotEmpty == true) ? raw! : 'Student';
      } catch (_) {
        studentName = 'Student';
      }
    }

    final newResult = StudentResult(
      studentId: studentId,
      studentName: studentName,
      score: score,
      total: current.questions.length,
      wrongAnswers: _computeWrongAnswers(answers, current.questions),
      submittedAt: attemptedAt,
    );

    final updatedResults = List<StudentResult>.from(current.studentResults);
    final idx = updatedResults.indexWhere((r) => r.studentId == studentId);
    if (idx >= 0) {
      updatedResults[idx] = newResult; // replace with latest attempt
    } else {
      updatedResults.insert(0, newResult);
    }
    // Keep sorted newest first
    updatedResults.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    emit(QuizResultsLoaded(
      questions: current.questions,
      studentResults: updatedResults,
      totalEnrolled: current.totalEnrolled,
      quizMaterialId: current.quizMaterialId,
      topicId: current.topicId,
      classId: current.classId,
    ));
  }

  @override
  Future<void> close() async {
    if (_channel != null) {
      await _supabase.removeChannel(_channel!);
    }
    return super.close();
  }
}
