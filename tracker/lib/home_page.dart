import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:quiver/collection.dart';
import 'package:tracker/pages/workout/workout_cubit.dart';

import 'pages/exercises_page.dart';
import 'pages/feed_page.dart';
import 'pages/history_page.dart';
import 'pages/workout/editor_page.dart';
import 'pages/workout/workout_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    5,
    (index) => GlobalKey<NavigatorState>(),
  );
  final Set<int> _visited = {0};

  void _selectTab(int index) {
    if (index != _currentIndex) {
      _setCurrentIndex(index);
    } else {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    }
  }

  void _setCurrentIndex(int index) {
    if (index < 0 || index >= _navigatorKeys.length) return;
    setState(() {
      _currentIndex = index;
      _visited.add(index);
    });
  }

  Widget _buildOffstageNavigator(int index, Widget child) {
    final isActive = _currentIndex == index;
    return Offstage(
      offstage: !isActive,
      child: TabVisibilityScope(
        index: index,
        isActive: isActive,
        child: Navigator(
          key: _navigatorKeys[index],
          onGenerateRoute: (settings) =>
              MaterialPageRoute(builder: (context) => child),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    HomePageSingleton().indexSetState = indexSetState;
  }

  @override
  void dispose() {
    if (HomePageSingleton().indexSetState == indexSetState) {
      HomePageSingleton().indexSetState = null;
    }
    super.dispose();
  }

  void indexSetState(int index) {
    if (!mounted || index < 0 || index >= _navigatorKeys.length) return;
    _setCurrentIndex(index);
  }

  Widget _pageFor(int index) => switch (index) {
    0 => const FeedPage(),
    1 => const HistoryPage(),
    2 => const WorkoutPage(),
    3 => const EditorPage(),
    4 => const ExercisesPage(),
    _ => const SizedBox.shrink(),
  };

  @override
  Widget build(BuildContext context) {
    final visited = _visited.toList()..sort();
    return Scaffold(
      body: Stack(
        children: [
          for (final index in visited)
            _buildOffstageNavigator(index, _pageFor(index)),
        ],
      ),
      bottomNavigationBar: FBottomNavigationBar(
        index: _currentIndex,
        onChange: _selectTab,
        children: <Widget>[
          const FBottomNavigationBarItem(
            key: ValueKey('feed-tab'),
            icon: Icon(FLucideIcons.house),
            label: Text('Feed'),
            semanticsLabel: 'Feed',
          ),
          const FBottomNavigationBarItem(
            key: ValueKey('history-tab'),
            icon: Icon(FLucideIcons.history),
            label: Text('History'),
            semanticsLabel: 'History',
          ),
          BlocBuilder<WorkoutCubit, WorkoutState>(
            builder: (context, state) => FBottomNavigationBarItem(
              key: const ValueKey('workout-tab'),
              icon: Transform.translate(
                offset: const Offset(0, -6),
                child: const Icon(FLucideIcons.dumbbell),
              ),
              label: const Text('Workout'),
              semanticsLabel: state.isInProgress
                  ? 'Workout in progress'
                  : 'Workout',
            ),
          ),
          const FBottomNavigationBarItem(
            key: ValueKey('editor-tab'),
            icon: Icon(FLucideIcons.notebookText),
            label: Text('Editor'),
            semanticsLabel: 'Editor',
          ),
          const FBottomNavigationBarItem(
            key: ValueKey('exercises-tab'),
            icon: Icon(FLucideIcons.personStanding),
            label: Text('Exercises'),
            semanticsLabel: 'Exercises',
          ),
        ],
      ),
    );
  }
}

/// Visibility contract for pages hosted by the persistent tab navigators.
/// Inactive pages stay mounted to preserve their nested route stack, but should
/// pause live subscriptions and resume them when [isActive] becomes true.
class TabVisibilityScope extends InheritedWidget {
  const TabVisibilityScope({
    required this.index,
    required this.isActive,
    required super.child,
    super.key,
  });

  final int index;
  final bool isActive;

  static bool isActiveOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<TabVisibilityScope>()
          ?.isActive ??
      true;

  @override
  bool updateShouldNotify(TabVisibilityScope oldWidget) =>
      isActive != oldWidget.isActive || index != oldWidget.index;
}

class HomePageSingleton {
  factory HomePageSingleton() => _singleton;

  HomePageSingleton._internal() {
    tabMap.addAll({
      TabName.feed: 0,
      TabName.history: 1,
      TabName.currentWorkout: 2,
      TabName.editor: 3,
      TabName.exercises: 4,
    });
  }

  static final HomePageSingleton _singleton = HomePageSingleton._internal();

  Function? indexSetState;

  void changeTab(TabName tabName) {
    final index = tabMap[tabName];
    if (index != null) indexSetState?.call(index);
  }

  BiMap<TabName, int> tabMap = BiMap<TabName, int>();
}

enum TabName { feed, history, currentWorkout, editor, exercises }
