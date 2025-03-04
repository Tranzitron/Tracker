import 'package:isar/isar.dart';

part 'workout_split.g.dart';
// dart run build_runner build

@collection
class WorkoutSplit {
  Id id = Isar.autoIncrement;
  String title;
  String description;
  List<WorkoutSplitDay> splitDays;
  int order;

  WorkoutSplit({
    this.title = "Split",
    this.description = "",
    this.splitDays = const [],
    this.order = -1,
  });
}

@embedded
class WorkoutSplitDay {
  String title;
  String description;
  List<int> exercises; // TODO create ExerciseItem model
  int order;

  WorkoutSplitDay({
    this.title = "Split Day",
    this.description = "",
    this.exercises = const [],
    this.order = -1,
  });
}
