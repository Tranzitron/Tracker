/// Pure analytics for progression/multipliers (Plan.md §2.3, §2.4).
library;

import 'package:tracker/models/workout_session.dart';
import 'package:tracker/models/workout_set.dart';

/// Scales a raw logged weight by its gym's multiplier (default 1.0).
double normalizedWeight(double raw, Map<int, double> multipliers, int? gymId) =>
    raw * (multipliers[gymId] ?? 1.0);

double epley1rm({required double weight, required int reps}) =>
    reps <= 1 ? weight : weight * (1 + reps / 30);

class ProgressionPoint {
  const ProgressionPoint({required this.date, required this.value});
  final DateTime date;
  final double value;
}

class ExerciseSummary {
  const ExerciseSummary({required this.best1rm, required this.peakVolume, required this.sessionCount});
  final double best1rm;
  final double peakVolume;
  final int sessionCount;
}

/// An immutable, internally consistent result of one analytics calculation.
/// Lists and maps are defensive unmodifiable copies, so a snapshot can safely
/// be retained by a widget between repository updates.
class AnalyticsSnapshot {
  AnalyticsSnapshot({
    required List<ProgressionPoint> best1rm,
    required List<ProgressionPoint> peakWeight,
    required List<ProgressionPoint> volume,
    required ExerciseSummary summary,
    required this.exerciseId,
    required this.revision,
  })  : best1rm = List.unmodifiable(best1rm),
        peakWeight = List.unmodifiable(peakWeight),
        volume = List.unmodifiable(volume),
        summary = summary;

  final int? exerciseId;
  final Object? revision;
  final List<ProgressionPoint> best1rm;
  final List<ProgressionPoint> peakWeight;
  final List<ProgressionPoint> volume;
  final ExerciseSummary summary;
}

/// Memoizes snapshots by the complete session content, gym multipliers, and
/// optional caller revision/filter. The content fingerprint means callers may
/// safely reuse a service while repositories replace or mutate list instances.
class AnalyticsService {
  final Map<_AnalyticsKey, AnalyticsSnapshot> _cache = {};

  AnalyticsSnapshot snapshot({
    required List<WorkoutSession> sessions,
    required Map<int, double> multipliers,
    int? exerciseId,
    Object? revision,
  }) {
    final key = _AnalyticsKey(_fingerprint(sessions), _mapFingerprint(multipliers), exerciseId, revision);
    return _cache[key] ??= AnalyticsSnapshot(
      best1rm: exerciseBest1rm(sessions, multipliers, exerciseId),
      peakWeight: exercisePeakWeight(sessions, multipliers, exerciseId),
      volume: volumeTrend(sessions, multipliers),
      summary: exerciseSummary(sessions, multipliers, exerciseId),
      exerciseId: exerciseId,
      revision: revision,
    );
  }

  /// Alias useful at call sites that treat this as a computation service.
  AnalyticsSnapshot compute({required List<WorkoutSession> sessions, required Map<int, double> multipliers, int? exerciseId, Object? revision}) =>
      snapshot(sessions: sessions, multipliers: multipliers, exerciseId: exerciseId, revision: revision);

  void clear() => _cache.clear();
}

class _AnalyticsKey {
  const _AnalyticsKey(this.sessions, this.multipliers, this.exerciseId, this.revision);
  final int sessions;
  final int multipliers;
  final int? exerciseId;
  final Object? revision;
  @override int get hashCode => Object.hash(sessions, multipliers, exerciseId, revision);
  @override bool operator ==(Object other) => other is _AnalyticsKey && sessions == other.sessions && multipliers == other.multipliers && exerciseId == other.exerciseId && revision == other.revision;
}

int _fingerprint(List<WorkoutSession> sessions) {
  var hash = 17;
  for (final s in sessions) {
    hash = Object.hash(hash, s.id, s.title, s.startTime.microsecondsSinceEpoch, s.endTime?.microsecondsSinceEpoch, s.gymId);
    for (final set in s.sets) hash = Object.hash(hash, set.exerciseId, set.weight, set.reps, set.type.index);
  }
  return hash;
}

