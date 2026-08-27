import 'package:flutter/material.dart';
import 'package:tracker/models/workout_session.dart';
import 'package:tracker/pages/custom/custom_route.dart';

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
    final theme = Theme.of(context);
    final grid = CalendarGrid(_year, _month);
    final monthWorkoutDays = _dateIndex.monthWorkoutDays(_year, _month);
    final streak = _dateIndex.currentStreak();

    return Column(
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
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        _dayGrid(grid, theme),
        const SizedBox(height: 6),
        _MetricsStrip(monthWorkoutDays: monthWorkoutDays, streak: streak),
        const SizedBox(height: 6),
        Text(
          _selectedDay == null
              ? 'Workouts'
              : 'Workouts · ${_dateLabel(_selectedDay!)}',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        _dayList(_selectedDay),
      ],
    );
  }

  Widget _dayGrid(CalendarGrid grid, ThemeData theme) {
    const double cellSpacing = 4;
    return GridView.count(
      padding: EdgeInsets.only(top: 4),
      crossAxisCount: 7,
      childAspectRatio: 1.75,
      mainAxisSpacing: cellSpacing,
      crossAxisSpacing: cellSpacing,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        for (var i = 0; i < grid.days.length; i++) _dayCell(grid, i, theme),
      ],
    );
  }

  Widget _dayCell(CalendarGrid grid, int index, ThemeData theme) {
    final dayVal = grid.days[index];
    if (dayVal == null) return const SizedBox.shrink();
    final date = DateTime(grid.year, grid.month, dayVal);
    final hasWorkout = _sessionsOn(date).isNotEmpty;
    final selected =
        _selectedDay != null && _selectedDay!.isAtSameMomentAs(date);

    final foreground = selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    final dot = selected
        ? theme.colorScheme.onPrimary
        : (hasWorkout ? theme.colorScheme.primary : Colors.transparent);

    return InkWell(
      onTap: () => setState(() => _selectedDay = date),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : null,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              dayVal.toString(),
              style: theme.textTheme.bodySmall?.copyWith(color: foreground),
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
    return SizedBox(
      height: 128,
      child: ListView.builder(
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.directions_run_sharp),
              title: Text(session.title),
              subtitle: Text('${session.sets.length} set(s)'),
              trailing: const Icon(Icons.chevron_right_sharp),
              onTap: () => pushTo(
                context,
                SessionDetailPage(
                  session: session,
                  gymName: session.gymId == null
                      ? null
                      : widget.gymNames[session.gymId],
                ),
              ),
            ),
          );
        },
      ),
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
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.chevron_left_sharp),
          onPressed: onPrev,
          tooltip: 'Previous month',
        ),
        Expanded(
          child: Text(
            '$monthName $year',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_sharp),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(value, style: theme.textTheme.titleSmall),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
