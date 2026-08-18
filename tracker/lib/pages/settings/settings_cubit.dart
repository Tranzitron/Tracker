import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

/// User-facing application preferences persisted independently of workout data.
class SettingsState {
  const SettingsState({
    this.unit = WeightUnit.kilograms,
    this.displayName = '',
    this.email = '',
    this.notificationsEnabled = true,
    this.analyticsEnabled = true,
  });

  final WeightUnit unit;
  final String displayName;
  final String email;
  final bool notificationsEnabled;
  final bool analyticsEnabled;

  SettingsState copyWith({
    WeightUnit? unit,
    String? displayName,
    String? email,
    bool? notificationsEnabled,
    bool? analyticsEnabled,
  }) {
    return SettingsState(
      unit: unit ?? this.unit,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'unit': unit.name,
    'displayName': displayName,
    'email': email,
    'notificationsEnabled': notificationsEnabled,
    'analyticsEnabled': analyticsEnabled,
  };

  factory SettingsState.fromJson(Map<String, dynamic> json) => SettingsState(
    unit: WeightUnit.values.asNameMap()[json['unit']] ?? WeightUnit.kilograms,
    displayName: json['displayName'] as String? ?? '',
    email: json['email'] as String? ?? '',
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    analyticsEnabled: json['analyticsEnabled'] as bool? ?? true,
  );
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

  void saveProfile({required String displayName, required String email}) {
    emit(state.copyWith(displayName: displayName.trim(), email: email.trim()));
  }

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
