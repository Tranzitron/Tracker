import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tracker/data/repository_scope.dart';
import 'package:tracker/models/exercise.dart';
import 'package:tracker/models/gym.dart';
import 'package:tracker/models/workout_set.dart';
import 'package:tracker/pages/custom/custom_app_bar.dart';
import 'package:tracker/pages/workout/workout_cubit.dart';

import 'gym_picker.dart';

/// The "Current Workout" tab: drives the active session from [WorkoutCubit].
///
/// Idle → a Start button (with gym selection). In progress → the session's
/// exercises (from the split plan, or free-form) with inline weight/reps set
/// logging, warmup flags, and an End button that writes a [WorkoutSession].
class CurrentWorkoutPage extends StatelessWidget {
  const CurrentWorkoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(context, title: 'Current Workout'),
        SliverToBoxAdapter(
          child: BlocBuilder<WorkoutCubit, WorkoutState>(
            builder: (context, state) {
              final cubit = context.read<WorkoutCubit>();
              return state.isInProgress
                  ? _InProgressView(state: state, onEnd: cubit.endWorkout)
                  : _IdleView(onStart: () => _startWorkout(context));
            },
          ),
        ),
      ],
    );
  }

  Future<void> _startWorkout(BuildContext context) async {
    final cubit = context.read<WorkoutCubit>();
    final repo = RepositoryScope.maybeOf(context);
    final gyms = (await repo?.gyms.getAll()) ?? const <Gym>[];
    if (!context.mounted) return;
    final gym = await promptGym(context, gyms);
    cubit.startWorkout(gym: gym);
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 64),
          const Icon(Icons.fitness_center_sharp, size: 48),
          const SizedBox(height: 12),
          const Text('No workout in progress'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Workout'),
          ),
        ],
      ),
    );
  }
}

class _InProgressView extends StatelessWidget {
  const _InProgressView({required this.state, required this.onEnd});

  final WorkoutState state;
  final Future<void> Function() onEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _WorkoutHeader(state: state),
          const SizedBox(height: 16),
          if (state.plan.isEmpty)
            const _FreeFormPanel()
          else
            for (final exercise in state.plan)
              _PlanExerciseCard(
                key: ValueKey('plan-${exercise.order}'),
                exercise: exercise,
                sets: state.sets
                    .where((s) => s.exerciseId == exercise.exerciseId)
                    .toList(),
                order: exercise.order,
              ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _confirmEnd(context),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.stop),
            label: const Text('End Workout'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmEnd(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End workout?'),
        content: Text(
          'Log ${state.sets.length} set(s) and save this workout to history.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('End & save'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await onEnd();
    }
  }
}

/// Session summary: title, gym, start time, and live set/volume totals.
class _WorkoutHeader extends StatelessWidget {
  const _WorkoutHeader({required this.state});

  final WorkoutState state;

  @override
  Widget build(BuildContext context) {
    final started = state.startTime;
    final working =
        state.sets.where((s) => !s.isWarmup).fold<double>(0, _volumeTotal);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.directions_run_sharp,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.planTitle ?? 'Free workout',
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.gymName != null)
              Text('${state.gymName} · ${_fmtTime(started)}')
            else
              Text(_fmtTime(started)),
            const SizedBox(height: 8),
            Text(
              '${state.sets.length} set(s) · '
              '${working.toStringAsFixed(0)} kg working volume',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  double _volumeTotal(double acc, ActiveSet s) => acc + s.weight * s.reps;

  String _fmtTime(DateTime? dt) {
    if (dt == null) return '';
    final t = dt.toLocal();
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return 'Started at $hh:$mm';
  }
}

/// One exercise from the plan: its logged sets plus an inline add-set form.
class _PlanExerciseCard extends StatelessWidget {
  const _PlanExerciseCard({
    super.key,
    required this.exercise,
    required this.sets,
    required this.order,
  });

  final PlanExercise exercise;
  final List<ActiveSet> sets;
  final int order;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  '${order + 1}. ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Expanded(
                  child: Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (sets.isEmpty)
              Text(
                'No sets yet',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              for (final set in sets) _SetTile(set: set),
            const Divider(height: 16),
            _AddSetForm(
              exerciseId: exercise.exerciseId,
              exerciseName: exercise.name,
            ),
          ],
        ),
      ),
    );
  }
}

/// Free-form logging (no split plan): a single editor with an exercise
/// dropdown (loaded from the repository) plus all sets logged so far.
class _FreeFormPanel extends StatefulWidget {
  const _FreeFormPanel();

