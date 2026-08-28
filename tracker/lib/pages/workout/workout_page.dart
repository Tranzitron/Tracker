import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:tracker/data/repository_scope.dart';
import 'package:tracker/models/exercise.dart';
import 'package:tracker/models/gym.dart';
import 'package:tracker/models/workout_set.dart';
import 'package:tracker/pages/custom/custom_app_bar.dart';
import 'package:tracker/pages/custom/form_validators.dart';
import 'package:tracker/pages/settings/weight_format.dart';
import 'package:tracker/pages/workout/workout_cubit.dart';

import 'gym_picker.dart';

/// The "Current Workout" tab: drives the active session from [WorkoutCubit].
///
/// Idle → a Start button (with gym selection). In progress → the session's
/// exercises (from the split plan, or free-form) with inline weight/reps set
/// logging, warmup flags, and an End button that writes a [WorkoutSession].
class WorkoutPage extends StatelessWidget {
  const WorkoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(context, title: 'Current Workout'),
        SliverToBoxAdapter(
          child: BlocSelector<WorkoutCubit, WorkoutState, bool>(
            selector: (state) => state.isInProgress,
            builder: (context, isInProgress) {
              final cubit = context.read<WorkoutCubit>();
              return isInProgress
                  ? _InProgressView(onEnd: cubit.endWorkout)
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
          const Icon(FLucideIcons.dumbbell, size: 48),
          const SizedBox(height: 12),
          const Text('No workout in progress'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(FLucideIcons.play),
            label: const Text('Start Workout'),
          ),
        ],
      ),
    );
  }
}

enum _WorkoutAction { save, discard, cancel }

class _InProgressView extends StatelessWidget {
  const _InProgressView({required this.onEnd});

