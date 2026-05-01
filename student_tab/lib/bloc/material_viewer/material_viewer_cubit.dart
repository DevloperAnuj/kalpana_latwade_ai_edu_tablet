import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:eduforge_core/eduforge_core.dart';

import '../../data/repositories/material_repository.dart';
import '../../models/study_materials.dart';

// ── States ────────────────────────────────────────────────────────────────────

abstract class MaterialViewerState {
  const MaterialViewerState();
}

class MaterialViewerInitial extends MaterialViewerState {
  const MaterialViewerInitial();
}

class MaterialViewerLoading extends MaterialViewerState {
  const MaterialViewerLoading();
}

class MaterialViewerLoaded extends MaterialViewerState {
  final List<MindmapNode> mindmapNodes;
  final List<Flashcard> flashcards;
  final List<InfographicSection> infographicSections;
  final TableData? tableData;
  final Map<String, dynamic>? quizJson;
  final String? quizMaterialId;

  const MaterialViewerLoaded({
    required this.mindmapNodes,
    required this.flashcards,
    required this.infographicSections,
    required this.tableData,
    required this.quizJson,
    required this.quizMaterialId,
  });
}

class MaterialViewerError extends MaterialViewerState {
  final String message;
  const MaterialViewerError(this.message);
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class MaterialViewerCubit extends Cubit<MaterialViewerState> {
  MaterialViewerCubit({StudentMaterialRepository? repository})
      : _repo = repository ??
            StudentMaterialRepository(Supabase.instance.client),
        super(const MaterialViewerInitial());

  final StudentMaterialRepository _repo;

  Future<void> loadMaterials(String topicId) async {
    emit(const MaterialViewerLoading());
    try {
      final (:byType, :quizMaterialId) = await _repo.fetchMaterials(topicId);

      final mindmapNodes = byType['mindmap'] != null
          ? (byType['mindmap']!['nodes'] as List)
              .map((n) => MindmapNode.fromJson(n as Map<String, dynamic>))
              .toList()
          : <MindmapNode>[];

      final flashcards = byType['flashcards'] != null
          ? (byType['flashcards']!['flashcards'] as List)
              .map((f) => Flashcard.fromJson(f as Map<String, dynamic>))
              .toList()
          : <Flashcard>[];

      final infographicSections = byType['infographic'] != null
          ? (byType['infographic']!['sections'] as List)
              .map((s) =>
                  InfographicSection.fromJson(s as Map<String, dynamic>))
              .toList()
          : <InfographicSection>[];

      final tableData =
          byType['table'] != null ? TableData.fromJson(byType['table']!) : null;

      emit(MaterialViewerLoaded(
        mindmapNodes: mindmapNodes,
        flashcards: flashcards,
        infographicSections: infographicSections,
        tableData: tableData,
        quizJson: byType['quiz'],
        quizMaterialId: quizMaterialId,
      ));
    } on AppException catch (e) {
      ErrorLogger.instance.logError(e, null, context: 'MaterialViewerCubit');
      emit(MaterialViewerError(e.message));
    } catch (e, st) {
      ErrorLogger.instance.logError(e, st, context: 'MaterialViewerCubit');
      emit(MaterialViewerError(e.toString()));
    }
  }
}
