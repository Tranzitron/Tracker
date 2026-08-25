import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../analytics/analytics.dart';
import '../../data/repositories.dart';
import '../../models/gym.dart';
import '../../models/workout_session.dart';
import '../../models/workout_set.dart';

/// A single set logged during the in-progress workout.
///
/// Lives in the cubit-local [WorkoutState] (serialized for hydration so an
/// active workout survives an app restart). It mirrors the persisted
/// [WorkoutSet] but snapshots [exerciseName] so the UI can render set rows
/// without a DB read. [order] preserves sequence.
class ActiveSet {
  const ActiveSet({
    required this.exerciseId,
    required this.exerciseName,
    this.weight = 0,
    this.reps = 0,
    this.type = SetType.working,
    this.order = 0,
  });

  factory ActiveSet.fromJson(Map<String, dynamic> json) => ActiveSet(
    exerciseId: _intValue(json['exerciseId']),
    exerciseName: json['exerciseName'] is String
        ? json['exerciseName'] as String
        : '',
    weight: _doubleValue(json['weight']),
    reps: _intValue(json['reps']),
    type: SetType.values.asNameMap()[json['type']] ?? SetType.working,
    order: _intValue(json['order']),
  );
  final int exerciseId;
  final String exerciseName;
  final double weight;
  final int reps;
  final SetType type;
  final int order;

  bool get isWarmup => type == SetType.warmup;

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'weight': weight,
    'reps': reps,
    'type': type.name,
    'order': order,
  };

  static int _intValue(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  static double _doubleValue(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}

/// An exercise the user intends to do this session ("the split's exercises for
/// today"). Captured at start so the active-workout screen can lay out the plan
/// even after the underlying [WorkoutSplit] changes.
class PlanExercise {
  const PlanExercise({
    required this.exerciseId,
    required this.name,
    this.order = 0,
  });

  factory PlanExercise.fromJson(Map<String, dynamic> json) => PlanExercise(
    exerciseId: json['exerciseId'] is num
        ? (json['exerciseId'] as num).toInt()
        : 0,
    name: json['name'] is String ? json['name'] as String : '',
    order: json['order'] is num ? (json['order'] as num).toInt() : 0,
  );
  final int exerciseId;
  final String name;
  final int order;

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'name': name,
    'order': order,
  };
}

Map<int, List<ActiveSet>> _groupSets(List<ActiveSet> sets) {
  final grouped = <int, List<ActiveSet>>{};
  for (final set in sets) {
    (grouped[set.exerciseId] ??= <ActiveSet>[]).add(set);
  }
  return grouped;
}

final _setsByExerciseCache = Expando<Map<int, List<ActiveSet>>>();
final _workingVolumeCache = Expando<double>();

class WorkoutState {
  const WorkoutState({
    required this.isInProgress,
    this.startTime,
    this.gymId,
    this.gymName,
    this.planTitle,
    this.plan = const [],
    this.sets = const [],
  });

