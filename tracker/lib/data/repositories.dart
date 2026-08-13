import 'package:isar/isar.dart';

import '../models/exercise.dart';
import '../models/gym.dart';
import '../models/workout_session.dart';
import '../models/workout_split.dart';

/// Pages and cubits talk to these repositories, never to [Isar] directly.
/// Each wraps the [Isar] collection query API for one entity.
class ExerciseRepository {
  ExerciseRepository(this._isar);

  final Isar _isar;

  Future<List<Exercise>> getAll() => _isar.exercises.where().findAll();

  Future<Exercise?> getById(int id) => _isar.exercises.get(id);

  Future<int> put(Exercise exercise) => _isar.writeTxn(
        () => _isar.exercises.put(exercise),
      );

  Future<void> putAll(List<Exercise> exercises) =>
      _isar.writeTxn(() => _isar.exercises.putAll(exercises));

  Future<bool> delete(int id) =>
      _isar.writeTxn(() => _isar.exercises.delete(id));

  Future<int> count() => _isar.exercises.count();

  /// Emits the current list and every later change (for UI subscribes).
  Stream<List<Exercise>> watchAll() =>
      _isar.exercises.where().watch(fireImmediately: true);
}

class GymRepository {
  GymRepository(this._isar);

  final Isar _isar;

  Future<List<Gym>> getAll() => _isar.gyms.where().sortByOrder().findAll();

  Future<Gym?> getById(int id) => _isar.gyms.get(id);

  Future<Gym?> getPrimary() =>
      _isar.gyms.filter().isPrimaryEqualTo(true).findFirst();

  Future<int> put(Gym gym) => _isar.writeTxn(() => _isar.gyms.put(gym));

  Future<bool> delete(int id) => _isar.writeTxn(() => _isar.gyms.delete(id));

  Stream<List<Gym>> watchAll() =>
      _isar.gyms.where().watch(fireImmediately: true);
}

class WorkoutSplitRepository {
  WorkoutSplitRepository(this._isar);

  final Isar _isar;

  Future<List<WorkoutSplit>> getAll() =>
      _isar.workoutSplits.where().sortByOrder().findAll();

  Future<WorkoutSplit?> getById(int id) => _isar.workoutSplits.get(id);

  Future<int> put(WorkoutSplit split) =>
      _isar.writeTxn(() => _isar.workoutSplits.put(split));

  Future<bool> delete(int id) =>
      _isar.writeTxn(() => _isar.workoutSplits.delete(id));

  Stream<List<WorkoutSplit>> watchAll() =>
      _isar.workoutSplits.where().watch(fireImmediately: true);
}

class WorkoutSessionRepository {
  WorkoutSessionRepository(this._isar);

  final Isar _isar;

  Future<List<WorkoutSession>> getAll() =>
      _isar.workoutSessions.where().sortByEndTime().findAll();

  Future<WorkoutSession?> getById(int id) => _isar.workoutSessions.get(id);

  Future<int> put(WorkoutSession session) =>
      _isar.writeTxn(() => _isar.workoutSessions.put(session));

  Future<bool> delete(int id) =>
      _isar.writeTxn(() => _isar.workoutSessions.delete(id));

  Stream<List<WorkoutSession>> watchAll() =>
      _isar.workoutSessions.where().watch(fireImmediately: true);
}

/// Facade bundling every repository for easy construction and injection.
class TrackerRepository {
  TrackerRepository(Isar isar)
      : isar = isar,
        exercises = ExerciseRepository(isar),
        gyms = GymRepository(isar),
        splits = WorkoutSplitRepository(isar),
        sessions = WorkoutSessionRepository(isar);

  /// Raw [Isar] kept for seeding and one-off queries; business code should
  /// prefer the typed repositories above.
  final Isar isar;

  final ExerciseRepository exercises;
  final GymRepository gyms;
  final WorkoutSplitRepository splits;
  final WorkoutSessionRepository sessions;
}
