import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/generation_result.dart';
import '../../services/ai_service.dart';

part 'generation_event.dart';
part 'generation_state.dart';

class GenerationBloc extends Bloc<GenerationEvent, GenerationState> {
  GenerationBloc() : super(const GenerationInitial()) {
    on<GenerateStudyPack>(_onGenerate);
    on<RegenerateMaterial>(_onRegenerate);
    on<PublishTopic>(_onPublish);
    on<RestoreResult>(_onRestore);
    on<ResetGeneration>(_onReset);
  }

  final _supabase = Supabase.instance.client;

  // In-memory key cache — never written to disk for security
  String? _cachedApiKey;

  // Current generation context (needed for RegenerateMaterial)
  String? _topicTitle;
  String? _lessonContent;
  String? _classId;
  // Non-null when editing an existing published topic (used to skip insert on republish)
  String? _topicId;

  // ── Helpers ─────────────────────────────────────────────────────────────

  Future<String> _getApiKey() async {
    _cachedApiKey ??= await _supabase.rpc<String>('get_gemini_api_key');
    return _cachedApiKey!;
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
    _topicId = null; // new topic — clear any previously restored id

    // Steps: key(0.05) mindmap(0.2) flashcards(0.4) infographic(0.6) table(0.8) quiz(1.0)
    emit(const GenerationLoading(step: 'Fetching AI key…', progress: 0.02));

    late String apiKey;
    try {
      apiKey = await _getApiKey();
    } catch (e) {
      emit(GenerationFailure(
        error: 'Could not retrieve API key: $e',
        failedStep: 'Fetching AI key',
      ));
      return;
    }

    final svc = _makeService(apiKey);

    // 5-second gap between calls keeps 5 sequential requests well under
    // Gemini free-tier 15 RPM limit.
    const callGap = Duration(seconds: 2);

    late Mindmap mindmap;
    emit(const GenerationLoading(step: 'Building mindmap…', progress: 0.15));
    try {
      mindmap = await svc.generateMindmap();
    } catch (e) {
      emit(GenerationFailure(error: e.toString(), failedStep: 'Mindmap'));
      return;
    }

    await Future.delayed(callGap);

    late List<Flashcard> flashcards;
    emit(const GenerationLoading(step: 'Creating flashcards…', progress: 0.35));
    try {
      flashcards = await svc.generateFlashcards();
    } catch (e) {
      emit(GenerationFailure(error: e.toString(), failedStep: 'Flashcards'));
      return;
    }

    await Future.delayed(callGap);

    late Infographic infographic;
    emit(const GenerationLoading(step: 'Designing infographic…', progress: 0.55));
    try {
      infographic = await svc.generateInfographic();
    } catch (e) {
      emit(GenerationFailure(error: e.toString(), failedStep: 'Infographic'));
      return;
    }

    await Future.delayed(callGap);

    late TableData table;
    emit(const GenerationLoading(step: 'Building summary table…', progress: 0.73));
    try {
      table = await svc.generateTable();
    } catch (e) {
      emit(GenerationFailure(error: e.toString(), failedStep: 'Table'));
      return;
    }

    await Future.delayed(callGap);

    late Quiz quiz;
    emit(const GenerationLoading(step: 'Writing quiz questions…', progress: 0.90));
    try {
      quiz = await svc.generateQuiz();
    } catch (e) {
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
    } catch (e) {
      emit(GenerationFailure(
        error: 'Could not retrieve API key: $e',
        failedStep: 'Fetching AI key',
      ));
      return;
    }

    final svc = _makeService(apiKey);

    try {
      final updated = switch (event.materialType) {
        'mindmap' => currentResult.copyWith(mindmap: await svc.generateMindmap()),
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
    } catch (e) {
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

    try {
      final r = event.result;
      final materials = {
        'mindmap': r.mindmap.toJson(),
        'flashcards': {'flashcards': r.flashcards.map((f) => f.toJson()).toList()},
        'infographic': r.infographic.toJson(),
        'table': r.table.toJson(),
        'quiz': r.quiz.toJson(),
      };

      late String topicId;

      // Sync lesson content if the teacher edited it in the Content tab
      if (event.lessonContent != null) {
        _lessonContent = event.lessonContent;
      }

      if (_topicId != null) {
        // Republish: update raw_content in case it was edited, then upsert materials
        topicId = _topicId!;
        await _supabase.from('topics').update({
          'raw_content': _lessonContent!,
        }).eq('id', topicId);
      } else {
        // New topic: insert row and capture its id
        final userId = _supabase.auth.currentUser!.id;
        final topicRow = await _supabase
            .from('topics')
            .insert({
              'class_id': _classId!,
              'teacher_id': userId,
              'title': _topicTitle!,
              'raw_content': _lessonContent!,
              'status': 'published',
            })
            .select('id')
            .single();
        topicId = topicRow['id'] as String;
        _topicId = topicId; // remember for any subsequent republish
      }

      for (final entry in materials.entries) {
        await _supabase.from('materials').upsert(
          {
            'topic_id': topicId,
            'type': entry.key,
            'json_data': entry.value,
          },
          onConflict: 'topic_id, type',
        );
      }

      emit(const PublishSuccess());
    } on PostgrestException catch (e) {
      emit(PublishFailure(
        error: e.message,
        result: event.result,
        topicTitle: _topicTitle!,
        lessonContent: _lessonContent!,
        classId: _classId!,
      ));
    } catch (e) {
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
