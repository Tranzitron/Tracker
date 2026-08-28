import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tracker/analytics/analytics.dart';
import 'package:tracker/models/exercise.dart';
import 'package:tracker/pages/settings/settings_cubit.dart';

/// Small dialog for creating or editing a feed graph configuration.
class GraphEditor extends StatefulWidget {
  const GraphEditor({super.key, this.initial, required this.exercises});

  final GraphConfig? initial;
  final List<Exercise> exercises;

  @override
  State<GraphEditor> createState() => _GraphEditorState();
}

class _GraphEditorState extends State<GraphEditor> {
  late final TextEditingController _title;
  late int? _exerciseId;
  late GraphMetric _metric;
  late GraphTimeframe _timeframe;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _title = TextEditingController(text: initial?.title ?? '');
    _exerciseId = initial?.exerciseId;
    _metric = initial?.metric ?? GraphMetric.best1rm;
    _timeframe = initial?.timeframe ?? GraphTimeframe.all;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add graph' : 'Edit graph'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FTextField(
              control: FTextFieldControl.managed(controller: _title),
              label: const Text('Title'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            FSelect<int?>(
              label: const Text('Exercise'),
              items: {
                'All exercises': null,
                for (final exercise in widget.exercises)
                  exercise.title: exercise.id,
              },
              control: FSelectControl<int?>.lifted(
                value: _exerciseId,
                onChange: (value) => setState(() => _exerciseId = value),
              ),
            ),
            const SizedBox(height: 12),
            FSelect<GraphMetric>(
              label: const Text('Metric'),
              items: {
                for (final metric in GraphMetric.values)
                  graphMetricLabel(metric): metric,
              },
              control: FSelectControl<GraphMetric>.lifted(
                value: _metric,
                onChange: (value) => setState(() => _metric = value!),
              ),
            ),
            const SizedBox(height: 12),
            FSelect<GraphTimeframe>(
              label: const Text('Timeframe'),
              items: {
                for (final timeframe in GraphTimeframe.values)
                  graphTimeframeLabel(timeframe): timeframe,
              },
              control: FSelectControl<GraphTimeframe>.lifted(
                value: _timeframe,
                onChange: (value) => setState(() => _timeframe = value!),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final title = _title.text.trim();
            if (title.isEmpty) return;
            Navigator.pop(
              context,
              GraphConfig(
                title: title,
                exerciseId: _exerciseId,
                metric: _metric,
                timeframe: _timeframe,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
