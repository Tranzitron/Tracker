import 'package:flutter/material.dart';
import 'package:tracker/data/repository_scope.dart';
import 'package:tracker/models/workout_session.dart';
import 'package:tracker/models/workout_set.dart';
import 'package:tracker/pages/custom/custom_app_bar.dart';
import 'package:tracker/pages/settings/weight_format.dart';

/// Full view of a single past [WorkoutSession] (Plan.md §1.2): header stats
/// plus every logged set with its warm-up/working indicator and working volume.
///
/// Reached from the history list and the calendar's day logs (Checkpoint 5).
class SessionDetailPage extends StatefulWidget {
  const SessionDetailPage({super.key, required this.session, this.gymName});

  final WorkoutSession session;

  /// Resolved gym display name (nullable — a session may have no gym).
  final String? gymName;

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  Map<int, String> _exerciseNames = const {};
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // RepositoryScope is an inherited widget, so read it after initState.
    if (!_didLoad) {
      _didLoad = true;
      _loadExerciseNames();
    }
  }

  Future<void> _loadExerciseNames() async {
    final repo = RepositoryScope.maybeOf(context);
    final exercises = await repo?.exercises.getAll() ?? const [];
    if (!mounted) return;
    setState(() {
      _exerciseNames = {for (final e in exercises) e.id: e.title};
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = widget.session;
    final workingSets = session.sets.where((s) => !s.isWarmup).toList();
    final workingVolume = workingSets.fold<double>(
      0,
      (sum, s) => sum + s.weight * s.reps,
    );

    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(context, title: session.title),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _HeaderCard(session: session, gymName: widget.gymName),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    _Stat(label: 'Sets', value: '${session.sets.length}'),
                    _Stat(
                      label: 'Working volume',
                      value: formatWeight(context, workingVolume),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Sets', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (session.sets.isEmpty)
                  const Text('No sets were logged in this session.')
                else
                  for (final set in session.sets)
                    _SetRow(
                      name:
                          _exerciseNames[set.exerciseId] ??
                          'Exercise ${set.exerciseId}',
                      set: set,
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.session, this.gymName});

  final WorkoutSession session;
  final String? gymName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = session.endTime != null
        ? session.endTime!.difference(session.startTime)
        : Duration.zero;
    final d = session.startTime.toLocal();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(_date(d), style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              [if (gymName != null) gymName!, _duration(duration)].join(' · '),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _date(DateTime d) =>
      '${d.year}-${_p(d.month)}-${_p(d.day)} ${_p(d.hour)}:${_p(d.minute)}';

  String _p(int v) => v.toString().padLeft(2, '0');

  String _duration(Duration dur) {
    if (dur.inHours > 0) return '${dur.inHours}h ${dur.inMinutes % 60}m';
    return '${dur.inMinutes}m';
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: <Widget>[
              Text(value, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({required this.name, required this.set});

  final String name;
  final WorkoutSet set;

  @override
  Widget build(BuildContext context) {
    final isWarmup = set.isWarmup;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: _WarmupChip(isWarmup: isWarmup),
        title: Text(name),
        subtitle: Text('${formatWeight(context, set.weight)} × ${set.reps}'),
      ),
    );
  }
}

/// W / S chip mirroring the current-workout screen's indicator (see the cubit's
/// `isWarmup`).
class _WarmupChip extends StatelessWidget {
  const _WarmupChip({required this.isWarmup});

  final bool isWarmup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isWarmup ? Colors.orange : theme.colorScheme.primary;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
      ),
      child: Text(
        isWarmup ? 'W' : 'S',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
