import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:eduforge_core/eduforge_core.dart';

import 'app.dart';
import 'core/router/app_router.dart';
import 'data/local/notes_local_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory(
            (await getApplicationDocumentsDirectory()).path,
          ),
  );

  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  await NotesLocalDatabase.init();

  Bloc.observer = AppBlocObserver();

  final authBloc = AuthBloc()..add(const AuthCheckStatus());
  final router = createRouter(authBloc);

  runApp(EduForgeApp(authBloc: authBloc, router: router));
}
