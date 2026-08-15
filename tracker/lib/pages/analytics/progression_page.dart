import 'package:flutter/material.dart';
import 'package:tracker/analytics/analytics.dart';
import 'package:tracker/data/repository_scope.dart';
import 'package:tracker/models/workout_session.dart';
import 'package:tracker/pages/custom/custom_app_bar.dart';
import 'package:tracker/pages/custom/line_chart.dart';

/// General progression analytics (Plan.md §2.4): overall strength and volume
/// trends across all exercises, normalized by gym multipliers (§2.3) with
/// warm-up sets excluded (§2.1).
class ProgressionPage extends StatefulWidget {
  const ProgressionPage({super.key});

  @override
  State<ProgressionPage> createState() => _ProgressionPageState();
}

class _ProgressionPageState extends State<ProgressionPage> {
  List<WorkoutSession> _sessions = const [];
  Map<int, double> _multipliers = const {};
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // RepositoryScope is an inherited widget, so read it after initState.
    if (!_didLoad) {
      _didLoad = true;
      _load();
    }
  }

  Future<void> _load() async {
    final repo = RepositoryScope.maybeOf(context);
    final sessions = await repo?.sessions.getAll() ?? const <WorkoutSession>[];
    final gyms = await repo?.gyms.getAll() ?? const [];
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _multipliers = {for (final g in gyms) g.id: g.multiplier};
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = exerciseSummary(_sessions, _multipliers, null);
    final volume = volumeTrend(_sessions, _multipliers);
    final totalVolume = volume.fold<double>(0, (sum, p) => sum + p.value);
    final best1rm = exerciseBest1rm(_sessions, _multipliers, null);

    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(context, title: 'Progression'),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _Stat(label: 'Workouts', value: '${summary.sessionCount}'),
                    _Stat(label: 'Best 1RM', value: _fmt(summary.best1rm)),
                    _Stat(
                      label: 'Peak volume',
                      value: _fmt(summary.peakVolume),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _Stat(label: 'Total volume', value: _fmt(totalVolume)),
                const SizedBox(height: 16),
                Text(
                  'Working volume over time',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LineChart(points: volume, unit: 'kg'),
                const SizedBox(height: 24),
                Text(
                  'Best estimated 1RM over time',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LineChart(points: best1rm, unit: 'kg'),
                const SizedBox(height: 16),
                Text(
                  'Warm-up sets are excluded; weights are normalized by each '
                  'gym\'s multiplier.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: <Widget>[
              Text(value, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
