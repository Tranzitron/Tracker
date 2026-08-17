// Smoke tests for the bottom-nav shell.
//
// MyApp's root build depends on WorkoutCubit, a HydratedCubit, so storage must
// be initialized before pumping (mirroring main()). We use an in-memory Storage
// rather than HydratedStorage's Hive/file storage: the real implementation does
// file I/O and keeps a static lock that cannot complete across the test's
// fake-async zone once a cubit has been pumped, so it can't survive repeated
// pumps in one file.
//
// Note: the shell uses Offstage-Stacked nested Navigators, so every tab's page
// is built (and can throw) even when not selected — the boot test therefore
// also proves every tab resolves to a buildable screen.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:tracker/main.dart';
import 'package:tracker/pages/workout/workout_cubit.dart';

import 'in_memory_storage.dart';

Future<WorkoutCubit> pumpApp(WidgetTester tester) async {
  final cubit = WorkoutCubit();
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<WorkoutCubit>(
          create: (_) => cubit,
          lazy: false,
        ),
      ],
      child: const MyApp(),
    ),
  );
  await tester.pumpAndSettle();
  return cubit;
}

void main() {
  setUp(() {
    HydratedBloc.storage = InMemoryStorage();
  });

  testWidgets(
      'boots into the five-tab shell, every screen builds, and tabs switch',
      (WidgetTester tester) async {
    await pumpApp(tester);

    // The app's root shell is a bottom NavigationBar with the five pluggable
    // tab destinations (Feed, History, Workout, Editor, Exercises).
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));

    // The workout destination keeps its TabName.currentWorkout handling but
    // displays the shorter label so it fits narrow destinations.
    final labels = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(NavigationDestination),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data)
        .toList();
    expect(labels, contains('Workout'));
    expect(labels, isNot(contains('CurrentWorkout')));

    // The initially selected tab (Feed) rendered without crashing. Note: the
    // other four tabs also build (Offstage), so this also proves every tab
    // resolves to a buildable screen.
    expect(find.text('Go to Current Workout'), findsOneWidget);

    // Drive tab switches through onDestinationSelected (the same callback the
    // NavigationBar wires to _selectTab) rather than hit-testing, which is
    // brittle under the Offstage navigators.
    for (final index in {2, 3, 4, 1, 0}) {
      tester
          .widget<NavigationBar>(find.byType(NavigationBar))
          .onDestinationSelected!(index);
      await tester.pump();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        index,
        reason: 'selecting index $index did not update the nav bar',
      );
    }
  });

  testWidgets(
      'feed quick action shows idle and hides while a workout is in progress',
      (WidgetTester tester) async {
    final cubit = await pumpApp(tester);

    // Idle workout → the Feed entry point is present.
    expect(find.text('Go to Current Workout'), findsOneWidget);

    // Starting a session gates the button off; the tab itself is the entry.
    cubit.startWorkout();
    await tester.pumpAndSettle();
    expect(find.text('Go to Current Workout'), findsNothing);

    // Ending the session restores the quick action.
    await cubit.endWorkout();
    await tester.pumpAndSettle();
    expect(find.text('Go to Current Workout'), findsOneWidget);
  });
}
