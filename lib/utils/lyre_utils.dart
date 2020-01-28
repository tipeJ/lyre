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
  print(uri.path);
  return;
  final LinkType linkType = suppliedLinkType ?? getLinkType(url);
  if(linkType == LinkType.YouTube){
    //TODO: Implement YT plugin?
    launchURL(context, url);
  } else if (linkType == LinkType.Default){
    final isGoogleAmpLink = (domain.contains("google") && uri.path.startsWith("/amp/s/amp.reddit.com"));
    if (
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
      final RedditLinkType redditLinkType = parsedData[_redditParserTYPE];
      final String id = parsedData[_redditParserID];

      switch (redditLinkType) {
        case RedditLinkType.Submission:
          PostsProvider().reddit.submission(id: id).populate().then((fetchedSubmission) {
            Navigator.of(context).pushNamed("comments", arguments: fetchedSubmission);
          });
          break;
          // TODO : ADD THE REST
        default:
      }
    }
  } else {
    PreviewCall().callback.preview(url);
  }
}

Map<String, dynamic> _parseRedditUrl(String url) {

}