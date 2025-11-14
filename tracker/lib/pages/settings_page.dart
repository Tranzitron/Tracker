import 'package:flutter/material.dart';

import 'custom/custom_app_bar.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
  });

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(
          context,
          title: 'Settings',
        ),
        SliverFillRemaining(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _buildSettingsCard(
                icon: Icons.person,
                title: 'Profile Settings',
                subtitle: 'Manage your account information',
                onTap: () => _showSnackbar(context, 'Profile tapped'),
              ),

              // Notifications Section
              _buildSettingsCard(
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Control your notification preferences',
                onTap: () => _showSnackbar(context, 'Notifications tapped'),
              ),

              // Privacy Section
              _buildSettingsCard(
                icon: Icons.security,
                title: 'Privacy & Security',
                subtitle: 'Manage your privacy settings',
                onTap: () => _showSnackbar(context, 'Privacy tapped'),
              )
            ],
          ),
        ),
      ],
    );
  }
}
