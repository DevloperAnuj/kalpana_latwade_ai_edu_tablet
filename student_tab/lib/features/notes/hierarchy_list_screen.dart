import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/notes/notes_bloc.dart';
import '../../bloc/notes/notes_event.dart';
import '../../bloc/notes/notes_state.dart';
import '../../data/models/notebook.dart';
import '../../data/models/notebook_type.dart';

/// Generic three-level hierarchy screen: Subjects → Chapters → Topics.
///
/// [parentId] null  → root subjects list
/// [parentId] set   → children of that notebook
/// [childType]      → the type being listed (subject / chapter / topic)
class HierarchyListScreen extends StatelessWidget {
  final String? parentId;
  final NotebookType childType;
  final String title;

  const HierarchyListScreen({
    super.key,
    required this.parentId,
    required this.childType,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotebooksBloc, NotesState>(
      builder: (context, state) {
        final all = state is NotesLoaded ? state.notebooks : <Notebook>[];
        final items = all
            .where((n) =>
                n.parentId == parentId &&
                n.type == childType &&
                !n.isArchived)
            .toList()
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              if (state is NotesLoaded && state.syncing)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          body: _buildBody(context, state, items),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCreateDialog(context),
            icon: const Icon(Icons.add),
            label: Text('New ${childType.label}'),
          ),
        );
      },
    );
  }

  Widget _buildBody(
      BuildContext context, NotesState state, List<Notebook> items) {
    if (state is NotesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is NotesError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(state.message),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  context.read<NotebooksBloc>().add(const LoadNotebooks()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return _EmptyState(
        type: childType,
        onCreate: () => _showCreateDialog(context),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _ItemCard(
        notebook: items[i],
        childType: childType,
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => BlocProvider.value(
        value: context.read<NotebooksBloc>(),
        child: _CreateDialog(parentId: parentId, type: childType),
      ),
    );
  }
}

// ── Item card ─────────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final Notebook notebook;
  final NotebookType childType;

  const _ItemCard({required this.notebook, required this.childType});

  static const _icons = {
    NotebookType.subject: Icons.subject,
    NotebookType.chapter: Icons.menu_book_outlined,
    NotebookType.topic: Icons.article_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: () => _navigate(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Icon(_icons[notebook.type],
                    color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notebook.title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (notebook.description != null &&
                        notebook.description!.isNotEmpty)
                      Text(notebook.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              PopupMenuButton<_Action>(
                onSelected: (a) => _onAction(context, a),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: _Action.rename, child: Text('Rename')),
                  const PopupMenuItem(
                      value: _Action.delete,
                      child: Text('Delete',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context) {
    if (notebook.type == NotebookType.topic) {
      // Topic → show its pages
      context.push('/student/notes/${notebook.id}',
          extra: notebook.title);
    } else {
      // Subject or Chapter → show children
      context.push(
        '/student/notes/${notebook.id}/children',
        extra: notebook.title,
      );
    }
  }

  void _onAction(BuildContext context, _Action action) {
    switch (action) {
      case _Action.rename:
        showDialog<void>(
          context: context,
          builder: (ctx) => BlocProvider.value(
            value: context.read<NotebooksBloc>(),
            child: _RenameDialog(notebook: notebook),
          ),
        );
      case _Action.delete:
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Delete ${notebook.type.label.toLowerCase()}?'),
            content: Text(
                '"${notebook.title}" and all its contents will be deleted.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error),
                onPressed: () {
                  context
                      .read<NotebooksBloc>()
                      .add(DeleteNotebook(notebook.id));
                  Navigator.of(ctx).pop();
                },
                child: const Text('Delete'),
              ),
            ],
          ),
        );
    }
  }
}

enum _Action { rename, delete }

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final NotebookType type;
  final VoidCallback onCreate;
  const _EmptyState({required this.type, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('No ${type.label.toLowerCase()}s yet.',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text('New ${type.label}'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create dialog ─────────────────────────────────────────────────────────────

class _CreateDialog extends StatefulWidget {
  final String? parentId;
  final NotebookType type;
  const _CreateDialog({required this.parentId, required this.type});

  @override
  State<_CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends State<_CreateDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _ctrl.text.trim();
    if (title.isEmpty) return;
    context.read<NotebooksBloc>().add(CreateNotebook(
          title: title,
          parentId: widget.parentId,
          type: widget.type,
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New ${widget.type.label}'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Title',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}

// ── Rename dialog ─────────────────────────────────────────────────────────────

class _RenameDialog extends StatefulWidget {
  final Notebook notebook;
  const _RenameDialog({required this.notebook});

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.notebook.title);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _ctrl.text.trim();
    if (title.isEmpty) return;
    context.read<NotebooksBloc>().add(UpdateNotebook(
          id: widget.notebook.id,
          title: title,
          description: widget.notebook.description,
          tags: widget.notebook.tags,
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rename ${widget.notebook.type.label}'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Title',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
