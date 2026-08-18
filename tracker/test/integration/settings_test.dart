// Settings integration tests (lib/pages/settings/): the SettingsCubit
// (a HydratedCubit) and the SettingsPage widget. Pure weight-format / state
// round-trip logic is unit-tested separately: test/unit/settings_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:tracker/pages/settings/settings_cubit.dart';
import 'package:tracker/pages/settings_page.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() {
    HydratedBloc.storage = InMemoryStorage();
  });

  test('SettingsCubit persists selected unit and profile in JSON', () {
    final cubit = SettingsCubit();
    addTearDown(cubit.close);

    cubit.setUnit(WeightUnit.pounds);
    cubit.saveProfile(displayName: ' Test User ', email: 'user@example.com');

    final restored = SettingsState.fromJson(cubit.state.toJson());
    expect(restored.unit, WeightUnit.pounds);
    expect(restored.displayName, 'Test User');
    expect(restored.email, 'user@example.com');
  });

  testWidgets('settings page replaces placeholder cards with controls', (
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
