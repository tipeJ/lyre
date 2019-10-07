import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lyre/UI/video_player/lyre_video_player.dart';
import 'package:lyre/UI/video_player/video_controls.dart';
import 'package:video_player/video_player.dart';

class LyreVideoPlayer extends StatelessWidget {
  LyreVideoPlayer({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LyreVideoController lyreVideoController = LyreVideoController.of(context);

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: _buildLyreVideoPlayer(lyreVideoController, context)
      ),
    );
  }

  Container _buildLyreVideoPlayer(LyreVideoController lyreVideoController, BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
          lyreVideoController.placeholder ?? Container(),
          Center(
            child: AspectRatio(
              aspectRatio: lyreVideoController.aspectRatio ??
                  _calculateAspectRatio(context),
              child: VideoPlayer(lyreVideoController.videoPlayerController),
            ),
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