import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:tracker/domain/models/exercise.dart';
import 'package:tracker/domain/models/gym.dart';
import 'package:tracker/domain/models/workout_session.dart';
import 'package:tracker/domain/models/workout_split.dart';

/// Owns the single [Isar] instance for the app.
///
/// All collections must be registered here; the generated `*Schema` classes
/// come from `dart run build_runner build`.
class DbInstance {
  static Future<Isar> getIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open([
      ExerciseSchema,
      WorkoutSplitSchema,
      GymSchema,
      WorkoutSessionSchema,
    ], directory: dir.path);
  }
}
