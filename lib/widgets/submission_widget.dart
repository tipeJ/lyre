import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lyre/Models/models.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Themes/textstyles.dart';
import 'package:lyre/screens/interfaces/previewCallback.dart';
import 'package:lyre/Bloc/bloc.dart';
import 'package:lyre/utils/utils.dart';

const _defaultColumnTextSize = 11.0;

class SubmissionWidget extends StatelessWidget {
  final Submission submission;
  final PreviewSource previewSource;
  final VoidCallback onTitleClick;
  final VoidCallback onCommentsClick;

  const SubmissionWidget({
    @required this.submission, 
    @required this.previewSource,
    @required this.onTitleClick,
    @required this.onCommentsClick
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      child: InkWell(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  child: Text(
                    submission.title,
                    style: LyreTextStyles.submissionTitle.apply(
                      color: (submission.stickied)
                        ? Color.fromARGB(255, 0, 200, 53)
                        : Colors.white),
                  ),
                  onTap: onTitleClick,
                ),
                padding:
                    const EdgeInsets.only(left: 6.0, right: 16.0, top: 6.0, bottom: 0.0)),
            Wrap(
              children: <Widget>[
                Padding(
                  child: Text(
                    "${submission.score}",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: _defaultColumnTextSize,
                      color: Colors.grey)),
                  padding:
                      const EdgeInsets.only(left: 4.0, right: 4.0)),
                Padding(
                  child: Text(
                    "u/${submission.author}",
                    style: TextStyle(
                      fontSize: _defaultColumnTextSize,
                    ),
                    textAlign: TextAlign.left,),
                  padding:
                    const EdgeInsets.only(right: 4.0)),
                Padding(
                          child: Text(
                            "r/${submission.subreddit}",
                            style: TextStyle(
                              fontSize: _defaultColumnTextSize,
                              color: Theme.of(context).accentColor
                            ),
                            textAlign: TextAlign.left,),
                          padding:
                            const EdgeInsets.only(left: 0.0, right: 4.0, top: 0.0)),
                Text(
                  "${submission.numComments} comments",
                  style: TextStyle(
                    fontSize: _defaultColumnTextSize,
                  )
                ),
            ]
            ),
            const SizedBox(
              height: 35.5,
            )
          ]),
        onTap: (){
          BlocProvider.of<PostsBloc>(context).add(FetchMore());
        },
      )
    );
    return Material(
      color: Theme.of(context).cardColor,
      child: InkWell(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  child: Text(
                    submission.title,
                    style: LyreTextStyles.submissionTitle.apply(
                      color: (submission.stickied)
                        ? Color.fromARGB(255, 0, 200, 53)
                        : Colors.white),
                  ),
                  onTap: onTitleClick,
                ),
                padding:
                    const EdgeInsets.only(left: 6.0, right: 16.0, top: 6.0, bottom: 0.0)),
            (submission.isSelf && submission.selftext != null && submission.selftext.isNotEmpty)
              ? Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10.0)
                ),
                child: Container(),
                padding: const EdgeInsets.only(
                  left: 8.0,
                  right: 8.0,
                  top: 8.0,
                  bottom: 8.0
                ),
                margin: const EdgeInsets.only(
                  left: 8.0,
                  right: 8.0,
                  top: 8.0,
                  bottom: 8.0
                ),
              )
            : Container(height: 3.5),
            Wrap(
              children: <Widget>[
                submission.over18
                  ? Padding(
                    padding: const EdgeInsets.only(left: 6.0, right: 4.0),
                    child: Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3.5),
                        color: Colors.red
                      ),
                      child: const Text('NSFW', style: TextStyle(fontSize: 7.0),),
                    )
                  )
                  : null,
                
                Padding(
                  child: Text(
                    "${submission.score}",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: _defaultColumnTextSize,
                      color: Colors.grey)),
                  padding:
                      const EdgeInsets.only(left: 4.0, right: 4.0)),
                previewSource == PreviewSource.PostsList
                ? BlocBuilder<PostsBloc, PostsState>(
                    builder: (context, state) {
                      return Visibility(
                        visible: !(state.contentSource == ContentSource.Redditor && state.target == submission.author.toLowerCase()),
                        child: Padding(
                          child: Text(
                            "u/${submission.author}",
                            style: TextStyle(
                              fontSize: _defaultColumnTextSize,
                            ),
                            textAlign: TextAlign.left,),
                          padding:
                            const EdgeInsets.only(right: 4.0)),
                      );
                    },
                  )
                  : Padding(
                      child: Text(
                        "u/${submission.author}",
                        style: TextStyle(
                          fontSize: _defaultColumnTextSize,
                        ),
                        textAlign: TextAlign.left,),
                      padding:
                        const EdgeInsets.only(left: 0.0, right: 4.0, top: 0.0)),
                previewSource == PreviewSource.PostsList
                  ? BlocBuilder<PostsBloc, PostsState>(
                    builder: (context, state) {
                      return Visibility(
                        visible: !(state.contentSource == ContentSource.Subreddit && state.target == submission.subreddit.toLowerCase()),
                        child: Padding(
                          child: Text(
                            "r/${submission.subreddit}",
                            style: TextStyle(
                              fontSize: _defaultColumnTextSize,
                              color: Theme.of(context).accentColor
                            ),
                            textAlign: TextAlign.left,),
                          padding:
                            const EdgeInsets.only(left: 0.0, right: 4.0, top: 0.0))
                      );
                    },
                  )
                  : Padding(
                      child: Text(
                        "r/${submission.subreddit}",
                        style: TextStyle(
                          fontSize: _defaultColumnTextSize,
                        ),
                        textAlign: TextAlign.left,),
                      padding:
                        const EdgeInsets.only(left: 0.0, right: 4.0, top: 0.0)),
                Text(
                  "${submission.numComments} comments",
                  style: TextStyle(
                    fontSize: _defaultColumnTextSize,
                  )
                  ),
                Padding(
                  child: Text(
                    getSubmissionAge(submission.createdUTC),
                    style: TextStyle(
                      fontSize: _defaultColumnTextSize,
                    )
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                ),
                submission.isSelf ? null :
                Padding(
                    child: Text(
                        submission.domain,
                        style: const TextStyle(
                          fontSize: _defaultColumnTextSize,
                        ),
                        textAlign: TextAlign.left,),
                    padding:
                        const EdgeInsets.only(left: 4.0)),
                  submission.gold != null && submission.gold >= 1 ?
                Padding(
                  child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromARGB(255, 255, 223, 0),
                      ),
                      width: 8.0,
                      height: 8.0
                    ),
                  padding: const EdgeInsets.symmetric(horizontal: 3.5),
                ) : null,
                  submission.silver != null && submission.silver >= 1 ?
                Padding(
                  child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromARGB(255, 192, 192, 192),
                      ),
                      width: 8.0,
                      height: 8.0
                    ),
                  padding: const EdgeInsets.symmetric(horizontal: 3.5),
                ) : null,
                submission.platinum != null && submission.platinum >= 1 ?
                Padding(
                  child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromARGB(255, 229, 228, 226),
                      ),
                      width: 8.0,
                      height: 8.0
                    ),
                  padding: const EdgeInsets.symmetric(horizontal: 3.5),
                ) : null,
                  
            ].where(notNull).toList()
            ),
            const SizedBox(
              height: 3.5,
            )
          ]),
        onTap: (){
          if (previewSource != PreviewSource.Comments) {
            showComments(context);
          }
        },
      )
    );
  }
  void showComments(BuildContext context) {
    Navigator.of(context).pushNamed('comments', arguments: submission);
  }
}