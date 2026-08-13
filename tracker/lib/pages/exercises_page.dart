import 'package:flutter/material.dart';

import 'custom/custom_app_bar.dart';

// Milestone 4 fills this with the categorized exercise library (Plan.md §1.4).
// For now it's a real screen shell with an empty state.
class ExercisesPage extends StatelessWidget {
  const ExercisesPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(context, title: 'Exercises'),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                Icon(Icons.fitness_center, size: 48),
                SizedBox(height: 12),
                Text('Exercise library coming soon'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
