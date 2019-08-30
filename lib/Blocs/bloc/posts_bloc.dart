import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';
import 'package:lyre/Models/User.dart';
import 'package:lyre/Resources/credential_loader.dart';
import 'package:lyre/Resources/globals.dart' as prefix0;
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Resources/repository.dart';
import '../../Resources/globals.dart';
import './bloc.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  @override //Default: Empty list of UserContent
  PostsState get initialState => PostsState(userContent: null, contentSource: ContentSource.Subreddit);

  final _repository = Repository();

  List<UserContent> _userContent = [];
  ContentSource _contentSource;

  @override
  Stream<PostsState> mapEventToState(
    PostsEvent event,
  ) async* {
    print('event mapped');
    var userNamesList = await readUsernames();
    userNamesList.insert(0, "Guest");
    RedditUser currentUser = await PostsProvider().getLatestUser();
    if(event is PostsSourceChanged){
      ContentSource source = event.source == null ? _contentSource : event.source;
      switch (prefix0.currentContentSource) {
        case ContentSource.Subreddit:
          _userContent = await _repository.fetchPostsFromSubreddit(false);
          break;
        case ContentSource.Redditor:
          _userContent = await _repository.fetchPostsFromRedditor(false, event.redditor);
          break;
        case ContentSource.Self:
          _userContent = await _repository.fetchPostsFromSelf(false, event.selfContentType);
          break;
      }
      print(_userContent.length.toString() + 'whhh');
      yield PostsState(userContent: _userContent, contentSource : _contentSource, usernamesList: userNamesList, currentUser: currentUser);
    }
  }
}
