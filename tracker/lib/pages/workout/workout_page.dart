import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tracker/data/repository_scope.dart';
import 'package:tracker/models/gym.dart';
import 'package:tracker/models/workout_split.dart';
import 'package:tracker/pages/custom/custom_app_bar.dart';
import 'package:tracker/pages/custom/custom_route.dart';
import 'package:tracker/pages/workout/workout_cubit.dart';

import 'gym_picker.dart';
import 'new_split_page.dart';
import 'split_day_page.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  Stream<List<WorkoutSplit>>? _stream;
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _stream = RepositoryScope.maybeOf(context)?.splits.watchAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(context, title: 'Workout'),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<List<WorkoutSplit>>(
              stream: _stream,
              initialData: const <WorkoutSplit>[],
              builder: (context, snapshot) {
                final splits = snapshot.data ?? const <WorkoutSplit>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const BuildStartWorkoutButton(),
                    if (splits.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('No splits yet. Create one below.'),
                      )
                    else
                      for (final split in splits) BuildMaterialSplit(split),
                    const BuildNewSplitButton(),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class BuildStartWorkoutButton extends StatelessWidget {
  const BuildStartWorkoutButton({super.key});

  Future<void> _start(BuildContext context) async {
    final cubit = context.read<WorkoutCubit>();
    final repo = RepositoryScope.maybeOf(context);
    final gyms = (await repo?.gyms.getAll()) ?? const <Gym>[];
    if (!context.mounted) return;
    final gym = await promptGym(context, gyms);
    cubit.startWorkout(gym: gym);
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: ButtonStyle(
        padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.symmetric(vertical: 16),
        ),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      onPressed: () => _start(context),
      child: const Text('Start Workout', style: TextStyle(fontSize: 16)),
    );
  }
}

class BuildNewSplitButton extends StatelessWidget {
  const BuildNewSplitButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => pushTo(context, const SplitEditorPage()),
      style: ButtonStyle(
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.add_sharp, size: 16),
          SizedBox(width: 4),
          Text('New Split', overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class BuildMaterialSplit extends StatelessWidget {
  const BuildMaterialSplit(this.split, {super.key});

  final WorkoutSplit split;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Material(
        color: const Color.fromARGB(25, 127, 127, 127),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.transparent),
        ),
        child: ListBody(
          children: <Widget>[
            WorkoutListTile(
              key: ValueKey<String>('split-header-${split.id}'),
              titleText: split.title,
              isSplitDay: false,
              trailing: const Icon(Icons.edit_outlined, size: 20),
              onTap: () => pushTo(context, SplitEditorPage(split: split)),
            ),
            for (var index = 0; index < split.splitDays.length; index++)
              InkWell(
                key: ValueKey<String>('split-day-${split.id}-$index'),
                onTap: () => pushTo(
                  context,
                  SplitDayPage(
                    splitTitle: split.title,
                    day: split.splitDays[index],
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    WorkoutListTile(
                      isSplitDay: true,
                      titleText: split.splitDays[index].title,
                      exercises: split.splitDays[index].exercises,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class WorkoutListTile extends StatelessWidget {
  const WorkoutListTile({
    super.key,
    required this.titleText,
    required this.isSplitDay,
    this.exercises,
    this.onTap,
    this.trailing,
  });

  final String titleText;
  final bool isSplitDay;
  final List<ExerciseItem>? exercises;
  final void Function()? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 40,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        titleText,
        style: TextStyle(color: isSplitDay ? Colors.blueAccent : Colors.white),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
      subtitle: exercises != null
          ? Text(
              exercises!.map((e) => e.exerciseId).join(', '),
              overflow: TextOverflow.ellipsis,
            )
          : const SizedBox(height: 0, width: 0),
      onTap: onTap,
    );
  }
}
