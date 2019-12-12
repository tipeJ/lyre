import 'package:flutter/material.dart';

class SlideRightRoute extends PageRouteBuilder {

  final Widget widget;
  SlideRightRoute({this.widget})
      : super(
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
        return widget;
      },
      transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
        /*return new FadeTransition(
            opacity: new Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).chain(new CurveTween(curve: Curves.easeOutSine,))
                .animate(animation),
          child: child,
        );*/
        return new SlideTransition(
          position: new Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(new CurveTween(curve: Curves.easeOutSine,))
          .animate(animation),
          child: child,
        );
      }
  );
}
class SlideUpRoute extends PageRouteBuilder {

  final Widget widget;
  SlideUpRoute({this.widget})
      : super(
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
        return widget;
      },
      transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      }
  );
}