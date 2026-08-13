import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tracker/pages/custom/custom_app_bar.dart';
import 'package:tracker/pages/workout/workout_cubit.dart';

/// The "Current Workout" tab: shows the in-progress workout or an idle state.
///
/// This is a functional shell driven by [WorkoutCubit]. Milestone 3 replaces
/// the summary body with full set-by-set logging; for now it renders the live
/// workout state and start/end actions.
class CurrentWorkoutPage extends StatelessWidget {
  const CurrentWorkoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(context, title: 'Current Workout'),
        SliverFillRemaining(
          hasScrollBody: false,
          child: BlocBuilder<WorkoutCubit, WorkoutState>(
            builder: (context, state) {
              final cubit = context.read<WorkoutCubit>();
              return state.isInProgress
                  ? _InProgressView(state: state, onEnd: cubit.endWorkout)
                  : _IdleView(onStart: cubit.startWorkout);
            },
          ),
        ),
      ],
    );
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
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final started = state.startTime;
    final completed = state.completedExercises.length;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Icon(Icons.directions_run_sharp, size: 48),
          const SizedBox(height: 12),
          Text(
            'Workout in progress',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (started != null) ...[
            const SizedBox(height: 8),
            Text(
              'Started ${started.toLocal()}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '$completed exercise${completed == 1 ? '' : 's'} logged',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onEnd,
            icon: const Icon(Icons.stop),
            label: const Text('End Workout'),
          ),
        ],
      ),
    );
  }
}
