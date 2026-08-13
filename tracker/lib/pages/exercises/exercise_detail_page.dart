import 'package:flutter/material.dart';
import 'package:tracker/models/exercise.dart';
import 'package:tracker/pages/custom/custom_app_bar.dart';

/// Individual exercise view (Plan.md §1.4.1.1).
///
/// Shows the exercise's profile (target muscles, equipment, movement pattern,
/// description). Historical stats/graphs are part of Milestone 6 (analytics);
/// this screen is the base that Milestone 6 will grow graphs into.
class ExerciseDetailPage extends StatelessWidget {
  const ExerciseDetailPage({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(context, title: exercise.title),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (exercise.description != null) ...[
                  Text(exercise.description!, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                ],
                _InfoRow(
                  label: 'Movement pattern',
                  value: MovementPatternLabel.label(exercise.movementPattern),
                ),
                _InfoRow(
                  label: 'Primary muscles',
                  value: exercise.primaryMuscle
                      .map((m) => m.scientificName)
                      .join(', '),
                ),
                if (exercise.secondaryMuscle != null &&
                    exercise.secondaryMuscle!.isNotEmpty)
                  _InfoRow(
                    label: 'Secondary muscles',
                    value: exercise.secondaryMuscle!
                        .map((m) => m.scientificName)
                        .join(', '),
                  ),
                _InfoRow(
                  label: 'Equipment',
                  value:
                      exercise.equipment.map((e) => e.displayName).join(', '),
                ),
                const Divider(height: 32),
                Text('Performance history', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Progression charts and set logs arrive with analytics '
                  '(Milestone 6).',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Shared movement-pattern display names (avoids duplicating the switch).
class MovementPatternLabel {
  static String label(MovementPattern m) => switch (m) {
        MovementPattern.unspecified => 'Unspecified',
        MovementPattern.push => 'Push',
        MovementPattern.pull => 'Pull',
        MovementPattern.legs => 'Legs',
        MovementPattern.core => 'Core',
        MovementPattern.fullBody => 'Full body',
      };
}
