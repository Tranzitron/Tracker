import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tracker/models/gym.dart';

/// Resolves which [Gym] a workout should be logged at (Plan.md §2.2).
///
/// - No gyms configured → returns `null` (workout proceeds gym-less).
/// - Exactly one gym → returned directly (no prompt).
/// - Several gyms → the user is asked to pick one via a modal bottom sheet;
///   dismissing leaves the selection `null`.
Future<Gym?> promptGym(BuildContext context, List<Gym> gyms) async {
  if (gyms.length <= 1) {
    return gyms.isEmpty ? null : gyms.first;
  }
  return _showGymPicker(context, gyms);
}

Future<Gym?> _showGymPicker(BuildContext context, List<Gym> gyms) {
  return showFSheet<Gym>(
    context: context,
    side: FLayout.btt,
    useSafeArea: true,
    mainAxisMaxRatio: null,
    builder: (sheetContext) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Where are you training?',
              style: sheetContext.theme.typography.body.md.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final gym in gyms)
            FItem(
              prefix: Icon(
                gym.isPrimary ? FLucideIcons.house : FLucideIcons.dumbbell,
              ),
              title: Text(gym.name),
              subtitle: gym.isPrimary ? const Text('Primary gym') : null,
              onPress: () => Navigator.of(sheetContext).pop(gym),
            ),
          const SizedBox(height: 8),
        ],
      );
    },
  );
}
