// Smoke test: verify the app boots into the bottom-nav shell.
//
// MyApp's root build depends on WorkoutCubit, a HydratedCubit, so storage must
// be initialized before pumping (mirroring main()). We use a throwaway temp
// directory rather than path_provider, whose platform channel is unavailable in
// tests.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:tracker/main.dart';
import 'package:tracker/pages/workout/workout_cubit.dart';

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('tracker_test');
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory(dir.path),
    );
  });

  testWidgets('app boots into the bottom-nav shell with the five tabs',
      (WidgetTester tester) async {
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

    // The app's root shell is a bottom NavigationBar with the five pluggable
    // tab destinations (Feed, History, Workout, Editor, Exercises).
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));

    // The initially selected tab (Feed) rendered without crashing.
    expect(find.text('Go to Workout Page'), findsOneWidget);
  });
}
