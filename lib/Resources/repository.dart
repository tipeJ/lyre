import 'dart:async';
import 'reddit_api_provider.dart';
import 'package:draw/draw.dart';
import '../Models/Comment.dart';
import '../Models/Subreddit.dart';
import 'globals.dart';

class Repository {
  final postsApiProvider = PostsProvider();

  Future<List<UserContent>> fetchPostsFromSubreddit(bool loadMore) => postsApiProvider.fetchUserContent(currentSortType, loadMore, source: ContentSource.Subreddit, timeFilter: currentSortTime);
  Future<List<UserContent>> fetchPostsFromRedditor(bool loadMore, String redditor) => postsApiProvider.fetchUserContent(currentSortType, loadMore, source: ContentSource.Redditor, redditor: redditor, timeFilter: currentSortTime);
  Future<List<UserContent>> fetchPostsFromSelf(bool loadMore, SelfContentType contentType) => postsApiProvider.fetchSelfUserContent(loadMore, contentType, typeFilter: currentSortType, timeFilter: currentSortTime);
  Future<CommentM> fetchComments() => postsApiProvider.fetchCommentsList();
  Future<SubredditM> fetchSubs(String q) => postsApiProvider.fetchSubReddits(q);
  Future<WikiPage> fetchWikiPage(String args, String displayName) => postsApiProvider.getWikiPage(args, displayName);
  Future<List<StyleSheetImage>> fetchStyleSheetImages(Subreddit s) => postsApiProvider.getStyleSheetImages(s);
  Future<Subreddit> fetchSubreddit(String s) => postsApiProvider.getSubreddit(s);

}