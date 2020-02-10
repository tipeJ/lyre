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

const double _chatBoxWidth = 300.0;

class _RedditLiveScreenState extends State<RedditLiveScreen> {

  VideoPlayerController _videoPlayerController;
  LyreVideoController _lyreVideoController;
  Future<void> _videoInitializer;

  bool _largeLayout = false;
  bool _chatVisible = true;

  @override
  void dispose() { 
    _lyreVideoController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoInitializer == null) _videoInitializer = _initializeVideo(widget.submission.data["media"]["reddit_video"]["dash_url"]);
    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        double aspectRatio = constraints.maxWidth / constraints.maxHeight;
        if (aspectRatio > 1.0 && constraints.maxWidth > 800.0) _largeLayout = true;
        return _largeLayout ? _splitLayout : _videoPlayer;
      })
    );
  }

  Widget get _videoPlayer => FutureBuilder(
    future: _videoInitializer,
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
  );
  Row get _splitLayout => Row(children: <Widget>[
    Expanded(
      child: _videoPlayer,
    ),
    AnimatedContainer(
      width: _chatVisible ? _chatBoxWidth : 0.0,
      curve: Curves.ease,
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: Colors.red,
      ),
    )
  ],);

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
          onPressed: (){
            setState(() {
              _chatVisible = !_chatVisible;
            });
          },
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