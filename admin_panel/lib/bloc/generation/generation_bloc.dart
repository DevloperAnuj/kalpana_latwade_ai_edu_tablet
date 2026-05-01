import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:eduforge_core/eduforge_core.dart';

import '../../data/repositories/material_repository.dart';
import '../../data/repositories/topic_repository.dart';
import '../../models/generation_result.dart';
import '../../services/ai_service.dart';

part 'generation_event.dart';
part 'generation_state.dart';

class GenerationBloc extends Bloc<GenerationEvent, GenerationState> {
  GenerationBloc({
    TopicRepository? topicRepository,
    MaterialRepository? materialRepository,
  })  : _topicRepo = topicRepository ??
            TopicRepository(Supabase.instance.client),
        _materialRepo = materialRepository ??
            MaterialRepository(Supabase.instance.client),
        super(const GenerationInitial()) {
    on<GenerateStudyPack>(_onGenerate);
    on<RegenerateMaterial>(_onRegenerate);
    on<PublishTopic>(_onPublish);
    on<RestoreResult>(_onRestore);
    on<ResetGeneration>(_onReset);
  }

  final TopicRepository _topicRepo;
  final MaterialRepository _materialRepo;

  // In-memory key cache — never written to disk
  String? _cachedApiKey;

  String? _topicTitle;
  String? _lessonContent;
  String? _classId;
  String? _topicId;

  // ── Helpers ─────────────────────────────────────────────────────────────

  Future<String> _getApiKey() async {
    if (_cachedApiKey != null) return _cachedApiKey!;
    try {
      _cachedApiKey =
          await Supabase.instance.client.rpc<String>('get_gemini_api_key');
      return _cachedApiKey!;
    } on PostgrestException catch (e) {
      throw DatabaseException(e.message, e);
    } catch (e) {
      throw NetworkException('Could not retrieve API key: $e', e);
    }
  }

  AiService _makeService(String apiKey) => AiService(
        apiKey: apiKey,
        topicTitle: _topicTitle!,
        lessonContent: _lessonContent!,
      );

  // ── Handlers ────────────────────────────────────────────────────────────

  Future<void> _onGenerate(
    GenerateStudyPack event,
    Emitter<GenerationState> emit,
  ) async {
    _topicTitle = event.topicTitle;
    _lessonContent = event.lessonContent;
    _classId = event.classId;
    _topicId = null;

    emit(const GenerationLoading(step: 'Fetching AI key…', progress: 0.02));

    // §2.4 Rate-limit check: max 10 AI generation calls per minute per teacher.
    try {
      final allowed = await Supabase.instance.client.rpc<bool>(
        'check_and_increment_rate_limit',
        params: {'p_action': 'ai_generate'},
      );
      if (!allowed) {
        emit(const GenerationFailure(
          error: 'Too many generation attempts. Please wait a minute.',
          failedStep: 'Rate limit',
        ));
        return;
      }
    } catch (_) {
      // If the RPC fails (e.g. function not yet deployed), continue gracefully.
    }

    late String apiKey;
    try {
      apiKey = await _getApiKey();
    } on AppException catch (e) {
      ErrorLogger.instance.logError(e, null, context: 'GenerationBloc.key');
      emit(GenerationFailure(error: e.message, failedStep: 'Fetching AI key'));
      return;
    }

    final svc = _makeService(apiKey);
    const callGap = Duration(seconds: 2);

    late Mindmap mindmap;
    emit(const GenerationLoading(step: 'Building mindmap…', progress: 0.15));
    try {
      mindmap = await svc.generateMindmap();
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'GenerationBloc.mindmap');
      emit(GenerationFailure(error: e.toString(), failedStep: 'Mindmap'));
      return;
    }

    await Future.delayed(callGap);

