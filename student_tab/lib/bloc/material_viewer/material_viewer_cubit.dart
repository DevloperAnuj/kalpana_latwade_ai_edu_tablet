import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final Map<String, dynamic>? quizJson; // raw, consumed by Phase 9

  const MaterialViewerLoaded({
    required this.mindmapNodes,
    required this.flashcards,
    required this.infographicSections,
    required this.tableData,
    required this.quizJson,
  });
}

class MaterialViewerError extends MaterialViewerState {
  final String message;
  const MaterialViewerError(this.message);
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class MaterialViewerCubit extends Cubit<MaterialViewerState> {
  MaterialViewerCubit() : super(const MaterialViewerInitial());

  final _supabase = Supabase.instance.client;

  Future<void> loadMaterials(String topicId) async {
    emit(const MaterialViewerLoading());
    try {
      final data = await _supabase
          .from('materials')
          .select('type, json_data')
          .eq('topic_id', topicId);

      // Build a type → json_data map
      final raw = <String, Map<String, dynamic>>{};
      for (final m in (data as List)) {
        raw[m['type'] as String] = m['json_data'] as Map<String, dynamic>;
      }

      // Mindmap: {"nodes": [...]}
      final mindmapNodes = raw['mindmap'] != null
          ? (raw['mindmap']!['nodes'] as List)
              .map((n) => MindmapNode.fromJson(n as Map<String, dynamic>))
              .toList()
          : <MindmapNode>[];

      // Flashcards: {"flashcards": [{term, definition}, ...]}
      final flashcards = raw['flashcards'] != null
          ? (raw['flashcards']!['flashcards'] as List)
              .map((f) => Flashcard.fromJson(f as Map<String, dynamic>))
              .toList()
          : <Flashcard>[];

      // Infographic: {"sections": [...]}
      final infographicSections = raw['infographic'] != null
          ? (raw['infographic']!['sections'] as List)
              .map((s) =>
                  InfographicSection.fromJson(s as Map<String, dynamic>))
              .toList()
          : <InfographicSection>[];

      // Table: {"headers": [...], "rows": [[...]]}
      final tableData =
          raw['table'] != null ? TableData.fromJson(raw['table']!) : null;

      emit(MaterialViewerLoaded(
        mindmapNodes: mindmapNodes,
        flashcards: flashcards,
        infographicSections: infographicSections,
        tableData: tableData,
        quizJson: raw['quiz'],
      ));
    } catch (e) {
      emit(MaterialViewerError(e.toString()));
    }
  }
}
