import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tracker/data/db.dart';
import 'package:tracker/data/repositories.dart';
import 'package:tracker/data/repository_scope.dart';
import 'package:tracker/data/seed.dart';
import 'package:tracker/home_page.dart';
import 'package:tracker/pages/settings/settings_cubit.dart';
import 'package:tracker/pages/workout/workout_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(
      (await getApplicationDocumentsDirectory()).path,
    ),
  );

  // Open the single Isar instance and make the shell available immediately.
  // First-run seeding runs after the first frame, so a slow write cannot delay
  // the initial UI or prevent startup when seeding fails.
  final isar = await DbInstance.getIsar();
  final repository = TrackerRepository(isar);

  runApp(
    RepositoryScope(
      repository: repository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<WorkoutCubit>(
            create: (_) => WorkoutCubit(repository: repository),
            lazy: false,
          ),
          BlocProvider<SettingsCubit>(
            create: (_) => SettingsCubit(),
            lazy: false,
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_seedExercises(repository));
  });
}

Future<void> _seedExercises(
  TrackerRepository repository, {
  int attempt = 0,
}) async {
  try {
    await seedExercisesIfNeeded(repository);
  } catch (error, stackTrace) {
    // Keep startup alive and make the failure observable. If the collection is
    // still empty, retry once after transient startup/IO failures.
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'tracker startup',
        context: ErrorDescription(
          'seeding the exercise library (attempt ${attempt + 1})',
        ),
      ),
    );
    if (attempt == 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
      await _seedExercises(repository, attempt: 1);
    }
  }
}

const NavigationBarThemeData _navigationBarTheme = NavigationBarThemeData(
  overlayColor: WidgetStatePropertyAll(Colors.transparent),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      theme: ThemeData.light(useMaterial3: true)
          .copyWith(navigationBarTheme: _navigationBarTheme),
      themeMode: ThemeMode.system,
      darkTheme: ThemeData.dark(useMaterial3: true)
          .copyWith(navigationBarTheme: _navigationBarTheme),
      debugShowCheckedModeBanner: false,
    );
  }
}
