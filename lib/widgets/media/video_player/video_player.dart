import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lyre/Models/models.dart';
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

  static const _animationDuration = Duration(milliseconds: 300);

  @override void initState(){
    animationController = AnimationController(vsync: this);
    animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    super.initState();
  }

  @override
  void dispose() { 
    animationController.dispose();
    super.dispose();
  }

  AnimationController animationController;
  CurvedAnimation animation;
  double fittedScale;

  LyreVideoFormat _currentFormat;
  
  @override
  Widget build(BuildContext context) {
    final LyreVideoController lyreVideoController = LyreVideoController.of(context);
    _currentFormat = lyreVideoController.currentFormat;
    final aspectRatio = _calculateAspectRatio(context);
    final videoAspectRatio = lyreVideoController.videoPlayerController.value.aspectRatio;
    fittedScale = aspectRatio / videoAspectRatio;
    lyreVideoController.addListener((){
      if (lyreVideoController.expanded != expanded){
        expanded = lyreVideoController.expanded;
        if (expanded == true && aspectRatio != videoAspectRatio){
          animationController.animateTo(1.0, duration: _animationDuration);
        } else if (expanded == false){
          animationController.animateTo(0.0, duration: _animationDuration);
        }
      } else if (lyreVideoController.currentFormat != _currentFormat) setState(() {
        print("SETTET STATE");
      });
    });
    zoomController.addIgnorableListener((){
      expanded = zoomController.scale < 1.0 ? false : true;
      if (lyreVideoController.expanded != expanded){
        lyreVideoController.toggleZoom();
      }
    });
    animation.addListener((){
      zoomController.scale = (animation.value * (PhotoViewComputedScale.covered.multiplier)) + 1.0;
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
            initialScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered,
            minScale: PhotoViewComputedScale.contained, //Calculates the corrent initial and minimum scale
            childSize: Size(_currentFormat.width.toDouble(), _currentFormat.height.toDouble()),
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
    print('rebuild');
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