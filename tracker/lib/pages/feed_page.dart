import 'package:flutter/material.dart';
import 'package:tracker/home_page.dart';

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
        ),
        SliverFillRemaining(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              const Text('Drag me up', textAlign: TextAlign.center),
              FilledButton(
                onPressed: () {
                  HomePageSingleton().changeTab(TabName.workout);
                },
                child: const Text('Go to Workout Page'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