    late List<Flashcard> flashcards;
    emit(const GenerationLoading(step: 'Creating flashcards…', progress: 0.35));
    try {
      flashcards = await svc.generateFlashcards();
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'GenerationBloc.flashcards');
      emit(GenerationFailure(error: e.toString(), failedStep: 'Flashcards'));
      return;
    }

    await Future.delayed(callGap);

    late Infographic infographic;
    emit(const GenerationLoading(step: 'Designing infographic…', progress: 0.55));
    try {
      infographic = await svc.generateInfographic();
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'GenerationBloc.infographic');
      emit(GenerationFailure(error: e.toString(), failedStep: 'Infographic'));
      return;
    }

    await Future.delayed(callGap);

    late TableData table;
    emit(const GenerationLoading(step: 'Building summary table…', progress: 0.73));
    try {
      table = await svc.generateTable();
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'GenerationBloc.table');
      emit(GenerationFailure(error: e.toString(), failedStep: 'Table'));
      return;
    }

    await Future.delayed(callGap);

    late Quiz quiz;
    emit(const GenerationLoading(step: 'Writing quiz questions…', progress: 0.90));
    try {
      quiz = await svc.generateQuiz();
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'GenerationBloc.quiz');
      emit(GenerationFailure(error: e.toString(), failedStep: 'Quiz'));
      return;
    }

    emit(GenerationSuccess(
      result: GenerationResult(
        mindmap: mindmap,
        flashcards: flashcards,
        infographic: infographic,
        table: table,
        quiz: quiz,
      ),
      topicTitle: _topicTitle!,
      lessonContent: _lessonContent!,
      classId: _classId!,
    ));
  }

  Future<void> _onRegenerate(
    RegenerateMaterial event,
    Emitter<GenerationState> emit,
  ) async {
    final current = state;
    late GenerationResult currentResult;
    if (current is GenerationSuccess) {
      currentResult = current.result;
    } else if (current is PublishFailure) {
      currentResult = current.result;
    } else {
      return;
    }

    emit(RegenerationLoading(
      currentResult: currentResult,
      materialType: event.materialType,
      topicTitle: _topicTitle!,
      lessonContent: _lessonContent!,
      classId: _classId!,
    ));

    late String apiKey;
    try {
      apiKey = await _getApiKey();
    } on AppException catch (e) {
      ErrorLogger.instance.logError(e, null, context: 'GenerationBloc.regenKey');
      emit(GenerationFailure(error: e.message, failedStep: 'Fetching AI key'));
      return;
    }

    final svc = _makeService(apiKey);

    try {
      final updated = switch (event.materialType) {
        'mindmap' =>
          currentResult.copyWith(mindmap: await svc.generateMindmap()),
        'flashcards' =>
          currentResult.copyWith(flashcards: await svc.generateFlashcards()),
        'infographic' =>
          currentResult.copyWith(infographic: await svc.generateInfographic()),
        'table' => currentResult.copyWith(table: await svc.generateTable()),
        'quiz' => currentResult.copyWith(quiz: await svc.generateQuiz()),
        _ => currentResult,
      };

      emit(GenerationSuccess(
        result: updated,
        topicTitle: _topicTitle!,
        lessonContent: _lessonContent!,
        classId: _classId!,
        topicId: _topicId,
        updatedType: event.materialType,
      ));
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st,
          context: 'GenerationBloc.regen.${event.materialType}');
      emit(GenerationFailure(
        error: e.toString(),
        failedStep: 'Regenerate ${event.materialType}',
      ));
    }
  }

  Future<void> _onPublish(
    PublishTopic event,
    Emitter<GenerationState> emit,
  ) async {
    emit(PublishLoading(
      result: event.result,
      topicTitle: _topicTitle!,
      lessonContent: _lessonContent!,
      classId: _classId!,
    ));

    if (event.lessonContent != null) {
      _lessonContent = event.lessonContent;
    }

    try {
      late String topicId;

      if (_topicId != null) {
        topicId = _topicId!;
        await _topicRepo.updateRawContent(topicId, _lessonContent!);
      } else {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        topicId = await _topicRepo.createTopic(
          classId: _classId!,
          teacherId: userId,
          title: _topicTitle!,
          rawContent: _lessonContent!,
        );
        _topicId = topicId;
      }

      await _materialRepo.upsertMaterials(topicId, event.result);

      emit(const PublishSuccess());
    } on AppException catch (e) {
      ErrorLogger.instance.logError(e, null, context: 'GenerationBloc.Publish');
      emit(PublishFailure(
        error: e.message,
        result: event.result,
        topicTitle: _topicTitle!,
        lessonContent: _lessonContent!,
        classId: _classId!,
      ));
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'GenerationBloc.Publish');
      emit(PublishFailure(
        error: e.toString(),
        result: event.result,
        topicTitle: _topicTitle!,
        lessonContent: _lessonContent!,
        classId: _classId!,
      ));
    }
  }

  void _onRestore(RestoreResult event, Emitter<GenerationState> emit) {
    _topicTitle = event.topicTitle;
    _lessonContent = event.lessonContent;
    _classId = event.classId;
    _topicId = event.topicId;
    emit(GenerationSuccess(
      result: event.result,
      topicTitle: event.topicTitle,
      lessonContent: event.lessonContent,
      classId: event.classId,
      topicId: event.topicId,
    ));
  }

  void _onReset(ResetGeneration event, Emitter<GenerationState> emit) {
    emit(const GenerationInitial());
  }
}
