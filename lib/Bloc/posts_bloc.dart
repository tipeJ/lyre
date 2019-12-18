import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';
import 'package:hive/hive.dart';
import 'package:lyre/Models/User.dart';
import 'package:lyre/Models/reddit_content.dart';
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
          userContent = await _repository.fetchPostsFromSubreddit(false, target);
          subreddit = await _repository.fetchSubreddit(target);
          sideBar = subreddit != null ? await _repository.fetchWikiPage(WIKI_SIDEBAR_ARGUMENTS, subreddit) : null;
          break;
        case ContentSource.Redditor:
          userContent = await _repository.fetchPostsFromRedditor(false, target);
          break;
        case ContentSource.Self:
         userContent = await _repository.fetchPostsFromSelf(false, target);
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
          userContent = await _repository.fetchPostsFromSubreddit(false, state.target);
          break;
        case ContentSource.Redditor:
          userContent = await _repository.fetchPostsFromRedditor(false, state.target);
          break;
        case ContentSource.Self:
          userContent = await _repository.fetchPostsFromSelf(false, state.target);
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
      
      var fetchedContent = List<UserContent>();
      
      switch (state.contentSource) {
        case ContentSource.Subreddit:
          fetchedContent = await _repository.fetchPostsFromSubreddit(true, state.target, after);
          break;
        case ContentSource.Redditor:
          fetchedContent = await _repository.fetchPostsFromRedditor(true, this.state.target, after);
          break;
        case ContentSource.Self:
          fetchedContent = await _repository.fetchPostsFromSelf(false, this.state.target);
          break;
      }
      yield getUpdatedstate(state.userContent..addAll(fetchedContent), true);
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
