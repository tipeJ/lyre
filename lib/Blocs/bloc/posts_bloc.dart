import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';
import 'package:hive/hive.dart';
import 'package:lyre/Models/User.dart';
import 'package:lyre/Resources/PreferenceValues.dart';
import 'package:lyre/Resources/credential_loader.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Resources/repository.dart';
import 'package:lyre/UI/postInnerWidget.dart';
import './bloc.dart';
import '../../Resources/globals.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  @override //Default: Empty list of UserContent
  PostsState get initialState => PostsState(userContent: [], contentSource : ContentSource.Subreddit, usernamesList: [], targetRedditor: "");

  final _repository = Repository();
  DateTime lastRefresh;

  @override
  Stream<PostsState> mapEventToState(
    PostsEvent event,
  ) async* {
    if(event is PostsSourceChanged){
      var userNamesList = await readUsernames();
      userNamesList.insert(0, "Guest");
      WikiPage sideBar;
      RedditUser currentUser = await PostsProvider().getLatestUser();
      List<UserContent> _userContent;
      List<StyleSheetImage> styleSheetImages;

      final source = event.source != null
        ? event.source
        : currentState.contentSource;
      final preferences = await Hive.openBox(BOX_SETTINGS);
      if(preferences.get(SUBMISSION_RESET_SORTING) ?? true){ //Reset Current Sort Configuration if user has set it to reset
        parseTypeFilter(preferences.get(SUBMISSION_DEFAULT_SORT_TYPE) ?? sortTypes[0]);
        currentSortTime = preferences.get(SUBMISSION_DEFAULT_SORT_TIME ?? defaultSortTime);
      }
      switch (source) {
        case ContentSource.Subreddit:
          _userContent = await _repository.fetchPostsFromSubreddit(false);
          sideBar = await _repository.fetchWikiPage(WIKI_SIDEBAR_ARGUMENTS);
          styleSheetImages = await _repository.fetchStyleSheetImages();
          break;
        case ContentSource.Redditor:
          _userContent = await _repository.fetchPostsFromRedditor(false, event.redditor);
          break;
        case ContentSource.Self:
          _userContent = await _repository.fetchPostsFromSelf(false, event.selfContentType);
          break;
      }

      lastRefresh = DateTime.now();
      yield PostsState(
        userContent: _userContent, 
        contentSource : source,
        usernamesList: userNamesList, 
        currentUser: currentUser, 
        targetRedditor: event.redditor, 
        sideBar: sideBar,
        styleSheetImages: styleSheetImages,
        preferences: preferences
        );
    } else if (event is ParamsChanged){
      List<UserContent> _userContent;
      switch (currentState.contentSource) {
        case ContentSource.Subreddit:
          _userContent = await _repository.fetchPostsFromSubreddit(false);
          break;
        case ContentSource.Redditor:
          _userContent = await _repository.fetchPostsFromRedditor(false, currentState.targetRedditor);
          break;
        case ContentSource.Self:
          _userContent = await _repository.fetchPostsFromSelf(false, currentState.selfContentType);
          break;
      }

      lastRefresh = DateTime.now();
      yield getUpdatedCurrentState(_userContent);
    } else if (event is FetchMore){
      if (lastRefresh.difference(DateTime.now()).inMilliseconds < 700) return; //Prevents repeated concussive FetchMore events (mainly caused by autoload)
      lastPost = currentState.userContent.last is Comment
        ? (currentState.userContent.last as Comment).id
        : (currentState.userContent.last as Submission).id;
      
      var fetchedContent = List<UserContent>();
      
      switch (currentState.contentSource) {
        case ContentSource.Subreddit:
          fetchedContent = await _repository.fetchPostsFromSubreddit(true);
          break;
        case ContentSource.Redditor:
          fetchedContent = await _repository.fetchPostsFromRedditor(false, this.currentState.targetRedditor);
          break;
        case ContentSource.Self:
          fetchedContent = await _repository.fetchPostsFromSelf(false, this.currentState.selfContentType);
          break;
      }
      print("before: " + currentState.userContent.length.toString());
      currentState.userContent.addAll(fetchedContent);
      print("after: " + currentState.userContent.length.toString());

      lastRefresh = DateTime.now();
      yield getUpdatedCurrentState();
    }
  }

  PostsState getUpdatedCurrentState([List<UserContent> userContent]){
    return PostsState(
      userContent: notNull(userContent) ? userContent : currentState.userContent,
      contentSource: currentState.contentSource,
      usernamesList: currentState.usernamesList,
      currentUser: currentState.currentUser,
      targetRedditor: currentState.targetRedditor,
      sideBar: currentState.sideBar,
      styleSheetImages: currentState.styleSheetImages,
      preferences: currentState.preferences
    );
  }
}
