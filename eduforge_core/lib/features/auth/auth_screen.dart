import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/auth/auth_bloc.dart';

class AuthScreen extends StatefulWidget {
  final String defaultRole;

  const AuthScreen({super.key, required this.defaultRole});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.go(
            state.role == 'teacher' ? '/teacher/classes' : '/student/topics',
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('EduForge'),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Login'),
                Tab(text: 'Sign Up'),
              ],
            ),
          ),
          body: state is AuthLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // ── Login tab ──────────────────────────────────────────
                    _LoginForm(
                      emailCtrl: _loginEmailCtrl,
                      passwordCtrl: _loginPasswordCtrl,
                    ),
                    // ── Sign-up tab ────────────────────────────────────────
                    _SignUpForm(defaultRole: widget.defaultRole),
                  ],
                ),
        );
      },
    );
  }
}

// ── Login form ────────────────────────────────────────────────────────────────

class _LoginForm extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;

  const _LoginForm({required this.emailCtrl, required this.passwordCtrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordCtrl,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => context.read<AuthBloc>().add(
                      AuthLoginRequested(
                        email: emailCtrl.text.trim(),
                        password: passwordCtrl.text,
                      ),
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.read<AuthBloc>().add(
                      AuthLoginRequested(
                        email: emailCtrl.text.trim(),
                        password: passwordCtrl.text,
                      ),
                    ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sign-up form ──────────────────────────────────────────────────────────────

class _SignUpForm extends StatefulWidget {
  final String defaultRole;

  const _SignUpForm({required this.defaultRole});

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _rollCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<AuthBloc>().add(AuthSignUpRequested(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: widget.defaultRole,
          displayName: _nameCtrl.text.trim(),
          rollNumber: widget.defaultRole == 'student' ? _rollCtrl.text.trim() : null,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.defaultRole == 'student';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  border: OutlineInputBorder(),
                  hintText: 'Your full name',
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction:
                    isStudent ? TextInputAction.next : TextInputAction.done,
                onSubmitted: isStudent ? null : (_) => _submit(),
              ),
              if (isStudent) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _rollCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Roll number (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 2024CS101',
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submit,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Sign Up'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
