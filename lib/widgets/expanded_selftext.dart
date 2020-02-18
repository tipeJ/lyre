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
          const SizedBox(height: 10.0),
          SubmissionDetailsBar(submission: submission, previewSource: PreviewSource.Comments)
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
      SubmissionDetailsBar(submission: submission, previewSource: PreviewSource.Comments)
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
  Future<void> _videoInitializer;

  @override
  void dispose() { 
    _lyreVideoController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> handleVideoLink(String url) async {
    if (widget.linkType == LinkType.Gfycat) {
      final videoUrl = await getGfyVideoUrl(url);
      _videoInitializer = _initializeVideo(videoUrl);
    } else if (widget.linkType == LinkType.RedditVideo) {
      print(widget.submission.data["media"]["reddit_video"]["dash_url"]);
      _videoInitializer = _initializeVideo(widget.submission.data["media"]["reddit_video"]["dash_url"], VideoFormat.dash);
    } else if (widget.linkType == LinkType.TwitchClip) {
      final clipVideoUrl = await getTwitchClipVideoLink(url);
      if (clipVideoUrl.contains('http')) {
        _videoInitializer = _initializeVideo(clipVideoUrl);
      } else {
        _videoInitializer = Future.error(clipVideoUrl);
      }
    }
    return _videoInitializer;
  }
  Future<void> _initializeVideo(String videoUrl, [VideoFormat format]) async {
    
    _videoPlayerController = VideoPlayerController.network(videoUrl, formatHint: format);
    await _videoPlayerController.initialize();
    _lyreVideoController = LyreVideoController(
      showControls: true,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      autoPlay: true,
      videoPlayerController: _videoPlayerController,
      looping: true,
      placeholder: const SizedBox(),
      customControls: const LyreMaterialVideoControls(),
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

  @override
  Widget build(BuildContext context) {
    if (_videoInitializer == null) _videoInitializer = handleVideoLink(widget.submission.url.toString());
    return Column(children: <Widget>[
      SafeArea(
        child: Text(widget.submission.title, style: LyreTextStyles.submissionTitle.apply(
          color: (widget.submission.stickied)
            ? const Color.fromARGB(255, 0, 200, 53)
            : Theme.of(context).textTheme.body1.color))
      ),
      Expanded(
        child: _videoPlayer
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: SubmissionDetailsBar(submission: widget.submission, previewSource: PreviewSource.Comments)
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
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: SubmissionDetailsBar(submission: submission, previewSource: PreviewSource.Comments)
      )
    ]);
  }
}