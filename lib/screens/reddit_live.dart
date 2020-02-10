import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:lyre/Themes/themes.dart';
import 'package:lyre/widgets/media/video_player/lyre_video_player.dart';
import 'package:lyre/widgets/widgets.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:video_player/video_player.dart';

class RedditLiveScreen extends StatefulWidget {
  Submission submission;
  RedditLiveScreen({this.submission, Key key}) : super(key: key);

  @override
  _RedditLiveScreenState createState() => _RedditLiveScreenState();
}

class _RedditLiveScreenState extends State<RedditLiveScreen> {
  VideoPlayerController _videoPlayerController;
  LyreVideoController _lyreVideoController;

  @override
  void dispose() { 
    _lyreVideoController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _initializeVideo(widget.submission.data["media"]["reddit_video"]["dash_url"]),
        builder: (context, snapshot){
          if (snapshot.connectionState == ConnectionState.done){
            if (snapshot.error == null) return LyreVideo(
              controller: _lyreVideoController,
            );
            return Material(color: Colors.black26, child: Center(child: Text('ERROR: ${snapshot.error.toString()}', style: LyreTextStyles.errorMessage)));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      )
    );
  }
  Future<void> _initializeVideo(String videoUrl) async {
    
    _videoPlayerController = VideoPlayerController.network(videoUrl, formatHint: VideoFormat.dash);
    await _videoPlayerController.initialize();
    _lyreVideoController = LyreVideoController(
      showControls: true,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      autoPlay: true,
      videoPlayerController: _videoPlayerController,
      looping: true,
      placeholder: CircularProgressIndicator(),
      customControls: LyreMaterialVideoControls(
        trailing: IconButton(
          icon: const Icon(MdiIcons.arrowCollapseRight),
          tooltip: "Show Chat",
          onPressed: (){},
        ),
      ),
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
}