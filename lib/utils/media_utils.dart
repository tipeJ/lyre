import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/utils/urlUtils.dart';
import 'package:lyre/Resources/gfycat_provider.dart';

Future<String> getTwitchClipVideoLink(String url) async {
  final slug = url.split('/').last;
  final response = await PostsProvider().httpget(
    "https://api.twitch.tv/kraken/clips/" + slug,
    {
      "Client-ID" : TWITCH_CLIENT_ID,
      "Accept" : 'application/vnd.twitchtv.v4+json'
    }
  );
  final videoUrl = _computeTwitchResponse(response.body);
  return videoUrl;
}

String _computeTwitchResponse(String body) {
  final parsedJson = json.decode(body);
  final errorMessage = parsedJson['error'];
  return errorMessage ?? parsedJson['videoQualities'][0]['sourceURL'];
}

Future<String> getGfyVideoUrl(String url) {
  final id = getGfyid(url);
  return gfycatProvider().getGfyWebmUrl(id);
}