import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/cupertino.dart' as prefix1;
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix0;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Bloc/bloc.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Themes/textstyles.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lyre/screens/interfaces/previewc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:ui';
import '../screens/Animations/OnSlide.dart';
import 'ActionItems.dart';
import '../Resources/globals.dart';
import '../utils/utils.dart';
import 'package:draw/draw.dart';
import '../screens/interfaces/previewCallback.dart';
import '../Resources/MediaProvider.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import '../Resources/RedditHandler.dart';

///Notification class for sending submission selection data to the parent widgets, Posts-List, for example.
class SubmissionOptionsNotification extends Notification {
  final Submission submission;

  const SubmissionOptionsNotification({@required this.submission});
}
const _defaultColumnTextSize = 11.0;

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

  Widget getWidget(BuildContext context){
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
        return intendedWidget(context);
      case PostView.ImagePreview:
        return imagePreview(context);
      case PostView.Compact:
        return compactWidget(context);
      default:
        return defaultColumn(submission, previewSource, linkType, onOptionsClick);
    }
  }

  Widget compactWidget(BuildContext context) {
    return _SlideColumn(
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            child: defaultColumn(submission, previewSource, linkType, onOptionsClick),
            width: MediaQuery.of(context).size.width * 0.9,
          ),
          getSquaredImage(context)
        ],
      ),
      submission: submission,
    );
  }

  Column imagePreview(BuildContext context) {
    return new Column(
      children: <Widget>[
        _getExpandedImage(context),
        getDefaultSlideColumn(context)
      ],
    );
  }

  Stack intendedWidget(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        _getExpandedImage(context),
        new Positioned(
          bottom: 0.0,
          child: 
            (((!(showNsfw ?? false) && submission.over18) ||    //Blur NSFW
            (!(showSpoiler ?? false) && submission.spoiler)) && previewSource == PreviewSource.PostsList)   //Blur Spoiler
              ? new BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: blurLevel,
                  sigmaY: blurLevel,
                ),
                child: new Container(
                  width: MediaQuery.of(context).size.width,
                  color: Colors.black,
                  child: getDefaultSlideColumn(context),
                ),
              )
              : new Container(
                width: MediaQuery.of(context).size.width,
                color: Theme.of(context).primaryColor,
                child: getDefaultSlideColumn(context),
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
    return new GestureDetector(
      child: Image(
        color: Colors.black38,
        colorBlendMode: BlendMode.luminosity,
        width: double.infinity,
        height: double.infinity,
        image: AdvancedNetworkImage(
          submission.preview.last.source.url.toString(),
          useDiskCache: true,
          cacheRule: const CacheRule(maxAge: const Duration(days: 7))
        ),
        fit: fit,
      ),
      
      onTap: () {
        _handleClick(context);
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
    return new Container(
      child: _getImageWidget(context, false),
      //The fixed height of the post image:
      constraints: BoxConstraints.tight(Size(MediaQuery.of(context).size.width * 0.1, MediaQuery.of(context).size.width * 0.1)),
    );
  }

  void _handleClick(BuildContext context){
    if (linkType == LinkType.RedditVideo) {
      handleLinkClick(submission.data["media"]["reddit_video"]["dash_url"]);
    } else {
      handleLinkClick(submission.url.toString(), linkType, context);
    }
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
    return showCircle
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
      );
  }

  Widget getIndicator(LinkType type){
    Widget content;
    if((submission.over18 && !showNsfw) || (submission.spoiler && !showSpoiler)){
      content = Column(children: <Widget>[
        const Icon(Icons.warning),
        Text(submission.over18 ? "NSFW" : "SPOILER"),
        const Divider(indent: 250,endIndent: 250,)
      ],);
    } else if (videoLinkTypes.contains(type)){
      content = const Icon(Icons.play_arrow, color: Colors.white,);
    }
    return Center(child: content);
  }

  Widget getDefaultSlideColumn(BuildContext context){
    return _SlideColumn(child: defaultColumn(submission, previewSource, linkType, onOptionsClick), submission: submission,);
  }


  Widget build(BuildContext context) {
    return ClipRRect(
      child: Padding(
        child: Container(
          child: getWidget(context),
          color: Theme.of(context).cardColor,
        ),
        padding: const EdgeInsets.only(
          //The gap bewtween the widgets.
          bottom: 5.0
        ),
      )
    );
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
    return new OnSlide(
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
          onPress: (){
            SubmissionOptionsNotification(submission: this.widget.submission)..dispatch(context);
          }
        ),
      ],
      child: widget.child,
      backgroundColor: Colors.transparent,
    );
  }
}

class defaultColumn extends StatelessWidget {
  defaultColumn(this.submission, this.previewSource, this.linkType, this.onLongPress);

