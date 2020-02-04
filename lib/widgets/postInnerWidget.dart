import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/cupertino.dart' as prefix1;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Bloc/bloc.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Themes/textstyles.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lyre/Themes/themes.dart';
import 'package:lyre/screens/interfaces/previewc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:ui';
import '../screens/Animations/OnSlide.dart';
import 'ActionItems.dart';
import '../Resources/globals.dart';
import '../utils/utils.dart';
import 'package:draw/draw.dart';
import '../screens/interfaces/previewCallback.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import '../Resources/RedditHandler.dart';

///Notification class for sending submission selection data to the parent widgets, Posts-List, for example.
class SubmissionOptionsNotification extends Notification {
  final Submission submission;

  const SubmissionOptionsNotification({@required this.submission});
}
const __defaultColumnTextSize = 11.0;
const __defaultColumnPadding = EdgeInsets.only(left: 5.0);

class postInnerWidget extends StatelessWidget{
  const postInnerWidget({
    this.submission, 
    this.previewSource, 
    this.linkType,
    this.fullSizePreviews,
    this.postView,
    this.showCircle,
    this.blurLevel,
    this.showNsfw,
    this.showSpoiler,

    this.onOptionsClick
  });

  final PreviewSource previewSource;
  final Submission submission;
  final LinkType linkType;

  final bool fullSizePreviews;
  final PostView postView;
  final bool showCircle;
  final double blurLevel;
  final bool showNsfw;
  final bool showSpoiler;

  final VoidCallback onOptionsClick;

  Widget _getWidget(BuildContext context){
    if (submission.isSelf) {
      return getDefaultSlideColumn(context);
    }
    if (submission.preview != null && submission.preview.isNotEmpty) {
      return _getMediaWidget(context);
    }
    return getDefaultSlideColumn(context);
  }

  Widget _getMediaWidget(BuildContext context) {
    switch (postView) {
      case PostView.IntendedPreview:
        return _intendedWidget(context);
      case PostView.ImagePreview:
        return _imagePreview(context);
      case PostView.Compact:
        return _compactWidget(context);
      default:
        return _defaultColumn(submission, previewSource, linkType, onOptionsClick);
    }
  }

  Widget _compactWidget(BuildContext context) {
    return _SlideColumn(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              child: _defaultColumn(submission, previewSource, linkType, onOptionsClick),
              width: MediaQuery.of(context).size.width * 0.9,
            )
          ),
          getSquaredImage(context)
        ],
      ),
      submission: submission,
    );
  }

  Column _imagePreview(BuildContext context) {
    return Column(
      children: <Widget>[
        _getExpandedImage(context),
        getDefaultSlideColumn(context)
      ],
    );
  }

  Stack _intendedWidget(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        _getExpandedImage(context),
        Positioned(
          bottom: 0.0,
          child: 
            (((!(showNsfw ?? false) && submission.over18) ||    //Blur NSFW
            (!(showSpoiler ?? false) && submission.spoiler)) && previewSource == PreviewSource.PostsList)   //Blur Spoiler
              ? BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blurLevel,
                    sigmaY: blurLevel,
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    child: Material(
                      color: Theme.of(context).cardColor.withOpacity(0.6),
                      child: getDefaultSlideColumn(context)
                    ),
                  ),
                )
              : Container(
                  width: MediaQuery.of(context).size.width,
                  child: Material(
                    color: Theme.of(context).cardColor.withOpacity(0.6),
                    child: getDefaultSlideColumn(context)
                  ),
                ),
        ),
        ((submission.over18 && !showNsfw || (submission.spoiler && !showSpoiler)) || videoLinkTypes.contains(linkType))
          ? getCenteredIndicator(linkType, showCircle)
          : null
    ].where((w) => notNull(w)).toList());
  }

  Widget _getExpandedImage(BuildContext context){
    var x = MediaQuery.of(context).size.width;
    var y = 250.0; //Default preview height
    final preview = submission.preview.first;
    if(preview.source.width >= x){
      y = (x / preview.source.width) * preview.source.height;
    }
    return Container(
      child: _getImageWidget(context, fullSizePreviews),
      height: y,
      width: x,
    );
  }

  Widget _getImageWidget(BuildContext context, [bool fullSizePreviews]){
    if (postView == PostView.Compact) {
      return getImageWrapper(context, BoxFit.cover);
    }
    return getImageWrapper(context, fullSizePreviews ? BoxFit.contain : BoxFit.cover);
  }

  Widget getImageWrapper(BuildContext context, BoxFit fit){
    return GestureDetector(
      child: Image(
        color: Colors.black38,
        colorBlendMode: BlendMode.luminosity,
        width: double.infinity,
        height: double.infinity,
        image: AdvancedNetworkImage(
          postView == PostView.Compact ? submission.preview.first.resolutions.first.url.toString() : submission.preview.first.source.url.toString(),
          useDiskCache: true,
          cacheRule: const CacheRule(maxAge: const Duration(days: 7))
        ),
        fit: fit,
      ),
      
      onTap: () {
        _handleClick(linkType, submission, context);
      },
      onLongPress: (){
        _handlePress(context);
      },
      onLongPressUp: (){
        PreviewCall().callback.previewEnd();
      },
    );
  }

  Widget getSquaredImage(BuildContext context){
    return Container(
      child: _getImageWidget(context, false),
      //The fixed height of the post image:
      constraints: BoxConstraints.tight(Size(MediaQuery.of(context).size.width * 0.1, MediaQuery.of(context).size.width * 0.1)),
    );
  }

  void _handlePress(BuildContext context){
    ///Do not QuickPreview the Album Url, show only the first image
    if (albumLinkTypes.contains(linkType)) {
      PreviewCall().callback.preview(submission.preview.first.source.url.toString());
    }
    switch (linkType) {
      case LinkType.YouTube:
        PreviewCall().callback.preview(getYoutubeThumbnailFromId(getYoutubeIdFromUrl(submission.url.toString())));
        break;
      case LinkType.RedditVideo:
        PreviewCall().callback.preview(submission.data["media"]["reddit_video"]["dash_url"]);
        break;
      case LinkType.Default:
        PreviewCall().callback.preview(submission.preview.first.source.url.toString());
        break;
      default:
        PreviewCall().callback.preview(submission.url.toString());
        break;
    }
  }

  Widget getCenteredIndicator(LinkType type, bool showCircle){
    return IgnorePointer(
      child: showCircle
        ? Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2.0,
            ),
          ),
          child: getIndicator(type),
        )
        : Container(
            width: 50,
            height: 50,
            child: getIndicator(type),
        )
    );
  }

  Widget getIndicator(LinkType type){
    Widget content;
    if((submission.over18 && !showNsfw) || (submission.spoiler && !showSpoiler)){
      content = Column(children: <Widget>[
        const Icon(Icons.warning),
        Text(submission.over18 ? "NSFW" : "SPOILER"),
      ],);
    } else if (videoLinkTypes.contains(type)){
      content = const Icon(Icons.play_arrow, color: Colors.white,);
    }
    return Center(child: content);
  }

  Widget getDefaultSlideColumn(BuildContext context){
    //return _defaultColumn(submission, previewSource, linkType, onOptionsClick);
    return _SlideColumn(child: _defaultColumn(submission, previewSource, linkType, onOptionsClick), submission: submission);
  }


  Widget build(BuildContext context) {
    return Padding(
      child: Card(
        child: _getWidget(context),
      ),
      padding: const EdgeInsets.only(
        //The gap bewtween the widgets.
        bottom: 0.0
      ),
    );
  }
}

