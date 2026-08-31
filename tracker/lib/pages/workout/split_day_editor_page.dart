import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tracker/data/repository_scope.dart';
import 'package:tracker/domain/models/workout_split.dart';
import 'package:tracker/pages/custom/custom_app_bar.dart';
import 'package:tracker/pages/custom/custom_route.dart';
import 'package:tracker/pages/custom/form_validators.dart';
import 'package:tracker/pages/workout/exercise_picker_page.dart';

/// Split day editor (Plan.md §1.3.1.1 / §1.3.1.1.1): configure a day's title,
/// description and ordered exercise list (add / remove / reorder). Pops the
/// edited [WorkoutSplitDay] so the parent split editor can store it.
class SplitDayEditorPage extends StatefulWidget {
  const SplitDayEditorPage({super.key, required this.day});

  final WorkoutSplitDay day;

  @override
  State<SplitDayEditorPage> createState() => _SplitDayEditorPageState();
}

class _SplitDayEditorPageState extends State<SplitDayEditorPage> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  List<ExerciseItem> _items = [];
  Map<int, String> _names = const {};
  bool _didLoad = false;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _title.text = widget.day.title;
    _description.text = widget.day.description;
    _items = List.of(widget.day.exercises);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // RepositoryScope is an inherited widget, so read it here (after initState).
    // Guard so a dependency change doesn't re-run the async load.
    if (!_didLoad) {
      _didLoad = true;
      _loadNames();
    }
  }

  Future<void> _loadNames() async {
    final repo = RepositoryScope.maybeOf(context);
    final exercises = await repo?.exercises.getAll() ?? const [];
    if (!mounted) return;
    setState(() {
      _names = {for (final e in exercises) e.id: e.title};
    });
  }

  Future<void> _addExercise() async {
    final exercise = await pushTo(context, const ExercisePickerPage());
    if (exercise != null && mounted) {
      setState(() {
        _items.add(ExerciseItem(exerciseId: exercise.id, order: _items.length));
      });
    }
  }

  void _save() {
    _titleError = requiredText(_title.text);
    if (_titleError != null) {
      setState(() {});
      return;
    }
    final day = WorkoutSplitDay(
      title: _title.text.trim(),
      description: _description.text.trim(),
      exercises: [
        for (var i = 0; i < _items.length; i++)
          ExerciseItem(
            exerciseId: _items[i].exerciseId,
            order: i,
            targetSets: _items[i].targetSets,
            targetReps: _items[i].targetReps,
            restSeconds: _items[i].restSeconds,
          ),
      ],
    );
    Navigator.of(context).pop(day);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(
          context,
          title: _title.text.isEmpty ? 'Edit Day' : _title.text,
          actionButton: (title: 'Save', onPressed: _save),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                FTextField(
                  control: FTextFieldControl.managed(
                    controller: _title,
                    onChange: (_) => setState(() => _titleError = null),
                  ),
                  label: const Text('Day name'),
                  error: _titleError == null ? null : Text(_titleError!),
                ),
                const SizedBox(height: 16),
                FTextField(
                  control: FTextFieldControl.managed(controller: _description),
                  label: const Text('Description (optional)'),
                  minLines: 1,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 24),
                Row(
                  children: <Widget>[
                    Text('Exercises', style: context.theme.typography.body.md),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _addExercise,
                      icon: const Icon(FLucideIcons.plus, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_items.isEmpty)
                  const Text('No exercises yet — drag the handle to reorder.')
                else
                  _buildReorderableList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReorderableList() {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorderItem: _onReorder,
      children: [
        for (var i = 0; i < _items.length; i++)
          _ExerciseRow(
            key: ValueKey('day-item-${_items[i].exerciseId}-$i'),
            index: i,
            orderLabel: '${i + 1}',
            name:
                _names[_items[i].exerciseId] ??
                'Exercise ${_items[i].exerciseId}',
            onDelete: () => setState(() => _items.removeAt(i)),
          ),
      ],
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      // onReorderItem already accounts for the removed item at oldIndex.
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    super.key,
    required this.index,
    required this.orderLabel,
    required this.name,
    required this.onDelete,
  });

  final int index;
  final String orderLabel;
  final String name;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return FItem(
      prefix: ReorderableDragStartListener(
        index: index,
        child: const Icon(FLucideIcons.gripHorizontal),
      ),
      title: Text('$orderLabel. $name'),
      suffix: IconButton(
        icon: const Icon(FLucideIcons.trash2),
        onPressed: onDelete,
      ),
    );
  }
}
