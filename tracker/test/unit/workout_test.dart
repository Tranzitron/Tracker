// Unit tests for WorkoutState (lib/pages/workout/workout_cubit.dart) — pure
// JSON serialization, no Isar, no HydratedBloc. The WorkoutCubit flow (which
// writes to Isar / HydratedStorage) is an integration test:
// test/integration/workout_test.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/ui/workout/view_models/workout_cubit.dart';

void main() {
  group('WorkoutState serialization', () {
    test('fromJson applies safe defaults to malformed values', () {
      final state = WorkoutState.fromJson({
        'isInProgress': true,
        'plan': [
          {'exerciseId': 'bad', 'name': null, 'order': null},
        ],
        'sets': [
          {
            'exerciseId': null,
            'weight': 'bad',
            'reps': null,
            'type': 'unknown',
          },
        ],
      });

      expect(state.isInProgress, isTrue);
      expect(state.plan.single.exerciseId, 0);
      expect(state.plan.single.name, '');
      expect(state.sets.single.weight, 0);
      expect(state.sets.single.reps, 0);
      expect(state.sets.single.isWarmup, isFalse);
      expect(() => state.sets.add(state.sets.single), throwsUnsupportedError);
    });

    test('states and nested values have structural equality', () {
      const set = ActiveSet(exerciseId: 1, exerciseName: 'Bench');
      const plan = PlanExercise(exerciseId: 1, name: 'Bench');
      final first = WorkoutState(isInProgress: true, plan: [plan], sets: [set]);
      final second = WorkoutState(
        isInProgress: true,
        plan: [plan],
        sets: [set],
      );
      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('copyWith can clear nullable fields', () {
      final state = WorkoutState(
        isInProgress: true,
        startTime: DateTime(2024),
        gymId: 1,
        gymName: 'Gym',
        planTitle: 'Plan',
      );
      final cleared = state.copyWith(
        startTime: null,
        gymId: null,
        gymName: null,
        planTitle: null,
      );
      expect(cleared.startTime, isNull);
      expect(cleared.gymId, isNull);
      expect(cleared.gymName, isNull);
      expect(cleared.planTitle, isNull);
    });

    test('malformed collection values are ignored safely', () {
      final state = WorkoutState.fromJson({
        'plan': [
          null,
          'bad',
          {'exerciseId': 2},
        ],
        'sets': [
          null,
          'bad',
          {'exerciseId': 2},
        ],
      });
      expect(state.plan, hasLength(1));
      expect(state.sets, hasLength(1));
    });
  });
}
