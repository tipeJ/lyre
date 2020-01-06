import 'package:draw/draw.dart';
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
  //Images
  DirectImage,
  ImgurAlbum,
  //Videos:
  YouTube,
  RedditVideo,
  Gfycat,
  Streamable, // ! Not yet supported
  TwitchClip,
}

final videoLinkTypes = [
  LinkType.Gfycat,
  LinkType.RedditVideo,
  LinkType.Streamable,
  LinkType.TwitchClip
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

  var last = divided.last;
  if (supportedFormats.contains(last)){
    return LinkType.DirectImage;
  } else if (url.contains("youtube.com") || url.contains("youtu.be")){
    return LinkType.YouTube;
  } else if(url.contains("imgur.com/a/")) {
    return LinkType.ImgurAlbum;
  } else if (url.contains("gfycat.com")){
    return LinkType.Gfycat;
  } else if(url.contains("v.redd.it")){
    return LinkType.RedditVideo;
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

bool isRedditUrl (String url) {
  return url.contains(".reddit.com") ? true : false;
}

void launchURL(BuildContext context, dynamic source) async {
  String url;
  if (source is Submission){
    url = source.url.toString();
  } else {
    url = source;
  }
  if (isRedditUrl(url)) {
    // TODO: Implement general Reddit content parsing
  }
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