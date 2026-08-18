import 'package:isar_community/isar.dart';

part 'gym.g.dart';

/// A gym location/profile the user trains at.
///
/// One gym is the "primary" home gym that acts as the baseline (multiplier 1.0)
/// when computing machine weight equivalence (see Plan.md §2.3). `multiplier`
/// is stored here so cross-machine equivalence can be derived/overridden later.
@collection
class Gym {
  Gym({
    required this.name,
    this.description,
    this.isPrimary = false,
    this.order = -1,
    this.multiplier = 1.0,
  });
  Id id = Isar.autoIncrement;
  String name;
  String? description;
  bool isPrimary;
  int order;

  /// Weight-equivalence multiplier vs. the primary gym (default 1.0).
  double multiplier;
}
