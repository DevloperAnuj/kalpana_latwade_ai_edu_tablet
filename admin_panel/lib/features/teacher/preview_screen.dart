import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/draft/draft_cubit.dart';
import '../../bloc/generation/generation_bloc.dart';
import '../../models/generation_result.dart';
import 'widgets/flashcards_tab.dart';
import 'widgets/infographic_tab.dart';
import 'widgets/mindmap_tab.dart';
import 'widgets/quiz_tab.dart';
import 'widgets/table_tab.dart';

class PreviewScreen extends StatefulWidget {
  final String classId;

  const PreviewScreen({super.key, required this.classId});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Local editable copies of each material type
  late Mindmap _mindmap;
  late List<Flashcard> _flashcards;
  late Infographic _infographic;
  late TableData _tableData;
  late List<QuizQuestion> _quiz;

  late String _topicTitle;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    final state = context.read<GenerationBloc>().state;
    if (state is GenerationSuccess) {
      _initFromSuccess(state);
    }
  }

  void _initFromSuccess(GenerationSuccess s) {
    _topicTitle = s.topicTitle;
    _mindmap = s.result.mindmap;
    _flashcards = List.from(s.result.flashcards);
    _infographic = s.result.infographic;
    _tableData = s.result.table;
    _quiz = List.from(s.result.quiz.questions);
  }

  void _updateMaterial(String type, GenerationResult result) {
    switch (type) {
      case 'mindmap':
        setState(() => _mindmap = result.mindmap);
      case 'flashcards':
        setState(() => _flashcards = List.from(result.flashcards));
      case 'infographic':
        setState(() => _infographic = result.infographic);
      case 'table':
        setState(() => _tableData = result.table);
      case 'quiz':
        setState(() => _quiz = List.from(result.quiz.questions));
    }
  }

  GenerationResult get _currentResult => GenerationResult(
        mindmap: _mindmap,
        flashcards: _flashcards,
        infographic: _infographic,
        table: _tableData,
        quiz: Quiz(questions: _quiz),
      );

  void _regenerate(String materialType) {
    context.read<GenerationBloc>().add(RegenerateMaterial(materialType));
  }

  void _publish() {
    context.read<GenerationBloc>().add(PublishTopic(_currentResult));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GenerationBloc, GenerationState>(
      listener: (context, state) {
        if (state is GenerationSuccess) {
          if (state.updatedType != null) {
            _updateMaterial(state.updatedType!, state.result);
          } else {
            // Full re-generation (shouldn't normally happen on preview screen)
            setState(() => _initFromSuccess(state));
          }
        } else if (state is GenerationFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Regeneration failed (${state.failedStep}): ${state.error}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else if (state is PublishSuccess) {
          context.read<DraftCubit>().clearDraft();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Topic published successfully!')),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (state is PublishFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Publish failed: ${state.error}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isPublishing = state is PublishLoading;
        final regeneratingType =
            state is RegenerationLoading ? state.materialType : null;
        final isRegenerating = regeneratingType != null;

        final tabLabels = ['Mindmap', 'Flashcards', 'Infographic', 'Table', 'Quiz'];
        final materialKeys = ['mindmap', 'flashcards', 'infographic', 'table', 'quiz'];

        return Scaffold(
          appBar: AppBar(
            title: Text(_topicTitle),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: tabLabels.asMap().entries.map((e) {
                final key = materialKeys[e.key];
                final isRegen = regeneratingType == key;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(e.value),
                      if (isRegen) ...[
                        const SizedBox(width: 6),
                        const SizedBox.square(
                          dimension: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
            actions: [
              if (isPublishing)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: isRegenerating ? null : _publish,
                  icon: const Icon(Icons.publish),
                  label: const Text('Publish'),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // ── Mindmap ────────────────────────────────────────────────
              _TabShell(
                materialType: 'mindmap',
                regeneratingType: regeneratingType,
                onRegenerate: () => _regenerate('mindmap'),
                child: MindmapTab(mindmap: _mindmap),
              ),

              // ── Flashcards ─────────────────────────────────────────────
              _TabShell(
                materialType: 'flashcards',
                regeneratingType: regeneratingType,
                onRegenerate: () => _regenerate('flashcards'),
                child: FlashcardsTab(
                  flashcards: _flashcards,
                  onChanged: (updated) =>
                      setState(() => _flashcards = updated),
                ),
              ),

              // ── Infographic ────────────────────────────────────────────
              _TabShell(
                materialType: 'infographic',
                regeneratingType: regeneratingType,
                onRegenerate: () => _regenerate('infographic'),
                child: InfographicTab(
                  infographic: _infographic,
                  onChanged: (updated) =>
                      setState(() => _infographic = updated),
                ),
              ),

              // ── Table ──────────────────────────────────────────────────
              _TabShell(
                materialType: 'table',
                regeneratingType: regeneratingType,
                onRegenerate: () => _regenerate('table'),
                child: TableTab(
                  tableData: _tableData,
                  onChanged: (updated) =>
                      setState(() => _tableData = updated),
                ),
              ),

              // ── Quiz ───────────────────────────────────────────────────
              _TabShell(
                materialType: 'quiz',
                regeneratingType: regeneratingType,
                onRegenerate: () => _regenerate('quiz'),
                child: QuizTab(
                  questions: _quiz,
                  onChanged: (updated) => setState(() => _quiz = updated),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Tab wrapper that shows a Regenerate button at the top ────────────────────

class _TabShell extends StatelessWidget {
  final String materialType;
  final String? regeneratingType;
  final VoidCallback onRegenerate;
  final Widget child;

  const _TabShell({
    required this.materialType,
    required this.regeneratingType,
    required this.onRegenerate,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isThisRegenerating = regeneratingType == materialType;
    final anyRegenerating = regeneratingType != null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: anyRegenerating ? null : onRegenerate,
                icon: isThisRegenerating
                    ? const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 16),
                label: Text(
                    'Regenerate ${_label(materialType)}'),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  String _label(String type) => switch (type) {
        'mindmap' => 'Mindmap',
        'flashcards' => 'Flashcards',
        'infographic' => 'Infographic',
        'table' => 'Table',
        'quiz' => 'Quiz',
        _ => type,
      };
}
