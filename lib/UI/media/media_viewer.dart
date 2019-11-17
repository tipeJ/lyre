import 'package:flutter/material.dart';
import 'package:lyre/Themes/textstyles.dart';
import 'package:lyre/UI/interfaces/previewCallback.dart';
import 'package:lyre/UI/interfaces/previewc.dart';
import 'package:lyre/UI/media/image_viewer/image_viewer.dart';
import 'package:lyre/UI/media/video_player/lyre_video_player.dart';
import 'package:lyre/utils/media_utils.dart';
import 'package:lyre/utils/urlUtils.dart';
import 'package:video_player/video_player.dart';

class MediaViewer extends StatelessWidget with MediaViewerCallback{
  final String url;

  Future<void> _videoInitialized;
  VideoPlayerController _videoController;
  LyreVideoController _vController;
  
  MediaViewer({@required this.url}) {
    PreviewCall().mediaViewerCallback = this; 
  }

  @override
  Widget build(BuildContext context) {
    final linkType = getLinkType(url);
    if (linkType == LinkType.DirectImage || albumLinkTypes.contains(linkType)){ 
      return ImageViewer(url);
    } else if (videoLinkTypes.contains(linkType)) {
      return FutureBuilder(
        future: handleVideoLink(linkType, url),
        builder: (context, snapshot){
          if (snapshot.connectionState == ConnectionState.done){
            return LyreVideo(
              controller: _vController,
            );
          } else {
            return const Center(child: const CircularProgressIndicator(),);
          }
        },
      );
    } 
    return const Center(child: Text("Media type not supported", style: LyreTextStyles.errorMessage,));
  }

  Future<void> handleVideoLink(LinkType linkType, String url) async {
    if (linkType == LinkType.Gfycat){
      getGfyVideoUrl(url).then((videoUrl) {
        _videoInitialized = _initializeVideo(videoUrl);
      });
    } else if (linkType == LinkType.RedditVideo){
      _videoInitialized = _initializeVideo(url, VideoFormat.dash);
    } else if (linkType == LinkType.TwitchClip){
      final clipVideoUrl = await getTwitchClipVideoLink(url);
      _videoInitialized = _initializeVideo(clipVideoUrl);
    }
    return _videoInitialized;
  }
  Future<void> _initializeVideo(String videoUrl, [VideoFormat format]) async {
    
    _videoController = VideoPlayerController.network(videoUrl, formatHint: format);
    //showVideoOverlay();
    await _videoController.initialize();
    _vController = LyreVideoController(
      showControls: true,
      aspectRatio: _videoController.value.aspectRatio,
      autoPlay: true,
      videoPlayerController: _videoController,
      looping: true,
      placeholder: CircularProgressIndicator(),
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: LyreTextStyles.errorMessage,
          ),
        );
      },
    );
  }

  @override
  bool canPopMediaViewer() {
    if (_vController != null && _vController.isFullScreen){
      _vController.exitFullScreen();
      return false;
    } else if (_vController != null) {
      _vController.pause();
      _vController.dispose();
      _videoController.dispose();
    }
    return true;
  }
}