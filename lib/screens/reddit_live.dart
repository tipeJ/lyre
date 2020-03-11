import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/Themes/themes.dart';
import 'package:lyre/widgets/media/video_player/lyre_video_player.dart';
import 'package:lyre/widgets/widgets.dart';
import 'package:video_player/video_player.dart';

class RedditLiveScreen extends StatefulWidget {
  Submission submission;
  RedditLiveScreen({this.submission, Key key}) : super(key: key);

  @override
  _RedditLiveScreenState createState() => _RedditLiveScreenState();
}

const double _chatBoxWidth = 400.0;

class _RedditLiveScreenState extends State<RedditLiveScreen> {

  VideoPlayerController _videoPlayerController;
  LyreVideoController _lyreVideoController;
  Future<void> _videoInitializer;

  TextEditingController _chatController;

  bool _largeLayout = false;
  bool _chatVisible = true;

  @override
  void initState() {
    // TODO: implement initState
    _chatController = TextEditingController();
  }

  @override
  void dispose() { 
    _lyreVideoController?.dispose();
    _videoPlayerController?.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoInitializer == null) _videoInitializer = _initializeVideo(widget.submission.url.toString());
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            height: 50.0,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Chat",
                style: Theme.of(context).primaryTextTheme.title,
              )
            ),
          ),
          // Expanded(
          //   child: ListView.builder(
          //     reverse: true,
          //     itemCount: widget.submission.comments.length,
          //     itemBuilder: (context, i) {
          //       if (widget.submission.comments[i] is Comment) return Container(
          //         color: Theme.of(context).cardColor,
          //         child: CommentContent(widget.submission.comments[i], PreviewSource.Comments)
          //       );
          //       // Return empty if MoreComments
          //       return const SizedBox();
          //     },
          //   ),
          // ),
          Expanded(child: const Center(child: Text("Live comments disabled until further notice"))),
          Material(
              color: Theme.of(context).cardColor,
            child: Container(
              height: 50.0,
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Row(children: <Widget>[
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).canvasColor,
                      borderRadius: BorderRadius.circular(BlocProvider.of<LyreBloc>(context).state.currentTheme.borderRadius.toDouble())
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: "Reply",
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabled: !BlocProvider.of<LyreBloc>(context).state.readOnly
                      ),
                      onSubmitted: (str) => print(str),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  tooltip: "Send",
                  onPressed: () async {
                    if (_chatController.text.isEmpty || BlocProvider.of<LyreBloc>(context).state.readOnly) return;
                    widget.submission.reply(_chatController.text);
                    _chatController.clear();
                  },
                )
              ],),
            )
          ),
        ],
      ),
    )
  ],);

  Future<void> _initializeVideo(String videoUrl) async {
    
    _videoPlayerController = VideoPlayerController.network(videoUrl, formatHint: VideoFormat.hls);
    await _videoPlayerController.initialize();
    _lyreVideoController = LyreVideoController(
      showControls: true,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      autoPlay: true,
      // videoPlayerController: _videoPlayerController,
      looping: true,
      placeholder: CircularProgressIndicator(),
      customControls: LyreMaterialVideoControls(
        trailing: Material(
          color: Colors.transparent,
          child: IconButton(
            icon: const Icon(Icons.chat_bubble),
            tooltip: "Show Chat",
            onPressed: (){
              setState(() {
                _chatVisible = !_chatVisible;
              });
            },
          )
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