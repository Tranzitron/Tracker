import 'package:flutter/material.dart';

/// Centers content and caps its width on wide windows so forms, lists and
/// buttons don't stretch full-bleed across a ~1280px desktop window. Mobile
/// widths (below [defaultMaxWidth]) are unaffected.
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, this.max = defaultMaxWidth, required this.child});

  static const double defaultMaxWidth = 720;

  final double max;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: max),
        child: child,
      ),
    );
  }
}
