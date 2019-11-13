import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:lyre/Models/User.dart';
import 'package:lyre/Resources/PreferenceValues.dart';
import 'package:lyre/Resources/credential_loader.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Resources/repository.dart';
import './bloc.dart';
import '../../Resources/globals.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  final PostsState firstState;

  PostsBloc({this.firstState});

  @override //Default: Empty list of UserContent
  PostsState get initialState => firstState == null ? PostsState(userContent: [], contentSource : ContentSource.Subreddit, usernamesList: [], targetRedditor: "") : firstState;

  final _repository = Repository();

  final loading = ValueNotifier(LoadingState.notLoading);

  @override
  Stream<PostsState> mapEventToState(
    PostsEvent event,
  ) async* {
    if(event is PostsSourceChanged){
      loading.value = LoadingState.refreshing;
      var userNamesList = await readUsernames();
      userNamesList.insert(0, "Guest");
      WikiPage sideBar;
      Subreddit subreddit;
      RedditUser currentUser = await PostsProvider().getLatestUser();
      List<UserContent> _userContent;
      List<StyleSheetImage> styleSheetImages;

      final source = event.source != null
        ? event.source
        : state.contentSource;
      final preferences = await Hive.openBox(BOX_SETTINGS);
      if(preferences.get(SUBMISSION_RESET_SORTING) ?? true){ //Reset Current Sort Configuration if user has set it to reset
        parseTypeFilter(preferences.get(SUBMISSION_DEFAULT_SORT_TYPE) ?? sortTypes[0]);
        currentSortTime = preferences.get(SUBMISSION_DEFAULT_SORT_TIME ?? defaultSortTime);
      }
      switch (source) {
        case ContentSource.Subreddit:
          _userContent = await _repository.fetchPostsFromSubreddit(false);
          sideBar = await _repository.fetchWikiPage(WIKI_SIDEBAR_ARGUMENTS);
          subreddit = await _repository.fetchSubreddit(currentSubreddit);
          styleSheetImages = await _repository.fetchStyleSheetImages(subreddit);
          break;
        case ContentSource.Redditor:
          _userContent = await _repository.fetchPostsFromRedditor(false, event.redditor);
          break;
        case ContentSource.Self:
          _userContent = await _repository.fetchPostsFromSelf(false, event.selfContentType);
          break;
      }

      loading.value = LoadingState.notLoading;
      yield PostsState(
        userContent: _userContent, 
        contentSource : source,
        usernamesList: userNamesList, 
        currentUser: currentUser, 
        targetRedditor: event.redditor, 
        sideBar: sideBar,
        styleSheetImages: styleSheetImages,
        preferences: preferences,
        subreddit: subreddit
        );
    } else if (event is ParamsChanged){
      loading.value = LoadingState.refreshing;
      List<UserContent> _userContent;
      switch (state.contentSource) {
        case ContentSource.Subreddit:
          _userContent = await _repository.fetchPostsFromSubreddit(false);
          break;
        case ContentSource.Redditor:
          _userContent = await _repository.fetchPostsFromRedditor(false, state.targetRedditor);
          break;
        case ContentSource.Self:
          _userContent = await _repository.fetchPostsFromSelf(false, state.selfContentType);
          break;
      }

      loading.value = LoadingState.notLoading;
      yield getUpdatedstate(_userContent, false);
    } else if (event is FetchMore){
      if (loading.value != LoadingState.notLoading) return; //Prevents repeated concussive FetchMore events (mainly caused by autoload)
      
      loading.value = LoadingState.loadingMore;
      lastPost = state.userContent.last is Comment
        ? (state.userContent.last as Comment).id
        : (state.userContent.last as Submission).id;
      
      var fetchedContent = List<UserContent>();
      
      switch (state.contentSource) {
        case ContentSource.Subreddit:
          fetchedContent = await _repository.fetchPostsFromSubreddit(true);
          break;
        case ContentSource.Redditor:
          fetchedContent = await _repository.fetchPostsFromRedditor(false, this.state.targetRedditor);
          break;
        case ContentSource.Self:
          fetchedContent = await _repository.fetchPostsFromSelf(false, this.state.selfContentType);
          break;
      }

      loading.value = LoadingState.notLoading;
      yield getUpdatedstate(state.userContent..addAll(fetchedContent), true);
    }
  }

  PostsState getUpdatedstate([List<UserContent> userContent, bool updated]){
    return PostsState(
      userContent: notNull(userContent) ? userContent : state.userContent,
      contentSource: state.contentSource,
      usernamesList: state.usernamesList,
      currentUser: state.currentUser,
      targetRedditor: state.targetRedditor,
      sideBar: state.sideBar,
      styleSheetImages: state.styleSheetImages,
      preferences: state.preferences
    );
  }
}
enum LoadingState {
  notLoading,
  loadingMore,
  refreshing,
}
