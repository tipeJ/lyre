import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lyre/Models/models.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Themes/themes.dart';
import 'package:lyre/utils/urlUtils.dart';
import 'package:lyre/Resources/gfycat_provider.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:flutter/foundation.dart';
import 'package:lyre/widgets/media/video_player/lyre_video_player.dart';
import 'package:video_player/video_player.dart';
import 'package:xml_parser/xml_parser.dart';

/// Prepare a video URL for playback via a [LyreVideoController]
Future<LyreVideoController> handleVideoLink(
    LinkType linkType, String url) async {
  if (linkType == LinkType.Gfycat) {
    final videoUrl = await getGfyVideoUrl(url);
    return _initializeVideo(url: videoUrl);
  } else if (linkType == LinkType.RedGifs) {
    final videoUrl = await getRedGifVideoUrl(url);
    return _initializeVideo(url: videoUrl);
  } else if (linkType == LinkType.RedditVideo) {
    final formats = await getRedditVideoFormats(url);
    return _initializeVideo(formats: formats);
  } else if (linkType == LinkType.TwitchClip) {
    final clipVideoUrl = await getTwitchClipVideoLink(url);
    if (clipVideoUrl.contains('http')) {
      return _initializeVideo(url: clipVideoUrl);
    } else {
      return Future.error(clipVideoUrl);
    }
  } else if (linkType == LinkType.Streamable) {
    final formats = await getStreamableVideoFormats(url);
    return _initializeVideo(formats: formats);
  }
  return Future.error("MEDIA NOT SUPPORTED");
}

/// Initialize the video source. Use a string url for single-source videos and a
/// list of [LyreVideoFormat]s for videos with multiple formats/qualities
Future<LyreVideoController> _initializeVideo(
    {List<LyreVideoFormat> formats, String url, VideoFormat formatHint}) async {
  VideoPlayerController videoController;
  if (url != null) {
    videoController =
        VideoPlayerController.network(url, formatHint: formatHint);
    await videoController.initialize();
  }
  return LyreVideoController(
      sourceUrl: url,
      showControls: true,
      aspectRatio: videoController != null
          ? videoController.value.aspectRatio
          : formats[0].width / formats[0].height,
      autoPlay: true,
      looping: true,
      placeholder: const CircularProgressIndicator(),
      formatHint: formatHint,
      formats: formats,
      videoPlayerController: videoController,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(errorMessage, style: LyreTextStyles.errorMessage),
        );
      });
}

Future<String> getTwitchClipVideoLink(String url) async {
  final slug = url.split('/').last;
  final response =
      await PostsProvider().client.post('https://gql.twitch.tv/gql',
          body: json.encode({
            'query': '''{
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
  }'''
          }),
          headers: {'Client-ID': TWITCH_CLIENT_ID});
  final videoUrl = await compute(_computeTwitchResponse, response.body);
  return videoUrl;
}

String _computeTwitchResponse(String body) {
  final parsedJson = json.decode(body);
  final errorMessage = parsedJson['errors'];
  return errorMessage ??
      parsedJson['data']['clip']['videoQualities'][0]['sourceURL'];
}

Future<String> getGfyVideoUrl(String url) {
  final id = getGfyId(url);
  return gfycatProvider().getGfyWebmUrl(id);
}

Future<String> getRedGifVideoUrl(String url) async {
  final id = getGfyId(url);
  final response = await PostsProvider()
      .client
      .get("https://www.gifdeliverynetwork.com/$id");
  final splitBody = response.body.split('"');
  final sourceUrl = splitBody[splitBody.indexOf("mp4Source") + 2];
  return sourceUrl;
}

// * Streamable
Future<String> getStreamableVideoUrl(String url) async {
  final streamableId = getStreamableId(url);
  final response = await PostsProvider()
      .client
      .get("https://ajax.streamable.com/videos/$streamableId");
  final List<LyreVideoFormat> formats =
      await compute(_computeStreamableResponse, response.body);
  return formats[0].url;
}

Future<List<LyreVideoFormat>> getStreamableVideoFormats(String url) async {
  final streamableId = getStreamableId(url);
  final response = await PostsProvider()
      .client
      .get("https://ajax.streamable.com/videos/$streamableId");
  final List<LyreVideoFormat> formats =
      await compute(_computeStreamableResponse, response.body);
  return formats;
}

/// Return a list of video formats from a streamable url
List<LyreVideoFormat> _computeStreamableResponse(String body) {
  // decode Json
  final j = json.decode(body);
  final status = j['status'];
  if (status != 2) {
    throw Exception(
        "This video is currently unavailable. It may still be uploading or processing.");
  }
  List<LyreVideoFormat> formats = [];
  j['files'].forEach((formatId, format) {
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

// TODO: Audio is not working on reddit multi-quality videos
// * Reddit Internal Videos
Future<List<LyreVideoFormat>> getRedditVideoFormats(String playlistUrl) async {
  final baseUrl = playlistUrl.replaceAll("DASHPlaylist.mpd", "");
  List<LyreVideoFormat> formats = [];
  final playlist = await PostsProvider().client.get(playlistUrl);
  final xmlDoc = await compute(XmlDocument.fromString, playlist.body);
  final List<XmlElement> formatElements = xmlDoc
      .getElement("AdaptationSet")
      .getElementsWhere(name: 'Representation');
  formatElements.forEach((fe) => formats.add(LyreVideoFormat(
        formatId: fe.getAttribute('mimeType').split('/').last,
        url: baseUrl + fe.getElement('BaseURL').text,
        width: int.parse(fe.getAttribute('width')),
        height: int.parse(fe.getAttribute('height')),
        framerate: double.parse(fe.getAttribute('frameRate')),
        filesize: int.parse(fe.getAttribute('bandwidth')),
      )));
  return formats;
}
