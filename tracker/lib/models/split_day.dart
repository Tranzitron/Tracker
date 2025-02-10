import 'package:isar/isar.dart';

@embedded
class SplitDay {
  String title;
  String description;
  List<int> exercises; // TODO create ExerciceItem model
  int order;

  SplitDay({
    this.title = "Split Day",
    this.description = "",
    this.exercises = const [],
    this.order = -1,
  });
}