  final Future<void> Function() onEnd;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WorkoutCubit, WorkoutState, _WorkoutPresentation>(
      selector: _WorkoutPresentation.fromState,
      builder: (context, presentation) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _WorkoutHeader(presentation: presentation.header),
            const SizedBox(height: 16),
            if (presentation.plan.isEmpty)
              const _FreeFormPanel()
            else
              for (final exercise in presentation.plan)
                _PlanExerciseCard(
                  key: ValueKey('plan-${exercise.exercise.order}'),
                  exercise: exercise.exercise,
                  sets: exercise.sets,
                  order: exercise.exercise.order,
                ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _confirmEnd(context, presentation.setCount),
              style: FilledButton.styleFrom(
                backgroundColor: context.theme.colors.error,
                foregroundColor: context.theme.colors.errorForeground,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(FLucideIcons.squareStop),
              label: const Text('End Workout'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmEnd(BuildContext context, int setCount) async {
    // Zero sets: prompt directly to discard
    if (setCount == 0) {
      final confirmDiscard = await _showDiscardConfirmation(
        context,
        noSets: true,
      );
      if (confirmDiscard && context.mounted) {
        await onEnd();
      }
      return;
    }

    // Has sets: prompt to Save or Discard
    final action = await _showEndOptionsDialog(context, setCount);
    if (!context.mounted || action == _WorkoutAction.cancel) return;

    if (action == _WorkoutAction.discard) {
      final confirmDiscard = await _showDiscardConfirmation(
        context,
        noSets: false,
      );
      if (confirmDiscard && context.mounted) {
        await onEnd();
      }
    } else if (action == _WorkoutAction.save) {
      await onEnd();
    }
  }

  Future<_WorkoutAction> _showEndOptionsDialog(
    BuildContext context,
    int setCount,
  ) async {
    return await showFDialog<_WorkoutAction>(
          context: context,
          builder: (dialogContext, _, _) => FDialog(
            builder: (context, style) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('End workout?', style: style.titleTextStyle),
                const SizedBox(height: 8),
                Text(
                  'Log $setCount set(s) and save this workout to history.',
                  style: style.bodyTextStyle,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(FLucideIcons.trash2),
                      color: dialogContext.theme.colors.error,
                      tooltip: 'Discard workout',
                      onPressed: () =>
                          Navigator.pop(dialogContext, _WorkoutAction.discard),
                    ),
                    const Spacer(),
                    FButton(
                      variant: .outline,
                      onPress: () =>
                          Navigator.pop(dialogContext, _WorkoutAction.cancel),
                      child: const Text('Keep going'),
                    ),
                    const SizedBox(width: 8),
                    FButton(
                      onPress: () =>
                          Navigator.pop(dialogContext, _WorkoutAction.save),
                      child: const Text('End & save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ) ??
        _WorkoutAction.cancel;
  }

  Future<bool> _showDiscardConfirmation(
    BuildContext context, {
    bool noSets = false,
  }) async {
    return await showFDialog<bool>(
          context: context,
          builder: (dialogContext, _, _) => FDialog(
            builder: (context, style) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Discard workout?', style: style.titleTextStyle),
                const SizedBox(height: 8),
                Text(
                  noSets
                      ? 'No sets have been logged. Do you want to discard this session?'
                      : 'This will delete all progress for this session.',
                  style: style.bodyTextStyle,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FButton(
                      variant: .outline,
                      onPress: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FButton(
                      onPress: () => Navigator.pop(dialogContext, true),
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ) ??
        false;
  }
}

class _WorkoutPresentation {
  const _WorkoutPresentation({
    required this.header,
    required this.plan,
    required this.setCount,
  });

  final _WorkoutHeaderData header;
  final List<({PlanExercise exercise, List<ActiveSet> sets})> plan;
  final int setCount;

  static _WorkoutPresentation fromState(WorkoutState state) {
    return _WorkoutPresentation(
      header: _WorkoutHeaderData.fromState(state),
      plan: [
        for (final exercise in state.plan)
          (
            exercise: exercise,
            sets: state.setsByExercise[exercise.exerciseId] ?? const [],
          ),
      ],
      setCount: state.sets.length,
    );
  }
}

class _WorkoutHeaderData {
  const _WorkoutHeaderData({
    this.planTitle,
    this.gymName,
    this.startTime,
    required this.setCount,
    required this.workingVolume,
  });

  final String? planTitle;
  final String? gymName;
  final DateTime? startTime;
  final int setCount;
  final double workingVolume;

  static _WorkoutHeaderData fromState(WorkoutState state) => _WorkoutHeaderData(
    planTitle: state.planTitle,
    gymName: state.gymName,
    startTime: state.startTime,
    setCount: state.sets.length,
    workingVolume: state.workingVolume,
  );
}

class _WorkoutHeader extends StatelessWidget {
  const _WorkoutHeader({required this.presentation});

  final _WorkoutHeaderData presentation;

  @override
  Widget build(BuildContext context) {
    final started = presentation.startTime;
    final working = presentation.workingVolume;
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  FLucideIcons.footprints,
                  color: context.theme.colors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    presentation.planTitle ?? 'Free workout',
                    style: context.theme.typography.body.xl.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (presentation.gymName != null)
              Text('${presentation.gymName} · ${_fmtTime(started)}')
            else
              Text(_fmtTime(started)),
            const SizedBox(height: 8),
            Text(
              '${presentation.setCount} set(s) · ${formatWeight(context, working)} working volume',
              style: context.theme.typography.body.md,
            ),
          ],
        ),
      ),
    );
  }

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    '${order + 1}. ',
                    style: context.theme.typography.body.md.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      exercise.name,
                      style: context.theme.typography.body.md.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (sets.isEmpty)
                Text(
                  'No sets yet',
                  style: context.theme.typography.body.xs.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                )
              else
                for (final set in sets) _SetTile(set: set),
              const FDivider(),
              _AddSetForm(
                exerciseId: exercise.exerciseId,
                exerciseName: exercise.name,
              ),
            ],
          ),
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
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Log a set',
              style: context.theme.typography.body.md.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
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
                  children: [for (final set in sets) _SetTile(set: set)],
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
    final theme = context.theme;
    return FItem(
      prefix: _WarmupBadge(isWarmup: set.isWarmup),
      title: Text('${formatWeight(context, set.weight)} × ${set.reps}'),
      subtitle: set.isWarmup
          ? Text(
              'Warm-up',
              style: theme.typography.body.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
            )
          : null,
      suffix: IconButton(
        icon: const Icon(FLucideIcons.trash2, size: 20),
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
    final theme = context.theme;
    final color = isWarmup ? theme.colors.secondary : theme.colors.primary;
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
  String? _weightError;
  String? _repsError;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.exerciseId;
    _weight.addListener(() => setState(() => _weightError = null));
    _reps.addListener(() => setState(() => _repsError = null));
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
              child: FTextField(
                control: FTextFieldControl.managed(controller: _weight),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                label: Text('Weight (${weightUnitOf(context).symbol})'),
                error: _weightError == null ? null : Text(_weightError!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FTextField(
                control: FTextFieldControl.managed(controller: _reps),
                keyboardType: TextInputType.number,
                label: const Text('Reps'),
                error: _repsError == null ? null : Text(_repsError!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            FCheckbox(
              label: const Text('Warm-up'),
              value: _warmup,
              onChange: (v) => setState(() => _warmup = v),
            ),
            const Spacer(),
            FilledButton(onPressed: _add, child: const Text('Add set')),
          ],
        ),
      ],
    );
  }

  Widget _exerciseDropdown() {
    final exercises = widget.exercises ?? const <Exercise>[];
    return FSelect<int>(
      label: const Text('Exercise'),
      items: {for (final e in exercises) e.title: e.id},
      control: FSelectControl<int>.lifted(
        value: _selectedId,
        onChange: (v) => setState(() => _selectedId = v),
      ),
    );
  }

  void _add() {
    final weightError = requiredDouble(_weight.text);
    final repsError = requiredDouble(_reps.text);
    final reps = int.tryParse(_reps.text);
    if (weightError != null || repsError != null || reps == null) {
      setState(() {
        _weightError = weightError;
        _repsError = repsError;
      });
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
    final displayedWeight = double.tryParse(_weight.text) ?? 0.0;
    final weight = kilogramsFromDisplay(context, displayedWeight);
    context.read<WorkoutCubit>().logSet(
      exerciseId: id,
      exerciseName: name,
      weight: weight,
      reps: reps,
      type: _warmup ? SetType.warmup : SetType.working,
    );
    _reps.clear();
    _warmup = false;
    setState(() {});
  }
}
