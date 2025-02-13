import 'package:isar/isar.dart';
import 'package:tracker/models/workout_split_day.dart';

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
