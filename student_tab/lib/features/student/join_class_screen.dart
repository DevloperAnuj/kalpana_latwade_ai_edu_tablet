import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eduforge_core/eduforge_core.dart';

import '../../bloc/student/student_bloc.dart';

class JoinClassScreen extends StatefulWidget {
  const JoinClassScreen({super.key});

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  @override
  void initState() {
    super.initState();
    context.read<StudentBloc>().add(const LoadJoinedClasses());
  }

  void _showJoinDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<StudentBloc>(),
        child: const _JoinClassDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StudentBloc, StudentState>(
      listener: (context, state) {
        if (state is StudentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          context.read<StudentBloc>().add(const LoadJoinedClasses());
        }
        if (state is StudentClassesLoaded &&
            state.justJoinedClassName != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Joined "${state.justJoinedClassName}" successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      },
      builder: (context, state) {
        final classes = state is StudentClassesLoaded
            ? state.classes
            : <Map<String, dynamic>>[];
        final isLoading = state is StudentLoading;

        return Scaffold(
          appBar: AppBar(
            title: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final name = authState is Authenticated
                    ? authState.displayName
                    : null;
                return Text(
                  name != null && name.isNotEmpty
                      ? 'Hello, $name'
                      : 'EduForge',
                );
              },
            ),
            actions: [
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
          body: _buildBody(context, classes, isLoading),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showJoinDialog,
            icon: const Icon(Icons.add),
            label: const Text('Join Class'),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<Map<String, dynamic>> classes,
    bool isLoading,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 88),
      children: [
        // ── Notes hero card ────────────────────────────────────────────────
        _NotesHeroCard(),
        const SizedBox(height: 28),

        // ── Classes section ────────────────────────────────────────────────
        Row(
          children: [
            Icon(Icons.school_outlined, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Text('My Classes', style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 12),

        if (isLoading && classes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (classes.isEmpty)
          _EmptyClassList(onJoin: _showJoinDialog)
        else
          ...classes.map(
            (cls) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Icon(Icons.school_outlined,
                        color: cs.onPrimaryContainer),
                  ),
                  title: Text(cls['name'] as String),
                  trailing: FilledButton.tonal(
                    onPressed: () => context.push(
                      '/student/classes/${cls['id']}/topics',
                      extra: cls['name'] as String,
                    ),
                    child: const Text('View Topics'),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Notes hero card ───────────────────────────────────────────────────────────

class _NotesHeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: cs.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => context.push('/student/notes'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon block
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.menu_book_rounded,
                    size: 32, color: cs.onPrimary),
              ),
              const SizedBox(width: 20),
              // Text block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Notebooks',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Subjects · Chapters · Topics\nHandwritten notes with OCR',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onPrimaryContainer.withAlpha(180),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                      ),
                      onPressed: () => context.push('/student/notes'),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Open Notebooks'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyClassList extends StatelessWidget {
  final VoidCallback onJoin;
  const _EmptyClassList({required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            "You haven't joined any class yet.",
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below to get started.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onJoin,
            icon: const Icon(Icons.add),
            label: const Text('Join Class'),
          ),
        ],
      ),
    );
  }
}

// ── Join dialog ───────────────────────────────────────────────────────────────

class _JoinClassDialog extends StatefulWidget {
  const _JoinClassDialog();

  @override
  State<_JoinClassDialog> createState() => _JoinClassDialogState();
}

class _JoinClassDialogState extends State<_JoinClassDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final code = _ctrl.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a 6-character join code.')),
      );
      return;
    }
    context.read<StudentBloc>().add(JoinClassWithCode(code));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StudentBloc, StudentState>(
      listener: (context, state) {
        if (state is StudentClassesLoaded &&
            state.justJoinedClassName != null) {
          Navigator.of(context).pop();
        }
        if (state is StudentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is StudentLoading;

        return AlertDialog(
          title: const Text('Join a Class'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter the 6-character code from your teacher.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Join Code',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. ABC123',
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                  counterText: '',
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  _UpperCaseFormatter(),
                ],
                onSubmitted: isLoading ? null : (_) => _submit(context),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: isLoading ? null : () => _submit(context),
              icon: isLoading
                  ? SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.login),
              label: Text(isLoading ? 'Joining…' : 'Join'),
            ),
          ],
        );
      },
    );
  }
}

// ── Formatters ────────────────────────────────────────────────────────────────

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