int _mapFingerprint(Map<int, double> map) {
  var hash = 17;
  final entries = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  for (final e in entries) hash = Object.hash(hash, e.key, e.value);
  return hash;
}

Iterable<WorkoutSet> _workingSets(WorkoutSession s) => s.sets.where((set) => !set.isWarmup);

List<ProgressionPoint> exerciseBest1rm(List<WorkoutSession> sessions, Map<int, double> multipliers, int? exerciseId) {
  final points = <ProgressionPoint>[];
  for (final session in sessions) {
    final sets = _workingSets(session).where((set) => exerciseId == null || set.exerciseId == exerciseId);
    if (sets.isEmpty) continue;
    final best = sets.map((s) => epley1rm(weight: normalizedWeight(s.weight, multipliers, session.gymId), reps: s.reps)).reduce((a, b) => a > b ? a : b);
    points.add(ProgressionPoint(date: session.startTime, value: best));
  }
  points.sort((a, b) => a.date.compareTo(b.date));
  return points;
}

List<ProgressionPoint> exercisePeakWeight(List<WorkoutSession> sessions, Map<int, double> multipliers, int? exerciseId) {
  final points = <ProgressionPoint>[];
  for (final session in sessions) {
    final sets = _workingSets(session).where((set) => exerciseId == null || set.exerciseId == exerciseId);
    if (sets.isEmpty) continue;
    points.add(ProgressionPoint(date: session.startTime, value: sets.map((s) => normalizedWeight(s.weight, multipliers, session.gymId)).reduce((a, b) => a > b ? a : b)));
  }
  points.sort((a, b) => a.date.compareTo(b.date));
  return points;
}

List<ProgressionPoint> volumeTrend(List<WorkoutSession> sessions, Map<int, double> multipliers) {
  final points = <ProgressionPoint>[];
  for (final session in sessions) {
    final sets = _workingSets(session);
    if (sets.isEmpty) continue;
    points.add(ProgressionPoint(date: session.startTime, value: sets.fold(0.0, (sum, s) => sum + normalizedWeight(s.weight, multipliers, session.gymId) * s.reps)));
  }
  points.sort((a, b) => a.date.compareTo(b.date));
  return points;
}

ExerciseSummary exerciseSummary(List<WorkoutSession> sessions, Map<int, double> multipliers, int? exerciseId) {
  var count = 0; var peak = 0.0; var best = 0.0;
  for (final session in sessions) {
    final sets = _workingSets(session).where((s) => exerciseId == null || s.exerciseId == exerciseId);
    if (sets.isEmpty) continue;
    count++; var volume = 0.0;
    for (final set in sets) { final weight = normalizedWeight(set.weight, multipliers, session.gymId); volume += weight * set.reps; final oneRm = epley1rm(weight: weight, reps: set.reps); if (oneRm > best) best = oneRm; }
    if (volume > peak) peak = volume;
  }
  return ExerciseSummary(best1rm: best, peakVolume: peak, sessionCount: count);
}

double? estimateGymMultiplier(List<WorkoutSession> sessions, int? primaryGymId, int gymId) {
  final primary = <int, List<double>>{}; final secondary = <int, List<double>>{};
  for (final session in sessions) {
    if (session.gymId == null) continue;
    final bucket = session.gymId == primaryGymId ? primary : (session.gymId == gymId ? secondary : null);
    if (bucket == null) continue;
    for (final set in _workingSets(session)) bucket.putIfAbsent(set.exerciseId, () => []).add(set.weight);
  }
  final ratios = <double>[];
  for (final entry in primary.entries) { final other = secondary[entry.key]; if (other == null || other.isEmpty) continue; final a = _mean(entry.value); final b = _mean(other); if (a > 0 && b > 0) ratios.add(a / b); }
  if (ratios.isEmpty) return null; ratios.sort(); return ratios[ratios.length ~/ 2];
}

double _mean(List<double> values) => values.fold<double>(0, (a, b) => a + b) / values.length;
