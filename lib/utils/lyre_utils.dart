import 'package:draw/draw.dart';
import 'package:flutter/cupertino.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:provider/provider.dart';

import 'utils.dart';
import 'package:lyre/screens/interfaces/previewc.dart';
import 'package:lyre/screens/screens.dart';
import 'package:flutter/material.dart';

enum RedditLinkType {
  Submission,
  Comments,
  Subreddit,
  WikiPage,
  User
}

const _redditParserID = "redditParserId";
const _redditParserWIkiPageName = "redditParserWikiPageName";
const _redditParserTYPE = "redditParserType";

/// Handles link clicks
/// Supply context if a direct launching web link
void handleLinkClick(dynamic source, BuildContext context, [LinkType suppliedLinkType, bool longPress = false]) {
  Uri uri;
  if (source is Submission) {
    uri = source.url;
  } else if (source is String) {
    uri = Uri.parse(source);
  } else {
    uri = source as Uri;
  }
  final url = uri.toString();
  final domain = uri.authority;
  final LinkType linkType = suppliedLinkType ?? getLinkType(url);
  if(linkType == LinkType.YouTube){
    //TODO: Implement YT plugin?
    launchURL(context, url);
  } else if (linkType == LinkType.RPAN) {
    // source MUST be submission
    if (!(source is Submission)) return;
    Navigator.of(context).pushNamed('livestream', arguments: source);
  } else if (linkType == LinkType.Internal){
    final isGoogleAmpLink = (domain.contains("google") && uri.path.startsWith("/amp/s/amp.reddit.com"));
    final Map<String, dynamic> parsedData = _parseRedditUrl(
    isGoogleAmpLink
      ? "https://" + url.substring(url.indexOf("/amp/s/") + "/amp/s/".length)
      : url
    );

    if (parsedData.isEmpty) {
      // Couldn't parse link, open in external instead
      launchURL(context, url);
      return;
    }
    final RedditLinkType redditLinkType = parsedData[_redditParserTYPE];
    final String id = parsedData[_redditParserID];

    String route;
    dynamic args;

    switch (redditLinkType) {
      case RedditLinkType.Submission:
        route = "comments";
        if (source is Submission) {
          args = source;
          break;
        }
        PostsProvider().reddit.submission(id: id).populate().then((fetchedSubmission) {
          route = "comments";
          args = fetchedSubmission;
        });
        break;
      case RedditLinkType.Comments:
        route = "comments";
        args = PostsProvider().reddit.comment(id: id);
        break;
      case RedditLinkType.Subreddit:
        route = "posts";
        args = {
          'content_source' : ContentSource.Subreddit,
          'target' : id
        };
        break;
      case RedditLinkType.WikiPage:
        route = "wiki";
        args = {
          'subreddit' : id,
          'page_name' : parsedData[_redditParserWIkiPageName]
        };
        break;
      case RedditLinkType.User:
        route = "posts";
        args = {
          'content_source' : ContentSource.Redditor,
          'target' : id
        };
        break;
    }
    if (longPress) {
      // Relay the info to the peek notifier provider
      Provider.of<PeekNotifier>(context).changePeek(route, args);
    } else {
      // Push a new route to the main navigator
      Navigator.of(context).pushNamed(route, arguments: args);
    }
  } else if (linkType == LinkType.Default) {
    launchURL(context, url);
  } else if (longPress && source is Submission) {
    // Show comments
    Provider.of<PeekNotifier>(context).changePeek("comments", source);
  } else {
    PreviewCall().callback.preview(url);
  }
}

void instantLaunchUrl(BuildContext context, Uri uri, [bool longPress = false]) {
  if (longPress) {
    // Peek the route
    Provider.of<PeekNotifier>(context).changePeek("instant_view", uri);
  } else {
    // Navigate to the route
    Navigator.of(context).pushNamed("instant_view", arguments: uri);
  }
}

Map<String, dynamic> _parseRedditUrl(String url) {
  if (url.contains("comments")) {
    // Comment or Submission
    final splitUrl = url.split("comments/").last.split('/')..removeWhere((s) => s.isEmpty);
    if (splitUrl.length == 2) {
      // Submission
      return {
        _redditParserTYPE : RedditLinkType.Submission,
        _redditParserID : splitUrl.first
      };
    } else {
      // Comment
      return {
        _redditParserTYPE : RedditLinkType.Comments,
        _redditParserID : splitUrl[2]
      };
    }
  } else if (url.contains("user/")) {
    final splitUrl = url.split("/");
    final userID = splitUrl[splitUrl.indexOf('user') + 1];
    return {
      _redditParserTYPE : RedditLinkType.User,
      _redditParserID : userID
    };
  } else if (url.contains("r/")) {
    final splitUrl = url.split("/");
    final subredditID = splitUrl[splitUrl.indexOf('r') + 1];
    if (url.contains("/wiki/")) {
      var wikiPageName = splitUrl[splitUrl.indexOf('wiki') + 1];
      if (wikiPageName.contains("#")) wikiPageName = wikiPageName.split("#").first;
      return {
        _redditParserTYPE : RedditLinkType.WikiPage,
        _redditParserID : subredditID,
        _redditParserWIkiPageName : wikiPageName
      };
    }
    return {
      _redditParserTYPE : RedditLinkType.Subreddit,
      _redditParserID : subredditID
    };
  } 
  // Failed to parse, return an empty map instead
  return const {};
}

bool wideLayout ({Size size, BoxConstraints constraints}) {
  Size s;
  if (size != null) {
    s = size;
  } else {
    s = Size(constraints.maxWidth, constraints.maxHeight);
  }
  return s.aspectRatio > 1.0 && s.width > 1200.0;
}