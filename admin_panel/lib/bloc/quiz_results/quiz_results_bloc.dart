import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:eduforge_core/eduforge_core.dart';

import '../../data/repositories/quiz_repository.dart';
import '../../models/generation_result.dart';

part 'quiz_results_event.dart';
part 'quiz_results_state.dart';

class QuizResultsBloc extends Bloc<QuizResultsEvent, QuizResultsState> {
  QuizResultsBloc({QuizRepository? repository})
      : _repo = repository ?? QuizRepository(Supabase.instance.client),
        super(const QuizResultsInitial()) {
    on<LoadQuizResults>(_onLoad);
    on<LoadMoreResults>(_onLoadMore);
    on<RefreshQuizResults>(_onRefresh);
    on<RealtimeAttemptReceived>(_onRealtimeAttempt);
  }

  final QuizRepository _repo;
  RealtimeChannel? _channel;

  static const _pageSize = 20;

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<WrongAnswer> _computeWrongAnswers(
    Map<String, int> answers,
    List<QuizQuestion> questions,
  ) {
    final result = <WrongAnswer>[];
    for (var i = 0; i < questions.length; i++) {
      final chosen = answers['$i'];
      if (chosen == null) continue;
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

  Map<String, int> _parseAnswers(dynamic raw) {
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }
    // Legacy: list format from pre-migration rows
    if (raw is List) {
      return {for (var i = 0; i < raw.length; i++) '$i': (raw[i] as num).toInt()};
    }
    return {};
  }

  List<StudentResult> _buildResults(
    List<Map<String, dynamic>> attempts,
    List<QuizQuestion> questions,
  ) {
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
      final rollNumber = profile?['roll_number'] as String?;
      final answers = _parseAnswers(a['answers_json']);
      final score = (a['score'] as num?)?.toInt() ?? 0;
      return StudentResult(
        studentId: a['student_id'] as String,
        studentName: name,
        rollNumber: rollNumber,
        score: score,
        total: questions.length,
        wrongAnswers: _computeWrongAnswers(answers, questions),
        submittedAt: DateTime.parse(a['submitted_at'] as String).toLocal(),
      );
    }).toList();
  }

  void _subscribeRealtime(String topicId, String quizMaterialId) {
    _channel = Supabase.instance.client
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
      final (:materialId, :questions) =
          await _repo.fetchQuizMaterial(event.topicId);

      final rawAttempts = await _repo.fetchAttempts(
        materialId,
        page: 0,
        pageSize: _pageSize,
      );
      final totalEnrolled = await _repo.fetchEnrolledCount(event.classId);
      final studentResults = _buildResults(rawAttempts, questions);

      emit(QuizResultsLoaded(
        questions: questions,
        studentResults: studentResults,
        totalEnrolled: totalEnrolled,
        quizMaterialId: materialId,
        topicId: event.topicId,
        classId: event.classId,
        currentPage: 0,
        hasMore: rawAttempts.length == _pageSize,
      ));

      _subscribeRealtime(event.topicId, materialId);
    } on AppException catch (e) {
      ErrorLogger.instance.logError(e, null, context: 'QuizResultsBloc.Load');
      emit(QuizResultsError(e.message));
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'QuizResultsBloc.Load');
      emit(QuizResultsError(e.toString()));
    }
  }

  Future<void> _onLoadMore(
    LoadMoreResults event,
    Emitter<QuizResultsState> emit,
  ) async {
    final current = state;
    if (current is! QuizResultsLoaded || !current.hasMore || current.isLoadingMore) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));

    try {
      final nextPage = current.currentPage + 1;
      final rawAttempts = await _repo.fetchAttempts(
        current.quizMaterialId,
        page: nextPage,
        pageSize: _pageSize,
      );
      final newResults = _buildResults(rawAttempts, current.questions);

      // Merge, keeping only most-recent per student
      final merged = List<StudentResult>.from(current.studentResults);
      for (final r in newResults) {
        if (!merged.any((e) => e.studentId == r.studentId)) {
          merged.add(r);
        }
      }

      emit(current.copyWith(
        studentResults: merged,
        currentPage: nextPage,
        hasMore: rawAttempts.length == _pageSize,
        isLoadingMore: false,
      ));
    } on AppException catch (e) {
      ErrorLogger.instance.logError(e, null, context: 'QuizResultsBloc.LoadMore');
      emit(current.copyWith(isLoadingMore: false));
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'QuizResultsBloc.LoadMore');
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onRefresh(
    RefreshQuizResults event,
    Emitter<QuizResultsState> emit,
  ) async {
    final current = state;
    if (current is QuizResultsLoaded) {
      await _onLoad(
        LoadQuizResults(topicId: current.topicId, classId: current.classId),
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
    final answers = _parseAnswers(record['answers_json']);
    final submittedAt = record['submitted_at'] != null
        ? DateTime.parse(record['submitted_at'] as String).toLocal()
        : DateTime.now();

    final existing = current.studentResults
        .where((r) => r.studentId == studentId)
        .firstOrNull;

    String studentName = existing?.studentName ?? '';
    String? rollNumber = existing?.rollNumber;

    if (studentName.isEmpty) {
      final profile = await _repo.fetchStudentProfile(studentId);
      studentName = profile.name;
      rollNumber = profile.rollNumber;
    }

    final newResult = StudentResult(
      studentId: studentId,
      studentName: studentName,
      rollNumber: rollNumber,
      score: score,
      total: current.questions.length,
      wrongAnswers: _computeWrongAnswers(answers, current.questions),
      submittedAt: submittedAt,
    );

    final updatedResults = List<StudentResult>.from(current.studentResults);
    final idx = updatedResults.indexWhere((r) => r.studentId == studentId);
    if (idx >= 0) {
      updatedResults[idx] = newResult;
    } else {
      updatedResults.insert(0, newResult);
    }
    updatedResults.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    emit(current.copyWith(studentResults: updatedResults));
  }

  @override
  Future<void> close() async {
    if (_channel != null) {
      await Supabase.instance.client.removeChannel(_channel!);
    }
    return super.close();
  }
}
