import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tracker/domain/models/gym.dart';

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
  // A real bottom-sheet container: showFSheet paints no surface of its own,
  // so the sheet needs an opaque themed background (forui 0.26 Sheet wraps
  // the builder's child directly) plus a SafeArea to sit flush on the nav.
  return showModalBottomSheet<Gym>(
    context: context,
    backgroundColor: context.theme.colors.background,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Column(
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
        ),
      );
    },
  );
}
