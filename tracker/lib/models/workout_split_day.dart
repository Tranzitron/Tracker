import 'package:isar/isar.dart';

@embedded
class WorkoutSplitDay {
  String title;
  String description;
  List<int> exercises; // TODO create ExerciceItem model
  int order;

  WorkoutSplitDay({
    this.title = "Split Day",
    this.description = "",
    this.exercises = const [],
    this.order = -1,
  });
}
