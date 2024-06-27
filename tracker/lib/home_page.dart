import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tracker/Logout.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late User user;

  @override
  void initState() {
    super.initState();

    user = FirebaseAuth.instance.currentUser!;
    setState(() {
      user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Home'),
        actions: const [
          Logout(),
        ],
      ),
      backgroundColor: Colors.red,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('uid: ${user.uid}'),
            Text('displayName: ${user.displayName}'),
            Text('email: ${user.email}'),
            Text('phoneNumber: ${user.phoneNumber}'),
          ],
        ),
      ),
    );
  }
}
