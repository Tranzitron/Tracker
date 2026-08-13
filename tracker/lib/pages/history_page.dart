import 'package:flutter/material.dart';

import 'custom/custom_app_bar.dart';

// Milestone 5 fills this with the actual session list + calendar (Plan.md §1.2,
// §2.5). For now it's a real screen shell with an empty state.
class HistoryPage extends StatelessWidget {
  const HistoryPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(context, title: 'History'),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                Icon(Icons.history, size: 48),
                SizedBox(height: 12),
                Text('No workouts logged yet'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
