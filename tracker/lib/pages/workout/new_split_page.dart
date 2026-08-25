import 'package:flutter/material.dart';
import 'package:tracker/data/repository_scope.dart';
import 'package:tracker/models/workout_split.dart';
import 'package:tracker/pages/custom/custom_app_bar.dart';
import 'package:tracker/pages/custom/custom_route.dart';

import '../../models/workout_split_templates.dart';
import 'split_day_editor_page.dart';

/// Split CRUD editor (Plan.md §1.3.1). Handles both creating a new split and
/// editing an existing one ([split] null → create). Configures the split's
/// title/description and its ordered list of days; each day opens
/// [SplitDayEditorPage].
class SplitEditorPage extends StatefulWidget {
  const SplitEditorPage({super.key, this.split});

  /// The split being edited, or null to create a new one.
  final WorkoutSplit? split;

  @override
  State<SplitEditorPage> createState() => _SplitEditorPageState();
}

class _SplitEditorPageState extends State<SplitEditorPage> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  List<WorkoutSplitDay> _days = [];
  bool _saving = false;

  bool get _isNew => widget.split == null;

  String? get _titleError =>
      _title.text.trim().isEmpty ? 'Cannot be empty' : null;

  @override
  void initState() {
    super.initState();
    final s = widget.split;
    if (s != null) {
      _title.text = s.title;
      _description.text = s.description;
      _days = [
        for (final d in s.splitDays)
          WorkoutSplitDay(
            title: d.title,
            description: d.description,
            exercises: List.of(d.exercises),
            order: d.order,
          ),
      ];
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _openDayEditor(int index) async {
    final edited = await pushTo<WorkoutSplitDay>(
      context,
      SplitDayEditorPage(day: _days[index]),
    );
    if (edited != null && mounted) {
      setState(() => _days[index] = edited);
    }
  }

  Future<void> _addDay() async {
    final day = WorkoutSplitDay(
      title: 'Day ${_days.length + 1}',
      order: _days.length,
    );
    final edited = await pushTo<WorkoutSplitDay>(
      context,
      SplitDayEditorPage(day: day),
    );
    if (edited != null && mounted) {
      setState(() => _days = [..._days, _dayWithOrder(edited, _days.length)]);
    }
  }

  WorkoutSplitDay _dayWithOrder(WorkoutSplitDay day, int order) =>
      WorkoutSplitDay(
        title: day.title,
        description: day.description,
        exercises: List.of(day.exercises),
        order: order,
      );

  Future<void> _chooseTemplate() async {
    final template = await showModalBottomSheet<WorkoutSplitTemplate>(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: Text('Use a template')),
          for (final template in workoutSplitTemplates)
            ListTile(
              title: Text(template.title),
              subtitle: Text('${template.days.length} days'),
              onTap: () => Navigator.of(context).pop(template),
            ),
        ],
      ),
    );
    if (template != null && mounted) {
      setState(() {
        _title.text = template.title;
        _days = template.createDays();
      });
    }
  }

  Future<void> _deleteSplit() async {
    final split = widget.split;
    final repo = RepositoryScope.maybeOf(context);
    if (split == null || repo == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete split?'),
        content: Text('Remove "${split.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await repo.splits.delete(split.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _save() async {
    if (_titleError != null) {
      setState(() {});
      return;
    }

    setState(() => _saving = true);
    final repo = RepositoryScope.maybeOf(context);

    final split = WorkoutSplit(
      title: _title.text.trim(),
      description: _description.text.trim(),
      splitDays: [
        for (var i = 0; i < _days.length; i++) _dayWithOrder(_days[i], i),
      ],
      order: widget.split?.order ?? -1,
    );
    if (widget.split != null) {
      split.id = widget.split!.id;
      split.order = widget.split!.order;
    } else if (repo != null) {
      var nextOrder = 0;
      final all = await repo.splits.getAll();
      if (all.isNotEmpty) {
        nextOrder = all.map((s) => s.order).reduce((a, b) => a > b ? a : b) + 1;
      }
      split.order = nextOrder;
    }

    if (repo != null) {
      await repo.splits.put(split);
    }
    if (!mounted) return;
    Navigator.of(context).pop(split);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(
          context,
          title: _isNew ? 'New Split' : 'Edit Split',
          actionButton: _saving ? null : (title: 'Save', onPressed: _save),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _title,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Split name',
                    errorText: _titleError,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _chooseTemplate,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Use a template'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _description,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 24),
                Text('Days', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_days.isEmpty)
                  const Text('No days yet — add one below.')
                else
                  for (var i = 0; i < _days.length; i++)
                    Card(
                      child: ListTile(
                        title: Text(_days[i].title),
                        subtitle: Text(
                          '${_days[i].exercises.length} exercise(s)',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Remove day',
                          onPressed: () => setState(() => _days.removeAt(i)),
                        ),
                        onTap: () => _openDayEditor(i),
                      ),
                    ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _addDay,
                  icon: const Icon(Icons.add_sharp),
                  label: const Text('Add day'),
                ),
                const SizedBox(height: 16),
                if (!_isNew)
                  FilledButton.tonal(
                    onPressed: _deleteSplit,
                    child: const Text('Delete split'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
