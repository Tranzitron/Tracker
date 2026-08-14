// Milestone 5 — history & calendar (Plan.md §1.2, §2.5).
//
// 1. Calendar math + consistency streak are pure functions/classes
//    (no Isar), so are unit-tested directly.
// 2. Session detail UI is widget-tested without a database: it declares no
//    dependency on repository data (exercise names degrade to ids) and the
//    sets/gym/duration come straight from the session passed in.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/models/workout_session.dart';
import 'package:tracker/models/workout_set.dart';
import 'package:tracker/pages/history/calendar_grid.dart';
import 'package:tracker/pages/history/session_detail_page.dart';

void main() {
  group('CalendarGrid math', () {
    test('Monday-start grid, correct leading blanks and day count', () {
      // March 2026 starts on a Sunday → 6 leading blanks (Mon..Sat of week),
      // then days 1..31. Verify via the last day landing in its cell.
      final grid = CalendarGrid(2026, 3);
      expect(grid.days, hasLength(42));
      // March 1 2026 is a Sunday: index 6 (0=Mon..6=Sun).
      expect(grid.days.sublist(0, 6).where((d) => d != null), isEmpty);
      expect(grid.days[6], 1);
      expect(grid.days[36], 31); // March has 31 days
      // Cells after the month end are blank.
      expect(grid.days.sublist(37).where((d) => d != null), isEmpty);
    });

    test('February 2026 (28 days) lays out in one fewer row', () {
      final grid = CalendarGrid(2026, 2);
      expect(grid.days.where((d) => d != null), hasLength(28));
    });

    test('dateFor maps an index back to a real date', () {
      final grid = CalendarGrid(2026, 3);
      expect(grid.dateFor(6), DateTime(2026, 3, 1));
    });
  });

  group('currentStreak', () {
    test('counts consecutive workout days ending today', () {
      final today = DateUtils.dateOnly(DateTime.now());
      final set = <DateTime>{
        today,
        today.subtract(const Duration(days: 1)),
        today.subtract(const Duration(days: 2)),
      };
      expect(currentStreak(set), 3);
    });

    test('zero when no workout at all', () {
      expect(currentStreak(<DateTime>{}), 0);
    });

    test('backs up to the last workout day when today has none', () {
      final today = DateUtils.dateOnly(DateTime.now());
      final set = <DateTime>{
        today.subtract(const Duration(days: 1)),
        today.subtract(const Duration(days: 2)),
      };
      expect(currentStreak(set), 2);
    });
  });

  group('SessionDetailPage UI', () {
    testWidgets('renders header, stats and every set with warmup marker',
        (tester) async {
      final session = WorkoutSession(
        title: 'Home workout',
        startTime: DateTime(2026, 1, 1, 9),
        endTime: DateTime(2026, 1, 1, 10),
        gymId: 3,
        sets: [
          WorkoutSet(
            exerciseId: 1,
            weight: 80,
            reps: 5,
            type: SetType.working,
            order: 0,
          ),
          WorkoutSet(
            exerciseId: 1,
            weight: 60,
            reps: 8,
            type: SetType.warmup,
            order: 1,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SessionDetailPage(session: session, gymName: 'Home'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home workout'), findsOneWidget); // app bar title
      expect(
        find.text('Home · 1h 0m'),
        findsOneWidget,
      ); // gym + duration in header
      expect(find.text('80 kg × 5'), findsOneWidget);
      expect(find.text('60 kg × 8'), findsOneWidget);
      expect(find.text('W'), findsOneWidget); // warmup marker
      expect(find.text('S'), findsOneWidget); // working marker
    });

    testWidgets('shows a working volume that excludes warmup sets',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionDetailPage(
            session: WorkoutSession(
              title: 'Push',
              startTime: DateTime(2026, 1, 2, 9),
              endTime: DateTime(2026, 1, 2, 10),
              sets: [
                WorkoutSet(
                  exerciseId: 1,
                  weight: 100,
                  reps: 5,
                  type: SetType.working,
                  order: 0,
                ),
                WorkoutSet(
                  exerciseId: 1,
                  weight: 60,
                  reps: 8,
                  type: SetType.warmup,
                  order: 1,
                ),
              ],
            ),
            gymName: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 100×5 = 500 kg working volume; the 60×8 warmup is excluded.
      expect(find.text('500 kg'), findsOneWidget);
    });
  });
}
