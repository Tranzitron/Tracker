import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tracker/analytics/analytics.dart';
import 'package:tracker/models/workout_session.dart';
import 'package:tracker/pages/custom/line_chart.dart';
import 'package:tracker/pages/settings/weight_format.dart';

class FeedGraphCard extends StatelessWidget {
  const FeedGraphCard({
    super.key,
    required this.config,
    required this.sessions,
    required this.multipliers,
    required this.exerciseName,
    required this.onEdit,
    required this.onDelete,
  });

  final GraphConfig config;
  final List<WorkoutSession> sessions;
  final Map<int, double> multipliers;
  final String exerciseName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final points = graphPoints(
      config: config,
      sessions: sessions,
      multipliers: multipliers,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      config.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              Text(
                '$exerciseName · ${graphMetricLabel(config.metric)} · ${graphTimeframeLabel(config.timeframe)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              LineChart(
                points: displayProgressionPoints(context, points),
                unit: weightUnitOf(context).symbol,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
