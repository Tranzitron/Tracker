// Smoke tests for the bottom-nav shell.
//
// MyApp's root build depends on WorkoutCubit, a HydratedCubit, so storage must
// be initialized before pumping (mirroring main()). We use a throwaway temp
// directory rather than path_provider, whose platform channel is unavailable in
// tests.
//
// Note: the shell uses Offstage-Stacked nested Navigators, so every tab's page
// is built (and can throw) even when not selected — the boot test therefore
// also proves every tab resolves to a buildable screen.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:tracker/main.dart';
import 'package:tracker/pages/workout/workout_cubit.dart';

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<WorkoutCubit>(
          create: (_) => WorkoutCubit(),
          lazy: false,
        ),
      ],
      child: const MyApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('tracker_test');
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory(dir.path),
    );
  });

  testWidgets(
      'boots into the five-tab shell, every screen builds, and tabs switch',
      (WidgetTester tester) async {
    await pumpApp(tester);

    // The app's root shell is a bottom NavigationBar with the five pluggable
    // tab destinations (Feed, History, CurrentWorkout, Editor, Exercises).
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));

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
}
