import 'package:flutter/material.dart';
import 'package:tracker/data/repository_scope.dart';
import 'package:tracker/models/exercise.dart';
import 'package:tracker/models/muscle.dart';
import 'package:tracker/pages/custom/custom_app_bar.dart';

/// Custom exercise creation form (Plan.md §1.4): title, movement pattern,
/// target muscle groups, equipment and a description, persisted to the library
/// via the repository. Pops the created [Exercise] so the caller can react.
class NewExercisePage extends StatefulWidget {
  const NewExercisePage({super.key});

  @override
  State<NewExercisePage> createState() => _NewExercisePageState();
}

class _NewExercisePageState extends State<NewExercisePage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();

  MovementPattern _movement = MovementPattern.unspecified;
  final Set<Muscle> _primary = {};
  final Set<Muscle> _secondary = {};
  final Set<Equipment> _equipment = {Equipment.bodyweight};

  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_primary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one target muscle.')),
      );
      return;
    }

    setState(() => _saving = true);
    final repo = RepositoryScope.maybeOf(context);
    final exercise = Exercise(
      title: _title.text.trim(),
      description:
          _description.text.trim().isEmpty ? null : _description.text.trim(),
      primaryMuscle: _primary.toList(),
      secondaryMuscle: _secondary.isEmpty ? null : _secondary.toList(),
      equipment:
          _equipment.isEmpty ? [Equipment.bodyweight] : _equipment.toList(),
      movementPattern: _movement,
    );
    if (repo != null) {
      final id = await repo.exercises.put(exercise);
      exercise.id = id;
    }
    if (!mounted) return;
    Navigator.of(context).pop(exercise);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(
          context,
          title: 'New Exercise',
          actionButton: _saving ? null : (title: 'Save', onPressed: _save),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _description,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<MovementPattern>(
                    initialValue: _movement,
                    decoration: const InputDecoration(
                      labelText: 'Movement pattern',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final m in MovementPattern.values)
                        DropdownMenuItem(
                          value: m,
                          child: Text(_movementLabel(m)),
                        ),
                    ],
                    onChanged: (v) =>
                        setState(() => _movement = v ?? _movement),
                  ),
                  _ChipSection(
                    label: 'Primary muscles',
                    muscles: Muscle.values,
                    selected: _primary,
                    onToggle: (m) => setState(() {
                      _primary.contains(m)
                          ? _primary.remove(m)
                          : _primary.add(m);
                    }),
                  ),
                  _ChipSection(
                    label: 'Secondary muscles (optional)',
                    muscles: Muscle.values,
                    selected: _secondary,
                    onToggle: (m) => setState(() {
                      _secondary.contains(m)
                          ? _secondary.remove(m)
                          : _secondary.add(m);
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Equipment',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final e in Equipment.values)
                        FilterChip(
                          label: Text(e.displayName),
                          selected: _equipment.contains(e),
                          onSelected: (sel) => setState(() {
                            sel ? _equipment.add(e) : _equipment.remove(e);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _movementLabel(MovementPattern m) => switch (m) {
        MovementPattern.unspecified => 'Unspecified',
        MovementPattern.push => 'Push',
        MovementPattern.pull => 'Pull',
        MovementPattern.legs => 'Legs',
        MovementPattern.core => 'Core',
        MovementPattern.fullBody => 'Full body',
      };
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.label,
    required this.muscles,
    required this.selected,
    required this.onToggle,
  });

  final String label;
  final List<Muscle> muscles;
  final Set<Muscle> selected;
  final void Function(Muscle) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 16),
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final m in muscles)
              FilterChip(
                label: Text(m.scientificName),
                selected: selected.contains(m),
                onSelected: (_) => onToggle(m),
              ),
          ],
        ),
      ],
    );
  }
}
