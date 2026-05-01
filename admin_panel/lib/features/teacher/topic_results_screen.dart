import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/quiz_results/quiz_results_bloc.dart';
import '../../models/generation_result.dart';

class TopicResultsScreen extends StatefulWidget {
  final String topicId;
  final String topicTitle;
  final String classId;

  const TopicResultsScreen({
    super.key,
    required this.topicId,
    required this.topicTitle,
    required this.classId,
  });

  @override
  State<TopicResultsScreen> createState() => _TopicResultsScreenState();
}

class _TopicResultsScreenState extends State<TopicResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<QuizResultsBloc>().add(LoadQuizResults(
          topicId: widget.topicId,
          classId: widget.classId,
        ));
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
        actions: [
          const _LiveIndicator(),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                context.read<QuizResultsBloc>().add(const RefreshQuizResults()),
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.summarize_outlined), text: 'Summary'),
            Tab(icon: Icon(Icons.people_outlined), text: 'Students'),
          ],
        ),
      ),
      body: BlocBuilder<QuizResultsBloc, QuizResultsState>(
        builder: (context, state) {
          if (state is QuizResultsInitial || state is QuizResultsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is QuizResultsError) {
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
                        .read<QuizResultsBloc>()
                        .add(const RefreshQuizResults()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is QuizResultsLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _SummaryTab(state: state),
                _StudentsTab(state: state),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Live indicator ────────────────────────────────────────────────────────────

class _LiveIndicator extends StatefulWidget {
  const _LiveIndicator();

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _anim,
          child: const Icon(Icons.circle, color: Colors.green, size: 10),
        ),
        const SizedBox(width: 4),
        Text(
          'Live',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ── Summary tab ───────────────────────────────────────────────────────────────

class _SummaryTab extends StatelessWidget {
  final QuizResultsLoaded state;

  const _SummaryTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final attempted = state.submittedCount;
    final enrolled = state.totalEnrolled;
    final avg = state.averageScore;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(
                icon: Icons.group_outlined,
                label: 'Enrolled',
                value: '$enrolled',
                color: Theme.of(context).colorScheme.primary,
              ),
              _StatCard(
                icon: Icons.quiz_outlined,
                label: 'Attempted',
                value: '$attempted',
                color: Theme.of(context).colorScheme.secondary,
              ),
              _StatCard(
                icon: Icons.percent,
                label: 'Average score',
                value: attempted > 0 ? '${avg.toStringAsFixed(1)}%' : '–',
                color: _avgColor(avg, context),
              ),
            ],
          ),

          if (attempted > 0) ...[
            const SizedBox(height: 32),
            Text('Participation',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: enrolled > 0 ? attempted / enrolled : 0,
                minHeight: 14,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$attempted of $enrolled student${enrolled == 1 ? '' : 's'} attempted',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],

          if (attempted == 0) ...[
            const SizedBox(height: 48),
            Center(
              child: Column(
                children: [
                  Icon(Icons.hourglass_empty,
                      size: 64,
                      color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No student has taken this quiz yet.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      'Results will appear here in real time as students submit.'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _avgColor(double avg, BuildContext context) {
    if (avg >= 80) return Colors.green;
    if (avg >= 60) return Colors.orange;
    return Theme.of(context).colorScheme.error;
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

// ── Students tab ──────────────────────────────────────────────────────────────

class _StudentsTab extends StatefulWidget {
  final QuizResultsLoaded state;

  const _StudentsTab({required this.state});

  @override
  State<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<_StudentsTab> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<QuizResultsBloc>().add(const LoadMoreResults());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (state.studentResults.isEmpty) {
      return const Center(child: Text('No quiz submissions yet.'));
    }

    return ListView.separated(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: state.studentResults.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == state.studentResults.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: state.isLoadingMore
                  ? const CircularProgressIndicator()
                  : FilledButton.tonal(
                      onPressed: () => context
                          .read<QuizResultsBloc>()
                          .add(const LoadMoreResults()),
                      child: const Text('Load more'),
                    ),
            ),
          );
        }
        return _StudentCard(
          result: state.studentResults[index],
          questions: state.questions,
        );
      },
    );
  }
}

// ── Student result card with expandable wrong-answer breakdown ────────────────

class _StudentCard extends StatefulWidget {
  final StudentResult result;
  final List<QuizQuestion> questions;

  const _StudentCard({required this.result, required this.questions});

  @override
  State<_StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<_StudentCard> {
  bool _expanded = false;

  Color _scoreColor(double pct) {
    if (pct >= 80) return Colors.green;
    if (pct >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final pct = r.percentage;
    final scoreColor = _scoreColor(pct);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            leading: CircleAvatar(
              backgroundColor: scoreColor,
              child: Text(
                '${pct.toInt()}%',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(r.studentName),
            subtitle: Text(
              '${r.rollNumber != null ? '${r.rollNumber}  ·  ' : ''}'
              '${r.score} / ${r.total} correct  ·  ${_formatDate(r.submittedAt)}',
            ),
            trailing: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
            ),
          ),

          // ── Expanded wrong-answer detail ──────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1),
            if (r.wrongAnswers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Perfect score!'),
                  ],
                ),
              )
            else
              _WrongAnswerTable(wrongAnswers: r.wrongAnswers),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]}  $h:$m';
  }
}

// ── Wrong-answer breakdown table ──────────────────────────────────────────────

class _WrongAnswerTable extends StatelessWidget {
  final List<WrongAnswer> wrongAnswers;

  const _WrongAnswerTable({required this.wrongAnswers});

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(fontWeight: FontWeight.w600, fontSize: 12);
    const cellStyle = TextStyle(fontSize: 13);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder.all(
            color: Theme.of(context).dividerColor,
            borderRadius: BorderRadius.circular(6),
          ),
          children: [
            // Header row
            TableRow(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              children: const [
                _Cell(child: Text('#', style: headerStyle)),
                _Cell(child: Text('Question', style: headerStyle)),
                _Cell(child: Text('Student answered', style: headerStyle)),
                _Cell(child: Text('Correct answer', style: headerStyle)),
                _Cell(child: Text('Explanation', style: headerStyle)),
              ],
            ),

            // Data rows
            for (final wa in wrongAnswers)
              TableRow(
                children: [
                  _Cell(
                    child: Text(
                      'Q${wa.questionIndex + 1}',
                      style:
                          cellStyle.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  _Cell(
                    maxWidth: 280,
                    child: Text(wa.questionText, style: cellStyle),
                  ),
                  _Cell(
                    child: Text(
                      wa.studentAnswer,
                      style: cellStyle.copyWith(color: Colors.red),
                    ),
                  ),
                  _Cell(
                    child: Text(
                      wa.correctAnswer,
                      style: cellStyle.copyWith(color: Colors.green),
                    ),
                  ),
                  _Cell(
                    maxWidth: 320,
                    child: Text(
                      wa.explanation,
                      style: cellStyle.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const _Cell({required this.child, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: child,
    );
    if (maxWidth != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: content,
      );
    }
    return TableCell(verticalAlignment: TableCellVerticalAlignment.middle, child: content);
  }
}
