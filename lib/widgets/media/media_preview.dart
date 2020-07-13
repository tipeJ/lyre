import 'package:flutter/material.dart';
import 'package:lyre/Themes/themes.dart';
import 'package:lyre/screens/screens.dart';
import 'package:lyre/utils/utils.dart';
import 'package:lyre/widgets/media/image_viewer/image_viewer.dart';
import 'package:video_player/video_player.dart';

class MediaPreview extends StatelessWidget with MediaViewerCallback {
  final String url;
  LinkType linkType;

  MediaPreview({@required this.url, Key key}) : assert(url != null) {
    linkType = getLinkType(url);
  }

  VideoPlayerController _videoPlayerController;

  @override
  Widget build(BuildContext context) {
    final linkType = getLinkType(url);
    if (linkType == LinkType.DirectImage || albumLinkTypes.contains(linkType)) {
      return ImageViewer(url);
    } else if (videoLinkTypes.contains(linkType)) {
      return FutureBuilder<void>(
        future: _handleVideoLink(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.error == null) {
              _videoPlayerController.play();
              final double scaleRatio = MediaQuery.of(context).size.width /
                  _videoPlayerController.value.size.width;
              return Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                      constraints: BoxConstraints.expand(
                          width: _videoPlayerController.value.size.width *
                              scaleRatio,
                          height: _videoPlayerController.value.size.height *
                              scaleRatio),
                      child: VideoPlayer(_videoPlayerController)));
            }
            return Material(
                color: Colors.black26,
                child: Center(
                    child: Text('ERROR: ${snapshot.error.toString()}',
                        style: LyreTextStyles.errorMessage)));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      );
    }
    return const Text("Media type not supported");
  }

  Future<void> _handleVideoLink() async {
    if (linkType == LinkType.Gfycat) {
      final videoUrl = await getGfyVideoUrl(url);
      _videoPlayerController = VideoPlayerController.network(videoUrl);
    } else if (linkType == LinkType.RedGifs) {
      final videoUrl = await getRedGifVideoUrl(url);
      _videoPlayerController = VideoPlayerController.network(videoUrl);
    } else if (linkType == LinkType.RedditVideo) {
      _videoPlayerController =
          VideoPlayerController.network(url, formatHint: VideoFormat.dash);
    } else if (linkType == LinkType.TwitchClip) {
      final clipVideoUrl = await getTwitchClipVideoLink(url);
      if (clipVideoUrl.contains('http')) {
        _videoPlayerController = VideoPlayerController.network(clipVideoUrl);
      } else {
        return Future.error(clipVideoUrl);
      }
    } else if (linkType == LinkType.Streamable) {
      final formats = await getStreamableVideoFormats(url);
      _videoPlayerController = VideoPlayerController.network(formats[0].url);
    } else {
      return Future.error("MEDIA NOT SUPPORTED");
    }
    return _videoPlayerController.initialize();
  }

  @override
  Future<bool> canPopMediaViewer() {
    if (_videoPlayerController != null) {
      _videoPlayerController.pause().then((_) {
        _videoPlayerController.dispose();
        _videoPlayerController = null;
        return Future.value(true);
      });
    }
    return Future.value(true);
  }
}
