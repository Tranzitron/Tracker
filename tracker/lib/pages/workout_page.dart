import 'package:flutter/cupertino.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            largeTitle: Text('Workout'),
          ),
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton.filled(
                          padding: EdgeInsets.all(0),
                          onPressed: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute<Widget>(
                                builder: (BuildContext context) {
                                  return const Text('restart if stuck here');
                                },
                              ),
                            );
                          },
                          child: const Text('Start Workout'),
                        ),
                      ),
                    ],
                  ),
                  // TODO From here we are using a for(splits) + trailing new split of type CupertinoListSection
                  const Text('Drag me up', textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
