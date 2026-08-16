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
                _buildSettingsCard(
                  context,
                  icon: Icons.person,
                  title: 'Profile Settings',
                  subtitle:
                      state.displayName.isEmpty ? 'Add your name and email' : '${state.displayName} · ${state.email}',
                  onTap: () => _editProfile(context, state),
                ),
                _buildSettingsCard(
                  context,
                  icon: Icons.scale,
                  title: 'Units',
                  subtitle: 'Display weights in ${state.unit.symbol}',
                  onTap: () => _chooseUnit(context, state.unit),
                ),
                _buildSettingsCard(
                  context,
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: state.notificationsEnabled ? 'Enabled' : 'Disabled',
                  onTap: () => _toggleNotifications(context, state),
                ),
                _buildSettingsCard(
                  context,
                  icon: Icons.security,
                  title: 'Privacy & Security',
                  subtitle: state.analyticsEnabled ? 'Analytics sharing enabled' : 'Analytics sharing disabled',
                  onTap: () => _toggleAnalytics(context, state),
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

  Future<void> _editProfile(BuildContext context, SettingsState state) async {
    final name = TextEditingController(text: state.displayName);
    final email = TextEditingController(text: state.email);
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, (name.text, email.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    name.dispose();
    email.dispose();
    if (result != null && context.mounted) {
      context.read<SettingsCubit>().saveProfile(displayName: result.$1, email: result.$2);
    }
  }

  Future<void> _chooseUnit(BuildContext context, WeightUnit current) async {
    final selected = await showDialog<WeightUnit>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Weight units'),
        children: [
          for (final unit in WeightUnit.values)
            ListTile(
              title: Text(unit.label),
              leading: Icon(
                unit == current ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              ),
              onTap: () => Navigator.pop(context, unit),
            ),
        ],
      ),
    );
    if (selected != null && context.mounted) {
      context.read<SettingsCubit>().setUnit(selected);
    }
  }

  Future<void> _toggleNotifications(
    BuildContext context,
    SettingsState state,
  ) async {
    final value = await _confirmToggle(
      context,
      title: 'Notifications',
      message: 'Allow workout reminders and progress notifications?',
      value: state.notificationsEnabled,
    );
    if (value != null && context.mounted) {
      context.read<SettingsCubit>().setNotificationsEnabled(value);
    }
  }

  Future<void> _toggleAnalytics(
    BuildContext context,
    SettingsState state,
  ) async {
    final value = await _confirmToggle(
      context,
      title: 'Privacy & Security',
      message: 'Allow anonymous analytics to improve the app?',
      value: state.analyticsEnabled,
    );
    if (value != null && context.mounted) {
      context.read<SettingsCubit>().setAnalyticsEnabled(value);
    }
  }

  Future<bool?> _confirmToggle(
    BuildContext context, {
    required String title,
    required String message,
    required bool value,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            Switch(
              value: value,
              onChanged: (v) => Navigator.pop(context, v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
