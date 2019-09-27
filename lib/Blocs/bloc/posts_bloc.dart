import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';
import 'package:lyre/Models/User.dart';
import 'package:lyre/Resources/credential_loader.dart';
import 'package:lyre/Resources/globals.dart' as prefix0;
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Resources/repository.dart';
import './bloc.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  @override //Default: Empty list of UserContent
  PostsState get initialState => PostsState(userContent: _userContent, contentSource : ContentSource.Subreddit, usernamesList: [], targetRedditor: "");

  final _repository = Repository();

  List<UserContent> _userContent = [];

  @override
  Stream<PostsState> mapEventToState(
    PostsEvent event,
  ) async* {
    var userNamesList = await readUsernames();
    userNamesList.insert(0, "Guest");
    RedditUser currentUser = await PostsProvider().getLatestUser();
    WikiPage sideBar;

    if(event is PostsSourceChanged){
      final source = event.source != null
        ? event.source
        : currentState.contentSource;
      switch (source) {
        case ContentSource.Subreddit:
          _userContent = await _repository.fetchPostsFromSubreddit(false);
          sideBar = await _repository.fetchWikiPage(prefix0.WIKI_SIDEBAR_ARGUMENTS);
          break;
        case ContentSource.Redditor:
          _userContent = await _repository.fetchPostsFromRedditor(false, event.redditor);
          break;
        case ContentSource.Self:
          _userContent = await _repository.fetchPostsFromSelf(false, event.selfContentType);
          break;
      }
      yield PostsState(userContent: _userContent, contentSource : source, usernamesList: userNamesList, currentUser: currentUser, targetRedditor: event.redditor, sideBar: sideBar);
    } else if(event is FetchMore){
      prefix0.lastPost = currentState.userContent.last is Comment
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
      yield PostsState(userContent: currentState.userContent, contentSource: currentState.contentSource, usernamesList: userNamesList, currentUser: currentUser, targetRedditor: currentState.targetRedditor);
    }
  }
}
