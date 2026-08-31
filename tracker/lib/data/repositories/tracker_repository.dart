import 'package:isar_community/isar.dart';

import 'package:tracker/data/repositories/exercise_repository.dart';
import 'package:tracker/data/repositories/gym_repository.dart';
import 'package:tracker/data/repositories/workout_session_repository.dart';
import 'package:tracker/data/repositories/workout_split_repository.dart';

/// Facade bundling every repository for easy construction and injection.
class TrackerRepository {
  TrackerRepository(Isar isar)
    : _isar = isar,
      exercises = ExerciseRepository(isar),
      gyms = GymRepository(isar),
      splits = WorkoutSplitRepository(isar),
      sessions = WorkoutSessionRepository(isar);

  /// Raw Isar stays private; business code uses typed repositories above.
  final Isar _isar;

  final ExerciseRepository exercises;
  final GymRepository gyms;
  final WorkoutSplitRepository splits;
  final WorkoutSessionRepository sessions;

  /// Closes owned database resources during app shutdown or test teardown.
  Future<bool> close() => _isar.close();
}
