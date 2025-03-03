import 'package:flutter/cupertino.dart';

class NewSplitPage extends StatefulWidget {
  const NewSplitPage({super.key});

  @override
  State<NewSplitPage> createState() => _NewSplitPageState();
}

class _NewSplitPageState extends State<NewSplitPage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            largeTitle: SizedBox(
              width: 0,
              height: 0,
            ),
            middle: Text('New Split'),
          ),
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text('asdasd'),
                  CupertinoTextFormFieldRow(
                    placeholder: 'Enter text2',
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a value';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
