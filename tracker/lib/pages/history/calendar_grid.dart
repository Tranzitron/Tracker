import 'package:flutter/material.dart';

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
int currentStreak(Set<DateTime> workoutDays) {
  var day = DateUtils.dateOnly(DateTime.now());
  if (!workoutDays.contains(day)) day = day.subtract(const Duration(days: 1));
  var streak = 0;
  while (workoutDays.contains(day)) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}
