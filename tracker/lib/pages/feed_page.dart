import 'package:flutter/material.dart';
import 'package:tracker/home_page.dart';
import 'package:tracker/pages/analytics/progression_page.dart';
import 'package:tracker/pages/custom/custom_route.dart';
import 'package:tracker/pages/settings_page.dart';

import 'custom/custom_app_bar.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(
          context,
          title: 'Feed',
          actionButton: (
            title: 'Settings',
            onPressed: () {
              pushTo(context, SettingsPage());
            }
          ),
        ),
        SliverFillRemaining(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              const Text('Drag me up', textAlign: TextAlign.center),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: ListTile(
                  leading: const Icon(Icons.show_chart_sharp),
                  title: const Text('Progression'),
                  subtitle: const Text(
                    'Strength and volume trends across all exercises',
                  ),
                  trailing: const Icon(Icons.chevron_right_sharp),
                  onTap: () => pushTo(context, const ProgressionPage()),
                ),
              ),
              FilledButton(
                onPressed: () {
                  HomePageSingleton().changeTab(TabName.currentWorkout);
                },
                child: const Text('Go to Current Workout'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