void _handleClick(LinkType linkType, Submission submission, BuildContext context){
    if (submission.isSelf) {
      Navigator.of(context).pushNamed("comments", arguments: submission);
    } else {
      if (linkType == LinkType.RedditVideo) {
        handleLinkClick(Uri.parse(submission.data["media"]["reddit_video"]["dash_url"]), context);
      } else {
        handleLinkClick(submission.url, context, linkType);
      }
    }
  }

///Sliding style column for [Submission] Widgets
class _SlideColumn extends StatefulWidget {
  const _SlideColumn({
    Key key,
    @required this.submission,
    @required this.child
  }) : super(key: key);

  final Submission submission;
  final Widget child;

  @override
  __SlideColumnState createState() => __SlideColumnState();
}

class __SlideColumnState extends State<_SlideColumn> {
  @override
  Widget build(BuildContext context) {
    return OnSlide(
      items: <ActionItems>[
        ActionItems(
          icon: Icon(
            MdiIcons.arrowUpBold,
            color: widget.submission.vote == VoteState.upvoted ? Colors.amber : Colors.grey,),
          onPress: () async {
            final response = await changeSubmissionVoteState(VoteState.upvoted, widget.submission);
            setState(() {
              if (response is String) {
                Scaffold.of(context).showSnackBar(SnackBar(content: Text(response),));
              }
            });
          }
        ),
        ActionItems(
          icon: Icon(
            MdiIcons.arrowDownBold,
            color: widget.submission.vote == VoteState.downvoted ? Colors.purple : Colors.grey,),
          onPress: () async {
            final response = await changeSubmissionVoteState(VoteState.downvoted, widget.submission);
            setState(() {
              if (response is String) {
                Scaffold.of(context).showSnackBar(SnackBar(content: Text(response),));
              }
            });
          }
        ),
        ActionItems(
          icon: Icon(
            Icons.bookmark,
            color: widget.submission.saved ? Colors.yellow : Colors.grey,),
          onPress: () async {
            final response = await changeSubmissionSave(widget.submission);
            setState(() {
              if (response is String) {
                Scaffold.of(context).showSnackBar(SnackBar(content: Text(response),));
              }
            });
          }
        ),
        ActionItems(
          icon: const Icon(Icons.person, color: Colors.grey,),
          onPress: (){
            Navigator.of(context).pushNamed('posts', arguments: {
              'target'        : widget.submission.author,
              'content_source'  : ContentSource.Redditor
            });
          }
        ),
        ActionItems(
          icon: const Icon(Icons.menu,color: Colors.grey,),
          onPress: () {
            SubmissionOptionsNotification(submission: this.widget.submission)..dispatch(context);
          }
        ),
      ],
      child: widget.child,
      backgroundColor: Colors.transparent,
    );
  }
}

