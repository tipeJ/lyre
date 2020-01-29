import 'package:lyre/Resources/reddit_api_provider.dart';

import 'utils.dart';
import 'package:lyre/screens/interfaces/previewc.dart';
import 'package:flutter/material.dart';

enum RedditLinkType {
  Submission,
  Comments,
  Subreddit,
  User
}

const _redditParserID = "redditParserId";
const _redditParserTYPE = "redditParserId";

/// Handles link clicks
/// Supply context if a direct launching web link
void handleLinkClick(Uri uri, [LinkType suppliedLinkType, BuildContext context]) {
  final url = uri.toString();
  final domain = uri.authority;
  final LinkType linkType = suppliedLinkType ?? getLinkType(url);
  if(linkType == LinkType.YouTube){
    //TODO: Implement YT plugin?
    launchURL(context, url);
  } else if (linkType == LinkType.Default){
    final isGoogleAmpLink = (domain.contains("google") && uri.path.startsWith("/amp/s/amp.reddit.com"));
    if ( // Check if domain is a reddit hosted link, ie: parseable
      domain.endsWith("reddit.com") ||
      domain.endsWith("redd.it") ||
      domain.contains("i.reddit.com") ||
      // Reddit AMP links
      isGoogleAmpLink
    ) {
      final Map<String, dynamic> parsedData = _parseRedditUrl(
        isGoogleAmpLink
          ? "https://" + url.substring(url.indexOf("/amp/s/") + "/amp/s/".length)
          : url
      );

      if (parsedData.isEmpty) {
        // Couldn't parse link, open in external instead
        launchURL(context, url);
      }

      final RedditLinkType redditLinkType = parsedData[_redditParserTYPE];
      final String id = parsedData[_redditParserID];

      switch (redditLinkType) {
        case RedditLinkType.Submission:
          PostsProvider().reddit.submission(id: id).populate().then((fetchedSubmission) {
            Navigator.of(context).pushNamed("comments", arguments: fetchedSubmission);
          });
          break;
        case RedditLinkType.Comments:
          Navigator.of(context).pushNamed("comments", arguments: PostsProvider().reddit.comment(id: id));
          break;
        case RedditLinkType.Subreddit:
          Navigator.of(context).pushNamed("posts", arguments: {
            'content_source' : ContentSource.Subreddit,
            'target' : id
          });
          break;
        case RedditLinkType.User:
          Navigator.of(context).pushNamed("posts", arguments: {
            'content_source' : ContentSource.Redditor,
            'target' : id
          });
          break;
      }
    } else {
      launchURL(context, url);
    }
  } else {
    PreviewCall().callback.preview(url);
  }
}

Map<String, dynamic> _parseRedditUrl(String url) {
  if (url.contains("comments")) {
    // Comment or Submission
    final splitUrl = url.split("comments").last.split('/');
    if (splitUrl.length == 2) {
      // Submission
      print("SUBMISSION ID: " + splitUrl.first);
      return {
        _redditParserTYPE : RedditLinkType.Submission,
        _redditParserID : splitUrl.first
      };
    } else {
      // Comment
      print("COMMENT ID: " + splitUrl[2]);
      return {
        _redditParserTYPE : RedditLinkType.Comments,
        _redditParserID : splitUrl[2]
      };
    }
  } else if (url.contains("r/")) {
    final splitUrl = url.split("/");
    final subredditID = splitUrl[splitUrl.indexOf('r') + 1];
    return {
      _redditParserTYPE : RedditLinkType.Subreddit,
      _redditParserID : subredditID
    };
  } else if (url.contains('user/')) {
    final splitUrl = url.split("/");
    final userID = splitUrl[splitUrl.indexOf('user') + 1];
    return {
      _redditParserTYPE : RedditLinkType.User,
      _redditParserID : userID
    };
  }
  // Failed to parse, return an empty map instead
  return const {};
}