import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tracker/data/db.dart';
import 'package:tracker/data/repositories.dart';
import 'package:tracker/data/repository_scope.dart';
import 'package:tracker/data/seed.dart';
import 'package:tracker/home_page.dart';
import 'package:tracker/pages/workout/workout_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(
      (await getApplicationDocumentsDirectory()).path,
    ),
  );

  // Open the single Isar instance, wrap it in typed repositories, and seed the
  // exercise library on first run.
  final isar = await DbInstance.getIsar();
  final repository = TrackerRepository(isar);
  if (await repository.exercises.count() == 0) {
    await repository.exercises.putAll(seedExercises());
  }

  runApp(
    RepositoryScope(
      repository: repository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<WorkoutCubit>(
            create: (_) => WorkoutCubit(repository: repository),
            lazy: false,
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      theme: ThemeData.light(useMaterial3: true),
      themeMode: ThemeMode.system,
      darkTheme: ThemeData.dark(useMaterial3: true),
      debugShowCheckedModeBanner: false,
    );
  }
}
