import 'package:tracker/domain/models/workout_split.dart';

class WorkoutSplitTemplate {
  const WorkoutSplitTemplate({required this.title, required this.days});

  final String title;
  final List<String> days;

  List<WorkoutSplitDay> createDays() => [
    for (var i = 0; i < days.length; i++)
      WorkoutSplitDay(title: days[i], order: i),
  ];
}

const workoutSplitTemplates = <WorkoutSplitTemplate>[
  WorkoutSplitTemplate(title: 'PPL', days: ['Push', 'Pull', 'Legs']),
  WorkoutSplitTemplate(title: 'Bro Split', days: ['Chest', 'Back', 'Legs']),
  WorkoutSplitTemplate(title: 'Upper / Lower', days: ['Upper', 'Lower']),
  WorkoutSplitTemplate(title: 'Full Body', days: ['Full Body']),
];
