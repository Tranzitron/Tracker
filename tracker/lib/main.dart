import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tracker/Models/exercise.dart';
import 'package:tracker/home_page.dart';
import 'package:tracker/models/workout_split.dart';
import 'package:tracker/pages/workout/workout_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(
      (await getApplicationDocumentsDirectory()).path,
    ),
  );
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<WorkoutCubit>(
          create: (_) => WorkoutCubit(),
          lazy: false,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class DbInstance {
  static Future<Isar> getIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open(
      [ExerciseSchema, WorkoutSplitSchema],
      directory: dir.path,
    );
  }
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
