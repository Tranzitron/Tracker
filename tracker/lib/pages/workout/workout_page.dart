import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tracker/models/workout_split.dart';
import 'package:tracker/pages/custom/custom_app_bar.dart';

import 'new_split.dart';

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
        title: 'PPL',
        description: 'Description 1',
        order: 0,
        splitDays: [
          WorkoutSplitDay(
            title: 'Push',
            exercises: [1, 2, 3, 4],
            description: 'Chest, Triceps, Shoulders',
            order: 0,
          ),
          WorkoutSplitDay(
            title: 'Pull',
            exercises: [5, 7, 1, 3],
            description: 'Back, Biceps, Trapz',
            order: 4,
          ),
        ],
      ),
    );
    splits.add(
      WorkoutSplit(
        title: 'Full body',
        description: 'Description 2',
        order: 5,
        splitDays: [
          WorkoutSplitDay(
            title: 'FB 1',
            exercises: [5, 7, 1, 3],
            description: 'Back, Biceps, Trapz',
            order: 4,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(
          context,
          title: 'Workout',
        ),
        SliverFillRemaining(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return BuildMaterialSplit(splits[index]);
                      },
                    ),
                  ),
                // Flexible(
                //   child: ListView.builder(
                //     padding: EdgeInsets.all(0),
                //     shrinkWrap: true,
                //     itemCount: splits.length,
                //     physics: NeverScrollableScrollPhysics(),
                //     itemBuilder: (context, index) {
                //       return BuildSplit(splits[index]);
                //     },
                //   ),
                // ),
                BuildNewSplitButton(),
              ],
            ),
          ),
        ),
      ],
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
          child: FilledButton(
            style: ButtonStyle(
              padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                EdgeInsets.symmetric(vertical: 16),
              ),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<Widget>(
                  builder: (BuildContext context) {
                    return const Text('restart if stuck here');
                  },
                ),
              );
            },
            child: const Text(
              'Start Workout',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class BuildNewSplitButton extends StatelessWidget {
  const BuildNewSplitButton({
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
          onTap: () => {
            Navigator.push(
              context,
              CupertinoPageRoute<Widget>(
                builder: (BuildContext context) {
                  return const NewSplitPage();
                },
              ),
            ),
          },
        ),
      ],
    );
  }
}

class BuildMaterialSplit extends StatelessWidget {
  const BuildMaterialSplit(this.split, {super.key});

  final WorkoutSplit split;

  final roundBorderRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    return ListBody(
      mainAxis: Axis.vertical,
      children: <ListTile>[
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(roundBorderRadius),
              topRight: Radius.circular(roundBorderRadius),
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
          ),
          title: Text(
            split.title,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const CupertinoListTileChevron(),
          onTap: () => (),
        ),
        for (final splitDay in split.splitDays)
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(0),
                bottomLeft: Radius.circular(roundBorderRadius),
                bottomRight: Radius.circular(roundBorderRadius),
              ),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
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
