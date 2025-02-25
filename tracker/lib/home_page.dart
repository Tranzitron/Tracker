import 'package:flutter/cupertino.dart';
import 'package:quiver/collection.dart';

import 'pages/exercices_page.dart';
import 'pages/feed_page.dart';
import 'pages/history_page.dart';
import 'pages/settings_page.dart';
import 'pages/workout/workout_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  get controller => HomePageSingleton().controller;

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      controller: controller,
      tabBar: CupertinoTabBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house_fill),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.clock_solid),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.plus_app_fill),
            label: 'Workout',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.tray_full_fill),
            label: 'Exercices',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          builder: (BuildContext context) {
            return CupertinoPageScaffold(
              child: switch (index) {
                0 => FeedPage(),
                1 => HistoryPage(),
                2 => WorkoutPage(),
                3 => ExercicesPage(),
                4 => SettingsPage(),
                int() => throw UnimplementedError(),
              },
            );
          },
        );
      },
    );
  }
}

class HomePageSingleton {
  static final HomePageSingleton _singleton = HomePageSingleton._internal();

  factory HomePageSingleton() {
    return _singleton;
  }

  HomePageSingleton._internal() {
    tabMap.addAll(
      {
        TabName.feed: 0,
        TabName.history: 1,
        TabName.workout: 2,
        TabName.exercises: 3,
        TabName.settings: 4,
      },
    );
  }

  CupertinoTabController controller = CupertinoTabController();

  BiMap<TabName, int> tabMap = BiMap<TabName, int>();
}

enum TabName { feed, history, workout, exercises, settings }
