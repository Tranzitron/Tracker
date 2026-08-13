import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/exercise.dart';
import '../models/gym.dart';
import '../models/workout_session.dart';
import '../models/workout_split.dart';

/// Owns the single [Isar] instance for the app.
///
/// All collections must be registered here; the generated `*Schema` classes
/// come from `dart run build_runner build`.
class DbInstance {
  static Future<Isar> getIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [
        ExerciseSchema,
        WorkoutSplitSchema,
        GymSchema,
        WorkoutSessionSchema,
      ],
      directory: dir.path,
    );
  }
}
