import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/profile/profile_bloc.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Cached from first ProfileLoaded — drives form visibility.
  String? _role;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<ProfileBloc>().add(LoadProfile(authState.userId));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rollCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated || _role == null) return;
    context.read<ProfileBloc>().add(UpdateProfile(
          userId: authState.userId,
          displayName: _nameCtrl.text,
          rollNumber: _role == 'student' ? _rollCtrl.text : null,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded && _role == null) {
          // First successful load – populate controllers once.
          _nameCtrl.text = state.displayName;
          _rollCtrl.text = state.rollNumber ?? '';
          _emailCtrl.text = state.email;
          setState(() {
            _role = state.role;
            _isSaving = false;
          });
        }
        if (state is ProfileLoading) {
          setState(() => _isSaving = true);
        }
        if (state is ProfileUpdateSuccess) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
        if (state is ProfileError) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        // Show full-page loader until first profile fetch completes.
        if (_role == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Profile')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final isStudent = _role == 'student';

        return Scaffold(
          appBar: AppBar(title: const Text('My Profile')),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Role badge (read-only) ─────────────────────────────
                    Row(
                      children: [
                        Icon(
                          isStudent ? Icons.school_outlined : Icons.class_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(
                            isStudent ? 'Student' : 'Teacher',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Email (read-only) ──────────────────────────────────
                    TextField(
                      controller: _emailCtrl,
                      readOnly: true,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Display name ───────────────────────────────────────
                    TextField(
                      controller: _nameCtrl,
                      enabled: !_isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: 'Your full name',
                      ),
                      textInputAction:
                          isStudent ? TextInputAction.next : TextInputAction.done,
                      onSubmitted: isStudent ? null : (_) => _save(),
                    ),

                    // ── Roll number (students only) ────────────────────────
                    if (isStudent) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _rollCtrl,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Roll number (optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge_outlined),
                          hintText: 'e.g. 2024CS101',
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _save(),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // ── Save button ────────────────────────────────────────
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_isSaving ? 'Saving…' : 'Update Profile'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
