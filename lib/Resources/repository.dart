import 'dart:async';
import 'reddit_api_provider.dart';
import 'package:lyre/Models/item_model.dart';
import '../Models/Comment.dart';
import '../Models/Subreddit.dart';
import 'globals.dart';

class Repository {
  final postsApiProvider = PostsProvider();

  Future<ItemModel> fetchPostsFromSubreddit(bool loadMore) => postsApiProvider.fetchUserContent(currentSortType, currentSortTime, loadMore);
  Future<ItemModel> fetchPostsFromRedditor(bool loadMore, String redditor) => postsApiProvider.fetchUserContent(currentSortType, currentSortTime, loadMore, source: ContentSource.Redditor, redditor: redditor);
  Future<CommentM> fetchComments() => postsApiProvider.fetchCommentsList();
  Future<SubredditM> fetchSubs(String q) => postsApiProvider.fetchSubReddits(q);
  Future<CommentM> fetchComment(String id, String name) => postsApiProvider.getC2(id, name);


}