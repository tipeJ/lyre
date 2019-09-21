import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:lyre/UI/Comments/comment_list.dart';
import 'package:lyre/UI/Preferences.dart';
import 'package:lyre/UI/posts_list.dart';
import 'package:lyre/UI/reply.dart';
import 'package:lyre/UI/submit.dart';

class Router {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case 'posts':
        String redditor = "";
        if(settings.arguments != null) redditor = settings.arguments;
        return MaterialPageRoute(builder: (_) => PostsView(redditor));
      case 'comments':
        return MaterialPageRoute(builder: (_) => CommentsList(settings.arguments as Submission));
      case 'settings':
        return MaterialPageRoute(builder: (_) => PreferencesView());
      case 'submit':
        return MaterialPageRoute(builder: (_) => SubmitWindow());
      case 'reply':
        return MaterialPageRoute(builder: (_) => replyWindow(settings.arguments as Comment));
      default:
        return MaterialPageRoute(builder: (_) {
          return Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          );
        });
    }
  }
}