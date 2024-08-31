import 'package:flutter/cupertino.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Home'),
      ),
      resizeToAvoidBottomInset: true,
      child: SafeArea(
        child: Center(
          child: CupertinoListSection(
            children: List.generate(
              10,
              (index) {
                return CupertinoListTile(
                  title: Text("Hi $index"),
                  trailing: const CupertinoListTileChevron(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
