import 'package:draw/draw.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/screens/screens.dart';
import 'package:lyre/Bloc/bloc.dart';

class Router {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case 'posts':
        dynamic target;
        ContentSource source = ContentSource.Subreddit; //Default ContentSource
        
        if(settings.arguments != null){
          final args = settings.arguments as Map<String, Object>;
          source = args['content_source'] as ContentSource;
          if (source == ContentSource.Redditor || source == ContentSource.Subreddit) {
            target = args['target'];
          } else {
            target = SelfContentType.Comments;
          }
        } else {
          target = homeSubreddit;
          if (target == FRONTPAGE_HOME_SUB) source = ContentSource.Frontpage;
        }

        return MaterialPageRoute(builder: (_) => BlocProvider(
          create: (context) => PostsBloc(firstState: PostsState(
            state: LoadingState.Inactive,
            userContent: [],
            contentSource: source,
            typeFilter: TypeFilter.Best,
            timeFilter: 'all',
            target: target,
            viewMode: BlocProvider.of<LyreBloc>(context).state.viewMode
          )),
          child: PostsList(),
        ));
      case 'wiki':
        final args = settings.arguments as Map<String, Object>;
        final String pageName = args['page_name'];
        final String subreddit = args['subreddit'];
        return CupertinoPageRoute(builder: (_) => WikiScreen(
          pageName: pageName,
          subreddit: subreddit,
        ));
      case 'comments':
        UserContent content = settings.arguments;
        if (content is Submission) {
          if(recentlyViewed.contains(content)) recentlyViewed.remove(content); //removes the submission from the list (will be readded, to index 0)
          recentlyViewed.add(content); //Adds the submission to the top of the recently viewed list
        }
        return CupertinoPageRoute(builder: (_) => BlocProvider(
          create: (context) => CommentsBloc(content),
          child: CommentList(),
        ));
      case 'settings':
        return CupertinoPageRoute(builder: (_) => PreferencesView());
      case 'filters':
        return CupertinoPageRoute(builder: (_) => FiltersView());
      case 'filters_global':
        return CupertinoPageRoute(builder: (_) => GlobalFilters());
      case 'themes':
        return CupertinoPageRoute(builder: (_) => ThemeView());
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
        return MaterialPageRoute(builder: (_) => SubmitWindow(initialTargetSubreddit: args == null ? '' : args['initialTargetSubreddit'],));
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