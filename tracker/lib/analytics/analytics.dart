/// Pure analytics for progression/multipliers (Plan.md §2.3, §2.4).
///
/// All functions operate on [WorkoutSession]s plus a `gymId → multiplier` map
/// and never touch Isar/widgets, so they are unit-testable without a DB (the
/// same pattern as `pages/history/calendar_grid.dart` in Milestone 5).
///
/// Normalization (§2.3): the primary gym is the baseline (multiplier 1.0);
/// a session's weights are scaled by its gym's multiplier so identical
/// movements across machines aggregate onto one chart.
///
/// Warm-up sets (Plan.md §2.1) are excluded from every value below.
library;

import 'package:tracker/models/workout_session.dart';
import 'package:tracker/models/workout_set.dart';

/// Scales a raw logged weight by its gym's multiplier (default 1.0).
double normalizedWeight(
  double raw,
  Map<int, double> multipliers,
  int? gymId,
) =>
    raw * (multipliers[gymId] ?? 1.0);

/// Epley 1RM estimate. `reps <= 1` returns [weight] unchanged.
double epley1rm({required double weight, required int reps}) =>
    reps <= 1 ? weight : weight * (1 + reps / 30);

/// A single chart datum: best value for one session, keyed by its date.
class ProgressionPoint {
  const ProgressionPoint({required this.date, required this.value});

  final DateTime date;
  final double value;
}

/// Rolled-up stats for an exercise (or overall, `exerciseId: null`).
class ExerciseSummary {
  const ExerciseSummary({
    required this.best1rm,
    required this.peakVolume,
    required this.sessionCount,
  });

  /// Best normalized working-set 1RM.
  final double best1rm;

  /// Peak single-session normalized working volume (Σ weight·reps).
  final double peakVolume;

  /// Sessions containing at least one working set.
  final int sessionCount;
}

Iterable<WorkoutSet> _workingSets(WorkoutSession s) =>
    s.sets.where((set) => !set.isWarmup);

/// One point per session (best normalized working-set 1RM for [exerciseId]),
/// sorted by date. `exerciseId: null` → best 1RM across the whole session.
List<ProgressionPoint> exerciseBest1rm(
  List<WorkoutSession> sessions,
  Map<int, double> multipliers,
  int? exerciseId,
) {
  final points = <ProgressionPoint>[];
  for (final session in sessions) {
    final sets = _workingSets(session).where(
      (set) => exerciseId == null || set.exerciseId == exerciseId,
    );
    if (sets.isEmpty) continue;
    final best = sets.map((s) {
      final w = normalizedWeight(s.weight, multipliers, session.gymId);
      return epley1rm(weight: w, reps: s.reps);
    }).reduce((a, b) => a > b ? a : b);
    points.add(ProgressionPoint(date: session.startTime, value: best));
  }
  points.sort((a, b) => a.date.compareTo(b.date));
  return points;
}

/// One point per session (best normalized working-set weight for [exerciseId]).
List<ProgressionPoint> exercisePeakWeight(
  List<WorkoutSession> sessions,
  Map<int, double> multipliers,
  int? exerciseId,
) {
  final points = <ProgressionPoint>[];
  for (final session in sessions) {
    final sets = _workingSets(session).where(
      (set) => exerciseId == null || set.exerciseId == exerciseId,
    );
    if (sets.isEmpty) continue;
    final best = sets
        .map((s) => normalizedWeight(s.weight, multipliers, session.gymId))
        .reduce((a, b) => a > b ? a : b);
    points.add(ProgressionPoint(date: session.startTime, value: best));
  }
  points.sort((a, b) => a.date.compareTo(b.date));
  return points;
}

/// One point per session: total normalized working volume (Σ weight·reps).
List<ProgressionPoint> volumeTrend(
  List<WorkoutSession> sessions,
  Map<int, double> multipliers,
) {
  final points = <ProgressionPoint>[];
  for (final session in sessions) {
    final sets = _workingSets(session);
    if (sets.isEmpty) continue;
    final volume = sets.fold<double>(
      0,
      (sum, s) =>
          sum + normalizedWeight(s.weight, multipliers, session.gymId) * s.reps,
    );
    points.add(ProgressionPoint(date: session.startTime, value: volume));
  }
  points.sort((a, b) => a.date.compareTo(b.date));
  return points;
}

/// Per-exercise stats with all working sets across every session.
ExerciseSummary exerciseSummary(
  List<WorkoutSession> sessions,
  Map<int, double> multipliers,
  int? exerciseId,
) {
  var sessionCount = 0;
  var peakVolume = 0.0;
  var best1rm = 0.0;
  for (final session in sessions) {
    final sets = _workingSets(session)
        .where((s) => exerciseId == null || s.exerciseId == exerciseId);
    if (sets.isEmpty) continue;
    sessionCount++;
    var volume = 0.0;
    for (final set in sets) {
      final w = normalizedWeight(set.weight, multipliers, session.gymId);
      volume += w * set.reps;
      final e1rm = epley1rm(weight: w, reps: set.reps);
      if (e1rm > best1rm) best1rm = e1rm;
    }
    if (volume > peakVolume) peakVolume = volume;
  }
  return ExerciseSummary(
    best1rm: best1rm,
    peakVolume: peakVolume,
    sessionCount: sessionCount,
  );
}

/// Estimates a secondary gym's equivalence multiplier from logs: for each
/// exercise shared with the primary gym, `ratio = meanRaw(primary, ex) /
/// meanRaw(gym, ex)`, then the median across shared exercises. Returns null
/// when there are no shared exercises (cannot estimate).
double? estimateGymMultiplier(
  List<WorkoutSession> sessions,
  int? primaryGymId,
  int gymId,
) {
  final primary = <int, List<double>>{};
  final secondary = <int, List<double>>{};
  for (final session in sessions) {
    if (session.gymId == null) continue;
    final bucket = session.gymId == primaryGymId
        ? primary
        : (session.gymId == gymId ? secondary : null);
    if (bucket == null) continue;
    for (final set in _workingSets(session)) {
      bucket.putIfAbsent(set.exerciseId, () => []).add(set.weight);
    }
  }

  final ratios = <double>[];
  for (final entry in primary.entries) {
    final secondaryWeights = secondary[entry.key];
    if (secondaryWeights == null || secondaryWeights.isEmpty) continue;
    final primaryMean = _mean(entry.value);
    final secondaryMean = _mean(secondaryWeights);
    if (primaryMean <= 0 || secondaryMean <= 0) continue;
    ratios.add(primaryMean / secondaryMean);
  }
  if (ratios.isEmpty) return null;
  ratios.sort();
  return ratios[ratios.length ~/ 2];
}

double _mean(List<double> values) =>
    values.fold<double>(0, (a, b) => a + b) / values.length;
