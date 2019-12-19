import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:connectivity/connectivity.dart';
import 'package:draw/draw.dart';
import 'package:hive/hive.dart';
import 'package:lyre/Models/User.dart';
import 'package:lyre/Resources/PreferenceValues.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Resources/repository.dart';
import 'bloc.dart';
import 'package:lyre/Resources/globals.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  final PostsState firstState;

  PostsBloc({this.firstState});

  @override //Default: Empty list of UserContent
  PostsState get initialState => firstState ?? PostsState(state: LoadingState.Inactive, userContent: const [], contentSource : ContentSource.Subreddit, target: homeSubreddit);

  final _repository = Repository();

  @override
  Stream<PostsState> mapEventToState(
    PostsEvent event,
  ) async* {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // Return state userContent if only fetchMore request has internet error (As we don't want to hide already downloaded submissions)
      List<UserContent> userContent = event is FetchMore ? state.userContent : const [];
      yield PostsState(
        state: LoadingState.Error,
        errorMessage: noConnectionErrorMessage,
        userContent: userContent,
        contentSource: state.contentSource,
        currentUser: state.currentUser,
        target: state.target,
        sideBar: state.sideBar,
      );
    } else {
      /// When [ContentSource] is Changed
      if(event is PostsSourceChanged){
        yield PostsState(
          state: LoadingState.Refreshing,
          contentSource: event.source,
          target: event.target,
          userContent: const []
        );
        WikiPage sideBar;
        Subreddit subreddit;
        RedditUser currentUser = await PostsProvider().getLatestUser();
        List<UserContent> userContent;

        final source = event.source ?? state.contentSource;
        final preferences = await Hive.openBox(BOX_SETTINGS);
        if(preferences.get(SUBMISSION_RESET_SORTING) ?? true){ 
          //Reset Current Sort Configuration if user has set it to reset
          parseTypeFilter(preferences.get(SUBMISSION_DEFAULT_SORT_TYPE) ?? sortTypes[0]);
          currentSortTime = preferences.get(SUBMISSION_DEFAULT_SORT_TIME ?? defaultSortTime);
        }
        final target = event.target ?? state.target;

        switch (source) {
          case ContentSource.Subreddit:
            userContent = await _repository.fetchPostsFromSubreddit(target);
            subreddit = await _repository.fetchSubreddit(target);
            sideBar = subreddit != null ? await _repository.fetchWikiPage(WIKI_SIDEBAR_ARGUMENTS, subreddit) : null;
            break;
          case ContentSource.Redditor:
            userContent = await _repository.fetchPostsFromRedditor(target);
            break;
          case ContentSource.Self:
            userContent = await _repository.fetchPostsFromSelf(target);
            break;
          case ContentSource.Frontpage:
            userContent = await _repository.fetchPostsFromFrontpage();
            break;
        }

        yield PostsState(
          state: LoadingState.Inactive,
          userContent: userContent, 
          contentSource : source,
          currentUser: currentUser, 
          target: target is String ? target.toLowerCase() : target, 
          sideBar: sideBar,
          subreddit: subreddit
        );
        preferences.close();
      } else if (event is ParamsChanged){
        yield PostsState(
          state: LoadingState.Refreshing,
          contentSource: state.contentSource,
          target: state.target,
          userContent: const []
        );
        List<UserContent> userContent;
        switch (state.contentSource) {
          case ContentSource.Subreddit:
            userContent = await _repository.fetchPostsFromSubreddit(state.target);
            break;
          case ContentSource.Redditor:
            userContent = await _repository.fetchPostsFromRedditor(state.target);
            break;
          case ContentSource.Self:
            userContent = await _repository.fetchPostsFromSelf(state.target);
            break;
          case ContentSource.Frontpage:
            userContent = await _repository.fetchPostsFromFrontpage();
            break;
        }

        yield getUpdatedstate(userContent, false);
      } else if (event is FetchMore){
        yield PostsState(
          state: LoadingState.LoadingMore,
          contentSource: state.contentSource,
          target: state.target,
          userContent: state.userContent
        );

        final last = state.userContent.last;
        final after = last is Submission ? last.fullname : (last as Comment).fullname;
        
        List<UserContent> fetchedContent;
        
        switch (state.contentSource) {
          case ContentSource.Subreddit:
            fetchedContent = await _repository.fetchPostsFromSubreddit(state.target, after: after);
            break;
          case ContentSource.Redditor:
            fetchedContent = await _repository.fetchPostsFromRedditor(state.target, after: after);
            break;
          case ContentSource.Self:
            fetchedContent = await _repository.fetchPostsFromSelf(state.target, after: after);
            break;
          case ContentSource.Frontpage:
            fetchedContent = await _repository.fetchPostsFromFrontpage(after: after);
            break;
        }
        yield getUpdatedstate(state.userContent..addAll(fetchedContent), true);
      }
    }
    
  }

  PostsState getUpdatedstate([List<UserContent> userContent, bool updated]){
    return PostsState(
      state: LoadingState.Inactive,
      userContent: notNull(userContent) ? userContent : state.userContent,
      contentSource: state.contentSource,
      currentUser: state.currentUser,
      target: state.target,
      sideBar: state.sideBar,
    );
  }
}
enum LoadingState {
  Inactive,
  Error,
  LoadingMore,
  Refreshing,
}
