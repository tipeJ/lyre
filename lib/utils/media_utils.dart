import 'dart:convert';
import 'package:lyre/Models/models.dart';
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
  final id = getGfyId(url);
  return gfycatProvider().getGfyWebmUrl(id);
}

Future<String> getStreamableVideoUrl(String url) async {
  final streamableId = getStreamableId(url);
  final response = await PostsProvider().client.get("https://ajax.streamable.com/videos/$streamableId");
  final List<LyreVideoFormat> formats = await compute(_computeStreamableResponse, response.body);
  print(formats[0].url);
  return formats[0].url;
}
Future<List<LyreVideoFormat>> getStreamableVideoFormats(String url) async {
  final streamableId = getStreamableId(url);
  final response = await PostsProvider().client.get("https://ajax.streamable.com/videos/$streamableId");
  final List<LyreVideoFormat> formats = await compute(_computeStreamableResponse, response.body);
  return formats;
}
/// Return a list of video formats from a streamable url
List<LyreVideoFormat> _computeStreamableResponse(String body) {
  // decode Json
  final j = json.decode(body);
  final status = j['status'];
  if (status != 2) {
    throw Exception("This video is currently unavailable. It may still be uploading or processing.");
  }
  List<LyreVideoFormat> formats = [];
  j['files'].forEach((formatId, format) {
    print(format.toString());
    if (format['url'] == null) return;
    formats.add(LyreVideoFormat(
      formatId: formatId,
      url: "https:${format['url']}",
      width: format['width'],
      height: format['height'],
      filesize: format['size'],
      framerate: format['framerate'].toDouble(),
      bitrate: format['bitrate'] ?? 1000,
    ));
  });
  return formats;
}