import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tracker/domain/services/analytics.dart';
import 'package:tracker/domain/models/workout_session.dart';
import 'package:tracker/domain/models/weight_unit.dart';
import 'package:tracker/ui/core/ui/line_chart.dart';
import 'package:tracker/domain/models/graph_config.dart';
import 'package:tracker/ui/core/ui/weight_format.dart';

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
                      style: context.theme.typography.body.md.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FPopoverMenu.tiles(
                    menuAnchor: .topRight,
                    childAnchor: .bottomRight,
                    menu: [
                      .group(
                        children: [
                          .tile(title: const Text('Edit'), onPress: onEdit),
                          .tile(title: const Text('Delete'), onPress: onDelete),
                        ],
                      ),
                    ],
                    builder: (_, controller, _) => FButton(
                      variant: .ghost,
                      onPress: controller.toggle,
                      child: const Icon(FLucideIcons.ellipsisVertical),
                    ),
                  ),
                ],
              ),
              Text(
                '$exerciseName · ${graphMetricLabel(config.metric)} · ${graphTimeframeLabel(config.timeframe)}',
                style: context.theme.typography.body.xs.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
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
