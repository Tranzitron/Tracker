/// User-facing application preferences value type persisted independently of
/// workout data.
enum FreeStartPlacement { before, after, disabled }

enum WeightUnit { kilograms, pounds }

extension WeightUnitLabel on WeightUnit {
  String get label =>
      this == WeightUnit.kilograms ? 'Kilograms (kg)' : 'Pounds (lb)';

  String get symbol => this == WeightUnit.kilograms ? 'kg' : 'lb';

  double fromKilograms(double value) =>
      this == WeightUnit.kilograms ? value : value * 2.2046226218;

  double toKilograms(double value) =>
      this == WeightUnit.kilograms ? value : value / 2.2046226218;
}
