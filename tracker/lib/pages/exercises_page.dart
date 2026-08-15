import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tracker/data/repository_scope.dart';
import 'package:tracker/models/exercise.dart';
import 'package:tracker/models/muscle.dart';
import 'package:tracker/pages/custom/custom_app_bar.dart';
import 'package:tracker/pages/custom/custom_route.dart';
import 'package:tracker/pages/exercises/exercise_detail_page.dart';
import 'package:tracker/pages/exercises/new_exercise_page.dart';

enum _BrowseMode { muscle, movement }

/// The master exercise library (Plan.md §1.4).
///
/// Browse the seeded + custom exercises by target muscle group or movement
/// pattern, tap through to each exercise's detail view, and create custom
/// exercises. Historical graphs land with analytics (Milestone 6).
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
    // Load immediately (avoids a blank flash) and keep listening for changes.
    repo.exercises.getAll().then((list) {
      if (mounted && _isActive) setState(() => _exercises = list);
    });
    _sub = repo.exercises.watchAll().listen(
      (list) {
        if (mounted && _isActive) setState(() => _exercises = list);
      },
      onError: (Object e, StackTrace st) {
        // Surface async Isar stream errors instead of leaving them unhandled.
        debugPrint('exercises watch error: $e');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SegmentedButton<_BrowseMode>(
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
                ),
                const SizedBox(height: 16),
                if (_exercises.isEmpty)
                  const Text('No exercises in the library yet.')
                else if (_mode == _BrowseMode.muscle)
                  _buildByMuscle()
                else
                  _buildByMovement(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildByMuscle() {
    final byGroup = <MuscleGroup, List<Exercise>>{};
    for (final e in _exercises) {
      for (final muscle in e.primaryMuscle) {
        byGroup.putIfAbsent(Muscle.muscleToGroup[muscle]!, () => []).add(e);
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in byGroup.entries)
          _GroupSection(
            title: MuscleGroupLabel.label(entry.key),
            exercises: entry.value,
          ),
      ],
    );
  }

  Widget _buildByMovement() {
    final byMovement = <MovementPattern, List<Exercise>>{};
    for (final e in _exercises) {
      byMovement.putIfAbsent(e.movementPattern, () => []).add(e);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in byMovement.entries)
          _GroupSection(
            title: MovementPatternLabel.label(entry.key),
            exercises: entry.value,
          ),
      ],
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.title, required this.exercises});

  final String title;
  final List<Exercise> exercises;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text('$title (${exercises.length})'),
        children: [
          for (final e in exercises)
            ListTile(
              title: Text(e.title),
              subtitle: Text(
                e.equipment.map((eq) => eq.displayName).join(', '),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_sharp),
              onTap: () => pushTo(context, ExerciseDetailPage(exercise: e)),
            ),
        ],
      ),
    );
  }
}

/// Shared muscle-group display names used by the category browser.
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
