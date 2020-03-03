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
  static Widget generateWidget(String route, dynamic args, [String key]) {
    switch (route) {
      case 'posts':
        dynamic target;
        ContentSource source = ContentSource.Subreddit; //Default ContentSource
        
        if(args != null){
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

        return BlocProvider(
          key: Key(key),
          create: (context) => PostsBloc(firstState: PostsState(
            state: LoadingState.Inactive,
            userContent: const [],
            contentSource: source,
            typeFilter: TypeFilter.Best,
            timeFilter: 'all',
            target: target,
            viewMode: BlocProvider.of<LyreBloc>(context).state.viewMode
          )),
          child: PostsList(),
        );
      case 'wiki':
        final String pageName = args['page_name'];
        final String subreddit = args['subreddit'];
        return WikiScreen(
          pageName: pageName,
          subreddit: subreddit,
        );
      case 'comments':
        UserContent content = args;
        if (content is Submission) {
          if(recentlyViewed.contains(content)) recentlyViewed.remove(content); //removes the submission from the list (will be readded, to index 0)
          recentlyViewed.add(content); //Adds the submission to the top of the recently viewed list
        }
        return BlocProvider(
          key: Key(key),
          create: (context) => CommentsBloc(content),
          child: CommentList(),
        );
      case 'livestream':
        Submission submission = args as Submission;
        return RedditLiveScreen(submission: submission);
      case 'settings':
        return PreferencesView();
      case 'filters':
        return FiltersView();
      case 'filters_global':
        return GlobalFilters();
      case 'themes':
        return ThemeView();
      case 'search_communities':
        return MultiBlocProvider(
          providers: [
            BlocProvider<SearchCommunitiesBloc>(
              key: Key(key),
              create: (BuildContext context) => SearchCommunitiesBloc()
            ),
          ],
          child: SearchCommunitiesView(),
        );
       case 'search_usercontent':
        return MultiBlocProvider(
          providers: [
            BlocProvider<SearchUsercontentBloc>(
              key: Key(key),
              create: (BuildContext context) => SearchUsercontentBloc()
            ),
          ],
          child: SearchUserContentView(),
        );
      case 'submit':
        return SubmitWindow(initialTargetSubreddit: args == null ? '' : args['initialTargetSubreddit']);
      case 'reply':
        final comment = args['content'] as UserContent;
        final text = args['reply_text'] as String;
        return replyWindow(comment, text);
      case 'instant_view':
        final uri = args as Uri;
        return InstantViewScreen(initialUri: uri);
      case 'top_growing':
        return BlocProvider(
          key: Key(key),
          create: (context) => TopCommunityBloc(),
          child: TopGrowingCommunitiesScreen(),
        );
      default:
        return Scaffold(
          body: Center(
            child: Text('No route defined for $route'),
          ),
        );
    }
  }
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final Widget widget = generateWidget(settings.name, settings.arguments);
    return CupertinoPageRoute(builder: (_) => widget);
  }
}