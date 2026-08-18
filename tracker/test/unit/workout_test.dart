// Unit tests for WorkoutState (lib/pages/workout/workout_cubit.dart) — pure
// JSON serialization, no Isar, no HydratedBloc. The WorkoutCubit flow (which
// writes to Isar / HydratedStorage) is an integration test:
// test/integration/workout_test.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/pages/workout/workout_cubit.dart';

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
    });
  });
}
