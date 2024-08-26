import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tracker/home_page.dart';

const iOSClientId =
    '165619535126-jagolbg46rjh32j9r979h9ndkrm3p1ah.apps.googleusercontent.com';
const webClientId =
    '165619535126-v10qhtub8ucbcbgtbn4l85vg8s0carvl.apps.googleusercontent.com';

String get googleClientId {
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => iOSClientId,
    _ => webClientId,
  };
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
