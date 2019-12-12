import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'lyre_video_player.dart';
import 'video_controls.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';

class LyreVideoPlayer extends StatefulWidget {
  LyreVideoPlayer({Key key}) : super(key: key);

  @override
  _LyreVideoPlayerState createState() => _LyreVideoPlayerState();
}

class _LyreVideoPlayerState extends State<LyreVideoPlayer> with SingleTickerProviderStateMixin{

  @override void initState(){
    animationController = AnimationController(vsync: this);
    animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    super.initState();
  }
  AnimationController animationController;
  CurvedAnimation animation;
  double fittedScale;
  @override
  Widget build(BuildContext context) {
    final LyreVideoController lyreVideoController = LyreVideoController.of(context);
    final aspectRatio = _calculateAspectRatio(context);
    final videoAspectRatio = lyreVideoController.videoPlayerController.value.aspectRatio;
    fittedScale = aspectRatio / videoAspectRatio;
    lyreVideoController.addListener((){
      if (lyreVideoController.expanded != expanded){
        expanded = lyreVideoController.expanded;
        if (expanded == true && aspectRatio != videoAspectRatio){
          animationController.animateTo(1.0, duration: Duration(milliseconds: 300));
        } else if (expanded == false){
          animationController.animateTo(0.0, duration: Duration(milliseconds: 300));
        }
      }
    });
    zoomController.addIgnorableListener((){
      expanded = zoomController.scale < 1.0 ? false : true;
      if (lyreVideoController.expanded != expanded){
        lyreVideoController.toggleZoom();
      }
    });
    animation.addListener((){
      zoomController.scale = (animation.value * (fittedScale -1)) + 1.0;
    });
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: _buildLyreVideoPlayer(lyreVideoController, context)
      ),
    );
  }

  bool expanded = false;

  final PhotoViewController zoomController = PhotoViewController(initialPosition: Offset.zero, initialRotation: 0.0);

  Container _buildLyreVideoPlayer(LyreVideoController lyreVideoController, BuildContext context) {
    
    return Container(
      child: Stack(
        children: <Widget>[
          lyreVideoController.placeholder ?? Container(),
          PhotoView.customChild(
            controller: zoomController,
            initialScale: MediaQuery.of(context).size.aspectRatio / lyreVideoController.videoPlayerController.value.aspectRatio,
            maxScale: 5.0,
            minScale: MediaQuery.of(context).size.aspectRatio / lyreVideoController.videoPlayerController.value.aspectRatio, //Calculates the corrent initial and minimum scale
            childSize: lyreVideoController.videoPlayerController.value.size,
            child: VideoPlayer(lyreVideoController.videoPlayerController),
          ),
          lyreVideoController.overlay ?? Container(),
          _buildControls(context, lyreVideoController),
        ],
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    LyreVideoController lyreVideoController,
  ) {
    return lyreVideoController.showControls
        ? lyreVideoController.customControls != null
            ? lyreVideoController.customControls
            : MaterialControls()
        : Container();
  }

  double _calculateAspectRatio(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return width > height ? width / height : height / width;
  }
}