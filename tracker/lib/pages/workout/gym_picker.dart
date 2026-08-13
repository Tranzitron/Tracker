import 'package:flutter/material.dart';
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
  return showModalBottomSheet<Gym>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Where are you training?',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            for (final gym in gyms)
              ListTile(
                leading: Icon(
                  gym.isPrimary ? Icons.home_sharp : Icons.fitness_center_sharp,
                ),
                title: Text(gym.name),
                subtitle: gym.isPrimary ? const Text('Primary gym') : null,
                onTap: () => Navigator.of(sheetContext).pop(gym),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
