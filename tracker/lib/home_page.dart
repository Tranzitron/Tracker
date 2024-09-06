import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:isar/isar.dart';
import 'package:tracker/main.dart';
import 'package:tracker/user.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Isar isar;
  late List<User> users = [];

  @override
  void initState() {
    super.initState();
    initDb();
  }

  Future<void> initDb() async {
    isar = await DbInstance.getIsar();
    refreshUsers();
  }

  void refreshUsers() async {
    users = await isar.users.where().findAll();
    setState(() {
      users;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Home'),
        trailing: CupertinoButton(
          padding: const EdgeInsets.all(0),
          child: const Text("Add"),
          onPressed: () async {
            await addBtn();
          },
        ),
        leading: CupertinoButton(
          padding: const EdgeInsets.all(0),
          child: const Text("Clear"),
          onPressed: () async {
            await clearBtn();
          },
        ),
      ),
      resizeToAvoidBottomInset: true,
      child: SafeArea(
        child: Center(
          child: users.isNotEmpty
              // fix list too long overflow
              ? CupertinoListSection(
                  children: List.generate(
                    users.length,
                    (index) {
                      final user = users[index];
                      return CupertinoListTile(
                        title: Text("Hi ${user.name} : ${user.id}"),
                        trailing: const CupertinoListTileChevron(),
                      );
                    },
                  ),
                )
              : const SizedBox(
                  width: 0,
                  height: 0,
                ),
        ),
      ),
    );
  }

  Future<void> clearBtn() async {
    await isar.writeTxn(
      () async {
        //await isar.users.where().deleteAll();
        await isar.users.clear();
      },
    );
    refreshUsers();
  }

  Future<void> addBtn() async {
    final newUser = User()
      ..name = 'Jane Doe'
      ..age = Random().nextInt(100);

    await isar.writeTxn(() async {
      await isar.users.put(newUser); // insert & update
    });

    refreshUsers();
  }
}
