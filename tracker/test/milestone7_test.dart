import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:tracker/pages/feed_page.dart';
import 'package:tracker/pages/settings/settings_cubit.dart';
import 'package:tracker/pages/settings_page.dart';
import 'package:tracker/pages/workout/workout_cubit.dart';

import 'in_memory_storage.dart';

void main() {
  setUp(() {
    HydratedBloc.storage = InMemoryStorage();
  });

  group('Milestone 7 settings', () {
    test('converts pounds and kilograms at the UI boundary', () {
      expect(WeightUnit.kilograms.fromKilograms(100), 100);
      expect(WeightUnit.pounds.fromKilograms(100), closeTo(220.462, 0.001));
      expect(WeightUnit.pounds.toKilograms(220.46226218), closeTo(100, 0.001));
    });

    test('settings state round-trips persisted preferences', () {
      const state = SettingsState(
        unit: WeightUnit.pounds,
        displayName: 'Alex',
        email: 'alex@example.com',
        notificationsEnabled: false,
        analyticsEnabled: false,
      );
      final restored = SettingsState.fromJson(state.toJson());
      expect(restored.unit, WeightUnit.pounds);
      expect(restored.displayName, 'Alex');
      expect(restored.email, 'alex@example.com');
      expect(restored.notificationsEnabled, isFalse);
      expect(restored.analyticsEnabled, isFalse);
    });
  });

  testWidgets('feed shows an intentional empty activity state', (tester) async {
    // FeedPage gates its quick action on the workout state, so it needs a
    // WorkoutCubit (idle here — no session → the button renders).
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => WorkoutCubit(),
        child: const MaterialApp(home: FeedPage()),
      ),
    );
    await tester.pump();
    expect(find.text('No workouts logged yet.'), findsOneWidget);
    expect(find.text('Progression'), findsOneWidget);
    expect(find.text('Go to Current Workout'), findsOneWidget);
  });

  testWidgets('settings replaces placeholder cards with controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => SettingsCubit(),
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pump();
    expect(find.text('Profile Settings'), findsOneWidget);
    expect(find.text('Units'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Privacy & Security'), findsOneWidget);
  });
}
