import 'package:flutter/material.dart';
import 'package:tracker/analytics/analytics.dart';
import 'package:tracker/data/repository_scope.dart';
import 'package:tracker/models/gym.dart';
import 'package:tracker/models/workout_session.dart';
import 'package:tracker/pages/custom/custom_app_bar.dart';
import 'package:tracker/pages/custom/form_validators.dart';

/// Gym management (Plan.md §2.2 / §2.3): create/edit gyms, mark one as the
/// primary baseline (multiplier locked to 1.0), and set or auto-estimate each
/// gym's weight-equivalence multiplier from logged sessions.
class GymsPage extends StatefulWidget {
  const GymsPage({super.key});

  @override
  State<GymsPage> createState() => _GymsPageState();
}

class _GymsPageState extends State<GymsPage> {
  List<WorkoutSession> _sessions = const [];
  Stream<List<Gym>>? _stream;
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // RepositoryScope is an inherited widget, so read it after initState.
    // Cache the watch stream once so rebuilds don't resubscribe the query.
    if (!_didLoad) {
      _didLoad = true;
      _stream = RepositoryScope.maybeOf(context)?.gyms.watchAll();
      _loadSessions();
    }
  }

  Future<void> _loadSessions() async {
    final repo = RepositoryScope.maybeOf(context);
    final sessions = await repo?.sessions.getAll() ?? const <WorkoutSession>[];
    if (!mounted) return;
    setState(() => _sessions = sessions);
  }

  Future<void> _addGym(List<Gym> gyms) async {
    final repo = RepositoryScope.maybeOf(context);
    var nextOrder = 0;
    if (gyms.isNotEmpty) {
      nextOrder = gyms.map((g) => g.order).reduce((a, b) => a > b ? a : b) + 1;
    }
    final created = await _editGymDialog(
      context,
      title: 'New Gym',
      initial: Gym(name: '', order: nextOrder, isPrimary: gyms.isEmpty),
      getExistingGyms: repo?.gyms.getAll,
    );
    if (created != null && repo != null) {
      await repo.gyms.put(created);
    }
  }

  Future<void> _editGym(Gym gym) async {
    final repo = RepositoryScope.maybeOf(context);
    final edited = await _editGymDialog(
      context,
      title: 'Edit Gym',
      initial: gym,
      getExistingGyms: repo?.gyms.getAll,
    );
    if (edited != null && repo != null) {
      await repo.gyms.put(edited);
    }
  }

  Future<void> _setPrimary(Gym gym) async {
    final repo = RepositoryScope.maybeOf(context);
    if (repo == null) return;
    final all = await repo.gyms.getAll();
    final updated = [
      for (final g in all)
        g
          ..isPrimary = g.id == gym.id
          ..multiplier = g.id == gym.id ? 1.0 : g.multiplier,
    ];
    await repo.gyms.putAll(updated);
  }

  Future<void> _estimateMultiplier(Gym gym) async {
    final repo = RepositoryScope.maybeOf(context);
    if (repo == null) return;
    final all = await repo.gyms.getAll();
    Gym? primary;
    for (final g in all) {
      if (g.isPrimary) {
        primary = g;
        break;
      }
    }
    if (primary == null) {
      _snack('Mark a gym as primary first.');
      return;
    }
    final estimates = estimateGymExerciseMultipliers(
      _sessions,
      primary.id,
      gym.id,
      halfLife: const Duration(days: 180),
    );
    final estimate = estimateGymMultiplier(
      _sessions,
      primary.id,
      gym.id,
      halfLife: const Duration(days: 180),
    );
    if (estimate == null) {
      _snack('No shared exercise logs to estimate from.');
      return;
    }
    await repo.gyms.put(
      gym
        ..multiplier = estimate
        ..perExerciseMultipliers = [
          for (final entry in estimates.entries)
            GymExerciseMultiplier(
              exerciseId: entry.key,
              multiplier: entry.value,
            ),
        ],
    );
    _snack('Estimated ${estimates.length} movement multipliers.');
  }

  Future<void> _deleteGym(Gym gym) async {
    final repo = RepositoryScope.maybeOf(context);
    if (repo == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete gym?'),
        content: Text('Remove "${gym.name}"? Past sessions keep their record.'),
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
    if (confirmed == true) {
      await repo.gyms.delete(gym.id);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(
          context,
          title: 'Gyms',
          actionButton: (
            title: 'Add',
            onPressed: () {
              final repo = RepositoryScope.maybeOf(context);
              repo?.gyms.getAll().then((gyms) {
                if (mounted) _addGym(gyms);
              });
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'The primary gym is the baseline (multiplier ×1.0). '
                  'Secondary multipliers align their weights to it.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<Gym>>(
                  stream: _stream,
                  initialData: const <Gym>[],
                  builder: (context, snapshot) {
                    final gyms = snapshot.data ?? const <Gym>[];
                    if (gyms.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Text('No gyms yet — add one.'),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final gym in gyms)
                          _GymTile(
                            gym: gym,
                            canEstimate: _sessions.isNotEmpty,
                            onPrimary: () => _setPrimary(gym),
                            onEdit: () => _editGym(gym),
                            onEstimate: () => _estimateMultiplier(gym),
                            onDelete: () => _deleteGym(gym),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Shows an add/edit dialog; returns the [Gym] to persist or null on cancel.
String? _gymNameError(String value) => requiredText(value);

String? _gymMultiplierError(String value, {required bool isPrimary}) =>
    isPrimary ? null : requiredDouble(value);

String _normalizeGymField(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

bool sameGymName(Gym first, Gym second) =>
    _normalizeGymField(first.name) == _normalizeGymField(second.name) &&
    _normalizeGymField(first.description ?? '') ==
        _normalizeGymField(second.description ?? '');

Future<Gym?> _editGymDialog(
  BuildContext context, {
  required String title,
  required Gym initial,
  Future<List<Gym>> Function()? getExistingGyms,
}) {
  final name = TextEditingController(text: initial.name);
  final description = TextEditingController(text: initial.description ?? '');
  final multiplier = TextEditingController(
    text: initial.isPrimary ? '1.0' : _fmtGym(initial.multiplier),
  );

  final dialog = showDialog<Gym>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: name,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Gym name',
                    errorText: _gymNameError(name.text),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: multiplier,
                  enabled: !initial.isPrimary,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: initial.isPrimary
                        ? 'Multiplier (primary = ×1.0)'
                        : 'Weight multiplier',
                    helperText: initial.isPrimary
                        ? 'The primary gym is the fixed baseline.'
                        : 'Scales logged weights to the primary gym.',
                    border: const OutlineInputBorder(),
                    errorText: _gymMultiplierError(
                      multiplier.text,
                      isPrimary: initial.isPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final nameText = name.text.trim();
                final multiplierError = _gymMultiplierError(
                  multiplier.text,
                  isPrimary: initial.isPrimary,
                );
                if (_gymNameError(nameText) != null ||
                    multiplierError != null) {
                  setState(() {});
                  return;
                }
                final candidate = Gym(
                  name: nameText,
                  description: description.text.trim(),
                  isPrimary: initial.isPrimary,
                  order: initial.order,
                  multiplier: initial.isPrimary
                      ? 1.0
                      : double.tryParse(multiplier.text.trim()) ?? 1.0,
                )..id = initial.id;
                final existing = await getExistingGyms?.call() ?? const <Gym>[];
                if (existing.any(
                  (gym) => gym.id != initial.id && sameGymName(gym, candidate),
                )) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('A gym with this name already exists'),
                      ),
                    );
                  }
                  return;
                }
                if (context.mounted) Navigator.of(context).pop(candidate);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    },
  );
  return dialog.whenComplete(() {
    name.dispose();
    description.dispose();
    multiplier.dispose();
  });
}

class _GymTile extends StatelessWidget {
  const _GymTile({
    required this.gym,
    required this.canEstimate,
    required this.onPrimary,
    required this.onEdit,
    required this.onEstimate,
    required this.onDelete,
  });

  final Gym gym;
  final bool canEstimate;
  final VoidCallback onPrimary;
  final VoidCallback onEdit;
  final VoidCallback onEstimate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = gym.isPrimary;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onEdit,
        leading: Icon(
          primary ? Icons.home_sharp : Icons.fitness_center_sharp,
          color: primary ? theme.colorScheme.primary : null,
        ),
        title: Text(gym.name),
        subtitle: Text(
          primary
              ? 'Primary · baseline ×1.0'
              : 'Multiplier ×${_fmtGym(gym.multiplier)} · '
                    '${gym.perExerciseMultipliers.length} movement overrides',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => switch (action) {
            'primary' => onPrimary(),
            'estimate' => onEstimate(),
            'delete' => onDelete(),
            _ => null,
          },
          itemBuilder: (context) => [
            if (!primary)
              const PopupMenuItem(
                value: 'primary',
                child: Text('Set as primary'),
              ),
            if (!primary && canEstimate)
              const PopupMenuItem(
                value: 'estimate',
                child: Text('Auto-estimate multiplier'),
              ),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

String _fmtGym(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(1) : v.toStringAsFixed(2);
