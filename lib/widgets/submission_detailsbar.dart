import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Bloc/bloc.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Themes/themes.dart';
import 'package:lyre/screens/screens.dart';
import 'package:lyre/utils/utils.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

const _defaultColumnTextSize = 11.0;
/// Default padding between submission data wrap items
const _defaultColumnPadding = EdgeInsets.only(left: 5.0);
/// Default diameter for the award circle (gold, silver, platinum)
const _defaulColumnAwardDiameter = 6.0;

class SubmissionDetailsBar extends StatelessWidget {
  final PreviewSource previewSource;
  final Submission submission;
  const SubmissionDetailsBar({this.previewSource, this.submission, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          "${submission.score}",
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.body1.apply(color: getScoreColor(submission, context), fontSizeFactor: 0.9)),
        
        mat.Visibility(
          visible: submission.over18,
          child: const Padding(
            padding: _defaultColumnPadding,
            child: Text("NSFW", style: TextStyle(color: LyreColors.unsubscribeColor, fontSize: _defaultColumnTextSize))
          )
        ),

        mat.Visibility(
          visible: submission.spoiler,
          child: const Padding(
            padding: _defaultColumnPadding,
            child: Text("SPOILER", style: TextStyle(color: LyreColors.unsubscribeColor, fontSize: _defaultColumnTextSize))
          )
        ),

        submission.linkFlairText != null
          ? Padding(
              padding: _defaultColumnPadding,
              child: Text(submission.linkFlairText, style: TextStyle(fontSize: _defaultColumnTextSize))
            )
          : null,

        previewSource == PreviewSource.PostsList
        ? BlocBuilder<PostsBloc, PostsState>(
            builder: (context, state) {
              return mat.Visibility(
                visible: !(state.contentSource == ContentSource.Redditor && state.target == submission.author.toLowerCase()),
                child: _authorText(context),
              );
            },
          )
          : _authorText(context),
        previewSource == PreviewSource.PostsList
          ? BlocBuilder<PostsBloc, PostsState>(
            builder: (context, state) {
              return mat.Visibility(
                visible: !(state.contentSource == ContentSource.Subreddit && state.target == submission.subreddit.displayName.toLowerCase()),
                child: _subRedditText(context)
              );
            },
          )
          : _subRedditText(context),
        Padding(
          child: Text(
            "● ${submission.numComments} comments",
            style: TextStyle(
              color: Theme.of(context).textTheme.body2.color,
              fontSize: _defaultColumnTextSize,
            )
          ),
          padding: _defaultColumnPadding,
        ),
        Padding(
          child: Text(
            "● ${getSubmissionAge(submission.createdUtc)}",
            style: TextStyle(
              color: Theme.of(context).textTheme.body2.color,
              fontSize: _defaultColumnTextSize,
            )
          ),
          padding: _defaultColumnPadding,
        ),
        submission.isSelf ? null :
          Padding(
              child: Text(
                  "● ${submission.domain}",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.body2.color,
                    fontSize: _defaultColumnTextSize,
                  ),
                  textAlign: TextAlign.left,),
              padding: _defaultColumnPadding),
        mat.Visibility(
          visible: submission.gold != null,
          child: Padding(
              child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromARGB(255, 255, 223, 0),
                  ),
                  width: _defaulColumnAwardDiameter,
                  height: _defaulColumnAwardDiameter
                ),
              padding: _defaultColumnPadding,
            )
        ),
        mat.Visibility(
          visible: submission.silver != null,
          child: Padding(
              child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromARGB(255, 192, 192, 192),
                  ),
                  width: _defaulColumnAwardDiameter,
                  height: _defaulColumnAwardDiameter
                ),
              padding: _defaultColumnPadding,
            )
        ),
        mat.Visibility(
          visible: submission.platinum != null,
          child: Padding(
              child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromARGB(255, 100, 225, 255),
                  ),
                  width: _defaulColumnAwardDiameter,
                  height: _defaulColumnAwardDiameter
                ),
              padding: _defaultColumnPadding,
            )
        ),
          
    ].where(notNull).toList()
    );
  }
  Widget _authorText(BuildContext context) {
    return Padding(
      child: Text.rich(
        TextSpan(
          style: Theme.of(context).textTheme.body2,
          children: <TextSpan> [
            const TextSpan(
              text: "● ",
            ),
            TextSpan(
              text: "u/${submission.author}",
              style: Theme.of(context).textTheme.body2,
            )
          ]
        ),
        textAlign: TextAlign.left),
      padding: _defaultColumnPadding);
  }
  Widget _subRedditText(BuildContext context) {
    return Padding(
      child: Text.rich(
        TextSpan(
          style: Theme.of(context).textTheme.body2,
          children: <TextSpan> [
            const TextSpan(
              text: "● ",
            ),
            TextSpan(
              text: "r/${submission.subreddit.displayName}",
              style: TextStyle(fontSize: _defaultColumnTextSize, color: Theme.of(context).textTheme.body1.color),
            )
          ]
        ),
        textAlign: TextAlign.left),
      padding: _defaultColumnPadding);
  }
}
class SubmissionDetailsAppBar extends StatefulWidget {
  final Submission submission;
  const SubmissionDetailsAppBar({@required this.submission, Key key}) : super(key: key);

  @override
  _SubmissionDetailsAppBarState createState() => _SubmissionDetailsAppBarState();
}

class _SubmissionDetailsAppBarState extends State<SubmissionDetailsAppBar> {
  VoteState _voteState;
  bool _saved;

  @override
  void initState() {
    _voteState = widget.submission.vote;
    _saved = widget.submission.saved;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        BlocBuilder<CommentsBloc, CommentsState>(
          builder: (_, state) => IconButton(
            icon: Icon(state.showSubmission ? MdiIcons.arrowCollapseLeft : MdiIcons.arrowCollapseRight, color: Colors.grey),
            tooltip: state.showSubmission ? "Hide Submission" : "Show Submission",
            onPressed: () {
              BlocProvider.of<CommentsBloc>(context).add(ToggleSubmissionView());
            }
          )),
        Expanded(
          child: SubmissionDetailsBar(submission: widget.submission, previewSource: PreviewSource.Comments)
        ),
        Row(children: <Widget>[
          IconButton(
            icon: Icon(
              MdiIcons.arrowUpBold,
              color: _voteState == VoteState.upvoted ? Colors.amber : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _voteState = _voteState == VoteState.upvoted ? VoteState.none : VoteState.upvoted;
              });
            },
          ),
          IconButton(
            icon: Icon(
              MdiIcons.arrowDownBold,
              color: _voteState == VoteState.downvoted ? Colors.purple : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _voteState = _voteState == VoteState.downvoted ? VoteState.none : VoteState.downvoted;
              });
            },
          ),
          IconButton(
            icon: Icon(
              _saved ? Icons.bookmark : Icons.bookmark_border,
              color: _saved ? Colors.amber : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _saved = !_saved;
              });
            },
          ),
          BlocBuilder<CommentsBloc, CommentsState>(
            builder: (context, state) => DropdownButton(
              value: state.sortTypeString(),
              items: List<DropdownMenuItem<String>>.generate(commentSortTypes.length - 1, (int i) => 
                DropdownMenuItem<String>(
                  value: commentSortTypes[i],
                  child: Text(commentSortTypes[i], style: const TextStyle(color: Colors.grey)),
                ),
              ),
              underline: const SizedBox(),
              onChanged: (str) => BlocProvider.of<CommentsBloc>(context).add(SortChanged(commentSortType: parseCommentSortType(str))),
            ),
          )
        ])
      ]
    );
  }
}