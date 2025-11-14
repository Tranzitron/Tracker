import 'package:flutter/material.dart';

void pushTo(BuildContext context, Widget destination) {
  final Color backgroundColor = Theme.of(context).colorScheme.surface;
  Navigator.of(context).push(_createRoute(backgroundColor, destination));
}

Route<void> _createRoute(Color backgroundColor, Widget destination) {
  return PageRouteBuilder(
    transitionDuration: Duration(milliseconds: 250),
    barrierColor: backgroundColor,
    pageBuilder: (context, animation, secondaryAnimation) => destination,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.ease;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
