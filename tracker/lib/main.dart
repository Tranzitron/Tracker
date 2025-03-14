import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tracker/Models/exercise.dart';
import 'package:tracker/home_page.dart';
import 'package:tracker/models/workout_split.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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
