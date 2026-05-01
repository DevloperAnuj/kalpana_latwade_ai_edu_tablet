import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eduforge_core/eduforge_core.dart';

import '../../bloc/ai_key/ai_key_bloc.dart';
import '../../bloc/class/class_bloc.dart';
import '../../bloc/class_selection/class_selection_cubit.dart';
import '../../bloc/draft/draft_cubit.dart';
import '../../bloc/generation/generation_bloc.dart';
import '../../models/class_model.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ClassBloc>().add(const FetchClasses());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ClassBloc, ClassState>(
          listener: (context, state) {
            if (state is ClassOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            } else if (state is ClassError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
        ),
        BlocListener<AiKeyBloc, AiKeyState>(
          listener: (context, state) {
            if (state is AiKeyExpired) _showKeyExpiredDialog(context);
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final name = authState is Authenticated
                ? authState.displayName
                : null;
            return Text(
              name != null && name.isNotEmpty
                  ? 'Welcome, $name'
                  : 'My Classes',
            );
          },
        ),
          actions: [
            BlocBuilder<AiKeyBloc, AiKeyState>(
              builder: (context, state) => IconButton(
                icon: state is AiKeyLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.vpn_key_outlined),
                tooltip: 'Refresh AI key',
                onPressed: state is AiKeyLoading
                    ? null
                    : () =>
                        context.read<AiKeyBloc>().add(const RefreshAiKey()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.brightness_6),
              tooltip: 'Toggle theme',
              onPressed: () => context.read<ThemeCubit>().toggleTheme(),
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: 'My profile',
              onPressed: () => context.push('/profile'),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
            ),
          ],
        ),
        body: Column(
          children: [
            // Draft resume banner
            BlocBuilder<DraftCubit, DraftState>(
              builder: (context, draft) {
                if (draft.isEmpty) return const SizedBox.shrink();
                return MaterialBanner(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: const Icon(Icons.edit_note),
                  content: Text(
                      'Unsaved draft: "${draft.topicTitle ?? 'Untitled'}"'),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          context.read<DraftCubit>().clearDraft(),
                      child: const Text('Discard'),
                    ),
                    FilledButton(
                      onPressed: () => _resumeDraft(context, draft),
                      child: const Text('Resume'),
                    ),
                  ],
                );
              },
            ),
            // Class list
            Expanded(
              child: BlocBuilder<ClassBloc, ClassState>(
                builder: (context, state) {
                  if (state is ClassInitial ||
                      state is ClassLoading ||
                      state is ClassOperationSuccess) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ClassError) {
                    return _ErrorState(
                      message: state.message,
                      onRetry: () =>
                          context.read<ClassBloc>().add(const FetchClasses()),
                    );
                  }

                  if (state is ClassesLoaded) {
                    if (state.classes.isEmpty) return const _EmptyState();

                    return ResponsiveLayout(
                      compact: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.classes.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ClassCard(cls: state.classes[index]),
                        ),
                      ),
                      medium: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: state.classes
                              .map((cls) => SizedBox(
                                    width: 380,
                                    child: _ClassCard(cls: cls),
                                  ))
                              .toList(),
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('New Class'),
        ),
      ),
    );
  }

  void _resumeDraft(BuildContext context, DraftState draft) {
    final result = draft.generationResult;
    if (result == null) {
      context.read<DraftCubit>().clearDraft();
      return;
    }
    context.read<GenerationBloc>().add(RestoreResult(
          result: result,
          topicTitle: draft.topicTitle!,
          lessonContent: draft.lessonContent!,
          classId: draft.classId!,
        ));
    context.push('/teacher/classes/${draft.classId}/topics/preview');
  }

  void _showCreateDialog(BuildContext ctx) {
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: ctx.read<ClassBloc>(),
        child: const _CreateClassDialog(),
      ),
    );
  }

  void _showKeyExpiredDialog(BuildContext ctx) {
    showDialog<void>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        icon: const Icon(Icons.vpn_key_off_outlined),
        title: const Text('AI Key May Have Expired'),
        content: const Text(
          'The AI API key could not be retrieved. '
          'It may have expired or your account lacks permission.\n\n'
          'Contact your administrator to renew the key, then tap '
          '"Refresh AI Key" in the toolbar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('OK'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ctx.read<AiKeyBloc>().add(const RefreshAiKey());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ─── Create class dialog ─────────────────────────────────────────────────────

class _CreateClassDialog extends StatefulWidget {
  const _CreateClassDialog();

  @override
  State<_CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends State<_CreateClassDialog> {
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    context.read<ClassBloc>().add(CreateClass(name));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClassBloc, ClassState>(
      listener: (context, state) {
        if (state is ClassOperationSuccess) {
          Navigator.of(context).pop();
        } else if (state is ClassError) {
          // Error snackbar is shown by the parent listener; keep dialog open.
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final isLoading = state is ClassLoading;
        final hasText = _nameCtrl.text.trim().isNotEmpty;

        return AlertDialog(
          title: const Text('New Class'),
          content: SizedBox(
            width: 360,
            child: TextField(
              controller: _nameCtrl,
              autofocus: true,
              enabled: !isLoading,
              decoration: const InputDecoration(
                labelText: 'Class name',
                hintText: 'e.g. Grade 10 – Science',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: hasText && !isLoading ? (_) => _submit(context) : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: hasText && !isLoading ? () => _submit(context) : null,
              child: isLoading
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}

// ─── Class card ──────────────────────────────────────────────────────────────

class _ClassCard extends StatelessWidget {
  final ClassModel cls;

  const _ClassCard({required this.cls});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: name + delete
            Row(
              children: [
                Expanded(
                  child: Text(
                    cls.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: colorScheme.error,
                  tooltip: 'Delete class',
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Join code chip
            GestureDetector(
              onTap: () => _copyCode(context),
              child: Chip(
                avatar: const Icon(Icons.content_copy, size: 16),
                label: Text(
                  'JOIN: ${cls.joinCode}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Footer row: student count + view button
            Row(
              children: [
                Icon(Icons.group_outlined,
                    size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${cls.studentCount} '
                  '${cls.studentCount == 1 ? 'student' : 'students'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    context
                        .read<ClassSelectionCubit>()
                        .selectClass(cls.id);
                    context.push(
                      '/teacher/classes/${cls.id}/roster',
                      extra: cls.name,
                    );
                  },
                  icon: const Icon(Icons.people_alt_outlined, size: 18),
                  label: const Text('Students'),
                ),
                const SizedBox(width: 4),
                FilledButton.icon(
                  onPressed: () => context.push(
                    '/teacher/classes/${cls.id}/topics',
                    extra: cls.name,
                  ),
                  icon: const Icon(Icons.topic_outlined, size: 18),
                  label: const Text('Topics'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: cls.joinCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Join code ${cls.joinCode} copied!')),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Delete Class?'),
        content: Text(
          'Deleting "${cls.name}" will also remove all its topics, '
          'materials, and student enrollments. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ClassBloc>().add(DeleteClass(cls.id));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.class_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No classes yet.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Tap + to create your first class.'),
        ],
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
