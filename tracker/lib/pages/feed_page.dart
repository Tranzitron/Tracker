import 'package:flutter/cupertino.dart';
import 'package:tracker/home_page.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      // A list of sliver widgets.
      slivers: <Widget>[
        CupertinoSliverNavigationBar(
          // This title is visible in both collapsed and expanded states.
          // When the "middle" parameter is omitted, the widget provided
          // in the "largeTitle" parameter is used instead in the collapsed state.
          largeTitle: Text('Feed'),
          trailing: CupertinoButton(
            onPressed: () {},
            padding: EdgeInsets.all(0),
            child: Text('Edit'),
          ),
        ),
        // This widget fills the remaining space in the viewport.
        // Drag the scrollable area to collapse the CupertinoSliverNavigationBar.
        SliverFillRemaining(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              const Text('Drag me up', textAlign: TextAlign.center),
              CupertinoButton.filled(
                onPressed: () {
                  HomePageSingleton().controller.index =
                      HomePageSingleton().tabMap[TabName.workout]!;
                },
                child: const Text('Go to Workout Page'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
