import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentTopicListScreen extends StatefulWidget {
  final String classId;
  final String className;

  const StudentTopicListScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<StudentTopicListScreen> createState() =>
      _StudentTopicListScreenState();
}

class _StudentTopicListScreenState extends State<StudentTopicListScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _topicsFuture;

  @override
  void initState() {
    super.initState();
    _topicsFuture = _fetchTopics();
  }

  Future<List<Map<String, dynamic>>> _fetchTopics() async {
    final data = await _supabase
        .from('topics')
        .select('id, title, created_at')
        .eq('class_id', widget.classId)
        .eq('status', 'published')
        .order('created_at', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.className),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                setState(() => _topicsFuture = _fetchTopics()),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
                  Icon(Icons.cloud_off,
                      size: 48,
                      color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 12),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () =>
                        setState(() => _topicsFuture = _fetchTopics()),
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
                  Text(
                    'No topics yet.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check back later when your teacher publishes topics!',
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: topics.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final topic = topics[index];
              final topicId = topic['id'] as String;
              final title = topic['title'] as String;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context)
                          .colorScheme
                          .onSecondaryContainer,
                    ),
                  ),
                  title: Text(title),
                  subtitle: const Text('5 study tools available'),
                  trailing: FilledButton(
                    onPressed: () => context.push(
                      '/student/material/$topicId',
                      extra: title,
                    ),
                    child: const Text('View'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
