import 'package:isar_community/isar.dart';

import 'workout_set.dart';

part 'workout_session.g.dart';

/// A completed (or in-progress) workout, persisted for history and analytics.
///
/// Uses a foreign key ([gymId]) rather than an [IsarLink] to keep save/load
/// semantics simple; the gym can be resolved by id through the repository.
@collection
class WorkoutSession {
  Id id = Isar.autoIncrement;
  String title;
  DateTime startTime;
  DateTime? endTime;

  /// Foreign key to a [Gym] (see Plan.md §2.2). Null if no gym was recorded.
  int? gymId;

  List<WorkoutSet> sets;

  WorkoutSession({
    this.title = 'Workout',
    required this.startTime,
    this.endTime,
    this.gymId,
    this.sets = const [],
  });
}
