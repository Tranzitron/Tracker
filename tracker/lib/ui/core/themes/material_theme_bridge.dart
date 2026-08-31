import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Approximate SDK [ThemeData] from a Forui [FThemeData].
///
/// Forui 0.26's `FThemeData.toApproximateMaterialTheme()` returns
/// `material_ui`'s `ThemeData`, which is a distinct type from Flutter SDK's
/// `ThemeData` and cannot be passed to the SDK `MaterialApp` used here
/// (switching the app root to `material_ui`'s `MaterialApp` is out of scope).
/// This bridge maps the Forui palette onto the SDK `ColorScheme` so the
/// remaining Material widgets (SliverAppBar, ExpansionTile,
/// CircularProgressIndicator, …) inherit the Forui palette.
extension FThemeMaterialBridge on FThemeData {
  ThemeData toSdkMaterialTheme() {
    final c = colors;
    return ThemeData(
      brightness: c.brightness,
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: c.brightness,
        primary: c.primary,
        onPrimary: c.primaryForeground,
        secondary: c.secondary,
        onSecondary: c.secondaryForeground,
        error: c.error,
        onError: c.errorForeground,
        surface: c.card,
        onSurface: c.foreground,
        onSurfaceVariant: c.mutedForeground,
        surfaceContainerHighest: c.muted,
        outline: c.border,
        outlineVariant: c.border,
      ),
      scaffoldBackgroundColor: c.background,
      dividerColor: c.border,
    );
  }
}

/// Strengthens the bottom nav's inactive icon + label color: the inherited
/// `mutedForeground` is too faint on the bar. One neutral step stronger per
/// brightness (light #737373 → #525252, dark #A1A1A1 → #D4D4D4); the selected
/// item keeps its primary color, so only the base is overridden.
FThemeData strengthenNavLabels(FThemeData data) {
  final inactive = data.colors.brightness == Brightness.light
      ? const Color(0xFF525252)
      : const Color(0xFFD4D4D4);
  final itemStyle = data.bottomNavigationBarStyle.itemStyle;
  return data.copyWith(
    bottomNavigationBarStyle: data.bottomNavigationBarStyle.copyWith(
      itemStyle: itemStyle.copyWith(
        iconStyle: itemStyle.iconStyle.apply([
          FVariantOperation.base(IconThemeDataDelta.delta(color: inactive)),
        ]),
        textStyle: itemStyle.textStyle.apply([
          FVariantOperation.base(TextStyleDelta.delta(color: inactive)),
        ]),
      ),
    ),
  );
}
