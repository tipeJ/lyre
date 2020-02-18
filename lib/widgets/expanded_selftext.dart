import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Themes/textstyles.dart';
import 'package:lyre/screens/screens.dart';
import 'package:lyre/utils/utils.dart';
import 'package:lyre/widgets/widgets.dart';

class ExpandedPostWidget extends StatelessWidget {
  final Submission submission;
  const ExpandedPostWidget({this.submission, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (submission.isSelf && submission.selftext.isNotEmpty) {
      return _ExpandedSelftextPostWidget(submission: submission);
    }
    final linkType = getLinkType(submission.url.toString());
    if (linkType == LinkType.DirectImage) {
      return _ExpandedImagePostWidget(submission: submission);
    }
    return const Text("ERROR: Expanded PostView");
  }
}

class _ExpandedSelftextPostWidget extends StatelessWidget {
  final Submission submission;
  const _ExpandedSelftextPostWidget({this.submission, Key key}) : super(key: key);

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
  const _ExpandedImagePostWidget({this.submission, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Text(submission.title, style: LyreTextStyles.submissionTitle.apply(
        color: (submission.stickied)
          ? const Color.fromARGB(255, 0, 200, 53)
          : Theme.of(context).textTheme.body1.color)),
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