  @override
  State<_FreeFormPanel> createState() => _FreeFormPanelState();
}

class _FreeFormPanelState extends State<_FreeFormPanel> {
  List<Exercise> _exercises = const [];
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
    final list = await repo?.exercises.getAll() ?? const <Exercise>[];
    if (!mounted) return;
    setState(() => _exercises = list);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Log a set', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _AddSetForm(exercises: _exercises),
            const SizedBox(height: 8),
            BlocBuilder<WorkoutCubit, WorkoutState>(
              builder: (context, state) {
                final sets = state.sets;
                if (sets.isEmpty) {
                  return const Text('No sets yet');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final set in sets) _SetTile(set: set),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A rendered set row with a warmup indicator and a delete action.
class _SetTile extends StatelessWidget {
  const _SetTile({required this.set});

  final ActiveSet set;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: _WarmupBadge(isWarmup: set.isWarmup),
      title: Text('${_fmt(set.weight)} kg × ${set.reps}'),
      subtitle: set.isWarmup
          ? Text('Warm-up', style: theme.textTheme.bodySmall)
          : null,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 20),
        tooltip: 'Remove set',
        onPressed: () => context.read<WorkoutCubit>().removeSet(set.order),
      ),
    );
  }
}

/// A compact color/number badge distinguishing warm-up from working sets.
class _WarmupBadge extends StatelessWidget {
  const _WarmupBadge({required this.isWarmup});

  final bool isWarmup;

  @override
  Widget build(BuildContext context) {
    final color = isWarmup
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isWarmup ? 'W' : 'S',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Inline editor: pick an exercise (either fixed by the plan or via a dropdown
/// over [_ExerciseRepository]) and enter weight + reps with a warm-up toggle.
class _AddSetForm extends StatefulWidget {
  const _AddSetForm({this.exerciseId, this.exerciseName, this.exercises});

  /// When set, the exercise is fixed (plan-driven) and no dropdown is shown.
  final int? exerciseId;
  final String? exerciseName;

  /// When provided with [exerciseId] null, a dropdown of [Exercise] is shown
  /// instead (free-form logging).
  final List<Exercise>? exercises;

  @override
  State<_AddSetForm> createState() => _AddSetFormState();
}

class _AddSetFormState extends State<_AddSetForm> {
  final _weight = TextEditingController();
  final _reps = TextEditingController();
  bool _warmup = false;
  int? _selectedId;
  bool _repsInvalid = false;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.exerciseId;
    _reps.addListener(() {
      setState(() => _repsInvalid = false);
    });
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (widget.exerciseId == null) ...[
          _exerciseDropdown(),
          const SizedBox(height: 8),
        ],
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _weight,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _reps,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Reps',
                  border: const OutlineInputBorder(),
                  errorText: _repsInvalid ? 'Required' : null,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            FilterChip(
              label: const Text('Warm-up'),
              selected: _warmup,
              onSelected: (v) => setState(() => _warmup = v),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _add,
              child: const Text('Add set'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _exerciseDropdown() {
    final exercises = widget.exercises ?? const <Exercise>[];
    return DropdownButtonFormField<int>(
      initialValue: _selectedId,
      decoration: const InputDecoration(
        labelText: 'Exercise',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final e in exercises)
          DropdownMenuItem(value: e.id, child: Text(e.title)),
      ],
      onChanged: (v) => setState(() => _selectedId = v),
    );
  }

  void _add() {
    final reps = int.tryParse(_reps.text);
    if (reps == null || reps <= 0) {
      setState(() => _repsInvalid = true);
      return;
    }
    final id = _selectedId;
    if (id == null || id <= 0) return;

    // Resolve the display name: fixed by the plan, or looked up from the
    // dropdown's exercise list.
    String name = widget.exerciseName ?? '';
    if (name.isEmpty && widget.exercises != null) {
      for (final e in widget.exercises!) {
        if (e.id == id) {
          name = e.title;
          break;
        }
      }
    }
    final weight = double.tryParse(_weight.text) ?? 0.0;
    context.read<WorkoutCubit>().logSet(
          exerciseId: id,
          exerciseName: name,
          weight: weight,
          reps: reps,
          type: _warmup ? SetType.warmup : SetType.working,
        );
    _weight.clear();
    setState(() {});
  }
}

String _fmt(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(1);
}
