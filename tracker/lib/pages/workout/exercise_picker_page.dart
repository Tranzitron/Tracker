import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tracker/data/repository_scope.dart';
import 'package:tracker/models/exercise.dart';
import 'package:tracker/pages/custom/custom_app_bar.dart';

/// Picks one exercise from the library for a split day (§1.3.1.1.1). Pops the
/// selected [Exercise] (or null if dismissed).
class ExercisePickerPage extends StatefulWidget {
  const ExercisePickerPage({super.key});

  @override
  State<ExercisePickerPage> createState() => _ExercisePickerPageState();
}

class _ExercisePickerPageState extends State<ExercisePickerPage> {
  List<Exercise> _all = const [];
  List<Exercise> _shown = const [];
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    final repo = RepositoryScope.maybeOf(context);
    final list = await repo?.exercises.getAll() ?? const <Exercise>[];
    if (!mounted) return;
    setState(() {
      _all = list;
      _shown = list;
    });
  }

  void _filter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _shown = q.isEmpty
          ? _all
          : _all.where((e) => e.title.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(context, title: 'Pick exercise'),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: FTextField(
              hint: 'Search exercises…',
              control: FTextFieldControl.managed(
                onChange: (value) => _filter(value.text),
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final e = _shown[index];
            return ListTile(
              title: Text(e.title),
              subtitle: Text(
                e.primaryMuscle.map((m) => m.scientificName).join(', '),
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.of(context).pop(e),
            );
          }, childCount: _shown.length),
        ),
      ],
    );
  }
}
