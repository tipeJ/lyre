import 'dart:convert';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/utils/urlUtils.dart';
import 'package:lyre/Resources/gfycat_provider.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:flutter/foundation.dart';

Future<String> getTwitchClipVideoLink(String url) async {
  final slug = url.split('/').last;
  final response = await PostsProvider().client.post('https://gql.twitch.tv/gql', body: json.encode({'query' : '''{
    clip(slug: "$slug") {
      broadcaster {
        displayName
      }
      createdAt
      curator {
        displayName
        id
      }
      durationSeconds
      id
      tiny: thumbnailURL(width: 86, height: 45)
      small: thumbnailURL(width: 260, height: 147)
      medium: thumbnailURL(width: 480, height: 272)
      title
      videoQualities {
        frameRate
        quality
        sourceURL
      }
      viewCount
    }
  }'''}), headers: {'Client-ID' : TWITCH_CLIENT_ID});
  final videoUrl = await compute(_computeTwitchResponse, response.body);
  return videoUrl;
}

String _computeTwitchResponse(String body) {
  final parsedJson = json.decode(body);
  final errorMessage = parsedJson['errors'];
  return errorMessage ?? parsedJson['data']['clip']['videoQualities'][0]['sourceURL'];
}

Future<String> getGfyVideoUrl(String url) {
  final id = getGfyid(url);
  return gfycatProvider().getGfyWebmUrl(id);
}