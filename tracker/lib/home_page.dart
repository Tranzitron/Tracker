import 'package:flutter/material.dart';
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
  @override
  void initState() {
    super.initState();
    HomePageSingleton().indexSetState = indexSetState;
  }

  void indexSetState() {
    setState(() {
      HomePageSingleton().selectedTabIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: goToTab(HomePageSingleton().selectedTabIndex),
      bottomNavigationBar: NavigationBar(
        animationDuration: Duration(seconds: 0),
        indicatorColor: Colors.transparent,
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        //overlayColor: WidgetStatePropertyAll(Colors.transparent),
        selectedIndex: HomePageSingleton().selectedTabIndex,
        onDestinationSelected: (index) => setState(() {
          HomePageSingleton().selectedTabIndex = index;
        }),
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.house_sharp),
            selectedIcon: Icon(
              Icons.house_sharp,
              color: Colors.blueAccent,
            ),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time_filled_sharp),
            selectedIcon: Icon(
              Icons.access_time_filled_sharp,
              color: Colors.blueAccent,
            ),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_sharp),
            selectedIcon: Icon(
              Icons.add_box_sharp,
              color: Colors.blueAccent,
            ),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_sharp),
            selectedIcon: Icon(
              Icons.fitness_center_sharp,
              color: Colors.blueAccent,
            ),
            label: 'Exercices',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_sharp),
            label: 'Settings',
            selectedIcon: Icon(
              Icons.settings_sharp,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget goToTab(int index) {
    return switch (index) {
      0 => FeedPage(),
      1 => HistoryPage(),
      2 => WorkoutPage(),
      3 => ExercicesPage(),
      4 => SettingsPage(),
      int() => throw UnimplementedError(),
    };
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

  Function? indexSetState;

  int selectedTabIndex = 0;

  void changeTab(TabName tabName) {
    int? index = tabMap[tabName];
    assert(index != null);
    selectedTabIndex = index!;
    indexSetState!();
  }

  BiMap<TabName, int> tabMap = BiMap<TabName, int>();
}

enum TabName { feed, history, workout, exercises, settings }
