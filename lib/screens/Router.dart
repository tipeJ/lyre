import 'package:draw/draw.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/screens/comments/comment_list.dart';
import 'package:lyre/screens/Preferences.dart';
import 'package:lyre/screens/filters.dart';
import 'package:lyre/screens/submissions/posts_list.dart';
import 'package:lyre/Bloc/bloc.dart';
import 'package:lyre/screens/reply.dart';
import 'package:lyre/screens/search/search.dart';
import 'package:lyre/screens/submit.dart';

class Router {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case 'posts':
        dynamic target;
        ContentSource source = ContentSource.Subreddit; //Default ContentSource
        
        if(settings.arguments != null){
          print('notnull');
          final args = settings.arguments as Map<String, Object>;
          source = args['content_source'] as ContentSource;
          if (source == ContentSource.Redditor || source == ContentSource.Subreddit) {
            target = args['target'];
            print('target: ' + target.toString());
          } else {
            target = SelfContentType.Comments;
          }
        } else {
          print('null');
          target = homeSubreddit;
        }

        return MaterialPageRoute(builder: (_) => BlocProvider(
          create: (context) => PostsBloc(firstState: PostsState(
            state: LoadingState.Inactive,
            userContent: [],
            contentSource: source,
            target: target
          )),
          child: PostsList(),
        ));
      case 'comments':
        UserContent content = settings.arguments;
        if (content is Submission) {
          if(recentlyViewed.contains(content)) recentlyViewed.remove(content); //removes the submission from the list (will be readded, to index 0)
          recentlyViewed.add(content); //Adds the submission to the top of the recently viewed list
        }
        // return CupertinoPageRoute(builder: (_) => BlocProvider(
        //   builder: (context) => CommentsBloc(content),
        //   child: CommentList(),
        // ));
        return CupertinoPageRoute(builder: (_) => BlocProvider(
          create: (context) => CommentsBloc(content),
          child: CommentList(),
        ));
      case 'settings':
        return MaterialPageRoute(builder: (_) => PreferencesView());
      case 'filters':
        return MaterialPageRoute(builder: (_) => FiltersView());
      case 'search_communities':
        return CupertinoPageRoute(builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<SearchCommunitiesBloc>(
              create: (BuildContext context) => SearchCommunitiesBloc()
            ),
          ],
          child: SearchCommunitiesView(),
        ));
       case 'search_usercontent':
        return CupertinoPageRoute(builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<SearchUsercontentBloc>(
              create: (BuildContext context) => SearchUsercontentBloc()
            ),
          ],
          child: SearchUserContentView(),
        ));
      case 'submit':
        final args = settings.arguments as Map<String, Object>;
        return MaterialPageRoute(builder: (_) => SubmitWindow(initialTargetSubreddit: args['initialTargetSubreddit'],));
      case 'reply':
        final args = settings.arguments as Map<String, Object>;
        final comment = args['content'] as UserContent;
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