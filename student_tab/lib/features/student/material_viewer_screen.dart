import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bloc/material_viewer/material_viewer_cubit.dart';
import '../../models/study_materials.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class MaterialViewerScreen extends StatefulWidget {
  final String topicId;
  final String topicTitle;

  const MaterialViewerScreen({
    super.key,
    required this.topicId,
    required this.topicTitle,
  });

  @override
  State<MaterialViewerScreen> createState() => _MaterialViewerScreenState();
}

class _MaterialViewerScreenState extends State<MaterialViewerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.account_tree_outlined), text: 'Mindmap'),
    Tab(icon: Icon(Icons.style_outlined), text: 'Flashcards'),
    Tab(icon: Icon(Icons.layers_outlined), text: 'Infographic'),
    Tab(icon: Icon(Icons.table_chart_outlined), text: 'Table'),
    Tab(icon: Icon(Icons.quiz_outlined), text: 'Quiz'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    context.read<MaterialViewerCubit>().loadMaterials(widget.topicId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topicTitle),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs,
        ),
      ),
      body: BlocBuilder<MaterialViewerCubit, MaterialViewerState>(
        builder: (context, state) {
          if (state is MaterialViewerLoading ||
              state is MaterialViewerInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MaterialViewerError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => context
                        .read<MaterialViewerCubit>()
                        .loadMaterials(widget.topicId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is MaterialViewerLoaded) {
            return TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _MindmapTab(nodes: state.mindmapNodes),
                _FlashcardsTab(flashcards: state.flashcards),
                _InfographicTab(sections: state.infographicSections),
                _TableTab(tableData: state.tableData),
                _QuizTab(
                  quizJson: state.quizJson,
                  materialId: state.quizMaterialId,
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Shared empty state ────────────────────────────────────────────────────────

class _EmptyMaterial extends StatelessWidget {
  final String message;
  const _EmptyMaterial(this.message);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline,
              size: 48, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Mindmap tab – full tree, all nodes visible simultaneously
// ════════════════════════════════════════════════════════════════════════════

// Column widths and spacing
const double _kMmRootW = 210.0;
const double _kMmNodeW = 148.0;
const double _kMmNodeH = 40.0;
const double _kMmHGap = 52.0; // horizontal gap between a node's right edge and its children
const double _kMmRowGap = 14.0; // vertical gap between sibling leaf slots

/// Left-x of a node at [depth].
double _mmX(int depth) =>
    depth == 0 ? 0.0 : _kMmRootW + _kMmHGap + (depth - 1) * (_kMmNodeW + _kMmHGap);

/// Width of a node at [depth].
double _mmW(int depth) => depth == 0 ? _kMmRootW : _kMmNodeW;

class _MindmapTab extends StatelessWidget {
  final List<MindmapNode> nodes;
  const _MindmapTab({required this.nodes});

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return const _EmptyMaterial('Mindmap not available for this topic.');
    }

    final childrenMap = <String?, List<MindmapNode>>{};
    for (final n in nodes) {
      childrenMap.putIfAbsent(n.parentId, () => []).add(n);
    }

    final roots = childrenMap[null] ?? [];
    if (roots.isEmpty) {
      return const _EmptyMaterial('Mindmap not available for this topic.');
    }

    // ── Layout ───────────────────────────────────────────────────────────
    // positions: node.id → (left_x, center_y)
    // depths:    node.id → depth level
    final positions = <String, Offset>{};
    final depths = <String, int>{};

    double totalH = 0;
    for (final root in roots) {
      totalH += _mmLayout(root, 0, totalH, childrenMap, positions, depths);
    }

    // ── Edges ────────────────────────────────────────────────────────────
    final edges = <_MmEdge>[];
    _mmCollectEdges(roots, childrenMap, positions, depths, edges);

    // ── Canvas size ──────────────────────────────────────────────────────
    int maxDepth = 0;
    for (final d in depths.values) {
      if (d > maxDepth) maxDepth = d;
    }
    final canvasW = _mmX(maxDepth) + _mmW(maxDepth) + 40;
    final canvasH = totalH + 40;

    final cs = Theme.of(context).colorScheme;

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(80),
      minScale: 0.25,
      maxScale: 3.5,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: canvasW,
          height: canvasH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Bezier lines drawn behind nodes
              Positioned.fill(
                child: CustomPaint(
                  painter: _MindmapPainter(
                    edges: edges,
                    lineColor: cs.primary.withValues(alpha: 0.45),
                  ),
                ),
              ),
              // Node boxes
              ...positions.entries.map((e) {
                final node = nodes.firstWhere((n) => n.id == e.key);
                final depth = depths[e.key]!;
                return Positioned(
                  left: e.value.dx,
                  top: e.value.dy - _kMmNodeH / 2,
                  child: _MindmapNodeBox(
                    label: node.label,
                    width: _mmW(depth),
                    isRoot: depth == 0,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Recursively positions [node] (and its whole subtree) starting at [startY].
/// Returns the total vertical height consumed by this subtree.
double _mmLayout(
  MindmapNode node,
  int depth,
  double startY,
  Map<String?, List<MindmapNode>> childrenMap,
  Map<String, Offset> positions,
  Map<String, int> depths,
) {
  depths[node.id] = depth;
  final children = childrenMap[node.id] ?? [];

  if (children.isEmpty) {
    // Leaf: occupies one row slot, centred vertically within it.
    positions[node.id] = Offset(_mmX(depth), startY + _kMmNodeH / 2);
    return _kMmNodeH + _kMmRowGap;
  }

  // Lay out children first, then centre this node over them.
  double childY = startY;
  for (final child in children) {
    childY += _mmLayout(child, depth + 1, childY, childrenMap, positions, depths);
  }

  final firstCY = positions[children.first.id]!.dy;
  final lastCY = positions[children.last.id]!.dy;
  positions[node.id] = Offset(_mmX(depth), (firstCY + lastCY) / 2);

  return childY - startY;
}

void _mmCollectEdges(
  List<MindmapNode> nodes,
  Map<String?, List<MindmapNode>> childrenMap,
  Map<String, Offset> positions,
  Map<String, int> depths,
  List<_MmEdge> edges,
) {
  for (final node in nodes) {
    final children = childrenMap[node.id] ?? [];
    if (children.isEmpty) continue;

    final pPos = positions[node.id]!;
    final pDepth = depths[node.id]!;
    final fromX = pPos.dx + _mmW(pDepth); // right edge of parent

    for (final child in children) {
      final cPos = positions[child.id]!;
      edges.add(_MmEdge(
        from: Offset(fromX, pPos.dy),
        to: Offset(cPos.dx, cPos.dy),
      ));
    }
    _mmCollectEdges(children, childrenMap, positions, depths, edges);
  }
}

class _MmEdge {
  final Offset from, to;
  const _MmEdge({required this.from, required this.to});
}

class _MindmapPainter extends CustomPainter {
  final List<_MmEdge> edges;
  final Color lineColor;

  const _MindmapPainter({required this.edges, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final e in edges) {
      final cpX = e.from.dx + (e.to.dx - e.from.dx) * 0.5;
      final path = Path()
        ..moveTo(e.from.dx, e.from.dy)
        ..cubicTo(cpX, e.from.dy, cpX, e.to.dy, e.to.dx, e.to.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_MindmapPainter old) =>
      old.edges != edges || old.lineColor != lineColor;
}

class _MindmapNodeBox extends StatelessWidget {
  final String label;
  final double width;
  final bool isRoot;

  const _MindmapNodeBox({
    required this.label,
    required this.width,
    required this.isRoot,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: _kMmNodeH,
      decoration: BoxDecoration(
        color: isRoot ? cs.primaryContainer : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRoot ? cs.primary : cs.primary.withValues(alpha: 0.5),
          width: isRoot ? 1.5 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: isRoot ? 0.22 : 0.08),
            blurRadius: isRoot ? 12 : 5,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          color: isRoot ? cs.onPrimaryContainer : cs.onSurface,
          fontSize: isRoot ? 13 : 12,
          fontWeight: isRoot ? FontWeight.w600 : FontWeight.w400,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Flashcards tab
// ════════════════════════════════════════════════════════════════════════════

class _FlashcardsTab extends StatefulWidget {
  final List<Flashcard> flashcards;

  const _FlashcardsTab({required this.flashcards});

  @override
  State<_FlashcardsTab> createState() => _FlashcardsTabState();
}

class _FlashcardsTabState extends State<_FlashcardsTab> {
  int _index = 0;
  late List<Flashcard> _deck;

  @override
  void initState() {
    super.initState();
    _deck = List.of(widget.flashcards);
  }

  void _prev() {
    if (_index > 0) setState(() => _index--);
  }

  void _next() {
    if (_index < _deck.length - 1) setState(() => _index++);
  }

  void _shuffle() {
    setState(() {
      _deck.shuffle();
      _index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_deck.isEmpty) {
      return const _EmptyMaterial('Flashcards not available for this topic.');
    }

    final card = _deck[_index];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Counter + shuffle
          Row(
            children: [
              Text(
                'Card ${_index + 1} of ${_deck.length}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _shuffle,
                icon: const Icon(Icons.shuffle, size: 18),
                label: const Text('Shuffle'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_index + 1) / _deck.length,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 24),

          // Flip card — re-keyed on index so it resets to front on navigation
          Expanded(
            child: _FlipCard(
              key: ValueKey(_index),
              term: card.term,
              definition: card.definition,
            ),
          ),
          const SizedBox(height: 24),

          // Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FilledButton.tonalIcon(
                onPressed: _index > 0 ? _prev : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Previous'),
              ),
              FilledButton.icon(
                onPressed:
                    _index < _deck.length - 1 ? _next : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Flip card ─────────────────────────────────────────────────────────────────

class _FlipCard extends StatefulWidget {
  final String term;
  final String definition;

  const _FlipCard({
    super.key,
    required this.term,
    required this.definition,
  });

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_ctrl.isAnimating) return;
    if (_showFront) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
    setState(() => _showFront = !_showFront);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final angle = _ctrl.value * math.pi;
          final isFrontVisible = angle <= math.pi / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isFrontVisible
                ? _CardFace(
                    label: 'TERM',
                    text: widget.term,
                    bgColor: cs.primaryContainer,
                    fgColor: cs.onPrimaryContainer,
                  )
                : Transform(
                    transform: Matrix4.rotationY(math.pi),
                    alignment: Alignment.center,
                    child: _CardFace(
                      label: 'DEFINITION',
                      text: widget.definition,
                      bgColor: cs.secondaryContainer,
                      fgColor: cs.onSecondaryContainer,
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String label;
  final String text;
  final Color bgColor;
  final Color fgColor;

  const _CardFace({
    required this.label,
    required this.text,
    required this.bgColor,
    required this.fgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      color: bgColor,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: fgColor.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 22, color: fgColor, height: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_outlined,
                      size: 14, color: fgColor.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to flip',
                    style: TextStyle(
                        fontSize: 12, color: fgColor.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Infographic tab  –  numbered side-stripe cards
// ════════════════════════════════════════════════════════════════════════════

class _InfographicTab extends StatelessWidget {
  final List<InfographicSection> sections;
  const _InfographicTab({required this.sections});

  static const _palette = [
    Color(0xFF4C6EF5), // indigo
    Color(0xFF0CA678), // teal
    Color(0xFFE8590C), // orange
    Color(0xFFAE3EC9), // violet
    Color(0xFF1971C2), // blue
    Color(0xFFC92A2A), // red
    Color(0xFF2F9E44), // green
    Color(0xFF1098AD), // cyan
  ];

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const _EmptyMaterial('Infographic not available for this topic.');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      itemCount: sections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, i) => _InfographicCard(
        section: sections[i],
        sectionNumber: i + 1,
        accentColor: _palette[i % _palette.length],
      ),
    );
  }
}

class _InfographicCard extends StatelessWidget {
  final InfographicSection section;
  final int sectionNumber;
  final Color accentColor;

  const _InfographicCard({
    required this.section,
    required this.sectionNumber,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1C2130) : Colors.white;
    final bodyText = isDark ? Colors.white70 : Colors.black87;
    final numStr = sectionNumber.toString().padLeft(2, '0');

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colored left stripe: section number + icon
            Container(
              width: 68,
              color: accentColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    numStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  if (section.iconReference != null &&
                      section.iconReference!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        section.iconReference!,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                ],
              ),
            ),

            // Content: title + bullets
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...section.bullets.map((bullet) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 6, right: 10),
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  bullet,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.55,
                                    color: bodyText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Table tab
// ════════════════════════════════════════════════════════════════════════════

class _TableTab extends StatelessWidget {
  final TableData? tableData;

  const _TableTab({required this.tableData});

  @override
  Widget build(BuildContext context) {
    if (tableData == null) {
      return const _EmptyMaterial('Table not available for this topic.');
    }

    final t = tableData!;
    if (t.headers.isEmpty) {
      return const _EmptyMaterial('Table not available for this topic.');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
            Theme.of(context).colorScheme.primaryContainer,
          ),
          border: TableBorder.all(
            color: Theme.of(context).dividerColor,
            borderRadius: BorderRadius.circular(8),
          ),
          columns: t.headers
              .map((h) => DataColumn(
                    label: Text(
                      h,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                    ),
                  ))
              .toList(),
          rows: t.rows
              .map((row) => DataRow(
                    cells: row.map((cell) => DataCell(Text(cell))).toList(),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Quiz tab – Phase 9
// ════════════════════════════════════════════════════════════════════════════

enum _QuizPhase { taking, submitting, done }

class _WrongAnswer {
  final int index;
  final String questionText;
  final String selectedText;
  final String correctText;
  final String explanation;

  const _WrongAnswer({
    required this.index,
    required this.questionText,
    required this.selectedText,
    required this.correctText,
    required this.explanation,
  });
}

class _QuizResult {
  final int score;
  final int total;
  final List<_WrongAnswer> wrongAnswers;
  final String? submitError; // null = submitted OK

  const _QuizResult({
    required this.score,
    required this.total,
    required this.wrongAnswers,
    this.submitError,
  });
}

class _QuizTab extends StatefulWidget {
  final Map<String, dynamic>? quizJson;
  final String? materialId;

  const _QuizTab({required this.quizJson, required this.materialId});

  @override
  State<_QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<_QuizTab> {
  List<QuizQuestion> _questions = [];
  List<int?> _selected = [];
  _QuizPhase _phase = _QuizPhase.taking;
  _QuizResult? _result;
  bool _parseError = false;

  @override
  void initState() {
    super.initState();
    _parseQuestions();
  }

  void _parseQuestions() {
    if (widget.quizJson == null) return;
    try {
      final list = widget.quizJson!['questions'] as List;
      _questions = list
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
      _selected = List.filled(_questions.length, null);
    } catch (_) {
      _parseError = true;
    }
  }

  int get _answeredCount => _selected.where((s) => s != null).length;
  bool get _allAnswered =>
      _questions.isNotEmpty && _answeredCount == _questions.length;

  Future<void> _confirmAndSubmit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Quiz?'),
        content: Text(
            'You have answered $_answeredCount of ${_questions.length} questions. Submit now?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit')),
        ],
      ),
    );
    if (confirmed == true && mounted) await _submit();
  }

  Future<void> _submit() async {
    // Grade
    int score = 0;
    final wrong = <_WrongAnswer>[];
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final ans = _selected[i]!;
      if (ans == q.correct) {
        score++;
      } else {
        wrong.add(_WrongAnswer(
          index: i,
          questionText: q.text,
          selectedText: q.options[ans],
          correctText: q.options[q.correct],
          explanation: q.explanation,
        ));
      }
    }

    setState(() => _phase = _QuizPhase.submitting);

    // Push to Supabase
    String? submitError;
    if (widget.materialId == null) {
      submitError = 'material_id is null — quiz was not saved to the database.';
    } else {
      try {
        final supabase = Supabase.instance.client;
        final answersJson = {
          for (int i = 0; i < _selected.length; i++) '$i': _selected[i]!
        };
        await supabase.from('quiz_attempts').insert({
          'student_id': supabase.auth.currentUser!.id,
          'material_id': widget.materialId,
          'answers_json': answersJson,
          'score': score,
        });
      } catch (e) {
        submitError = e.toString();
      }
    }

    if (!mounted) return;
    setState(() {
      _result = _QuizResult(
          score: score,
          total: _questions.length,
          wrongAnswers: wrong,
          submitError: submitError);
      _phase = _QuizPhase.done;
    });
  }

  Future<void> _retrySubmit() async {
    setState(() => _phase = _QuizPhase.submitting);
    String? submitError;
    try {
      final supabase = Supabase.instance.client;
      final answersJson = {
        for (int i = 0; i < _selected.length; i++) '$i': _selected[i]!
      };
      await supabase.from('quiz_attempts').insert({
        'student_id': supabase.auth.currentUser!.id,
        'material_id': widget.materialId,
        'answers_json': answersJson,
        'score': _result!.score,
      });
    } catch (e) {
      submitError = e.toString();
    }
    if (!mounted) return;
    setState(() {
      _result = _QuizResult(
          score: _result!.score,
          total: _result!.total,
          wrongAnswers: _result!.wrongAnswers,
          submitError: submitError);
      _phase = _QuizPhase.done;
    });
  }

  void _retake() {
    setState(() {
      _selected = List.filled(_questions.length, null);
      _phase = _QuizPhase.taking;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quizJson == null) {
      return const _EmptyMaterial('Quiz not available for this topic.');
    }
    if (_parseError) {
      return const _EmptyMaterial(
          'Quiz data is invalid. Please contact your teacher.');
    }
    if (_questions.isEmpty) {
      return const _EmptyMaterial('No questions found in this quiz.');
    }

    return switch (_phase) {
      _QuizPhase.taking => _buildForm(context),
      _QuizPhase.submitting =>
        const Center(child: CircularProgressIndicator()),
      _QuizPhase.done => _buildResults(context),
    };
  }

  // ── Quiz form ─────────────────────────────────────────────────────────────

  Widget _buildForm(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final answered = _answeredCount;
    final total = _questions.length;

    return Column(
      children: [
        // Sticky progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$answered of $total answered',
                      style: Theme.of(context).textTheme.labelMedium),
                  Text('${(answered / total * 100).round()}%',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: cs.primary, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                    value: answered / total, minHeight: 6),
              ),
            ],
          ),
        ),

        // Scrollable questions + submit button
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: _questions.length + 1,
            itemBuilder: (ctx, i) {
              if (i == _questions.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FilledButton.icon(
                    onPressed:
                        _allAnswered ? () => _confirmAndSubmit(context) : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Submit Quiz'),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                  ),
                );
              }

              final q = _questions[i];
              final selected = _selected[i];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: selected != null
                                  ? cs.primary
                                  : cs.surfaceContainerHigh,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text('${i + 1}',
                                style: TextStyle(
                                  color: selected != null
                                      ? cs.onPrimary
                                      : cs.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                )),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(q.text,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Options
                      ...List.generate(q.options.length, (oi) {
                        final isSel = selected == oi;
                        return GestureDetector(
                          onTap: () => setState(() => _selected[i] = oi),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 7),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? cs.primaryContainer
                                  : cs.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSel ? cs.primary : cs.outlineVariant,
                                width: isSel ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSel
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: isSel
                                      ? cs.primary
                                      : cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    q.options[oi],
                                    style: TextStyle(
                                      color: isSel
                                          ? cs.onPrimaryContainer
                                          : cs.onSurface,
                                      fontWeight: isSel
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Results view ──────────────────────────────────────────────────────────

  Widget _buildResults(BuildContext context) {
    final r = _result!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = r.score / r.total;
    final isGood = pct >= 0.7;
    final accentColor =
        isGood ? const Color(0xFF2E7D32) : cs.error;
    final bannerBg = isGood
        ? (isDark ? const Color(0xFF1B3A1E) : const Color(0xFFE8F5E9))
        : cs.errorContainer;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Score banner
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: bannerBg, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Icon(
                isGood ? Icons.emoji_events_rounded : Icons.replay_rounded,
                size: 52,
                color: accentColor,
              ),
              const SizedBox(height: 10),
              Text(
                'You got ${r.score} / ${r.total} correct!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700, color: accentColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 10,
                  color: accentColor,
                  backgroundColor: accentColor.withValues(alpha: 0.18),
                ),
              ),
              const SizedBox(height: 6),
              Text('${(pct * 100).round()}%',
                  style: TextStyle(
                      color: accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Submission status banner
        if (r.submitError == null)
          _statusTile(context,
              icon: Icons.cloud_done_rounded,
              color: const Color(0xFF1971C2),
              text: 'Results submitted to your teacher.')
        else ...[
          _statusTile(context,
              icon: Icons.cloud_off_rounded,
              color: cs.error,
              text: 'Submission failed: ${r.submitError}'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _retrySubmit,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry Submission'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44)),
          ),
        ],
        const SizedBox(height: 20),

        // Wrong answers
        if (r.wrongAnswers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                const Icon(Icons.star_rounded,
                    size: 48, color: Color(0xFFFCC419)),
                const SizedBox(height: 8),
                Text('Perfect score — all answers correct!',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center),
              ],
            ),
          )
        else ...[
          Text('Review wrong answers',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...r.wrongAnswers.map((w) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading:
                      Icon(Icons.close_rounded, color: cs.error, size: 20),
                  title: Text(
                    'Q${w.index + 1}. ${w.questionText}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _answerRow(context, 'Your answer', w.selectedText,
                              cs.error),
                          const SizedBox(height: 6),
                          _answerRow(context, 'Correct answer',
                              w.correctText, const Color(0xFF2E7D32)),
                          if (w.explanation.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('💡 ',
                                      style: TextStyle(fontSize: 14)),
                                  Expanded(
                                    child: Text(w.explanation,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(height: 1.5)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],

        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _retake,
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Retake Quiz'),
          style:
              OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _statusTile(BuildContext context,
      {required IconData icon,
      required Color color,
      required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _answerRow(
      BuildContext context, String label, String answer, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text('$label:',
              style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(answer,
              style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