class _defaultColumn extends StatelessWidget {
  _defaultColumn(this.submission, this.previewSource, this.linkType, this.onLongPress);

  final PreviewSource previewSource;
  final LinkType linkType;
  final Submission submission;
  final VoidCallback onLongPress;

  void showComments(BuildContext context) {
    Navigator.of(context).pushNamed('comments', arguments: submission);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
                      : Theme.of(context).textTheme.body1.color),
                ),
                onTap: (){
                  _handleClick(linkType, submission, context);
                },
              ),
              padding:
                  const EdgeInsets.only(left: 6.0, right: 16.0, top: 6.0, bottom: 0.0)),
          (submission.isSelf && submission.selftext != null && submission.selftext.isNotEmpty)
            ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0)
              ),
              child: MarkdownBody(
                data: previewSource == PreviewSource.Comments ? submission.selftext : submission.selftext.substring(0, min(submission.selftext.length-1, 100)) + ((submission.selftext.length >= 100) ? '...' : ''), 
                styleSheet: LyreTextStyles.getMarkdownStyleSheet(context),
                onTapLink: (String s) => handleLinkClick(Uri.parse(s), context),
                fitContent: true,
              ),
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
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Padding(
                child: Text(
                  "${submission.score}",
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.body1.apply(color: getScoreColor(submission, context), fontSizeFactor: 0.9)),
                padding: __defaultColumnPadding),

              submission.over18
                ? Padding(
                  padding: __defaultColumnPadding,
                  child: Text("NSFW", style: TextStyle(color: LyreColors.unsubscribeColor, fontSize: __defaultColumnTextSize))
                )
                : null,

              submission.spoiler
                ? Padding(
                  padding: __defaultColumnPadding,
                  child: Text("SPOILER", style: TextStyle(color: LyreColors.unsubscribeColor, fontSize: __defaultColumnTextSize))
                )
                : null,

              previewSource == PreviewSource.PostsList
              ? BlocBuilder<PostsBloc, PostsState>(
                  builder: (context, state) {
                    return prefix1.Visibility(
                      visible: !(state.contentSource == ContentSource.Redditor && state.target == submission.author.toLowerCase()),
                      child: _authorText(context),
                    );
                  },
                )
                : _authorText(context),
              previewSource == PreviewSource.PostsList
                ? BlocBuilder<PostsBloc, PostsState>(
                  builder: (context, state) {
                    return prefix1.Visibility(
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
                    fontSize: __defaultColumnTextSize,
                  )
                ),
                padding: __defaultColumnPadding,
              ),
              Padding(
                child: Text(
                  "● ${getSubmissionAge(submission.createdUtc)}",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.body2.color,
                    fontSize: __defaultColumnTextSize,
                  )
                ),
                padding: __defaultColumnPadding,
              ),
              submission.isSelf ? null :
                Padding(
                    child: Text(
                        "● ${submission.domain}",
                        style: TextStyle(
                          color: Theme.of(context).textTheme.body2.color,
                          fontSize: __defaultColumnTextSize,
                        ),
                        textAlign: TextAlign.left,),
                    padding: __defaultColumnPadding),
              submission.gold != null && submission.gold >= 1 ?
                Padding(
                  child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromARGB(255, 255, 223, 0),
                      ),
                      width: 8.0,
                      height: 8.0
                    ),
                  padding: __defaultColumnPadding,
                ) : null,
              submission.silver != null && submission.silver >= 1 ?
                Padding(
                  child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromARGB(255, 192, 192, 192),
                      ),
                      width: 8.0,
                      height: 8.0
                    ),
                  padding: __defaultColumnPadding,
                ) : null,
              submission.platinum != null && submission.platinum >= 1 ?
                Padding(
                  child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromARGB(255, 229, 228, 226),
                      ),
                      width: 8.0,
                      height: 8.0
                    ),
                  padding: __defaultColumnPadding,
                ) : null,
                
          ].where(notNull).toList()
          ),
          const SizedBox(
            height: 3.5,
          )
        ]),
      onTap: (){
        if (previewSource != PreviewSource.Comments) {
          currentPostId = submission.id;
          showComments(context);
        }
      },
      onLongPress: onLongPress,
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
      padding: __defaultColumnPadding);
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
              style: Theme.of(context).textTheme.body2.apply(color: Theme.of(context).accentColor),
            )
          ]
        ),
        textAlign: TextAlign.left),
      padding: __defaultColumnPadding);
  }
}