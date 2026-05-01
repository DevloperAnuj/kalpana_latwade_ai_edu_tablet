import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bloc/draft/draft_cubit.dart';
import '../../bloc/generation/generation_bloc.dart';
import '../../models/generation_result.dart';

class TopicsScreen extends StatefulWidget {
  final String classId;
  final String className;

  const TopicsScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _topicsFuture;
  late TabController _tabController;

  String? _loadingTopicId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _load() {
    _topicsFuture = _fetchTopics();
  }

  Future<List<Map<String, dynamic>>> _fetchTopics() async {
    final data = await _supabase
        .from('topics')
        .select('id, title, status, raw_content, created_at')
        .eq('class_id', widget.classId)
        .order('created_at', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  // ── Open existing topic in PreviewScreen ─────────────────────────────────

  Future<void> _openTopic(Map<String, dynamic> topic) async {
    final topicId = topic['id'] as String;
    setState(() => _loadingTopicId = topicId);

    try {
      final materials = await _supabase
          .from('materials')
          .select('type, json_data')
          .eq('topic_id', topicId);

      final matMap = <String, dynamic>{};
      for (final m in (materials as List)) {
        matMap[m['type'] as String] = m['json_data'];
      }

      const required = ['mindmap', 'flashcards', 'infographic', 'table', 'quiz'];
      final missing = required.where((k) => !matMap.containsKey(k)).toList();
      if (missing.isNotEmpty) {
        throw Exception('Topic is missing materials: ${missing.join(', ')}');
      }

      final result = GenerationResult(
        mindmap: Mindmap.fromJson(matMap['mindmap'] as Map<String, dynamic>),
        flashcards: (matMap['flashcards']['flashcards'] as List)
            .map((e) => Flashcard.fromJson(e as Map<String, dynamic>))
            .toList(),
        infographic:
            Infographic.fromJson(matMap['infographic'] as Map<String, dynamic>),
        table: TableData.fromJson(matMap['table'] as Map<String, dynamic>),
        quiz: Quiz.fromJson(matMap['quiz'] as Map<String, dynamic>),
      );

      if (!mounted) return;

      context.read<GenerationBloc>().add(RestoreResult(
            result: result,
            topicTitle: topic['title'] as String,
            lessonContent: topic['raw_content'] as String,
            classId: widget.classId,
            topicId: topicId,
          ));

      await context.push('/teacher/classes/${widget.classId}/topics/preview');
      if (mounted) setState(_load);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load topic: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingTopicId = null);
    }
  }

  // ── Edit title ────────────────────────────────────────────────────────────

  Future<void> _editTitle(String topicId, String currentTitle) async {
    final ctrl = TextEditingController(text: currentTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Title'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Topic title',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    ctrl.dispose();

    if (newTitle == null || newTitle.isEmpty || newTitle == currentTitle) return;

    try {
      await _supabase
          .from('topics')
          .update({'title': newTitle})
          .eq('id', topicId);
      setState(_load);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update title: $e')),
        );
      }
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _delete(String topicId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error),
        title: const Text('Delete Topic?'),
        content: Text(
          'Deleting "$title" will also remove all its generated materials. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('topics').delete().eq('id', topicId);
      setState(_load);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  // ── Resume local draft ────────────────────────────────────────────────────

  void _resumeDraft(DraftState draft) {
    final result = draft.generationResult;
    if (result == null) {
      context.read<DraftCubit>().clearDraft();
      return;
    }
    context.read<GenerationBloc>().add(RestoreResult(
          result: result,
          topicTitle: draft.topicTitle!,
          lessonContent: draft.lessonContent!,
          classId: widget.classId,
          // topicId null: draft not yet published
        ));
    context.push('/teacher/classes/${widget.classId}/topics/preview');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.className),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.check_circle_outline), text: 'Published'),
            Tab(icon: Icon(Icons.edit_note), text: 'Draft'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(
            '/teacher/classes/${widget.classId}/new-topic',
            extra: widget.className,
          );
          setState(_load);
        },
        icon: const Icon(Icons.auto_awesome),
        label: const Text('New Topic'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPublishedTab(),
          _buildDraftTab(),
        ],
      ),
    );
  }

  // ── Published tab ─────────────────────────────────────────────────────────

  Widget _buildPublishedTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _topicsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(snapshot.error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => setState(_load),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final topics = snapshot.data ?? [];

        if (topics.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.topic_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 16),
                Text('No topics yet.',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text('Tap + to create your first topic.'),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: topics.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final t = topics[index];
            final topicId = t['id'] as String;
            final title = t['title'] as String;
            final status = t['status'] as String;
            final createdAt =
                DateTime.parse(t['created_at'] as String).toLocal();
            final isPublished = status == 'published';
            final isThisLoading = _loadingTopicId == topicId;

            return Card(
              child: ListTile(
                onTap: _loadingTopicId != null ? null : () => _openTopic(t),
                leading: isThisLoading
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isPublished
                            ? Icons.check_circle_outline
                            : Icons.edit_note,
                        color: isPublished
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                title: Text(title),
                subtitle: Text(_formatDate(createdAt)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(
                        isPublished ? 'Published' : 'Draft',
                        style: TextStyle(
                          fontSize: 11,
                          color: isPublished
                              ? Theme.of(context).colorScheme.onPrimary
                              : null,
                        ),
                      ),
                      backgroundColor: isPublished
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      padding: EdgeInsets.zero,
                    ),
                    if (isPublished)
                      IconButton(
                        icon: const Icon(Icons.bar_chart_rounded),
                        tooltip: 'View quiz results',
                        onPressed: _loadingTopicId != null
                            ? null
                            : () => context.push(
                                  '/teacher/classes/${widget.classId}/topics/$topicId/results',
                                  extra: title,
                                ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit title',
                      onPressed: _loadingTopicId != null
                          ? null
                          : () => _editTitle(topicId, title),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Theme.of(context).colorScheme.error,
                      tooltip: 'Delete topic',
                      onPressed: _loadingTopicId != null
                          ? null
                          : () => _delete(topicId, title),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Draft tab ─────────────────────────────────────────────────────────────

  Widget _buildDraftTab() {
    return BlocBuilder<DraftCubit, DraftState>(
      builder: (context, draft) {
        if (draft.isEmpty || !draft.matchesClass(widget.classId)) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_note,
                  size: 80,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 16),
                Text('No local draft.',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                    'Generate a topic — it auto-saves here until published.'),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              draft.topicTitle ?? 'Untitled Draft',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              draft.generationResult != null
                                  ? 'Materials generated — not yet published'
                                  : 'Lesson saved — generation pending',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            context.read<DraftCubit>().clearDraft(),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Discard'),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _resumeDraft(draft),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('Continue editing'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
