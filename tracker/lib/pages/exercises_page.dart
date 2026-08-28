import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tracker/data/repository_scope.dart';
import 'package:tracker/models/exercise.dart';
import 'package:tracker/models/muscle.dart';
import 'package:tracker/pages/custom/custom_app_bar.dart';
import 'package:tracker/pages/custom/custom_route.dart';
import 'package:tracker/pages/exercises/exercise_detail_page.dart';
import 'package:tracker/pages/exercises/new_exercise_page.dart';

import '../home_page.dart';

enum _BrowseMode { muscle, movement }

Map<MuscleGroup, List<Exercise>> groupExercisesByMuscle(
  List<Exercise> exercises,
) {
  final grouped = <MuscleGroup, List<Exercise>>{};
  for (final exercise in exercises) {
    final muscleGroups = exercise.primaryMuscle
        .map((muscle) => Muscle.muscleToGroup[muscle]!)
        .toSet();
    for (final muscleGroup in muscleGroups) {
      grouped.putIfAbsent(muscleGroup, () => []).add(exercise);
    }
  }
  return grouped;
}

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  _BrowseMode _mode = _BrowseMode.muscle;
  List<Exercise> _exercises = const [];
  StreamSubscription<List<Exercise>>? _sub;
  bool _loaded = false;
  bool _isActive = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isActive = TabVisibilityScope.isActiveOf(context);
    if (!_loaded) {
      _loaded = true;
      _isActive = isActive;
      if (isActive) _subscribe();
    } else if (isActive != _isActive) {
      _isActive = isActive;
      if (isActive) {
        _subscribe();
      } else {
        _sub?.cancel();
        _sub = null;
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  void deactivate() {
    // Keep the explicit tab contract separate from Flutter deactivation: the
    // nested navigator remains mounted while its tab is inactive.
    super.deactivate();
  }

  void _subscribe() {
    if (_sub != null) return;
    final repo = RepositoryScope.maybeOf(context);
    if (repo == null) return;
    repo.exercises.getAll().then((list) {
      if (mounted && _isActive) setState(() => _exercises = list);
    });
    _sub = repo.exercises.watchAll().listen(
      (list) {
        if (mounted && _isActive) setState(() => _exercises = list);
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('exercises watch error: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = _mode == _BrowseMode.muscle
        ? _groupsByMuscle(_exercises)
        : _groupsByMovement(_exercises);
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(
          context,
          title: 'Exercises',
          actionButton: (
            title: 'New',
            onPressed: () => pushTo(context, const NewExercisePage()),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverToBoxAdapter(child: _buildModeSelector()),
        ),
        if (_exercises.isEmpty)
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverToBoxAdapter(
              child: Text('No exercises in the library yet.'),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return _GroupSection(
                  key: ValueKey<String>('exercise-group-${group.id}'),
                  title: group.title,
                  exercises: group.exercises,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return SegmentedButton<_BrowseMode>(
      segments: const [
        ButtonSegment(
          value: _BrowseMode.muscle,
          label: Text('Muscle group'),
          icon: Icon(Icons.accessibility_new_sharp),
        ),
        ButtonSegment(
          value: _BrowseMode.movement,
          label: Text('Movement'),
          icon: Icon(Icons.swap_vert_sharp),
        ),
      ],
      selected: {_mode},
      onSelectionChanged: (s) => setState(() => _mode = s.first),
    );
  }

  List<_ExerciseGroup> _groupsByMuscle(List<Exercise> exercises) {
    final grouped = groupExercisesByMuscle(exercises);
    return [
      for (final entry in grouped.entries)
        _ExerciseGroup(
          id: 'muscle-${entry.key.name}',
          title: MuscleGroupLabel.label(entry.key),
          exercises: entry.value,
        ),
    ];
  }

  List<_ExerciseGroup> _groupsByMovement(List<Exercise> exercises) {
    final grouped = <MovementPattern, List<Exercise>>{};
    for (final exercise in exercises) {
      grouped.putIfAbsent(exercise.movementPattern, () => []).add(exercise);
    }
    return [
      for (final entry in grouped.entries)
        _ExerciseGroup(
          id: 'movement-${entry.key.name}',
          title: MovementPatternLabel.label(entry.key),
          exercises: entry.value,
        ),
    ];
  }
}

class _ExerciseGroup {
  const _ExerciseGroup({
    required this.id,
    required this.title,
    required this.exercises,
  });

  final String id;
  final String title;
  final List<Exercise> exercises;
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({
    super.key,
    required this.title,
    required this.exercises,
  });

  final String title;
  final List<Exercise> exercises;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FCard(
        child: ExpansionTile(
          title: Text('$title (${exercises.length})'),
          children: [
            for (final exercise in exercises)
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  key: ValueKey<String>('exercise-${exercise.id}'),
                  onTap: () =>
                      pushTo(context, ExerciseDetailPage(exercise: exercise)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(exercise.title),
                              Text(
                                exercise.equipment
                                    .map((eq) => eq.displayName)
                                    .join(', '),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_sharp),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MuscleGroupLabel {
  static String label(MuscleGroup g) => switch (g) {
    MuscleGroup.abdominals => 'Abdominals',
    MuscleGroup.arms => 'Arms',
    MuscleGroup.shoulders => 'Shoulders',
    MuscleGroup.back => 'Back',
    MuscleGroup.legs => 'Legs',
    MuscleGroup.chest => 'Chest',
  };
}

class MovementPatternLabel {
  static String label(MovementPattern pattern) => switch (pattern) {
    MovementPattern.unspecified => 'Other',
    MovementPattern.push => 'Push',
    MovementPattern.pull => 'Pull',
    MovementPattern.legs => 'Legs',
    MovementPattern.core => 'Core',
    MovementPattern.fullBody => 'Full body',
  };
}
