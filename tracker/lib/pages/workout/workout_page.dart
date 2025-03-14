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
                      padding: EdgeInsets.zero,
                      shrinkWrap: false,
                      itemCount: splits.length,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return BuildMaterialSplit(splits[index]);
                      },
                    ),
                  ),
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
    return FilledButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute<Widget>(
            builder: (BuildContext context) {
              return const NewSplitPage();
            },
          ),
        );
      },
      style: ButtonStyle(
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.add_sharp,
            size: 16,
          ),
          SizedBox(width: 4),
          const Text(
            'New Split',
            overflow: TextOverflow.ellipsis,
          ),
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
      margin: EdgeInsets.only(
        top: 16,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.transparent,
        ),
        color: Color.fromARGB(25, 127, 127, 127),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListBody(
        mainAxis: Axis.vertical,
        children: <Widget>[
          WorkoutListTile(
            titleText: split.title,
            isSplitDay: false,
            trailing: const Icon(Icons.chevron_right_sharp),
            onTap: () => (),
          ),
          ListView.builder(
            itemCount: split.splitDays.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final splitDay = split.splitDays[index];
              return Column(
                children: [
                  Divider(
                    height: 1.0,
                    indent: 16.0,
                    endIndent: 16.0,
                  ),
                  WorkoutListTile(
                    isSplitDay: true,
                    titleText: splitDay.title,
                    exercises: splitDay.exercises,
                  ),
                ],
              );
            },
          ),
        ],
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
  final List? exercises;
  final void Function()? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 40.0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      title: Text(
        titleText,
        style: TextStyle(
          color: isSplitDay ? Colors.blueAccent : Colors.white,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
      subtitle: exercises != null
          ? Text(
              exercises!.join(', '),
              overflow: TextOverflow.ellipsis,
            )
          : SizedBox(
              height: 0,
              width: 0,
            ),
      onTap: onTap,
    );
  }
}
