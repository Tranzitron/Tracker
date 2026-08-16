// Milestone 6 — analytics, multipliers & progression (Plan.md §2.3, §2.4,
// §1.4.1.1). The analytics layer is pure (no Isar/widgets), so it's tested
// directly. The LineChart and ExerciseDetailPage are widget-tested DB-free.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/analytics/analytics.dart';
import 'package:tracker/models/exercise.dart';
import 'package:tracker/models/muscle.dart';
import 'package:tracker/models/workout_session.dart';
import 'package:tracker/models/workout_set.dart';
import 'package:tracker/pages/analytics/progression_page.dart';
import 'package:tracker/pages/custom/line_chart.dart';
import 'package:tracker/pages/exercises/exercise_detail_page.dart';

WorkoutSet _set(int exerciseId, double weight, int reps, SetType type) =>
    WorkoutSet(exerciseId: exerciseId, weight: weight, reps: reps, type: type);

WorkoutSession _session(DateTime start, int gymId, List<WorkoutSet> sets) =>
    WorkoutSession(startTime: start, gymId: gymId, sets: sets);

void main() {
  group('1RM estimate (Epley)', () {
    test('multiplies by (1 + reps/30) for reps > 1', () {
      expect(
        epley1rm(weight: 100, reps: 5),
        closeTo(100 * (1 + 5 / 30), 0.001),
      );
    });

    test('returns weight unchanged for 1 or 0 reps', () {
      expect(epley1rm(weight: 100, reps: 1), 100);
      expect(epley1rm(weight: 100, reps: 0), 100);
    });
  });

  group('normalizedWeight (§2.3)', () {
    const multipliers = {1: 1.0, 2: 0.9};

    test('scales by the session gym\'s multiplier', () {
      expect(normalizedWeight(110, multipliers, 2), closeTo(99, 0.001));
      expect(normalizedWeight(110, multipliers, 1), 110);
    });

    test('defaults to 1.0 for unknown/null gym', () {
      expect(normalizedWeight(110, multipliers, null), 110);
      expect(normalizedWeight(110, multipliers, 99), 110);
    });
  });

  group('per-exercise series excludes warmups + normalizes', () {
    test('unifies the same movement across two gyms (checkpoint)', () {
      // Same exercise logged at gym A (mult 1.0) and gym B (mult 0.9).
      final sessions = [
        _session(DateTime(2026, 1, 1), 1, [
          _set(7, 100, 5, SetType.working),
          _set(7, 60, 8, SetType.warmup), // excluded
        ]),
        _session(DateTime(2026, 1, 2), 2, [
          _set(7, 110, 5, SetType.working), // normalized → 99
          _set(7, 70, 8, SetType.warmup), // excluded
        ]),
      ];
      const multipliers = {1: 1.0, 2: 0.9};

      final series = exerciseBest1rm(sessions, multipliers, 7);
      expect(series, hasLength(2));
      expect(series[0].date, DateTime(2026, 1, 1));
      expect(series[0].value, closeTo(epley1rm(weight: 100, reps: 5), 0.001));
      // Raw 110 × 0.9 = 99, then Epley.
      expect(series[1].value, closeTo(epley1rm(weight: 99, reps: 5), 0.001));
    });

    test('skips sessions with only warmup sets for that exercise', () {
      final sessions = [
        _session(DateTime(2026, 1, 1), 1, [
          _set(7, 60, 8, SetType.warmup),
        ]),
      ];
      expect(exerciseBest1rm(sessions, const {}, 7), isEmpty);
    });

    test('exercisePeakWeight uses normalized working weight', () {
      final sessions = [
        _session(DateTime(2026, 1, 1), 2, [
          _set(7, 110, 5, SetType.working),
        ]),
      ];
      const multipliers = {2: 0.9};
      final peak = exercisePeakWeight(sessions, multipliers, 7);
      expect(peak.single.value, closeTo(99, 0.001));
    });
  });

  group('volume trend (§2.1, §2.4)', () {
    test('excludes warmup sets and normalizes weight', () {
      final sessions = [
        _session(DateTime(2026, 1, 1), 2, [
          _set(1, 100, 5, SetType.working), // 100×0.9×5 = 450
          _set(1, 60, 8, SetType.warmup), // excluded
        ]),
      ];
      const multipliers = {2: 0.9};
      final trend = volumeTrend(sessions, multipliers);
      expect(trend.single.value, closeTo(450, 0.001));
    });
  });

  group('exerciseSummary', () {
    test('aggregates working sets across sessions', () {
      final sessions = [
        _session(DateTime(2026, 1, 1), 1, [
          _set(7, 100, 5, SetType.working),
          _set(7, 60, 8, SetType.warmup),
        ]),
        _session(DateTime(2026, 1, 2), 1, [
          _set(7, 90, 5, SetType.working),
        ]),
      ];
      final s = exerciseSummary(sessions, const {1: 1.0}, 7);
      expect(s.sessionCount, 2);
      expect(s.best1rm, closeTo(epley1rm(weight: 100, reps: 5), 0.001));
      expect(s.peakVolume, closeTo(500, 0.001));
    });
  });

  group('AnalyticsService snapshots', () {
    test('memoizes equivalent inputs and keeps snapshot immutable', () {
      final sessions = [
        _session(DateTime(2026, 1, 1), 1, [
          _set(7, 100, 5, SetType.working),
        ]),
      ];
      final service = AnalyticsService();
      final first = service.snapshot(
        sessions: sessions,
        multipliers: const {1: 1.0},
        exerciseId: 7,
        revision: 3,
      );
      final second = service.snapshot(
        sessions: sessions,
        multipliers: const {1: 1.0},
        exerciseId: 7,
        revision: 3,
      );
      expect(identical(first, second), isTrue);
      expect(() => first.best1rm.clear(), throwsA(anything));
    });

    test('recomputes when revision, filter, or multiplier changes', () {
      final sessions = [
        _session(DateTime(2026, 1, 1), 1, [_set(7, 100, 5, SetType.working)]),
      ];
      final service = AnalyticsService();
      final first = service.compute(
        sessions: sessions,
        multipliers: const {1: 1.0},
        revision: 1,
      );
      expect(
        identical(
          first,
          service.compute(
            sessions: sessions,
            multipliers: const {1: 1.0},
            revision: 2,
          ),
        ),
        isFalse,
      );
      expect(
        identical(
          first,
          service.compute(
            sessions: sessions,
            multipliers: const {1: 0.9},
            revision: 1,
          ),
        ),
        isFalse,
      );
      expect(
        identical(
          first,
          service.compute(
            sessions: sessions,
            multipliers: const {1: 1.0},
            exerciseId: 7,
            revision: 1,
          ),
        ),
        isFalse,
      );
    });
  });

  group('estimateGymMultiplier (§2.3)', () {
    test('median of mean-ratio across shared exercises', () {
      final sessions = [
        _session(DateTime(2026, 1, 1), 1, [
          _set(1, 100, 5, SetType.working),
          _set(1, 100, 5, SetType.working),
          _set(2, 50, 8, SetType.working),
        ]),
        _session(DateTime(2026, 1, 2), 2, [
          _set(1, 110, 5, SetType.working),
          _set(1, 110, 5, SetType.working),
          _set(2, 60, 8, SetType.working),
        ]),
      ];
      // ex1 ratio 100/110 = 0.909; ex2 ratio 50/60 = 0.833; median = 0.909.
      final estimate = estimateGymMultiplier(sessions, 1, 2);
      expect(estimate, isNotNull);
      expect(estimate!, closeTo(0.9090909, 0.001));
    });

    test('returns null with no shared exercises', () {
      final sessions = [
        _session(DateTime(2026, 1, 1), 1, [
          _set(1, 100, 5, SetType.working),
        ]),
        _session(DateTime(2026, 1, 2), 2, [
          _set(3, 40, 8, SetType.working),
        ]),
      ];
      expect(estimateGymMultiplier(sessions, 1, 2), isNull);
    });
  });

  group('analytics widgets (DB-free)', () {
    testWidgets('LineChart renders an empty state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LineChart(points: <ProgressionPoint>[]),
          ),
        ),
      );
      expect(find.text('No data yet'), findsOneWidget);
    });

    testWidgets('LineChart renders a series without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LineChart(
              points: [
                ProgressionPoint(date: DateTime(2026, 1, 1), value: 10),
                ProgressionPoint(date: DateTime(2026, 1, 2), value: 20),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('ExerciseDetailPage builds and shows an empty chart',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseDetailPage(
            exercise: Exercise(
              title: 'Bench Press',
              primaryMuscle: [Muscle.chest],
              equipment: [Equipment.barbell],
              movementPattern: MovementPattern.push,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Best 1RM'), findsOneWidget);
      expect(find.text('No data yet'), findsOneWidget);
    });

    testWidgets('ProgressionPage opens without a repository', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProgressionPage()),
      );
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Working volume over time'), findsOneWidget);
      expect(find.text('No data yet'), findsNWidgets(2));
    });
  });
}
