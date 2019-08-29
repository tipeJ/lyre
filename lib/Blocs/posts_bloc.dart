import '../Resources/repository.dart';
import '../Resources/globals.dart';
import '../Resources/credential_loader.dart';
import 'package:rxdart/rxdart.dart';
import '../Models/item_model.dart';
import '../Models/User.dart';
import '../Resources/reddit_api_provider.dart';

class PostsBloc {
  final _repository = Repository();
  final _postsFetcher = PublishSubject<ItemModel>();
  ItemModel latestModel;

  Observable<ItemModel> get allPosts => _postsFetcher.stream;
  List<String> usernamesList = new List();
  RedditUser currentUser;
  
  RedditUser getCurrentUser(){
    return (currentUser != null) ? currentUser : RedditUser(username: "Guest", credentials: "", date: 0);
  }
  Future<String> cplas;
  Future<String> getCUserName() async {
    if(PostsProvider().isLoggedIn()){
      PostsProvider().reddit.user.me().then((redditor){
        return redditor.displayName;
      });
    }else{
      return "Guest";
    }
    
  }

  var contentSource = ContentSource.Subreddit;
  
  String redditor = "";

  String getSourceString(){
    switch (contentSource) {
      case ContentSource.Subreddit:
        return 'r/$currentSubreddit';
      case ContentSource.Redditor:
        return 'u/$redditor';
      default:
        break;
    }
  }

  fetchAllPosts() async {
    temporaryType = currentSortType;
    temporaryTime = currentSortTime;
    ItemModel itemModel;
    if(contentSource == ContentSource.Subreddit){
      itemModel = await _repository.fetchPostsFromSubreddit(false);
    }else if(contentSource == ContentSource.Redditor){
      itemModel = await _repository.fetchPostsFromRedditor(false, redditor);
    }

    print("ITEMMODEL LENGTH: " + itemModel.results.length.toString());
    latestModel = itemModel;
    _postsFetcher.sink.add(latestModel);
    currentCount = latestModel.results.length;
    //Currently refreshes list of registered usernames via refreshing list of posts.
    var x = await readUsernames();
    x.insert(0, "Guest");
    usernamesList = x;
    currentUser = await PostsProvider().getLatestUser();
  }
  fetchMore() async {
    lastPost = latestModel.results.last.s.id;
    print("START FETCH MORE");
    ItemModel itemModel;
    if(contentSource == ContentSource.Subreddit){
      itemModel = await _repository.fetchPostsFromSubreddit(true);
    }else if(contentSource == ContentSource.Redditor){
      itemModel = await _repository.fetchPostsFromRedditor(true, redditor);
    }
    currentCount += itemModel.results.length;
    latestModel.results.addAll(itemModel.results);
    _postsFetcher.sink.add(latestModel);
  }

  dispose() {
    _postsFetcher.close();
  }

  void resetFilters(){
    currentSortTime = defaultSortTime;
    currentSortType = defaultSortType;
  }
  String getFilterString(){
    if(temporaryType == "top" || temporaryType == "controversial"){
      return temporaryType + " ● " + temporaryTime;
    }else{
      return temporaryType;
    }
  }
  var temporaryType = currentSortType;
  var temporaryTime = currentSortTime;

  String tempType = "";

}