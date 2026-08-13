// Milestone 3 — core workout logging.
//
// Two layers:
//  1. Cubit+repository: start → select gym → log working + warmup sets → end
//     workout → a WorkoutSession with the right gym/sets/duration lands in Isar
//     (Checkpoint 3 persistence), plus hydration round-trips.
//  2. Widget: the CurrentWorkout page renders the plan and logs a set inline.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:isar/isar.dart';
import 'package:tracker/data/repositories.dart';
import 'package:tracker/models/gym.dart';
import 'package:tracker/models/workout_session.dart';
import 'package:tracker/models/workout_set.dart';
import 'package:tracker/pages/workout/current_workout_page.dart';
import 'package:tracker/pages/workout/workout_cubit.dart';

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('workout_flow_test');
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory(dir.path),
    );
  });

  group('WorkoutCubit persistence (Checkpoint 3)', () {
    late Isar isar;
    late TrackerRepository repo;
    late WorkoutCubit cubit;

    setUp(() async {
      final dir = Directory.systemTemp.createTempSync('workout_flow_isar');
      isar = await Isar.open(
        [WorkoutSessionSchema, GymSchema],
        directory: dir.path,
      );
      repo = TrackerRepository(isar);
      cubit = WorkoutCubit(repository: repo);
    });

    tearDown(() async {
      await cubit.close();
      await isar.close();
    });

    test('start → log working + warmup → persist session to Isar', () async {
      final gymId = await repo.gyms.put(Gym(name: 'Home', isPrimary: true));
      final gym = (await repo.gyms.getById(gymId))!;

      cubit.startWorkout(gym: gym);
      expect(cubit.state.isInProgress, isTrue);
      expect(cubit.state.gymId, gymId);

      cubit.logSet(
        exerciseId: 1,
        exerciseName: 'Squat',
        weight: 100,
        reps: 5,
      );
      cubit.logSet(
        exerciseId: 1,
        exerciseName: 'Squat',
        weight: 60,
        reps: 8,
        type: SetType.warmup,
      );
      cubit.logSet(
        exerciseId: 1,
        exerciseName: 'Squat',
        weight: 100,
        reps: 5,
      );
      expect(cubit.state.sets, hasLength(3));
      expect(cubit.state.sets[1].isWarmup, isTrue);

      final started = DateTime.now();
      await cubit.endWorkout();

      expect(cubit.state.isInProgress, isFalse);
      final sessions = await repo.sessions.getAll();
      expect(sessions, hasLength(1));

      final session = sessions.first;
      expect(session.title, 'Home workout');
      expect(session.gymId, gymId);
      expect(session.sets, hasLength(3));
      expect(session.sets[1].type, SetType.warmup);
      // Duration computed from now − start and stored as endTime.
      expect(session.endTime, isNotNull);
      expect(
        session.endTime!.difference(session.startTime),
        isNot(greaterThan(const Duration(minutes: 1))),
        reason: 'duration should be ~(now - start) for a quick test session',
      );
      expect(started.difference(session.startTime).inSeconds, lessThan(60));
    });

    test('startPlanWorkout sets the plan and planTitle on persist', () async {
      cubit.startPlanWorkout(
        title: 'PPL · Push',
        exercises: const [
          PlanExercise(exerciseId: 1, name: 'Bench Press', order: 0),
          PlanExercise(exerciseId: 2, name: 'OHP', order: 1),
        ],
      );
      expect(cubit.state.plan, hasLength(2));
      expect(cubit.state.planTitle, 'PPL · Push');
      expect(cubit.state.plan.first.name, 'Bench Press');

      cubit.logSet(
          exerciseId: 1, exerciseName: 'Bench Press', weight: 80, reps: 6);
      await cubit.endWorkout();

      final session = (await repo.sessions.getAll()).single;
      expect(session.title, 'PPL · Push');
      expect(session.sets.single.exerciseId, 1);
    });

    test('removeSet drops a set and reindexes order', () async {
      cubit.startWorkout();
      cubit.logSet(exerciseId: 1, exerciseName: 'A', weight: 10, reps: 5);
      cubit.logSet(exerciseId: 2, exerciseName: 'B', weight: 20, reps: 5);
      cubit.logSet(exerciseId: 3, exerciseName: 'C', weight: 30, reps: 5);

      cubit.removeSet(1); // remove the middle set
      expect(cubit.state.sets, hasLength(2));
      expect(cubit.state.sets.map((s) => s.order).toList(), [0, 1]);
      expect(cubit.state.sets.first.exerciseName, 'A');
      expect(cubit.state.sets.last.exerciseName, 'C');
    });

    test('hydration round-trips plan + sets through JSON', () {
      cubit.startPlanWorkout(
        title: 'PPL · Pull',
        exercises: const [PlanExercise(exerciseId: 7, name: 'Row', order: 0)],
      );
      cubit.logSet(exerciseId: 7, exerciseName: 'Row', weight: 70, reps: 8);
      cubit.logSet(
        exerciseId: 7,
        exerciseName: 'Row',
        weight: 50,
        reps: 10,
        type: SetType.warmup,
      );

      final restored = WorkoutState.fromJson(cubit.state.toJson());
      expect(restored.isInProgress, isTrue);
      expect(restored.planTitle, 'PPL · Pull');
      expect(restored.plan.single.name, 'Row');
      expect(restored.sets, hasLength(2));
      expect(restored.sets[1].isWarmup, isTrue);
    });
  });

  group('CurrentWorkout logging UI', () {
    testWidgets('logs a set inline from a plan exercise', (tester) async {
      final cubit = WorkoutCubit()
        ..startPlanWorkout(
          title: 'PPL · Push',
          exercises: const [
            PlanExercise(exerciseId: 1, name: 'Bench Press', order: 0),
          ],
        );
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [BlocProvider.value(value: cubit)],
            child: const CurrentWorkoutPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The plan title and exercise render.
      expect(find.text('PPL · Push'), findsOneWidget);
      expect(find.text('Bench Press'), findsOneWidget);
      // One inline add-form → weight + reps fields, warm-up chip, Add set.
      expect(find.byType(TextField), findsNWidgets(2));

      await tester.enterText(find.byType(TextField).at(0), '100');
      await tester.enterText(find.byType(TextField).at(1), '5');

      // Mark the set as warm-up before adding.
      await tester.tap(find.text('Warm-up'));
      await tester.pump();
      await tester.tap(find.text('Add set'));
      await tester.pumpAndSettle();

      final state = cubit.state;
      expect(state.sets, hasLength(1));
      expect(state.sets.single.weight, 100);
      expect(state.sets.single.reps, 5);
      expect(state.sets.single.type, SetType.warmup);
      expect(find.text('100 kg × 5'), findsOneWidget);
    });
  });
}
