import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tracker/domain/models/workout_session.dart';
import 'package:tracker/ui/core/ui/custom_route.dart';
import 'package:tracker/ui/core/ui/weight_format.dart';

import 'calendar_grid.dart';
import 'session_detail_page.dart';

/// Interactive month calendar of workout days (Plan.md §2.5).
///
/// Days with at least one session get a dot; tapping a day selects it and lists
/// that day's sessions (each → [SessionDetailPage]). A metrics strip shows the
/// month's workout-day count and the current consistency streak.
class HistoryCalendar extends StatefulWidget {
  const HistoryCalendar({
    super.key,
    required this.sessions,
    required this.gymNames,
  });

  final List<WorkoutSession> sessions;
  final Map<int, String> gymNames;

  @override
  State<HistoryCalendar> createState() => _HistoryCalendarState();
}

class _HistoryCalendarState extends State<HistoryCalendar> {
  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  /// Height kept for everything around the day grid (month header, weekday
  /// row, metrics strip, day-list title + list) plus a small safety margin,
  /// so a 6-row month fits the visible area on wide windows.
  static const double _reservedHeight = 340;

  /// Estimated bottom-navigation height for the unbounded-constraint fallback.
  static const double _navAllowance = 64;

  late int _year;
  late int _month;
  DateTime? _selectedDay;
  late WorkoutDateIndex _dateIndex;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _selectedDay = _day(now);
    _dateIndex = WorkoutDateIndex.fromSessions(widget.sessions);
  }

  @override
  void didUpdateWidget(covariant HistoryCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.sessions, widget.sessions)) {
      _dateIndex = WorkoutDateIndex.fromSessions(widget.sessions);
    }
  }

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  List<WorkoutSession> _sessionsOn(DateTime day) => _dateIndex.sessionsOn(day);

  void _goMonth(int delta) {
    setState(() {
      final d = DateTime(_year, _month + delta);
      _year = d.year;
      _month = d.month;
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final grid = CalendarGrid(_year, _month);
    final monthWorkoutDays = _dateIndex.monthWorkoutDays(_year, _month);
    final streak = _dateIndex.currentStreak();

    return LayoutBuilder(
      builder: (context, constraints) {
        // The calendar sits inside the page's scroll view, so its height
        // constraint is unbounded; fall back to the window height minus the
        // app bar / bottom navigation chrome.
        final available = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).top -
                  kToolbarHeight -
                  _navAllowance;
        // Reserve the month header, weekday row, metrics strip and the day
        // list below the grid; split the rest between the grid rows.
        final cellHeight =
            ((available - _reservedHeight) / (grid.days.length ~/ 7)).clamp(
              36.0,
              56.0,
            );
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _BuildMonthHeader(
                year: _year,
                monthName: _monthName(_month),
                onPrev: () => _goMonth(-1),
                onNext: () => _goMonth(1),
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  for (final label in _weekdayLabels)
                    Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: theme.typography.body.xs.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              _dayGrid(grid, theme, cellHeight),
              const SizedBox(height: 6),
              _MetricsStrip(monthWorkoutDays: monthWorkoutDays, streak: streak),
              const SizedBox(height: 6),
              Text(
                _selectedDay == null
                    ? 'Workouts'
                    : 'Workouts · ${_dateLabel(_selectedDay!)}',
                style: theme.typography.body.sm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              _dayList(_selectedDay),
            ],
          ),
        );
      },
    );
  }

  Widget _dayGrid(CalendarGrid grid, FThemeData theme, double cellHeight) {
    const double cellSpacing = 4;
    return GridView.builder(
      padding: const EdgeInsets.only(top: 4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisExtent: cellHeight,
        mainAxisSpacing: cellSpacing,
        crossAxisSpacing: cellSpacing,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: grid.days.length,
      itemBuilder: (context, index) => _dayCell(grid, index, theme),
    );
  }

  Widget _dayCell(CalendarGrid grid, int index, FThemeData theme) {
    final dayVal = grid.days[index];
    if (dayVal == null) return const SizedBox.shrink();
    final date = DateTime(grid.year, grid.month, dayVal);
    final hasWorkout = _sessionsOn(date).isNotEmpty;
    final selected =
        _selectedDay != null && _selectedDay!.isAtSameMomentAs(date);

    final foreground = selected
        ? theme.colors.primaryForeground
        : theme.colors.foreground;
    final dot = selected
        ? theme.colors.primaryForeground
        : (hasWorkout ? theme.colors.primary : Colors.transparent);

    return InkWell(
      onTap: () => setState(() => _selectedDay = date),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: selected ? theme.colors.primary : null,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              dayVal.toString(),
              style: theme.typography.body.xs.copyWith(color: foreground),
            ),
            const SizedBox(height: 0),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayList(DateTime? day) {
    final sessions = day == null ? const <WorkoutSession>[] : _sessionsOn(day);
    if (day == null) {
      return const Text('Pick a workout day above.');
    }
    if (sessions.isEmpty) {
      return const Text('No workouts on this day.');
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: FItem.raw(
            onPress: () => pushTo(
              context,
              SessionDetailPage(
                session: session,
                gymName: session.gymId == null
                    ? null
                    : widget.gymNames[session.gymId],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(FLucideIcons.footprints),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.title),
                        Text(plural('set', session.sets.length)),
                      ],
                    ),
                  ),
                  const Icon(FLucideIcons.chevronRight),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _monthName(int m) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[m - 1];
  }

  String _dateLabel(DateTime d) => '${d.year}-${_p(d.month)}-${_p(d.day)}';

  String _p(int v) => v.toString().padLeft(2, '0');
}

class _BuildMonthHeader extends StatelessWidget {
  const _BuildMonthHeader({
    required this.year,
    required this.monthName,
    required this.onPrev,
    required this.onNext,
  });

  final int year;
  final String monthName;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Row(
      children: <Widget>[
        IconButton(
          icon: const Icon(FLucideIcons.chevronLeft),
          onPressed: onPrev,
          tooltip: 'Previous month',
        ),
        Expanded(
          child: Text(
            '$monthName $year',
            textAlign: TextAlign.center,
            style: theme.typography.body.md.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(FLucideIcons.chevronRight),
          onPressed: onNext,
          tooltip: 'Next month',
        ),
      ],
    );
  }
}

class _MetricsStrip extends StatelessWidget {
  const _MetricsStrip({required this.monthWorkoutDays, required this.streak});

  final int monthWorkoutDays;
  final int streak;

  @override
  Widget build(BuildContext context) {
    // Wrap (not Row): two metric cards can exceed a narrow window's width.
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _Metric(label: 'workout days', value: '$monthWorkoutDays'),
        _Metric(label: 'day streak', value: '$streak'),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return FCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              value,
              style: theme.typography.body.sm.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.typography.body.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
