import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Blocs/bloc/posts_bloc.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/UI/Animations/transitions.dart';
import 'package:lyre/UI/Comments/bloc/bloc.dart';
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
        ContentSource source = ContentSource.Subreddit; //Default ContentSource
        if(settings.arguments != null){
          final args = settings.arguments as Map<String, Object>;
          redditor = args['redditor'] as String;
          source = args['content_source'] as ContentSource;
        }
        if (redditor.isNotEmpty) {
          source = ContentSource.Redditor;
        }
        return MaterialPageRoute(builder: (_) => BlocProvider(
          builder: (context) => PostsBloc(),
          child: PostsList(redditor, source),
        ));
      case 'comments':
        Submission submission = settings.arguments as Submission;
        if(recentlyViewed.contains(submission)) recentlyViewed.remove(submission); //removes the submission from the list (will be readded, to index 0)
        recentlyViewed.add(submission); //Adds the submission to the top of the recently viewed list
        return SlideUpRoute(widget: BlocProvider(
          builder: (context) => CommentsBloc(submission),
          child: CommentList(),
        ));
      case 'settings':
        return MaterialPageRoute(builder: (_) => PreferencesView());
      case 'submit':
        return MaterialPageRoute(builder: (_) => SubmitWindow());
      case 'reply':
        final args = settings.arguments as Map<String, Object>;
        final comment = args['comment'] as Comment;
        final text = args['reply_text'] as String;
        return MaterialPageRoute(builder: (_) => replyWindow(comment, text));
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