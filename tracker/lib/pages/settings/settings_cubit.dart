import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Metric rendered by a user-defined feed graph.
enum GraphMetric { best1rm, peakWeight, volume }

/// Date range used by a user-defined feed graph.
enum GraphTimeframe { all, last30Days, last90Days, lastYear }

/// Persisted configuration for one user-defined feed graph.
class GraphConfig {
  const GraphConfig({
    required this.title,
    this.exerciseId,
    this.metric = GraphMetric.best1rm,
    this.timeframe = GraphTimeframe.all,
  });

  final String title;
  final int? exerciseId;
  final GraphMetric metric;
  final GraphTimeframe timeframe;

  GraphConfig copyWith({
    String? title,
    Object? exerciseId = _unset,
    GraphMetric? metric,
    GraphTimeframe? timeframe,
  }) => GraphConfig(
    title: title ?? this.title,
    exerciseId: identical(exerciseId, _unset)
        ? this.exerciseId
        : exerciseId as int?,
    metric: metric ?? this.metric,
    timeframe: timeframe ?? this.timeframe,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'exerciseId': exerciseId,
    'metric': metric.name,
    'timeframe': timeframe.name,
  };

  @override
  bool operator ==(Object other) =>
      other is GraphConfig &&
      title == other.title &&
      exerciseId == other.exerciseId &&
      metric == other.metric &&
      timeframe == other.timeframe;

  @override
  int get hashCode => Object.hash(title, exerciseId, metric, timeframe);

  static const _unset = Object();

  // ignore: sort_constructors_first
  factory GraphConfig.fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    if (title is! String || title.trim().isEmpty) {
      throw const FormatException('Graph title is required');
    }
    final exerciseId = json['exerciseId'];
    return GraphConfig(
      title: title,
      exerciseId: exerciseId is num ? exerciseId.toInt() : null,
      metric:
          GraphMetric.values.asNameMap()[json['metric']] ?? GraphMetric.best1rm,
      timeframe:
          GraphTimeframe.values.asNameMap()[json['timeframe']] ??
          GraphTimeframe.all,
    );
  }
}

/// User-facing application preferences persisted independently of workout data.
enum FreeStartPlacement { before, after, disabled }

class SettingsState {
  factory SettingsState.fromJson(Map<String, dynamic> json) {
    final rawGraphs = json['graphs'];
    return SettingsState(
      unit: WeightUnit.values.asNameMap()[json['unit']] ?? WeightUnit.kilograms,
      notificationsEnabled: json['notificationsEnabled'] is bool
          ? json['notificationsEnabled'] as bool
          : true,
      analyticsEnabled: json['analyticsEnabled'] is bool
          ? json['analyticsEnabled'] as bool
          : true,
      freeStartPlacement:
          FreeStartPlacement.values.asNameMap()[json['freeStartPlacement']] ??
          FreeStartPlacement.before,
      graphs: rawGraphs is List
          ? rawGraphs
                .whereType<Map>()
                .map((entry) {
                  try {
                    return GraphConfig.fromJson(
                      Map<String, dynamic>.from(entry),
                    );
                  } catch (_) {
                    return null;
                  }
                })
                .whereType<GraphConfig>()
                .toList()
          : const [],
    );
  }

  SettingsState({
    this.unit = WeightUnit.kilograms,
    this.notificationsEnabled = true,
    this.analyticsEnabled = true,
    this.freeStartPlacement = FreeStartPlacement.before,
    List<GraphConfig> graphs = const [],
  }) : graphs = List.unmodifiable(graphs);

  final WeightUnit unit;
  final bool notificationsEnabled;
  final bool analyticsEnabled;
  final FreeStartPlacement freeStartPlacement;
  final List<GraphConfig> graphs;

  SettingsState copyWith({
    WeightUnit? unit,
    bool? notificationsEnabled,
    bool? analyticsEnabled,
    FreeStartPlacement? freeStartPlacement,
    List<GraphConfig>? graphs,
  }) {
    return SettingsState(
      unit: unit ?? this.unit,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      freeStartPlacement: freeStartPlacement ?? this.freeStartPlacement,
      graphs: graphs ?? this.graphs,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SettingsState &&
      unit == other.unit &&
      notificationsEnabled == other.notificationsEnabled &&
      analyticsEnabled == other.analyticsEnabled &&
      freeStartPlacement == other.freeStartPlacement &&
      _listEquals(graphs, other.graphs);

  @override
  int get hashCode => Object.hash(
    unit,
    notificationsEnabled,
    analyticsEnabled,
    freeStartPlacement,
    Object.hashAll(graphs),
  );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'unit': unit.name,
    'notificationsEnabled': notificationsEnabled,
    'analyticsEnabled': analyticsEnabled,
    'freeStartPlacement': freeStartPlacement.name,
    'graphs': graphs.map((graph) => graph.toJson()).toList(),
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
  SettingsCubit() : super(SettingsState());

  void setUnit(WeightUnit unit) => emit(state.copyWith(unit: unit));

  void setNotificationsEnabled(bool value) =>
      emit(state.copyWith(notificationsEnabled: value));

  void setAnalyticsEnabled(bool value) =>
      emit(state.copyWith(analyticsEnabled: value));

  void setFreeStartPlacement(FreeStartPlacement placement) =>
      emit(state.copyWith(freeStartPlacement: placement));

  void addGraph(GraphConfig graph) =>
      emit(state.copyWith(graphs: [...state.graphs, graph]));

  void updateGraph(int index, GraphConfig graph) {
    if (index < 0 || index >= state.graphs.length) return;
    final graphs = [...state.graphs]..[index] = graph;
    emit(state.copyWith(graphs: graphs));
  }

  void removeGraph(int index) {
    if (index < 0 || index >= state.graphs.length) return;
    final graphs = [...state.graphs]..removeAt(index);
    emit(state.copyWith(graphs: graphs));
  }

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
