import 'package:flutter/widgets.dart';

import 'repositories.dart';

/// Lightweight dependency injection for the [TrackerRepository].
///
/// Built once in [main] and exposed down the tree so pages/cubits can read
/// repositories without a DI package. Read via `RepositoryScope.of(context)`.
class RepositoryScope extends InheritedWidget {
  const RepositoryScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final TrackerRepository repository;

  static TrackerRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RepositoryScope>();
    assert(scope != null, 'RepositoryScope not found above this context');
    return scope!.repository;
  }

  /// Like [of], but nullable so widgets can degrade gracefully when no scope is
  /// present (e.g. the isolate widget tests that pump [MyApp] without a repo).
  static TrackerRepository? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<RepositoryScope>()
        ?.repository;
  }

  @override
  bool updateShouldNotify(RepositoryScope oldWidget) =>
      repository != oldWidget.repository;
}
