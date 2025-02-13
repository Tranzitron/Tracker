import 'package:flutter/cupertino.dart';
import 'package:tracker/models/workout_split.dart';

import '../models/workout_split_day.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({
    super.key,
  });

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  List<WorkoutSplit> splits = [];

  @override
  void initState() {
    super.initState();
    splits.add(
      WorkoutSplit(
        title: 'Split 1',
        description: 'Description 1',
        order: 0,
        splitDays: [
          WorkoutSplitDay(
            title: 'Push',
            exercises: [1, 2, 3, 4],
            description: 'Chest, Triceps, Shoulders',
            order: 0,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            largeTitle: Text('Workout'),
          ),
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  BuildStartWorkoutButton(),
                  if (splits.isNotEmpty)
                    Flexible(
                      child: ListView.builder(
                        padding: EdgeInsets.all(0),
                        shrinkWrap: true,
                        itemCount: splits.length,
                        prototypeItem: BuildSplit(splits.first),
                        itemBuilder: (context, index) {
                          return BuildSplit(splits[index]);
                        },
                      ),
                    ),
                  BuildNewWorkoutButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BuildStartWorkoutButton extends StatelessWidget {
  const BuildStartWorkoutButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CupertinoButton.filled(
            padding: EdgeInsets.all(0),
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute<Widget>(
                  builder: (BuildContext context) {
                    return const Text('restart if stuck here');
                  },
                ),
              );
            },
            child: const Text('Start Workout'),
          ),
        ),
      ],
    );
  }
}

class BuildNewWorkoutButton extends StatelessWidget {
  const BuildNewWorkoutButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      margin: EdgeInsets.only(top: 16),
      children: <CupertinoListTile>[
        CupertinoListTile(
          title: Row(
            children: [
              Icon(
                CupertinoIcons.plus,
                size: 16,
              ),
              SizedBox(width: 4),
              const Text(
                'New Split',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: CupertinoColors.activeBlue,
                ),
              ),
            ],
          ),
          onTap: () => (),
        ),
      ],
    );
  }
}

class BuildSplit extends StatelessWidget {
  const BuildSplit(this.split, {super.key});

  final WorkoutSplit split;

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      margin: EdgeInsets.only(top: 16),
      additionalDividerMargin: 0,
      children: <CupertinoListTile>[
        CupertinoListTile(
          title: Text(
            split.title,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const CupertinoListTileChevron(),
          onTap: () => (),
        ),
        for (final splitDay in split.splitDays)
          CupertinoListTile(
            title: Text(
              splitDay.title,
              style: TextStyle(
                color: CupertinoColors.activeBlue,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              splitDay.exercises.join(', '),
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => (),
          ),
      ],
    );
  }
}
