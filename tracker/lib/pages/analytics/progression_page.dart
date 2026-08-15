import 'package:flutter/material.dart';
import 'package:tracker/analytics/analytics.dart';
import 'package:tracker/data/repository_scope.dart';
import 'package:tracker/models/workout_session.dart';
import 'package:tracker/pages/custom/custom_app_bar.dart';
import 'package:tracker/pages/custom/line_chart.dart';
import 'package:tracker/pages/settings/weight_format.dart';

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
  bool _loading = false;
  Object? _loadError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _loading = true;
      // didChangeDependencies runs during the mount/build phase. Defer the
      // first state update until that phase completes.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final repo = RepositoryScope.maybeOf(context);
      final sessions =
          await repo?.sessions.getAll() ?? const <WorkoutSession>[];
      final gyms = await repo?.gyms.getAll() ?? const [];
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _multipliers = {for (final gym in gyms) gym.id: gym.multiplier};
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error;
      });
    }
  }

  Widget _content(BuildContext context) {
    if (_loading && _sessions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_loadError != null && _sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(height: 8),
            const Text('Could not load progression data.'),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    final summary = exerciseSummary(_sessions, _multipliers, null);
    final volume = displayProgressionPoints(
      context,
      volumeTrend(_sessions, _multipliers),
    );
    final totalVolume =
        volume.fold<double>(0, (sum, point) => sum + point.value);
    final best1rm = displayProgressionPoints(
      context,
      exerciseBest1rm(_sessions, _multipliers, null),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            _Stat(label: 'Workouts', value: '${summary.sessionCount}'),
            _Stat(
              label: 'Best 1RM',
              value: formatWeight(context, summary.best1rm),
            ),
            _Stat(
              label: 'Peak volume',
              value: formatWeight(context, summary.peakVolume),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _Stat(
              label: 'Total volume',
              value: formatWeight(context, totalVolume),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Working volume over time', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        LineChart(points: volume, unit: weightUnitOf(context).symbol),
        const SizedBox(height: 24),
        Text(
          'Best estimated 1RM over time',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        LineChart(points: best1rm, unit: weightUnitOf(context).symbol),
        const SizedBox(height: 16),
        Text(
          'Warm-up sets are excluded; weights are normalized by each '
          'gym\'s multiplier.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(context, title: 'Progression'),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _content(context),
          ),
        ),
      ],
    );
  }
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
