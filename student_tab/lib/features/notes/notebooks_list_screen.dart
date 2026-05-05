import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/notes/notes_bloc.dart';
import '../../bloc/notes/notes_event.dart';
import '../../bloc/notes/notes_state.dart';
import '../../data/models/notebook.dart';

class NotebooksListScreen extends StatelessWidget {
  const NotebooksListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotebooksBloc, NotesState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Notebooks'),
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
          body: _buildBody(context, state),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCreateDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('New Notebook'),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, NotesState state) {
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

    final notebooks = state is NotesLoaded
        ? state.notebooks.where((n) => !n.isArchived).toList()
        : <Notebook>[];

    if (notebooks.isEmpty) {
      return _EmptyNotebooks(onCreate: () => _showCreateDialog(context));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: notebooks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) =>
          _NotebookCard(notebook: notebooks[index]),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<NotebooksBloc>(),
        child: const _CreateNotebookDialog(),
      ),
    );
  }
}

// ── Notebook card ─────────────────────────────────────────────────────────────

class _NotebookCard extends StatelessWidget {
  final Notebook notebook;
  const _NotebookCard({required this.notebook});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: () => context.push('/student/notes/${notebook.id}',
            extra: notebook.title),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.book_outlined,
                    color: theme.colorScheme.onPrimaryContainer),
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
                        notebook.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(notebook.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                    if (notebook.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: notebook.tags
                            .map((t) => Chip(
                                  label: Text(t),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<_CardAction>(
                onSelected: (action) =>
                    _onAction(context, action, notebook),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: _CardAction.rename,
                      child: Text('Rename')),
                  PopupMenuItem(
                      value: _CardAction.archive,
                      child: Text('Archive')),
                  PopupMenuItem(
                      value: _CardAction.delete,
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

  void _onAction(
      BuildContext context, _CardAction action, Notebook nb) {
    switch (action) {
      case _CardAction.rename:
        showDialog<void>(
          context: context,
          builder: (ctx) => BlocProvider.value(
            value: context.read<NotebooksBloc>(),
            child: _RenameDialog(notebook: nb),
          ),
        );
      case _CardAction.archive:
        context
            .read<NotebooksBloc>()
            .add(ArchiveNotebook(nb.id, archive: true));
      case _CardAction.delete:
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete notebook?'),
            content:
                Text('All pages in "${nb.title}" will be permanently deleted.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error),
                onPressed: () {
                  context
                      .read<NotebooksBloc>()
                      .add(DeleteNotebook(nb.id));
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

enum _CardAction { rename, archive, delete }

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyNotebooks extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyNotebooks({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.book_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text('No notebooks yet.',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Create your first notebook to start writing.',
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('New Notebook'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create dialog ─────────────────────────────────────────────────────────────

class _CreateNotebookDialog extends StatefulWidget {
  const _CreateNotebookDialog();

  @override
  State<_CreateNotebookDialog> createState() => _CreateNotebookDialogState();
}

class _CreateNotebookDialogState extends State<_CreateNotebookDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    context.read<NotebooksBloc>().add(CreateNotebook(
          title: title,
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Notebook'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
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
      title: const Text('Rename Notebook'),
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
