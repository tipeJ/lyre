import 'dart:async';
import 'package:lyre/Models/reddit_content.dart';

import 'reddit_api_provider.dart';
import 'package:draw/draw.dart';
import '../Models/Subreddit.dart';
import 'globals.dart';

class Repository {
  final postsApiProvider = PostsProvider();

  Future<List<UserContent>> fetchPostsFromSubreddit(bool loadMore, String subreddit, [String after]) => postsApiProvider.fetchUserContent(currentSortType, loadMore, subreddit, source: ContentSource.Subreddit, timeFilter: currentSortTime);
  Future<List<UserContent>> fetchPostsFromRedditor(bool loadMore, String redditor, [String after]) => postsApiProvider.fetchUserContent(currentSortType, loadMore, redditor, source: ContentSource.Redditor, timeFilter: currentSortTime, after: after);
  Future<List<UserContent>> fetchPostsFromSelf(bool loadMore, SelfContentType contentType) => postsApiProvider.fetchSelfUserContent(loadMore, contentType, typeFilter: currentSortType, timeFilter: currentSortTime);
  Future<SubredditM> fetchSubs(String q) => postsApiProvider.fetchSubReddits(q);
  Future<WikiPage> fetchWikiPage(String args, Subreddit subreddit) => postsApiProvider.getWikiPage(args, subreddit);
  Future<List<StyleSheetImage>> fetchStyleSheetImages(Subreddit s) => postsApiProvider.getStyleSheetImages(s);
  Future<Subreddit> fetchSubreddit(String s) => postsApiProvider.getSubreddit(s);

}