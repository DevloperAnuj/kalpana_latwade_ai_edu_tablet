import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eduforge_core/eduforge_core.dart';

import 'bloc/ai_key/ai_key_bloc.dart';
import 'bloc/class/class_bloc.dart';
import 'bloc/class_selection/class_selection_cubit.dart';
import 'bloc/draft/draft_cubit.dart';
import 'bloc/generation/generation_bloc.dart';


class EduForgeApp extends StatelessWidget {
  final AuthBloc authBloc;
  final GoRouter router;

  const EduForgeApp({
    super.key,
    required this.authBloc,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authBloc),
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => AiKeyBloc()),
        BlocProvider(create: (_) => ClassBloc()),
        BlocProvider(create: (_) => ClassSelectionCubit()),
        BlocProvider(create: (_) => GenerationBloc()),
        BlocProvider(create: (_) => DraftCubit()),
        BlocProvider(create: (_) => ProfileBloc()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'EduForge – Teacher Panel',
            theme: ThemeData.light(useMaterial3: true),
            darkTheme: ThemeData.dark(useMaterial3: true),
            themeMode: themeMode,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
