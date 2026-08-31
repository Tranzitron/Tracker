import 'package:isar_community/isar.dart';

import 'package:tracker/domain/models/workout_split.dart';

/// Pages and cubits talk to these repositories, never to [Isar] directly.
/// Each wraps the [Isar] collection query API for one entity.
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
