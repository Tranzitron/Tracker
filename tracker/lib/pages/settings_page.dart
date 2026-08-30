import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import 'custom/custom_app_bar.dart';
import 'custom/custom_route.dart';
import 'custom/max_width.dart';
import 'settings/gyms_page.dart';
import 'settings/settings_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(context, title: 'Settings'),
        SliverFillRemaining(
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) => MaxWidth(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: <Widget>[
                  _buildSettingsMenuItem(
                    context,
                    icon: FLucideIcons.dumbbell,
                    title: 'Gyms',
                    subtitle: 'Manage gyms and weight multipliers',
                    onTap: () => pushTo(context, const GymsPage()),
                  ),
                  _buildSettingsDropdownRow(
                    context,
                    icon: FLucideIcons.scale,
                    title: 'Units',
                    subtitle: 'Set your preferred weight unit',
                    value: state.unit,
                    onChanged: (unit) {
                      context.read<SettingsCubit>().setUnit(unit);
                    },
                  ),
                  _buildSwitchRow(
                    context,
                    icon: FLucideIcons.bell,
                    title: 'Notifications',
                    subtitle:
                        'Allow workout reminders and progress notifications',
                    value: state.notificationsEnabled,
                    onChanged: context
                        .read<SettingsCubit>()
                        .setNotificationsEnabled,
                  ),
                  _buildSwitchRow(
                    context,
                    icon: FLucideIcons.shield,
                    title: 'Privacy & Security',
                    subtitle: 'Allow anonymous analytics to improve the app',
                    value: state.analyticsEnabled,
                    onChanged: context
                        .read<SettingsCubit>()
                        .setAnalyticsEnabled,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsDropdownRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required WeightUnit value,
    required ValueChanged<WeightUnit> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: FCard(
        child: FItem.raw(
          child: Row(
            children: [
              Icon(icon, color: context.theme.colors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.theme.typography.body.md),
                    Text(
                      subtitle,
                      style: context.theme.typography.body.xs.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 120,
                child: FSelect<WeightUnit>(
                  items: {
                    for (final unit in WeightUnit.values) unit.symbol: unit,
                  },
                  control: FSelectControl<WeightUnit>.lifted(
                    value: value,
                    onChange: (unit) {
                      if (unit != null) {
                        onChanged(unit);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: FCard(
        child: FItem(
          prefix: Icon(icon, color: context.theme.colors.primary),
          title: Text(title),
          subtitle: Text(subtitle),
          suffix: const Icon(FLucideIcons.chevronRight, size: 16),
          onPress: onTap,
        ),
      ),
    );
  }

  Widget _buildSwitchRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: FCard(
        child: FItem(
          prefix: Icon(icon, color: context.theme.colors.primary),
          title: Text(title),
          subtitle: Text(subtitle),
          suffix: FSwitch(value: value, onChange: onChanged),
          onPress: () => onChanged(!value),
        ),
      ),
    );
  }
}
