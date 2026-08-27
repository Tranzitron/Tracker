import '../models/exercise.dart';
import '../models/muscle.dart';
import 'repositories.dart';

/// Inserts the built-in exercise library when the collection is empty.
///
/// The check and insert share one Isar write transaction so concurrent startup
/// attempts cannot duplicate the seed. An empty collection remains retryable if
/// the transaction fails.
Future<void> seedExercisesIfNeeded(TrackerRepository repository) {
  return repository.exercises.putAllIfEmpty(seedExercises());
}

/// The seed is the initial cast of the exercise library. `dart run build_runner
/// build` has already generated `*Schema`; these records are inserted on first
/// run (see [seedExercisesIfNeeded]).
///
/// Keep it curated, not exhaustive: enough to make splits, logging and the
/// exercises tab meaningful without opinionating the whole library.
List<Exercise> seedExercises() => [
  Exercise(
    title: 'Bench Press',
    description: 'Barbell horizontal push',
    primaryMuscle: [Muscle.chest],
    secondaryMuscle: [Muscle.triceps, Muscle.frontDelts],
    equipment: [Equipment.barbell],
    movementPattern: MovementPattern.push,
  ),
  Exercise(
    title: 'Incline Bench Press',
    primaryMuscle: [Muscle.chest],
    secondaryMuscle: [Muscle.frontDelts],
    equipment: [Equipment.barbell],
    movementPattern: MovementPattern.push,
  ),
  Exercise(
    title: 'Dumbbell Bench Press',
    primaryMuscle: [Muscle.chest],
    secondaryMuscle: [Muscle.triceps],
    equipment: [Equipment.dumbbell],
    movementPattern: MovementPattern.push,
  ),
  Exercise(
    title: 'Dips',
    primaryMuscle: [Muscle.chest, Muscle.triceps],
    equipment: [Equipment.bodyweight],
    movementPattern: MovementPattern.push,
  ),
  Exercise(
    title: 'Overhead Press',
    primaryMuscle: [Muscle.frontDelts, Muscle.sideDelts],
    secondaryMuscle: [Muscle.triceps],
    equipment: [Equipment.barbell],
    movementPattern: MovementPattern.push,
  ),
  Exercise(
    title: 'Dumbbell Shoulder Press',
    primaryMuscle: [Muscle.frontDelts, Muscle.sideDelts],
    secondaryMuscle: [Muscle.triceps],
    equipment: [Equipment.dumbbell],
    movementPattern: MovementPattern.push,
  ),
  Exercise(
    title: 'Triceps Pushdown',
    primaryMuscle: [Muscle.triceps],
    equipment: [Equipment.cable],
    movementPattern: MovementPattern.push,
  ),
  Exercise(
    title: 'Squat',
    primaryMuscle: [Muscle.quadriceps],
    secondaryMuscle: [Muscle.glutes, Muscle.hamstrings],
    equipment: [Equipment.barbell],
    movementPattern: MovementPattern.legs,
  ),
  Exercise(
    title: 'Leg Press',
    primaryMuscle: [Muscle.quadriceps, Muscle.glutes],
    equipment: [Equipment.machine],
    movementPattern: MovementPattern.legs,
  ),
  Exercise(
    title: 'Romanian Deadlift',
    primaryMuscle: [Muscle.hamstrings],
    secondaryMuscle: [Muscle.glutes, Muscle.lowerBack],
    equipment: [Equipment.barbell],
    movementPattern: MovementPattern.legs,
  ),
  Exercise(
    title: 'Deadlift',
    primaryMuscle: [Muscle.lowerBack, Muscle.lats, Muscle.glutes],
    secondaryMuscle: [Muscle.hamstrings],
    equipment: [Equipment.barbell],
    movementPattern: MovementPattern.pull,
  ),
  Exercise(
    title: 'Barbell Row',
    primaryMuscle: [Muscle.lats],
    secondaryMuscle: [Muscle.biceps, Muscle.lowerBack],
    equipment: [Equipment.barbell],
    movementPattern: MovementPattern.pull,
  ),
  Exercise(
    title: 'Lat Pulldown',
    primaryMuscle: [Muscle.lats],
    secondaryMuscle: [Muscle.biceps],
    equipment: [Equipment.cable],
    movementPattern: MovementPattern.pull,
  ),
  Exercise(
    title: 'Pull Up',
    primaryMuscle: [Muscle.lats],
    secondaryMuscle: [Muscle.biceps],
    equipment: [Equipment.bodyweight],
    movementPattern: MovementPattern.pull,
  ),
  Exercise(
    title: 'Dumbbell Curl',
    primaryMuscle: [Muscle.biceps],
    equipment: [Equipment.dumbbell],
    movementPattern: MovementPattern.pull,
  ),
];
