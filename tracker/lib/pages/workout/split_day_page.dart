import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tracker/data/repository_scope.dart';
import 'package:tracker/home_page.dart';
import 'package:tracker/models/gym.dart';
import 'package:tracker/models/workout_split.dart';
import 'package:tracker/pages/custom/custom_app_bar.dart';
import 'package:tracker/pages/workout/workout_cubit.dart';

import 'gym_picker.dart';

/// A real detail screen for one split day (Milestone 3): shows the day's
/// exercises and lets the user start that workout as the active session. This
/// replaces the old `Text('restart if stuck in fake workout')` placeholder.
class SplitDayPage extends StatefulWidget {
  const SplitDayPage({super.key, required this.splitTitle, required this.day});

  final String splitTitle;
  final WorkoutSplitDay day;

  @override
  State<SplitDayPage> createState() => _SplitDayPageState();
}

class _SplitDayPageState extends State<SplitDayPage> {
  Map<int, String> _names = const {};
  bool _loading = true;
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // RepositoryScope is an inherited widget, so read it here (after initState)
    // rather than in initState.
    if (!_didLoad) {
      _didLoad = true;
      _load();
    }
  }

  Future<void> _load() async {
    final repo = RepositoryScope.maybeOf(context);
    final exercises = await repo?.exercises.getAll() ?? const [];
    final names = <int, String>{for (final e in exercises) e.id: e.title};
    if (!mounted) return;
    setState(() {
      _names = names;
      _loading = false;
    });
  }

  Future<void> _startWorkout(BuildContext context) async {
    final cubit = context.read<WorkoutCubit>();
    final repo = RepositoryScope.maybeOf(context);
    final gyms = (await repo?.gyms.getAll()) ?? const <Gym>[];
    if (!context.mounted) return;
    final gym = await promptGym(context, gyms);

    final plan = <PlanExercise>[];
    final items = widget.day.exercises;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      plan.add(
        PlanExercise(
          exerciseId: item.exerciseId,
          name: _names[item.exerciseId] ?? 'Exercise ${item.exerciseId}',
          order: i,
        ),
      );
    }
    cubit.startPlanWorkout(
      title: '${widget.splitTitle} · ${widget.day.title}',
      exercises: plan,
      gym: gym,
    );
    HomePageSingleton().changeTab(TabName.currentWorkout);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(context, title: widget.day.title),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  '${widget.splitTitle} · ${widget.day.title}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (widget.day.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.day.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (items.isEmpty)
                  const Text('No exercises in this day yet.')
                else
                  for (final (index, item) in items.indexed)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text('${index + 1}'),
                      title: Text(
                        _names[item.exerciseId] ??
                            'Exercise ${item.exerciseId}',
                      ),
                      subtitle: _targetSubtitle(item),
                    ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _startWorkout(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start this workout'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<ExerciseItem> get items => widget.day.exercises;

  Widget? _targetSubtitle(ExerciseItem item) {
    if (item.targetSets == null && item.targetReps == null) return null;
    final parts = <String>[];
    if (item.targetSets != null) parts.add('${item.targetSets} sets');
    if (item.targetReps != null) parts.add('${item.targetReps} reps');
    return Text(parts.join(' × '));
  }
}
