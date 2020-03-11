import 'package:flutter/material.dart';
import 'package:lyre/Themes/textstyles.dart';
import 'package:lyre/widgets/media/image_viewer/image_viewer.dart';
import 'package:lyre/utils/media_utils.dart';
import 'package:lyre/utils/urlUtils.dart';
import 'package:lyre/widgets/media/video_player/lyre_video_player.dart';

class MediaViewer extends StatefulWidget {
  final String url;

  MediaViewer({@required this.url});

  @override
  _MediaViewerState createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer>{

  LyreVideoController _vController;

  @override
  Widget build(BuildContext context) {
    final linkType = getLinkType(widget.url);
    if (linkType == LinkType.DirectImage || albumLinkTypes.contains(linkType)){ 
      return ImageViewer(widget.url);
    } else if (videoLinkTypes.contains(linkType)) {
      return FutureBuilder<LyreVideoController>(
        future: handleVideoLink(linkType, widget.url),
        builder: (context, snapshot){
          if (snapshot.connectionState == ConnectionState.done){
            if (snapshot.error == null) {
              _vController = snapshot.data;
              return LyreVideo(
                controller: _vController,
              );
            }
            return Material(color: Colors.black26, child: Center(child: Text('ERROR: ${snapshot.error.toString()}', style: LyreTextStyles.errorMessage)));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      );
    } 
    return const Center(child: Material(child: Text("Media type not supported", style: LyreTextStyles.errorMessage)));
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