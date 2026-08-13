// Milestone 4 — exercises & splits management (Plan.md §1.3, §1.4).
//
// Repository integration: create an exercise, create a split, add a day with
// exercises, and reorder them — then read the persisted ordering back. This is
// the data operations the editors perform; the screens that reflect them
// (ExercisesPage / WorkoutPage) stream this same repository data and are
// covered as build smoke tests in widget_test.dart.

import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:tracker/data/repositories.dart';
import 'package:tracker/models/exercise.dart';
import 'package:tracker/models/muscle.dart';
import 'package:tracker/models/workout_split.dart';

void main() {
  late Isar isar;
  late TrackerRepository repo;

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
    final dir = Directory.systemTemp.createTempSync('m4_test');
    isar = await Isar.open(
      [ExerciseSchema, WorkoutSplitSchema],
      directory: dir.path,
    );
    repo = TrackerRepository(isar);
  });

  tearDown(() => isar.close());

  test('create exercise + split, add/reorder day exercises, read back',
      () async {
    final benchId = await repo.exercises.put(
      Exercise(
        title: 'Bench Press',
        primaryMuscle: [Muscle.chest],
        equipment: [Equipment.barbell],
        movementPattern: MovementPattern.push,
      ),
    );
    final squatId = await repo.exercises.put(
      Exercise(
        title: 'Squat',
        primaryMuscle: [Muscle.quadriceps],
        equipment: [Equipment.barbell],
        movementPattern: MovementPattern.legs,
      ),
    );

    final split = WorkoutSplit(
      title: 'PPL',
      description: 'Push / Pull / Legs',
      order: 0,
      splitDays: [
        WorkoutSplitDay(
          title: 'Push',
          order: 0,
          exercises: [
            ExerciseItem(exerciseId: benchId, order: 0),
            ExerciseItem(exerciseId: squatId, order: 1),
          ],
        ),
      ],
    );
    final id = await repo.splits.put(split);

    var fetched = (await repo.splits.getById(id))!;
    expect(fetched.title, 'PPL');
    expect(fetched.splitDays.single.exercises, hasLength(2));
    expect(fetched.splitDays.single.exercises[0].exerciseId, benchId);

    // Reorder: squat becomes the first exercise of the day.
    fetched.splitDays.single.exercises = [
      ExerciseItem(exerciseId: squatId, order: 0),
      ExerciseItem(exerciseId: benchId, order: 1),
    ];
    await repo.splits.put(fetched);

    final reread = (await repo.splits.getById(id))!;
    final orders = reread.splitDays.single.exercises
        .map((e) => (e.exerciseId, e.order))
        .toList();
    expect(orders, [
      (squatId, 0),
      (benchId, 1),
    ]);

    // Delete the split.
    expect(await repo.splits.delete(id), isTrue);
    expect(await repo.splits.getById(id), isNull);
  });
}
