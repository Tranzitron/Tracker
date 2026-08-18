import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:tracker/models/workout_session.dart';

/// Immutable, normalized index of sessions by local calendar date.
///
/// Building this once per session-list update avoids repeatedly scanning all
/// sessions while painting each calendar cell and calculating metrics.
class WorkoutDateIndex {
  factory WorkoutDateIndex.fromSessions(Iterable<WorkoutSession> sessions) {
    final byDay = <DateTime, List<WorkoutSession>>{};
    for (final session in sessions) {
      final day = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      byDay.putIfAbsent(day, () => <WorkoutSession>[]).add(session);
    }
    return WorkoutDateIndex._(byDay);
  }
  WorkoutDateIndex._(Map<DateTime, List<WorkoutSession>> byDay)
    : _byDay = UnmodifiableMapView(<DateTime, List<WorkoutSession>>{
        for (final entry in byDay.entries)
          entry.key: UnmodifiableListView(entry.value),
      }),
      workoutDays = UnmodifiableSetView(byDay.keys.toSet()) {
    final counts = <int, int>{};
    for (final day in byDay.keys) {
      final key = day.year * 100 + day.month;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    _monthCounts = UnmodifiableMapView(counts);
    _streak = _currentStreak(workoutDays);
  }

  late final Map<int, int> _monthCounts;
  late final int _streak;

  final Map<DateTime, List<WorkoutSession>> _byDay;
  final Set<DateTime> workoutDays;

  List<WorkoutSession> sessionsOn(DateTime day) => _byDay[day] ?? const [];

  int monthWorkoutDays(int year, int month) =>
      _monthCounts[year * 100 + month] ?? 0;

  int currentStreak() => _streak;
}

/// Pure calendar math for the history calendar (Plan.md §2.5), kept free of
/// Isar/widget concerns so the layout and consistency logic can be unit-tested
/// without a database.
class CalendarGrid {
  CalendarGrid(this.year, this.month) {
    final first = DateTime(year, month);
    final leading = first.weekday - 1; // Monday-start grid
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final cells = <int?>[for (var i = 0; i < 6 * 7; i++) null];
    for (var d = 1; d <= daysInMonth; d++) {
      cells[leading + d - 1] = d;
    }
    days = cells;
  }

  final int year;
  final int month;

  /// 42 cells (6 rows × 7 columns); [int?] day-of-month, null for a blank slot.
  late final List<int?> days;

  DateTime dateFor(int index) => DateTime(year, month, days[index] ?? 1);
}

/// Number of consecutive days (ending today, or the last workout day if today
/// has none) that each contain at least one workout. Dates should be passed
/// date-only (midnight). Pure → unit-testable.
int currentStreak(Set<DateTime> workoutDays) => _currentStreak(workoutDays);

int _currentStreak(Set<DateTime> workoutDays) {
  var day = DateUtils.dateOnly(DateTime.now());
  if (!workoutDays.contains(day)) day = day.subtract(const Duration(days: 1));
  var streak = 0;
  while (workoutDays.contains(day)) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}
