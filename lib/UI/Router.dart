import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/UI/Comments/comment_list.dart';
import 'package:lyre/UI/Preferences.dart';
import 'package:lyre/UI/interfaces/previewc.dart';
import 'package:lyre/UI/posts_list.dart';
import 'package:lyre/UI/reply.dart';
import 'package:lyre/UI/submit.dart';

class Router {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case 'posts':
        String redditor = "";
        ContentSource source = ContentSource.Subreddit; //Default ContentSource
        if(settings.arguments != null){
          final args = settings.arguments as Map<String, Object>;
          redditor = args['redditor'] as String;
          source = args['content_source'] as ContentSource;
        }
        return MaterialPageRoute(builder: (_) => PostsView(redditor, source));
      case 'comments':
        Submission submission = settings.arguments as Submission;
        if(recentlyViewed.contains(submission)) recentlyViewed.remove(submission); //removes the submission from the list (will be readded, to index 0)
        recentlyViewed.add(submission); //Adds the submission to the top of the recently viewed list
        return MaterialPageRoute(builder: (_) => CommentsList(submission));
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
  Widget popWidget(Widget child){
    return WillPopScope(
      onWillPop: PreviewCall().callback.canPop,
      child: child,
    );
  }
}