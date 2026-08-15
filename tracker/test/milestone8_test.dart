import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:isar/isar.dart';
import 'package:tracker/data/repositories.dart';
import 'package:tracker/models/exercise.dart';
import 'package:tracker/models/muscle.dart';
import 'package:tracker/pages/settings/settings_cubit.dart';
import 'package:tracker/pages/workout/workout_cubit.dart';

void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(
      libraries: {
        Abi.windowsX64: 'test/assets/isar_windows_x64.dll',
        Abi.linuxX64: 'test/assets/libisar_linux_x64.so',
        Abi.macosX64: 'test/assets/libisar_macos.dylib',
      },
    );
  });

  setUp(() async {
    final directory = Directory.systemTemp.createTempSync('tracker_m8_test');
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory(directory.path),
    );
  });

  test('WorkoutCubit ignores ending an idle workout', () async {
    final cubit = WorkoutCubit();
    addTearDown(cubit.close);

    await cubit.endWorkout();

    expect(cubit.state.isInProgress, isFalse);
    expect(cubit.state.sets, isEmpty);
  });

  test('WorkoutState.fromJson applies safe defaults to malformed values', () {
    final state = WorkoutState.fromJson({
      'isInProgress': true,
      'plan': [
        {'exerciseId': 'bad', 'name': null, 'order': null},
      ],
      'sets': [
        {'exerciseId': null, 'weight': 'bad', 'reps': null, 'type': 'unknown'},
      ],
    });

    expect(state.isInProgress, isTrue);
    expect(state.plan.single.exerciseId, 0);
    expect(state.plan.single.name, '');
    expect(state.sets.single.weight, 0);
    expect(state.sets.single.reps, 0);
    expect(state.sets.single.isWarmup, isFalse);
  });

  test('repository exercise watcher emits initial and updated values',
      () async {
    final directory = Directory.systemTemp.createTempSync('tracker_m8_isar');
    final isar = await Isar.open(
      [ExerciseSchema],
      directory: directory.path,
    );
    addTearDown(isar.close);
    final repository = TrackerRepository(isar);
    final values = <List<Exercise>>[];
    final subscription = repository.exercises.watchAll().listen(values.add);
    addTearDown(subscription.cancel);

    await _waitFor(() => values.isNotEmpty);
    expect(values.last, isEmpty);

    await repository.exercises.put(
      Exercise(
        title: 'Test Squat',
        primaryMuscle: [Muscle.quadriceps],
        equipment: [Equipment.barbell],
        movementPattern: MovementPattern.legs,
      ),
    );
    await _waitFor(() => values.any((list) => list.length == 1));
    expect(values.last.single.title, 'Test Squat');
  });

  test('SettingsCubit persists selected unit and profile in JSON', () {
    final cubit = SettingsCubit();
    addTearDown(cubit.close);

    cubit.setUnit(WeightUnit.pounds);
    cubit.saveProfile(displayName: ' Test User ', email: 'user@example.com');

    final restored = SettingsState.fromJson(cubit.state.toJson());
    expect(restored.unit, WeightUnit.pounds);
    expect(restored.displayName, 'Test User');
    expect(restored.email, 'user@example.com');
  });
}

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 100 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(condition(), isTrue, reason: 'Timed out waiting for Isar watcher');
}
