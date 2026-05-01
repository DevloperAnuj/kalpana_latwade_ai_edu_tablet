import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eduforge_core/eduforge_core.dart';

import '../../bloc/ai_key/ai_key_bloc.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AiKeyBloc, AiKeyState>(
      listener: (context, state) {
        if (state is AiKeyLoaded) {
          _showKeyDialog(context, key: state.key);
        } else if (state is AiKeyError) {
          _showKeyDialog(context, error: state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Teacher Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.brightness_6),
              tooltip: 'Toggle theme',
              onPressed: () => context.read<ThemeCubit>().toggleTheme(),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Teacher Dashboard – coming soon',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 32),
              BlocBuilder<AiKeyBloc, AiKeyState>(
                builder: (context, state) {
                  final isLoading = state is AiKeyLoading;
                  return FilledButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => context
                            .read<AiKeyBloc>()
                            .add(const FetchAiKey()),
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.vpn_key),
                    label: Text(
                      isLoading ? 'Fetching…' : 'Test AI Key Fetch',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showKeyDialog(
    BuildContext context, {
    String? key,
    String? error,
  }) {
    final isSuccess = key != null;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(
          isSuccess ? Icons.check_circle_outline : Icons.error_outline,
          color: isSuccess ? Colors.green : Colors.red,
          size: 40,
        ),
        title: Text(isSuccess ? 'AI Key Retrieved' : 'Key Fetch Failed'),
        content: Text(
          isSuccess ? _maskKey(key) : error ?? 'Unknown error',
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Shows first 6 and last 4 characters, masks the rest.
  String _maskKey(String key) {
    if (key.length <= 12) return '****';
    final head = key.substring(0, 6);
    final tail = key.substring(key.length - 4);
    final stars = '*' * (key.length - 10).clamp(4, 20);
    return '$head$stars$tail';
  }
}
