import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eduforge_core/eduforge_core.dart';

import '../../bloc/material_viewer/material_viewer_cubit.dart';
import '../../features/student/join_class_screen.dart';
import '../../features/student/material_viewer_screen.dart';
import '../../features/student/student_topic_list_screen.dart';
import '../../features/teacher/teacher_home_screen.dart';

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

      // AuthScreen hardcodes these paths after login — remap both to /student/join
      if (location == '/student/topics') return '/student/join';
      if (location == '/teacher/classes') return '/student/join';

      final isAuthRoute = location == '/auth';

      if (authState is Unauthenticated || authState is AuthError) {
        return isAuthRoute ? null : '/auth';
      }

      if (authState is Authenticated) {
        if (isAuthRoute) return '/student/join';
        if (location.startsWith('/teacher')) return '/student/join';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(defaultRole: 'student'),
      ),
      GoRoute(
        path: '/teacher/classes',
        builder: (context, state) => const TeacherHomeScreen(),
      ),
      GoRoute(
        path: '/student/join',
        builder: (context, state) => const JoinClassScreen(),
      ),
      GoRoute(
        path: '/student/classes/:classId/topics',
        builder: (context, state) => StudentTopicListScreen(
          classId: state.pathParameters['classId']!,
          className: state.extra as String? ?? 'Topics',
        ),
      ),
      GoRoute(
        path: '/student/material/:topicId',
        builder: (context, state) => BlocProvider(
          create: (_) => MaterialViewerCubit(),
          child: MaterialViewerScreen(
            topicId: state.pathParameters['topicId']!,
            topicTitle: state.extra as String? ?? 'Topic',
          ),
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
