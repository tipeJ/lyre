import 'package:flutter/material.dart';
import 'package:lyre/Models/models.dart';
import 'package:lyre/Themes/textstyles.dart';
import 'package:lyre/screens/interfaces/previewCallback.dart';
import 'package:lyre/screens/interfaces/previewc.dart';
import 'package:lyre/widgets/media/image_viewer/image_viewer.dart';
import 'package:lyre/widgets//media/video_player/lyre_video_player.dart';
import 'package:lyre/utils/media_utils.dart';
import 'package:lyre/utils/urlUtils.dart';
import 'package:video_player/video_player.dart';

class MediaViewer extends StatefulWidget {
  final String url;

  MediaViewer({@required this.url});

  @override
  _MediaViewerState createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer>{
  Future<void> _videoInitialized;

  LyreVideoController _vController;

  @override
  Widget build(BuildContext context) {
    final linkType = getLinkType(widget.url);
    if (linkType == LinkType.DirectImage || albumLinkTypes.contains(linkType)){ 
      return ImageViewer(widget.url);
    } else if (videoLinkTypes.contains(linkType)) {
      return FutureBuilder(
        future: handleVideoLink(linkType, widget.url),
        builder: (context, snapshot){
          if (snapshot.connectionState == ConnectionState.done){
            if (snapshot.error == null) return LyreVideo(
              controller: _vController,
            );
            return Material(color: Colors.black26, child: Center(child: Text('ERROR: ${snapshot.error.toString()}', style: LyreTextStyles.errorMessage)));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      );
    } 
    return const Center(child: Material(child: Text("Media type not supported", style: LyreTextStyles.errorMessage)));
  }

  Future<void> handleVideoLink(LinkType linkType, String url) async {
    if (linkType == LinkType.Gfycat) {
      // final videoUrl = await getGfyVideoUrl(url);
      // _videoInitialized = _initializeVideo(videoUrl);
    } else if (linkType == LinkType.RedditVideo) {
      // _videoInitialized = _initializeVideo(url, VideoFormat.dash);
    } else if (linkType == LinkType.TwitchClip) {
      // final clipVideoUrl = await getTwitchClipVideoLink(url);
      // if (clipVideoUrl.contains('http')) {
      //   _videoInitialized = _initializeVideo(clipVideoUrl);
      // } else {
      //   _videoInitialized = Future.error(clipVideoUrl);
      // }
    } else if (linkType == LinkType.Streamable) {
      final videoUrl = await getStreamableVideoFormats(url);
      _videoInitialized = _initializeVideo(videoUrl);
    }
    return _videoInitialized;
  }

  Future<void> _initializeVideo(List<LyreVideoFormat> formats, [VideoFormat format]) async {
    // _videoController = VideoPlayerController.network(videoUrl, formatHint: format);
    // await _videoController.initialize();
    _vController = LyreVideoController(
      showControls: true,
      aspectRatio: formats[0].width / formats[0].height,
      autoPlay: true,
      looping: true,
      placeholder: const CircularProgressIndicator(),
      formatHint: format,
      formats: formats,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: LyreTextStyles.errorMessage
          ),
        );
      }
    );
  }

  @override
  void dispose() {
    if (_vController != null && _vController.isFullScreen){
      _vController.exitFullScreen();
    } else if (_vController != null) {
      _vController.pause().then((_){
        _vController.dispose();
        _vController = null;
      });
    }
    super.dispose();
  }
}