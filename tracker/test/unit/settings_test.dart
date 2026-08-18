// Unit tests for settings (lib/pages/settings/) — pure: weight unit conversion
// and SettingsState JSON round-trip. The SettingsCubit (HydratedCubit) and
// SettingsPage widget are integration tests: test/integration/settings_test.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/pages/settings/settings_cubit.dart';

void main() {
  group('Setting conversions & state', () {
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
}
