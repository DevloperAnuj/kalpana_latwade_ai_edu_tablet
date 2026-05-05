import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eduforge_core/eduforge_core.dart';

import '../../bloc/material_viewer/material_viewer_cubit.dart';
import '../../bloc/notes/notes_bloc.dart';
import '../../bloc/notes/notes_event.dart';
import '../../data/repositories/notes_local_repository.dart';
import '../../data/models/notebook_type.dart';
import '../../features/notes/hierarchy_list_screen.dart';
import '../../features/notes/notebook_detail_screen.dart';
import '../../features/notes/note_page_editor_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/student/join_class_screen.dart';
import '../../features/student/material_viewer_screen.dart';
import '../../features/student/student_topic_list_screen.dart';
import '../../features/teacher/teacher_home_screen.dart';

GoRouter createRouter(AuthBloc authBloc) {
  final notifier = _RouterNotifier(authBloc);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = authBloc.state;
      final location = state.uri.path;

      // While auth check is in progress show the splash screen
      if (authState is AuthInitial || authState is AuthLoading) {
        return location == '/splash' ? null : '/splash';
      }

      // AuthScreen hardcodes these paths after login — remap both to /student/join
      if (location == '/student/topics') return '/student/join';
      if (location == '/teacher/classes') return '/student/join';

      final isPublicRoute = location == '/auth' || location == '/splash';

      if (authState is Unauthenticated || authState is AuthError) {
        return location == '/auth' ? null : '/auth';
      }

      if (authState is Authenticated) {
        if (isPublicRoute) return '/student/join';
        if (location.startsWith('/teacher')) return '/student/join';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
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
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // ── Notes ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/student/notes',
        builder: (context, state) => BlocProvider(
          create: (_) => NotebooksBloc()..add(const LoadNotebooks()),
          child: const HierarchyListScreen(
            parentId: null,
            childType: NotebookType.subject,
            title: 'Subjects',
          ),
        ),
      ),
      GoRoute(
        path: '/student/notes/:parentId/children',
        builder: (context, state) {
          final parentId = state.pathParameters['parentId']!;
          final parent = NotesLocalRepository().getNotebook(parentId);
          final childType = parent?.type.childType ?? NotebookType.topic;
          final title = state.extra as String? ?? '${childType.label}s';
          return BlocProvider(
            create: (_) => NotebooksBloc()..add(const LoadNotebooks()),
            child: HierarchyListScreen(
              parentId: parentId,
              childType: childType,
              title: title,
            ),
          );
        },
      ),
      GoRoute(
        path: '/student/notes/:notebookId',
        builder: (context, state) => NotebookDetailScreen(
          notebookId: state.pathParameters['notebookId']!,
          notebookTitle: state.extra as String? ?? 'Notebook',
        ),
      ),
      GoRoute(
        path: '/student/notes/:notebookId/page/:pageId',
        builder: (context, state) {
          final pageId = state.pathParameters['pageId']!;
          final page = NotesLocalRepository().getPage(pageId);
          if (page == null) {
            return const Scaffold(
              body: Center(child: Text('Page not found.')),
            );
          }
          return NotePageEditorScreen(
            page: page,
            pageTitle: state.extra as String? ?? 'Page',
          );
        },
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
