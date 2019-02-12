import 'dart:async';
import 'reddit_api_provider.dart';
import 'package:lyre/Models/item_model.dart';
import '../Models/Comment.dart';
import '../Models/Subreddit.dart';

class Repository {
  final postsApiProvider = PostsProvider();

  Future<ItemModel> fetchPosts() => postsApiProvider.fetchPostsList();
  Future<CommentM> fetchComments() => postsApiProvider.fetchCommentsList();
  Future<SubredditM> fetchSubs(String q) => postsApiProvider.fetchSubReddits(q);
}