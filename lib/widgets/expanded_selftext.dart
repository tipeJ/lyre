import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Themes/textstyles.dart';
import 'package:lyre/screens/screens.dart';
import 'package:lyre/utils/utils.dart';
import 'package:lyre/widgets/widgets.dart';
import 'package:video_player/video_player.dart';
import 'package:lyre/widgets/media/video_player/lyre_video_player.dart';

class ExpandedPostWidget extends StatelessWidget {
  final Submission submission;
  const ExpandedPostWidget({this.submission, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (submission.isSelf && submission.selftext.isNotEmpty) {
      return _ExpandedSelftextPostWidget(submission);
    }
    final linkType = getLinkType(submission.url.toString());
    if (linkType == LinkType.DirectImage) {
      return _ExpandedImagePostWidget(submission);
    } else if (videoLinkTypes.contains(linkType)) {
      return _ExpandedVideoWidget(submission, linkType);
    }
    return _ExpandedWebviewPostWidget(submission);
  }
}

class _ExpandedSelftextPostWidget extends StatelessWidget {
  final Submission submission;
  const _ExpandedSelftextPostWidget(this.submission, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(right: screenSplitterWidth),
      child: ListView(
        padding: const EdgeInsets.all(10.0),
        children: <Widget>[
          SafeArea(
            child: Text(submission.title, style: LyreTextStyles.submissionTitle.apply(
              color: (submission.stickied)
                ? const Color.fromARGB(255, 0, 200, 53)
                : Theme.of(context).textTheme.body1.color)),
          ),
          const SizedBox(height: 10.0),
          Text(submission.selftext),
        ]
      )
    );
  }
}
class _ExpandedImagePostWidget extends StatelessWidget {
  final Submission submission;
  const _ExpandedImagePostWidget(this.submission, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      SafeArea(
        child: Text(submission.title, style: LyreTextStyles.submissionTitle.apply(
          color: (submission.stickied)
            ? const Color.fromARGB(255, 0, 200, 53)
            : Theme.of(context).textTheme.body1.color))
      ),
      Expanded(
        child: GestureDetector(
          child: Image(
            image: AdvancedNetworkImage(submission.url.toString()),
          ),
          onTap: () => PreviewCall().callback.preview(submission.url.toString()),
          onLongPress: () => PreviewCall().callback.preview(submission.url.toString()),
          onLongPressEnd: (details) => PreviewCall().callback.previewEnd(),
        )
      ),
    ]);
  }
}
class _ExpandedVideoWidget extends StatefulWidget {
  final Submission submission;
  final LinkType linkType;
  const _ExpandedVideoWidget(this.submission, this.linkType, {Key key}) : super(key: key);

  @override
  __ExpandedVideoWidgetState createState() => __ExpandedVideoWidgetState();
}

class __ExpandedVideoWidgetState extends State<_ExpandedVideoWidget> {
  VideoPlayerController _videoPlayerController;
  LyreVideoController _lyreVideoController;
  Future<LyreVideoController> _videoInitializer;
  @override
  void dispose() { 
    _lyreVideoController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Widget get _videoPlayer => FutureBuilder<LyreVideoController>(
    future: _videoInitializer,
    builder: (context, snapshot){
      if (snapshot.connectionState == ConnectionState.done){
        if (snapshot.error == null) {
          _lyreVideoController = snapshot.data..customControls = LyreMaterialVideoControls(
            trailing: widget.linkType == LinkType.RPAN ? Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.fullscreen),
                tooltip: "Show Chat",
                onPressed: () {
                  _lyreVideoController.pause();
                  PreviewCall().callback.preview(widget.linkType == LinkType.RedditVideo ? widget.submission.data["media"]["reddit_video"]["dash_url"] : widget.submission.url.toString());
                }
              )
            ) : const SizedBox(),
          )..placeholder = const SizedBox();
          return LyreVideo(controller: _lyreVideoController);
        };
        return Material(color: Colors.black26, child: Center(child: Text('ERROR: ${snapshot.error.toString()}', style: LyreTextStyles.errorMessage)));
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    if (_videoInitializer == null) _videoInitializer = handleVideoLink(widget.linkType, widget.submission.url.toString());
    return Column(children: <Widget>[
      SafeArea(
        child: Text(widget.submission.title, style: LyreTextStyles.submissionTitle.apply(
          color: (widget.submission.stickied)
            ? const Color.fromARGB(255, 0, 200, 53)
            : Theme.of(context).textTheme.body1.color))
      ),
      Expanded(
        child: _videoPlayer
      )
    ]);
  }
}
class _ExpandedWebviewPostWidget extends StatelessWidget {
  final Submission submission;
  const _ExpandedWebviewPostWidget(this.submission, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(submission.title, style: LyreTextStyles.submissionTitle.apply(
            color: (submission.stickied)
              ? const Color.fromARGB(255, 0, 200, 53)
              : Theme.of(context).textTheme.body1.color))
        ),
      ),
      Expanded(
        child: InAppWebView(initialUrl: submission.url.toString())
      )
    ]);
  }
}