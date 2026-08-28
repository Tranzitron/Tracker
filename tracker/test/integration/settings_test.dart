// Settings integration tests (lib/pages/settings/): the SettingsCubit
// (a HydratedCubit) and the SettingsPage widget. Pure weight-format / state
// round-trip logic is unit-tested separately: test/unit/settings_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:tracker/pages/settings/settings_cubit.dart';
import 'package:tracker/pages/settings_page.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() {
    HydratedBloc.storage = InMemoryStorage();
  });

  test(
    'SettingsCubit persists preferences and ignores legacy profile keys',
    () {
      final cubit = SettingsCubit();
      addTearDown(cubit.close);

      cubit.setUnit(WeightUnit.pounds);
      cubit.setNotificationsEnabled(false);
      cubit.setAnalyticsEnabled(false);

      final restored = SettingsState.fromJson({
        ...cubit.state.toJson(),
        'displayName': 'Legacy User',
        'email': 'legacy@example.com',
      });
      expect(restored.unit, WeightUnit.pounds);
      expect(restored.notificationsEnabled, isFalse);
      expect(restored.analyticsEnabled, isFalse);
      expect(restored.toJson().containsKey('displayName'), isFalse);
      expect(restored.toJson().containsKey('email'), isFalse);
    },
  );

  testWidgets('settings page replaces placeholder cards with controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => SettingsCubit(),
        child: MaterialApp(
          home: FTheme(
            data: FTheme.neutral.light.touch,
            child: const SettingsPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Profile Settings'), findsNothing);
    expect(find.text('Units'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Privacy & Security'), findsOneWidget);
    expect(find.byType(FSwitch), findsNWidgets(2));
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.byType(FSwitch).first);
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.widget<FSwitch>(find.byType(FSwitch).first).value, isFalse);

    await tester.tap(find.text('kg'));
    await tester.pumpAndSettle();
    expect(find.text('lb'), findsOneWidget);
    await tester.tap(find.text('lb'));
    await tester.pumpAndSettle();
    expect(find.text('lb'), findsOneWidget);
  });
}
