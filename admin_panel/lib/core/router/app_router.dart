import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:eduforge_core/eduforge_core.dart';

import '../../features/student/student_home_screen.dart';
import '../../features/teacher/class_roster_screen.dart';
import '../../features/teacher/new_topic_screen.dart';
import '../../features/teacher/preview_screen.dart';
import '../../features/teacher/teacher_home_screen.dart';
import '../../features/teacher/topics_screen.dart';

GoRouter createRouter(AuthBloc authBloc) {
  final notifier = _RouterNotifier(authBloc);

  return GoRouter(
    initialLocation: '/auth',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = authBloc.state;

      if (authState is AuthInitial || authState is AuthLoading) {
        return null;
      }

      final location = state.uri.path;
      final isAuthRoute = location == '/auth';

      if (authState is Unauthenticated || authState is AuthError) {
        return isAuthRoute ? null : '/auth';
      }

      if (authState is Authenticated) {
        if (isAuthRoute) {
          return authState.role == 'teacher'
              ? '/teacher/classes'
              : '/student/topics';
        }
        if (authState.role == 'teacher' && location.startsWith('/student')) {
          return '/teacher/classes';
        }
        if (authState.role == 'student' && location.startsWith('/teacher')) {
          return '/student/topics';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(defaultRole: 'teacher'),
      ),
      GoRoute(
        path: '/teacher/classes',
        builder: (context, state) => const TeacherHomeScreen(),
      ),
      GoRoute(
        path: '/teacher/classes/:classId/roster',
        builder: (context, state) => ClassRosterScreen(
          classId: state.pathParameters['classId']!,
          className: state.extra as String? ?? 'Class Roster',
        ),
      ),
      GoRoute(
        path: '/student/topics',
        builder: (context, state) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: '/teacher/classes/:classId/topics',
        builder: (context, state) => TopicsScreen(
          classId: state.pathParameters['classId']!,
          className: state.extra as String? ?? 'Topics',
        ),
      ),
      GoRoute(
        path: '/teacher/classes/:classId/new-topic',
        builder: (context, state) => NewTopicScreen(
          classId: state.pathParameters['classId']!,
          className: state.extra as String? ?? 'Class',
        ),
      ),
      GoRoute(
        path: '/teacher/classes/:classId/topics/preview',
        builder: (context, state) => PreviewScreen(
          classId: state.pathParameters['classId']!,
        ),
      ),
    ],
  );
}

class _RouterNotifier extends ChangeNotifier {
  final AuthBloc _authBloc;
  late final StreamSubscription<AuthState> _sub;

  _RouterNotifier(this._authBloc) {
    _sub = _authBloc.stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
