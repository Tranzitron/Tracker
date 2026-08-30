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
      // The title Row below lays out its own back button and action aligned
      // with the body margin; the app bar must not inject a second leading.
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          // Explicit ghost back-button (Phase 6): tab-root pages sit at the
          // bottom of their nested Navigator, so canPop() is false there and
          // no leading is shown.
          if (Navigator.of(context).canPop())
            FButton(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.chevronLeft),
            ),
          Expanded(
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (actionButton != null)
            FButton(
              variant: .ghost,
              onPress: actionButton!.onPressed,
              child: Text(actionButton!.title),
            ),
        ],
      ),
    );
  }
}
