import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar(
    BuildContext context, {
    super.key,
    required this.title,
    this.actionButton,
  });

  final String title;
  final ({String title, VoidCallback onPressed})? actionButton;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      snap: false,
      floating: false,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(title),
        background: Center(
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top,
              left: 4,
              right: 4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Explicit ghost back-button (Phase 6): tab-root pages sit at
                // the bottom of their nested Navigator, so canPop() is false
                // there and no leading is shown.
                if (Navigator.of(context).canPop())
                  FButton(
                    variant: .ghost,
                    onPress: () => Navigator.of(context).maybePop(),
                    child: const Icon(FLucideIcons.chevronLeft),
                  )
                else
                  const Spacer(),
                if (actionButton != null)
                  FButton(
                    variant: .ghost,
                    onPress: actionButton!.onPressed,
                    child: Text(actionButton!.title),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
