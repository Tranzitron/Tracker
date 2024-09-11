import 'package:isar/isar.dart';

import 'muscle.dart';

part 'exercise.g.dart';
// flutter pub run build_runner build

@collection
class Exercise {
  Id id = Isar.autoIncrement;
  String title;
  String? description;
  @enumerated
  List<Muscle> primaryMuscle;
  @enumerated
  List<Muscle>? secondaryMuscle;
  List<String> equipment;

  Exercise({
    required this.title,
    required this.primaryMuscle,
    required this.equipment,
  });
}

enum Equipment {
  dumbbell(displayName: 'Dumbbell'),
  barbell(displayName: 'Barbell'),
  machine(displayName: 'Machine');

  const Equipment({required this.displayName});

  final String displayName;
}