  final PreviewSource previewSource;
  final LinkType linkType;
  final Submission submission;
  final VoidCallback onLongPress;

  void showComments(BuildContext context) {
    Navigator.of(context).pushNamed('comments', arguments: submission);
  }

  @override
  Widget build(BuildContext context) {
    return new Material(
      color: Theme.of(context).cardColor,
      child: InkWell(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            new Padding(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  child: Text(
                    submission.title,
                    style: LyreTextStyles.submissionTitle.apply(
                      color: (submission.stickied)
                        ? Color.fromARGB(255, 0, 200, 53)
                        : Colors.white),
                  ),
                  onTap: (){
                    switch (linkType) {
                      case LinkType.YouTube:
                        playYouTube(submission.url.toString());
                        break;
                      case LinkType.Default:
                        launchURL(context, submission);
                        break;
                      default:
                        PreviewCall().callback.preview(submission.url.toString());
                        break;
                    }
                  },
                ),
                padding:
                    const EdgeInsets.only(left: 6.0, right: 16.0, top: 6.0, bottom: 0.0)),
            (submission.isSelf && submission.selftext != null && submission.selftext.isNotEmpty)
              ? Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10.0)
                ),
                child: MarkdownBody(
                  data: previewSource == PreviewSource.Comments ? submission.selftext : submission.selftext.substring(0, min(submission.selftext.length-1, 100)) + ((submission.selftext.length >= 100) ? '...' : ''), 
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
                      child: const Text('NSFW', style: prefix0.TextStyle(fontSize: 7.0),),
                    )
                  )
                  : null,
                
                new Padding(
                  child: new Text(
                    "${submission.score}",
                    textAlign: TextAlign.left,
                    style: new TextStyle(
                      fontSize: _defaultColumnTextSize,
                      color: getScoreColor(submission, context))),
                  padding:
                      const EdgeInsets.only(left: 4.0, right: 4.0, top: 0.0)),
                previewSource == PreviewSource.PostsList
                ? BlocBuilder<PostsBloc, PostsState>(
                    builder: (context, state) {
                      return prefix1.Visibility(
                        visible: !(state.contentSource == ContentSource.Redditor && state.target == submission.author.toLowerCase()),
                        child: Padding(
                          child: new Text(
                            "u/${submission.author}",
                            style: TextStyle(
                              fontSize: _defaultColumnTextSize,
                            ),
                            textAlign: TextAlign.left,),
                          padding:
                            const EdgeInsets.only(left: 0.0, right: 4.0, top: 0.0)),
                      );
                    },
                  )
                  : Padding(
                      child: new Text(
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
                      return prefix1.Visibility(
                        visible: !(state.contentSource == ContentSource.Subreddit && state.target == submission.subreddit.displayName.toLowerCase()),
                        child: Padding(
                          child: new Text(
                            "r/${submission.subreddit.displayName}",
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
                      child: new Text(
                        "r/${submission.subreddit.displayName}",
                        style: TextStyle(
                          fontSize: _defaultColumnTextSize,
                        ),
                        textAlign: TextAlign.left,),
                      padding:
                        const EdgeInsets.only(left: 0.0, right: 4.0, top: 0.0)),
                new Text(
                  "${submission.numComments} comments",
                  style: TextStyle(
                    fontSize: _defaultColumnTextSize,
                  )
                  ),
                new Padding(
                  child: new Text(
                    getSubmissionAge(submission.createdUtc),
                    style: TextStyle(
                      fontSize: _defaultColumnTextSize,
                    )
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                ),
                submission.isSelf ? null :
                new Padding(
                    child: new Text(
                        submission.domain,
                        style: TextStyle(
                          fontSize: _defaultColumnTextSize,
                        ),
                        textAlign: TextAlign.left,),
                    padding:
                        const EdgeInsets.only(left: 4.0)),
                  submission.gold != null && submission.gold >= 1 ?
                new Padding(
                  child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromARGB(255, 255, 223, 0),
                      ),
                      width: 8.0,
                      height: 8.0
                    ),
                  padding: const EdgeInsets.symmetric(horizontal: 3.5),
                ) : null,
                  submission.silver != null && submission.silver >= 1 ?
                new Padding(
                  child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromARGB(255, 192, 192, 192),
                      ),
                      width: 8.0,
                      height: 8.0
                    ),
                  padding: const EdgeInsets.symmetric(horizontal: 3.5),
                ) : null,
                submission.platinum != null && submission.platinum >= 1 ?
                new Padding(
                  child: Container(
                      decoration: BoxDecoration(
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
            currentPostId = submission.id;
            showComments(context);
          }
        },
        onLongPress: onLongPress,
      )
    );
  }
}