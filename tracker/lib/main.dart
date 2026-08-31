import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:forui/forui.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tracker/data/services/db.dart';
import 'package:tracker/data/repositories/tracker_repository.dart';
import 'package:tracker/ui/core/ui/repository_scope.dart';
import 'package:tracker/data/services/seed.dart';
import 'package:tracker/routing/home_page.dart';
import 'package:tracker/pages/settings/settings_cubit.dart';
import 'package:tracker/pages/workout/workout_cubit.dart';
import 'package:window_size/window_size.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(
      (await getApplicationDocumentsDirectory()).path,
    ),
  );

  // Open the single Isar instance and make the shell available immediately.
  // First-run seeding runs after the first frame, so a slow write cannot delay
  // the initial UI or prevent startup when seeding fails.
  final isar = await DbInstance.getIsar();
  final repository = TrackerRepository(isar);

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle("Tracker");
    setWindowMinSize(Size(320, 568));
  }

  runApp(
    RepositoryProvider<TrackerRepository>.value(
      value: repository,
      child: RepositoryScope(
        repository: repository,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<WorkoutCubit>(
              create: (_) => WorkoutCubit(repository: repository),
              lazy: false,
            ),
            BlocProvider<SettingsCubit>(
              create: (_) => SettingsCubit(),
              lazy: false,
            ),
          ],
          child: const MyApp(),
        ),
      ),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_seedExercises(repository));
  });
}

Future<void> _seedExercises(
  TrackerRepository repository, {
  int attempt = 0,
}) async {
  try {
    await seedExercisesIfNeeded(repository);
  } catch (error, stackTrace) {
    // Keep startup alive and make the failure observable. If the collection is
    // still empty, retry once after transient startup/IO failures.
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'tracker startup',
        context: ErrorDescription(
          'seeding the exercise library (attempt ${attempt + 1})',
        ),
      ),
    );
    if (attempt == 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
      await _seedExercises(repository, attempt: 1);
    }
  }
}

/// Approximate SDK [ThemeData] from a Forui [FThemeData].
///
/// Forui 0.26's `FThemeData.toApproximateMaterialTheme()` returns
/// `material_ui`'s `ThemeData`, which is a distinct type from Flutter SDK's
/// `ThemeData` and cannot be passed to the SDK `MaterialApp` used here
/// (switching the app root to `material_ui`'s `MaterialApp` is out of scope).
/// This bridge maps the Forui palette onto the SDK `ColorScheme` so the
/// remaining Material widgets (SliverAppBar, ExpansionTile,
/// CircularProgressIndicator, …) inherit the Forui palette.
extension _FThemeMaterialBridge on FThemeData {
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
FThemeData _strengthenNavLabels(FThemeData data) {
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    /// Try changing this and hot reloading the application.
    ///
    /// To create a custom theme:
    /// ```shell
    /// dart forui theme create
    /// ```
    final (lightTheme, darkTheme) =
        const <TargetPlatform>{
          .android,
          .iOS,
          .fuchsia,
        }.contains(defaultTargetPlatform)
        ? (FTheme.neutral.light.touch, FTheme.neutral.dark.touch)
        : (FTheme.neutral.light.desktop, FTheme.neutral.dark.desktop);
    final (navLightTheme, navDarkTheme) = (
      _strengthenNavLabels(lightTheme),
      _strengthenNavLabels(darkTheme),
    );

    return MaterialApp(
      supportedLocales: FLocalizations.supportedLocales,
      localizationsDelegates: const [
        ...FLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const FScaffold(child: HomePage()),
      // ForUI 0.26 targets `material_ui` ThemeData, while MaterialApp uses
      // Flutter's ThemeData. Bridge the Forui-selected FThemeData into the
      // Material theme so remaining Material widgets (SliverAppBar,
      // ExpansionTile, CircularProgressIndicator, …) inherit the Forui
      // palette; FTheme below keeps Forui widgets themed.
      theme: navLightTheme.toSdkMaterialTheme(),
      darkTheme: navDarkTheme.toSdkMaterialTheme(),
      builder: (context, child) => FTheme(
        data: Theme.brightnessOf(context) == Brightness.light
            ? navLightTheme
            : navDarkTheme,
        child: FToaster(child: FTooltipGroup(child: child!)),
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
    );
  }
}
