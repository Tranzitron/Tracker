import 'package:isar/isar.dart';
import 'package:tracker/models/split_day.dart';

part 'split.g.dart';
// dart run build_runner build

@collection
class Split {
  Id id = Isar.autoIncrement;
  String title;
  String description;
  List<SplitDay> splitDays;
  int order;

  Split({
    this.title = "Split",
    this.description = "",
    this.splitDays = const [],
    this.order = -1,
  });
}
