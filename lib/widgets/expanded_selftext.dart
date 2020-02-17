import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Themes/textstyles.dart';
import 'package:lyre/screens/screens.dart';
import 'package:lyre/widgets/widgets.dart';

class ExpandedSelftextPostWidget extends StatelessWidget {
  final Submission submission;
  const ExpandedSelftextPostWidget({this.submission, Key key}) : super(key: key);

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