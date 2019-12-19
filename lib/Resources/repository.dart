import 'dart:async';

import 'reddit_api_provider.dart';
import 'package:draw/draw.dart';
import '../Models/Subreddit.dart';
import 'globals.dart';

class Repository {
  final postsApiProvider = PostsProvider();

  Future<List<UserContent>> fetchPostsFromSubreddit(String subreddit, {String after}) => postsApiProvider.fetchUserContent(currentSortType, subreddit, source: ContentSource.Subreddit, timeFilter: currentSortTime, after: after);
  Future<List<UserContent>> fetchPostsFromRedditor(String redditor, {String after}) => postsApiProvider.fetchUserContent(currentSortType, redditor, source: ContentSource.Redditor, timeFilter: currentSortTime, after: after);
  Future<List<UserContent>> fetchPostsFromFrontpage({String after}) => postsApiProvider.fetchUserContent(currentSortType, '', source: ContentSource.Frontpage, timeFilter: currentSortTime, after: after);
  Future<List<UserContent>> fetchPostsFromSelf(SelfContentType contentType, {String after}) => postsApiProvider.fetchSelfUserContent(contentType, typeFilter: currentSortType, timeFilter: currentSortTime, after: after);
  Future<SubredditM> fetchSubs(String q) => postsApiProvider.fetchSubReddits(q);
  Future<WikiPage> fetchWikiPage(String args, Subreddit subreddit) => postsApiProvider.getWikiPage(args, subreddit);
  Future<List<StyleSheetImage>> fetchStyleSheetImages(Subreddit s) => postsApiProvider.getStyleSheetImages(s);
  Future<Subreddit> fetchSubreddit(String s) => postsApiProvider.getSubreddit(s);

}