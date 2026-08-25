import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'custom/custom_app_bar.dart';
import 'custom/custom_route.dart';
import 'settings/gyms_page.dart';
import 'settings/settings_cubit.dart';

/// Application preferences and user-facing settings.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(context, title: 'Settings'),
        SliverFillRemaining(
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) => ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: <Widget>[
                _buildSettingsCard(
                  context,
                  icon: Icons.fitness_center,
                  title: 'Gyms',
                  subtitle: 'Manage gyms and weight multipliers',
                  onTap: () => pushTo(context, const GymsPage()),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.scale,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        const Expanded(child: Text('Units')),
                        DropdownButton<WeightUnit>(
                          value: state.unit,
                          onChanged: (unit) {
                            if (unit != null) {
                              context.read<SettingsCubit>().setUnit(unit);
                            }
                          },
                          items: [
                            for (final unit in WeightUnit.values)
                              DropdownMenuItem(
                                value: unit,
                                child: Text(unit.symbol),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                _buildPlacementCard(context, state.freeStartPlacement),
                _buildSwitchCard(
                  context,
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle:
                      'Allow workout reminders and progress notifications',
                  value: state.notificationsEnabled,
                  onChanged: context
                      .read<SettingsCubit>()
                      .setNotificationsEnabled,
                ),
                _buildSwitchCard(
                  context,
                  icon: Icons.security,
                  title: 'Privacy & Security',
                  subtitle: 'Allow anonymous analytics to improve the app',
                  value: state.analyticsEnabled,
                  onChanged: context.read<SettingsCubit>().setAnalyticsEnabled,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildPlacementCard(
    BuildContext context,
    FreeStartPlacement placement,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: Icon(
          Icons.play_circle_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Start Workout button'),
        subtitle: DropdownButton<FreeStartPlacement>(
          value: placement,
          isExpanded: true,
          onChanged: (value) {
            if (value != null) {
              context.read<SettingsCubit>().setFreeStartPlacement(value);
            }
          },
          items: const [
            DropdownMenuItem(
              value: FreeStartPlacement.before,
              child: Text('Before splits'),
            ),
            DropdownMenuItem(
              value: FreeStartPlacement.after,
              child: Text('After splits'),
            ),
            DropdownMenuItem(
              value: FreeStartPlacement.disabled,
              child: Text('Disabled'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SwitchListTile(
        secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
