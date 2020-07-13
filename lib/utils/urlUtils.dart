import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

import 'imageUtils.dart';

const supportedYoutubeUrls = ["youtube.com", "youtu.be"];

enum LinkType {
  Self, //Text post
  Default, //Fallback
  Internal, //Reddit Links (That can be opened via pushing a new route)
  //Images
  DirectImage,
  ImgurAlbum,
  //Videos:
  YouTube,
  RedditVideo,
  Gfycat,
  RedGifs,
  Streamable,
  TwitchClip,
  RPAN
}

const videoLinkTypes = [
  LinkType.Gfycat,
  LinkType.RedGifs,
  LinkType.RedditVideo,
  LinkType.Streamable,
  LinkType.TwitchClip,
  LinkType.RPAN
];

const albumLinkTypes = [LinkType.ImgurAlbum];

LinkType getLinkType(String url) {
  if (url.contains("preview.redd.it")) return LinkType.DirectImage;

  var divided = url.split(".");

  final uri = Uri.parse(url);
  final domain = uri.authority;

  var last = divided.last;
  if (supportedFormats.contains(last)) {
    return LinkType.DirectImage;
  } else if (url.contains("youtube.com") || url.contains("youtu.be")) {
    return LinkType.YouTube;
  } else if (url.contains("imgur.com/a/")) {
    return LinkType.ImgurAlbum;
  } else if (url.contains("gfycat.com")) {
    return LinkType.Gfycat;
  } else if (url.contains("redgifs.com")) {
    return LinkType.RedGifs;
  } else if (url.contains("v.redd.it")) {
    return LinkType.RedditVideo;
  } else if (url.contains("streamable.com")) {
    return LinkType.Streamable;
  } else if (domain.endsWith("watch.redd.it")) {
    return LinkType.RPAN;
  } else if (domain.endsWith("reddit.com") ||
      domain.endsWith("redd.it") ||
      domain.contains("i.reddit.com") ||
      (domain.contains("google") &&
          uri.path.startsWith("/amp/s/amp.reddit.com"))) {
    return LinkType.Internal;
  } else if (url.contains("clips.twitch.tv")) {
    return LinkType.TwitchClip;
  }

  return LinkType.Default;
}

String getYoutubeIdFromUrl(String url) {
  if (url.contains("youtu.be")) {
    final strings = url.split("/");
    return strings.last;
  }
  var videoId = url.split("v=")[1];
  final ampersandPosition = videoId.indexOf("&");
  if (ampersandPosition != -1) {
    videoId = videoId.substring(0, ampersandPosition);
  }
  return videoId;
}

String getGfyId(String url) {
  var divided = url.split("/").last;
  if (divided.contains('-')) {
    divided = divided.split('-').first;
  }
  return divided;
}

String getStreamableId(String url) {
  final divided = url.split("/");
  return divided.last;
}

void launchURL(BuildContext context, String url) async {
  try {
    await launch(url,
        option: new CustomTabsOption(
            toolbarColor: Theme.of(context).primaryColor,
            enableDefaultShare: true,
            enableUrlBarHiding: true,
            showPageTitle: true,
            animation: new CustomTabsAnimation(
              startEnter: 'slide_up',
              startExit: 'android:anim/fade_out',
              endEnter: 'android:anim/fade_in',
              endExit: 'slide_down',
            ),
            extraCustomTabs: <String>[
              // ref. https://play.google.com/store/apps/details?id=org.mozilla.firefox
              'org.mozilla.firefox',
              // ref. https://play.google.com/store/apps/details?id=com.microsoft.emmx
              'com.microsoft.emmx',
            ]));
  } catch (e) {
    debugPrint(e.toString());
  }
}
