import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:tracker/auth_page.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Profile'),
      ),
      showMFATile: false,
      showDeleteConfirmationDialog: true,
      showUnlinkConfirmationDialog: true,
      actions: [
        SignedOutAction(
          (context) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const AuthPage(),
              ),
              (route) => false,
            );
          },
        ),
      ],
    );
  }
}
