import 'imageUtils.dart';

var supportedYoutubeUrls = [
    "youtube.com",
    "youtu.be"
];
enum LinkType{
  Self,
  Default,
  YouTube,
  DirectImage,
  Gfycat
}
String getYoutubeIdFromUrl(String url){
  if(url.contains("youtu.be")){
    var strings = url.split("/");
    return strings.last;
  }
  var video_id = url.split("v=")[1];
  var ampersandPosition = video_id.indexOf("&");
  if(ampersandPosition != -1){
    video_id = video_id.substring(0,ampersandPosition);
  }
  return video_id;
}

LinkType getLinkType(String url){
  var divided = url.split(".");
  var last = divided.last;
  if(supportedFormats.contains(last)){
    return LinkType.DirectImage;
  }else if(url.contains("youtube.com") || url.contains("youtu.be")){
    return LinkType.YouTube;
  }
  return LinkType.Default;
}