  factory WorkoutState.fromJson(Map<String, dynamic> json) => WorkoutState(
    isInProgress: json['isInProgress'] as bool? ?? false,
    startTime: json['startTime'] != null
        ? DateTime.tryParse(json['startTime'] as String)
        : null,
    gymId: json['gymId'] as int?,
    gymName: json['gymName'] as String?,
    planTitle: json['planTitle'] as String?,
    plan:
        (json['plan'] as List?)
            ?.map((e) => PlanExercise.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    sets:
        (json['sets'] as List?)
            ?.map((e) => ActiveSet.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );
  final bool isInProgress;
  final DateTime? startTime;

  /// Foreign key + display snapshot of the gym this session is logged at
  /// (see Plan.md §2.2). Null if no gym was selected.
  final int? gymId;
  final String? gymName;

  /// Title + ordered exercise plan if this session follows a split day.
  final String? planTitle;
  final List<PlanExercise> plan;

  /// Sets logged so far this session, in [ActiveSet.order] sequence.
  final List<ActiveSet> sets;

  /// Lazily groups the active sets for the presentation layer.
  ///
  /// The grouping is cached per immutable state instance, so rendering a plan
  /// does not repeatedly scan all sets once per exercise card. This is derived
  /// state only; it is intentionally not included in hydration serialization.
  Map<int, List<ActiveSet>> get setsByExercise =>
      _setsByExerciseCache[this] ??= _groupSets(sets);

  /// Working-set volume for the live workout summary (warm-ups excluded).
  double get workingVolume => _workingVolumeCache[this] ??= sets
      .where((set) => !set.isWarmup)
      .fold<double>(0, (total, set) => total + set.weight * set.reps);

  /// The resting (no workout) state — the app does not boot into a session.
  static WorkoutState initial() => const WorkoutState(isInProgress: false);

  Map<String, dynamic> toJson() => {
    'isInProgress': isInProgress,
    'startTime': startTime?.toIso8601String(),
    'gymId': gymId,
    'gymName': gymName,
    'planTitle': planTitle,
    'plan': plan.map((e) => e.toJson()).toList(),
    'sets': sets.map((s) => s.toJson()).toList(),
  };

  WorkoutState copyWith({
    bool? isInProgress,
    DateTime? startTime,
    int? gymId,
    String? gymName,
    String? planTitle,
    List<PlanExercise>? plan,
    List<ActiveSet>? sets,
  }) {
    return WorkoutState(
      isInProgress: isInProgress ?? this.isInProgress,
      startTime: startTime ?? this.startTime,
      gymId: gymId ?? this.gymId,
      gymName: gymName ?? this.gymName,
      planTitle: planTitle ?? this.planTitle,
      plan: plan ?? this.plan,
      sets: sets ?? this.sets,
    );
  }
}

class WorkoutCubit extends HydratedCubit<WorkoutState> {
  WorkoutCubit({this.repository}) : super(WorkoutState.initial());

  /// Reference for the workout flow; `endWorkout` persists a real
  /// [WorkoutSession] (with sets + gym + duration) to Isar instead of doing its
  /// own DB work. The cubit never opens a connection itself.
  final TrackerRepository? repository;

  /// Begin a free-form workout (no split plan) at [startTime] now.
  void startWorkout({Gym? gym}) {
    emit(
      WorkoutState(
        isInProgress: true,
        startTime: DateTime.now(),
        gymId: gym?.id,
        gymName: gym?.name,
      ),
    );
  }

  /// Begin a workout following a split day's exercise plan.
  void startPlanWorkout({
    required String title,
    required List<PlanExercise> exercises,
    Gym? gym,
  }) {
    emit(
      WorkoutState(
        isInProgress: true,
        startTime: DateTime.now(),
        gymId: gym?.id,
        gymName: gym?.name,
        planTitle: title,
        plan: exercises,
      ),
    );
  }

  /// Select/change the gym for the active (or upcoming) session.
  void setGym(Gym gym) {
    emit(state.copyWith(gymId: gym.id, gymName: gym.name));
  }

  /// Log one performed set, appending it in sequence.
  void logSet({
    required int exerciseId,
    required String exerciseName,
    required double weight,
    required int reps,
    SetType type = SetType.working,
  }) {
    final sets = [
      ...state.sets,
      ActiveSet(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        weight: weight,
        reps: reps,
        type: type,
        order: state.sets.length,
      ),
    ];
    emit(state.copyWith(sets: sets));
  }

  /// Remove the set at [order] and reindex the rest so [ActiveSet.order] stays
  /// contiguous.
  void removeSet(int order) {
    var sets = state.sets.where((s) => s.order != order).toList();
    for (var i = 0; i < sets.length; i++) {
      sets[i] = ActiveSet(
        exerciseId: sets[i].exerciseId,
        exerciseName: sets[i].exerciseName,
        weight: sets[i].weight,
        reps: sets[i].reps,
        type: sets[i].type,
        order: i,
      );
    }
    emit(state.copyWith(sets: sets));
  }

  /// Finish the workout: writes a [WorkoutSession] to Isar (duration = now −
  /// start) and resets to the idle state. When no repository is wired (tests),
  /// it only resets state.
  Future<void> endWorkout() async {
    final s = state;
    if (!s.isInProgress) return;

    final repo = repository;
    if (repo != null) {
      final completed = WorkoutSession(
        title:
            s.planTitle ??
            (s.gymName != null ? '${s.gymName} workout' : 'Workout'),
        startTime: s.startTime ?? DateTime.now(),
        endTime: DateTime.now(),
        gymId: s.gymId,
        sets: s.sets
            .map(
              (a) => WorkoutSet(
                exerciseId: a.exerciseId,
                weight: a.weight,
                reps: a.reps,
                type: a.type,
                order: a.order,
              ),
            )
            .toList(),
      );
      await repo.sessions.put(completed);

      // Keep per-exercise estimates fresh without changing the persisted
      // session shape. Existing manually entered multipliers remain fallback.
      if (completed.gymId != null) {
        final primary = await repo.gyms.getPrimary();
        if (primary != null && primary.id != completed.gymId) {
          final gyms = await repo.gyms.getAll();
          final sessions = await repo.sessions.getAll();
          final estimates = estimateGymExerciseMultipliers(
            sessions,
            primary.id,
            completed.gymId!,
          );
          final gym = gyms.firstWhere(
            (candidate) => candidate.id == completed.gymId,
          );
          if (estimates.isNotEmpty) {
            gym.perExerciseMultipliers = [
              for (final entry in estimates.entries)
                GymExerciseMultiplier(
                  exerciseId: entry.key,
                  multiplier: entry.value,
                ),
            ];
            gym.multiplier =
                estimateGymMultiplier(sessions, primary.id, gym.id) ??
                gym.multiplier;
            await repo.gyms.put(gym);
          }
        }
      }
    }

    emit(WorkoutState.initial());
  }

  @override
  WorkoutState fromJson(Map<String, dynamic> json) {
    return WorkoutState.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(WorkoutState state) {
    return state.toJson();
  }
}
