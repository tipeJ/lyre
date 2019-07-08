import 'package:flutter_youtube/flutter_youtube.dart';
import 'globals.dart';


void playYouTube(String url){
  FlutterYoutube.playYoutubeVideoByUrl(
      apiKey: youtubeApiKey,
      videoUrl: url,
      autoPlay: true,
      fullScreen: true
  );
}