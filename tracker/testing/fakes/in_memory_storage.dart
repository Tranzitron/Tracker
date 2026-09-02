import 'package:hydrated_bloc/hydrated_bloc.dart';

/// [Storage] backed by an in-memory map, for widget/pages tests.
///
/// HydratedStorage (Hive/file) performs real I/O behind a static lock that
/// cannot complete or be rebuilt across the widget-test fake-async zone once a
/// HydratedCubit has been pumped - so repeated pumps in one file hang. An
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
