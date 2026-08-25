// Shared test infrastructure for both unit/ and integration/ tests.
//
// unit/ tests are pure Dart and need none of this. integration/ tests that
// open a real Isar DB or pump the widget tree call initIsarCore() (setUpAll),
// openTestIsar() (setUp), and pumpApp() for the app shell.

import 'dart:ffi';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:tracker/main.dart';
import 'package:tracker/pages/settings/settings_cubit.dart';
import 'package:tracker/pages/workout/workout_cubit.dart';

/// Load Isar's native core once. Call from `setUpAll` in any integration test
/// that opens a real Isar instance.
Future<void> initIsarCore() async {
  await Isar.initializeIsarCore(
    libraries: {
      Abi.windowsX64: 'test/assets/isar_windows_x64.dll',
      Abi.linuxX64: 'test/assets/libisar_linux_x64.so',
      Abi.macosX64: 'test/assets/libisar_macos.dylib',
    },
  );
}

/// Open a throwaway Isar DB (no path_provider) in a temp directory.
Future<Isar> openTestIsar(
  List<CollectionSchema<dynamic>> schemas, {
  String name = 'isar_test',
}) async {
  final dir = Directory.systemTemp.createTempSync(name);
  return Isar.open(schemas, directory: dir.path);
}

/// Pump the app shell ([MyApp]) with a fresh [WorkoutCubit]; returns the cubit.
Future<WorkoutCubit> pumpApp(WidgetTester tester) async {
  final cubit = WorkoutCubit();
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<WorkoutCubit>(create: (_) => cubit, lazy: false),
        BlocProvider<SettingsCubit>(
          create: (_) => SettingsCubit(),
          lazy: false,
        ),
      ],
      child: const MyApp(),
    ),
  );
  await tester.pumpAndSettle();
  return cubit;
}

/// Poll `condition` until true (bounded), failing on timeout. For async
/// sources like Isar watchers / streams.
Future<void> waitFor(bool Function() condition) async {
  for (var i = 0; i < 100 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(condition(), isTrue, reason: 'Timed out waiting for condition');
}

/// [Storage] backed by an in-memory map, for widget/pages tests.
///
/// HydratedStorage (Hive/file) performs real I/O behind a static lock that
/// cannot complete or be rebuilt across the widget-test fake-async zone once a
/// HydratedCubit has been pumped — so repeated pumps in one file hang. An
/// in-memory implementation avoids that entirely and is functionally equivalent
/// for pages that don't need real persistence.
class InMemoryStorage implements Storage {
  final Map<String, dynamic> _data = <String, dynamic>{};

  @override
  dynamic read(String key) => _data[key];

  @override
  Future<void> write(String key, dynamic value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> clear() async => _data.clear();

  @override
  Future<void> close() async {}
}
