import 'package:isar_community/isar.dart';

part 'workout_split.g.dart';

// After changing @collection/@embedded/@enumerated annotations, regenerate with:
//   cd tracker && dart run build_runner build

@collection
class WorkoutSplit {
  WorkoutSplit({
    this.title = "Split",
    this.description = "",
    this.splitDays = const [],
    this.order = -1,
  });

  Id id = Isar.autoIncrement;
  String title;
  String description;
  List<WorkoutSplitDay> splitDays;
  int order;
}

@embedded
class WorkoutSplitDay {
  WorkoutSplitDay({
    this.title = "Split Day",
    this.description = "",
    this.exercises = const [],
    this.order = -1,
  });

  String title;
  String description;
  List<ExerciseItem> exercises;
  int order;
}

/// An exercise within a split day: links to an [Exercise] by id plus per-slot
/// guidance. Embedded, so ordered by [order] rather than an `Id`.
@embedded
class ExerciseItem {
  ExerciseItem({
    this.exerciseId = 0,
    this.order = 0,
    this.targetSets,
    this.targetReps,
    this.restSeconds,
  });

  int exerciseId;
  int order;
  int? targetSets;
  int? targetReps;
  int? restSeconds;
}
