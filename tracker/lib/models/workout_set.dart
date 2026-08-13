import 'package:isar/isar.dart';

part 'workout_set.g.dart';

/// How a set should be treated for analysis (see Plan.md §2.1).
///
/// Warm-up sets are excluded from progression algorithms, 1RM estimates, peak
/// volume and performance analytics.
enum SetType { warmup, working }

/// A single performed set within a [WorkoutSession]. Embedded inline, so it has
/// no `Id` of its own; [order] preserves sequence and [exerciseId] links back to
/// the [Exercise] performed.
@embedded
class WorkoutSet {
  int exerciseId;
  double weight;
  int reps;
  @enumerated
  SetType type;
  int order;

  WorkoutSet({
    this.exerciseId = 0,
    this.weight = 0,
    this.reps = 0,
    this.type = SetType.working,
    this.order = 0,
  });

  bool get isWarmup => type == SetType.warmup;
}
