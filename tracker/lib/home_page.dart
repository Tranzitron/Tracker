import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quiver/collection.dart';
import 'package:tracker/pages/workout/workout_cubit.dart';

import 'pages/exercises_page.dart';
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
  int _currentIndex = 0;
  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List.generate(5, (index) => GlobalKey<NavigatorState>());

  void _selectTab(int index) {
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
    } else {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    }
  }

  Widget _buildOffstageNavigator(int index, Widget child) {
    return Offstage(
      offstage: _currentIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (settings) =>
            MaterialPageRoute(builder: (context) => child),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    HomePageSingleton().indexSetState = indexSetState;
  }

  void indexSetState(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildOffstageNavigator(0, const FeedPage()),
          _buildOffstageNavigator(1, const HistoryPage()),
          _buildOffstageNavigator(2, const WorkoutPage()),
          _buildOffstageNavigator(3, const ExercisesPage()),
          _buildOffstageNavigator(4, const SettingsPage()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        animationDuration: Duration.zero,
        indicatorColor: Colors.transparent,
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        selectedIndex: _currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: _selectTab,
        destinations: <Widget>[
          NavigationDestination(
            icon: Icon(Icons.house_sharp),
            selectedIcon: Icon(
              Icons.house_sharp,
              color: Colors.blueAccent,
            ),
            label: 'Feed',
            tooltip: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time_filled_sharp),
            selectedIcon: Icon(
              Icons.access_time_filled_sharp,
              color: Colors.blueAccent,
            ),
            label: 'History',
            tooltip: '',
          ),
          BlocBuilder<WorkoutCubit, WorkoutState>(
            builder: (context, state) => NavigationDestination(
              icon: Icon(Icons.add_box_sharp),
              selectedIcon: Icon(
                Icons.add_box_sharp,
                color: Colors.blueAccent,
              ),
              label: 'Workout ${state.isInProgress}',
              tooltip: '',
            ),
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_sharp),
            selectedIcon: Icon(
              Icons.fitness_center_sharp,
              color: Colors.blueAccent,
            ),
            label: 'Exercises',
            tooltip: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_sharp),
            selectedIcon: Icon(
              Icons.settings_sharp,
              color: Colors.blueAccent,
            ),
            label: 'Settings',
            tooltip: '',
          ),
        ],
      ),
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

  Function? indexSetState;

  int selectedTabIndex = 0;

  void changeTab(TabName tabName) {
    int? index = tabMap[tabName];
    assert(index != null);
    indexSetState!(index);
  }

  BiMap<TabName, int> tabMap = BiMap<TabName, int>();
}

enum TabName { feed, history, workout, exercises, settings }
