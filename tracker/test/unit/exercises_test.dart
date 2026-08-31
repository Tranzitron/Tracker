import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/models/exercise.dart';
import 'package:tracker/domain/models/muscle.dart';
import 'package:tracker/ui/exercises/widgets/exercises_page.dart';

void main() {
  test('muscle-group browsing lists exercise once per group', () {
    final exercise = Exercise(
      title: 'Abdominal crunch',
      primaryMuscle: [Muscle.abdominals, Muscle.obliques],
      equipment: [Equipment.bodyweight],
    );

    final grouped = groupExercisesByMuscle([exercise]);

    expect(grouped.keys, {MuscleGroup.abdominals});
    expect(grouped[MuscleGroup.abdominals], [exercise]);
  });

  test('exercise remains in each distinct muscle group once', () {
    final exercise = Exercise(
      title: 'Squat',
      primaryMuscle: [Muscle.quadriceps, Muscle.glutes, Muscle.hamstrings],
      equipment: [Equipment.barbell],
    );

    final grouped = groupExercisesByMuscle([exercise]);

    expect(grouped.keys, {MuscleGroup.legs});
    expect(grouped[MuscleGroup.legs], [exercise]);
  });
}
