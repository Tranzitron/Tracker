import 'package:flutter/widgets.dart';
import 'package:tracker/analytics/analytics.dart';
import 'package:tracker/pages/settings/settings_cubit.dart';

export 'settings_cubit.dart';

WeightUnit weightUnitOf(BuildContext context) {
  return SettingsCubit.maybeOf(context)?.state.unit ?? WeightUnit.kilograms;
}

double displayWeightOf(BuildContext context, double kilograms) =>
    weightUnitOf(context).fromKilograms(kilograms);

double kilogramsFromDisplay(BuildContext context, double displayed) =>
    weightUnitOf(context).toKilograms(displayed);

String formatWeight(BuildContext context, double kilograms) {
  final value = displayWeightOf(context, kilograms);
  final formatted = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$formatted ${weightUnitOf(context).symbol}';
}

List<ProgressionPoint> displayProgressionPoints(
  BuildContext context,
  List<ProgressionPoint> points,
) {
  final unit = weightUnitOf(context);
  return [
    for (final point in points)
      ProgressionPoint(
          date: point.date, value: unit.fromKilograms(point.value)),
  ];
}
