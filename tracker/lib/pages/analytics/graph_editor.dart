import 'package:flutter/material.dart';
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
            TextField(
              controller: _title,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _exerciseId,
              decoration: const InputDecoration(labelText: 'Exercise'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All exercises'),
                ),
                ...widget.exercises.map(
                  (exercise) => DropdownMenuItem<int?>(
                    value: exercise.id,
                    child: Text(exercise.title),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _exerciseId = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<GraphMetric>(
              initialValue: _metric,
              decoration: const InputDecoration(labelText: 'Metric'),
              items: [
                for (final metric in GraphMetric.values)
                  DropdownMenuItem(
                    value: metric,
                    child: Text(graphMetricLabel(metric)),
                  ),
              ],
              onChanged: (value) => setState(() => _metric = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<GraphTimeframe>(
              initialValue: _timeframe,
              decoration: const InputDecoration(labelText: 'Timeframe'),
              items: [
                for (final timeframe in GraphTimeframe.values)
                  DropdownMenuItem(
                    value: timeframe,
                    child: Text(graphTimeframeLabel(timeframe)),
                  ),
              ],
              onChanged: (value) => setState(() => _timeframe = value!),
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
