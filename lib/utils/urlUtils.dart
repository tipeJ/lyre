import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

import 'imageUtils.dart';

final supportedYoutubeUrls = [
    "youtube.com",
    "youtu.be"
];

enum LinkType{
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
  Streamable, // ! Not yet supported
  TwitchClip,
  RPAN,
}

final videoLinkTypes = [
  LinkType.Gfycat,
  LinkType.RedditVideo,
  LinkType.Streamable,
  LinkType.TwitchClip,
  LinkType.RPAN
];

final albumLinkTypes = [
  LinkType.ImgurAlbum
];

String getYoutubeIdFromUrl(String url){
  if (url.contains("youtu.be")){
    var strings = url.split("/");
    return strings.last;
  }
  var video_id = url.split("v=")[1];
  var ampersandPosition = video_id.indexOf("&");
  if (ampersandPosition != -1){
    video_id = video_id.substring(0,ampersandPosition);
  }
  return video_id;
}

LinkType getLinkType(String url){

  if (url.contains("preview.redd.it")) return LinkType.DirectImage;

  var divided = url.split(".");

  final uri = Uri.parse(url);
  final domain = uri.authority;

  var last = divided.last;
  if (supportedFormats.contains(last)){
    return LinkType.DirectImage;
  } else if (url.contains("youtube.com") || url.contains("youtu.be")){
    return LinkType.YouTube;
  } else if (url.contains("imgur.com/a/")) {
    return LinkType.ImgurAlbum;
  } else if (url.contains("gfycat.com")){
    return LinkType.Gfycat;
  } else if (url.contains("v.redd.it")){
    return LinkType.RedditVideo;
  } else if (
    domain.endsWith("reddit.com") ||
    domain.endsWith("redd.it") ||
    domain.contains("i.reddit.com") ||
    (domain.contains("google") && uri.path.startsWith("/amp/s/amp.reddit.com"))
  ) {
    return LinkType.Internal;
  }
  // ! API BLOCKED, NO LONGER (YET) SUPPORTED
  // else if(url.contains("clips.twitch.tv")){
  //   return LinkType.TwitchClip;
  // }

  return LinkType.Default;
}

String getGfyid(String url){
  var divided = url.split("/");
  var last = divided.last;
  return last;
}

void launchURL(BuildContext context, String url) async {
  try{
    await launch(
        url,
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
          ]
        )
    );
  }catch(e){
    debugPrint(e.toString());
  }
}