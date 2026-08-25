import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

/// User-facing application preferences persisted independently of workout data.
class SettingsState {
  factory SettingsState.fromJson(Map<String, dynamic> json) => SettingsState(
    unit: WeightUnit.values.asNameMap()[json['unit']] ?? WeightUnit.kilograms,
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    analyticsEnabled: json['analyticsEnabled'] as bool? ?? true,
  );

  const SettingsState({
    this.unit = WeightUnit.kilograms,
    this.notificationsEnabled = true,
    this.analyticsEnabled = true,
  });

  final WeightUnit unit;
  final bool notificationsEnabled;
  final bool analyticsEnabled;

  SettingsState copyWith({
    WeightUnit? unit,
    bool? notificationsEnabled,
    bool? analyticsEnabled,
  }) {
    return SettingsState(
      unit: unit ?? this.unit,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'unit': unit.name,
    'notificationsEnabled': notificationsEnabled,
    'analyticsEnabled': analyticsEnabled,
  };
}

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

class SettingsCubit extends HydratedCubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  void setUnit(WeightUnit unit) => emit(state.copyWith(unit: unit));

  void setNotificationsEnabled(bool value) =>
      emit(state.copyWith(notificationsEnabled: value));

  void setAnalyticsEnabled(bool value) =>
      emit(state.copyWith(analyticsEnabled: value));

  @override
  SettingsState? fromJson(Map<String, dynamic> json) =>
      SettingsState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(SettingsState state) => state.toJson();

  static SettingsCubit? maybeOf(BuildContext context) {
    try {
      return context.read<SettingsCubit>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}
