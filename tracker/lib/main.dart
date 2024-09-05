import 'package:flutter/cupertino.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tracker/home_page.dart';
import 'package:tracker/user.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class DbInstance {
  static Future<Isar> getIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open(
      [UserSchema],
      directory: dir.path,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Flutter Demo',
      home: HomePage(),
      theme: CupertinoThemeData(
        brightness: Brightness.light,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
