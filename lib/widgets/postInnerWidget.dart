import 'dart:math';
import 'package:lyre/screens/screens.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/cupertino.dart' as mat;
import 'package:flutter/material.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Themes/textstyles.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lyre/Themes/themes.dart';
import 'package:lyre/screens/interfaces/previewc.dart';
import 'package:lyre/widgets/widgets.dart';
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
/// Max. Preview height (If fullSizePreviews not enabled)
const _defaultPreviewHeight = 250.0;
/// Max. Preview height for full size previews (needed for ultra-long infographics etc.)
const _defaultMaxFullSizePreviewHeight = 1000.0;

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
            child: _defaultColumn(submission, previewSource, linkType, onOptionsClick)
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
    final preview = submission.preview.first;
    var x = MediaQuery.of(context).size.width; // Width of Image (Screen width)
    var y = min(_defaultMaxFullSizePreviewHeight, preview.source.height.toDouble()); // Height of Image
    if (y > _defaultPreviewHeight && !fullSizePreviews){
      y = _defaultPreviewHeight;
    }
    if (fullSizePreviews && preview.source.width > x) {
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
    return getImageWrapper(context, fullSizePreviews ? BoxFit.cover : BoxFit.fitWidth);
  }

  Widget getImageWrapper(BuildContext context, BoxFit fit){
    return GestureDetector(
      child: Image(
        color: Colors.black38,
        colorBlendMode: BlendMode.luminosity,
        width: double.infinity,
        height: double.infinity,
        image: AdvancedNetworkImage(
          postView == PostView.Compact 
            ? submission.preview.last.resolutions.isNotEmpty
              ? submission.preview.last.resolutions.first.url.toString()
              : submission.preview.last.source.url.toString()
            : submission.preview.first.source.url.toString(),
          useDiskCache: true,
          cacheRule: const CacheRule(maxAge: Duration(days: 7))
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
      constraints: BoxConstraints.tight(const Size(50, 50)),
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
    return Card(
      child: _getWidget(context),
    );
  }
}

void _handleClick(LinkType linkType, Submission submission, BuildContext context, [bool longPress = false]){
  if (linkType == LinkType.RedditVideo) {
    handleLinkClick(submission.data["media"]["reddit_video"]["dash_url"], context);
  } else {
    handleLinkClick(submission, context, linkType, longPress);
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
            final response = await changeVoteState(VoteState.upvoted, widget.submission);
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
            final response = await changeVoteState(VoteState.downvoted, widget.submission);
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
            color: widget.submission.saved ? Colors.amber : Colors.grey,),
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
  const _defaultColumn(this.submission, this.previewSource, this.linkType, this.onLongPress);

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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      child: Text(
                        submission.title,
                        style: LyreTextStyles.submissionTitle.apply(
                          color: (submission.stickied)
                            ? const Color.fromARGB(255, 0, 200, 53)
                            : Theme.of(context).textTheme.body1.color),
                      ),
                      onTap: (){
                        _handleClick(linkType, submission, context);
                      },
                      onLongPress: (){
                        _handleClick(linkType, submission, context, true);
                      },
                    )
                  ),
                  // Instant View Button
                  mat.Visibility(
                    visible: linkType == LinkType.Default,
                    child: GestureDetector(
                      child: const Icon(MdiIcons.flashCircle),
                      onTap: () => instantLaunchUrl(context, submission.url),
                      onLongPress: () => instantLaunchUrl(context, submission.url, true),
                    )
                  )
                ]
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
          : const SizedBox(height: 3.5),
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: SubmissionDetailsBar(submission: submission, previewSource: previewSource)
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
      onLongPress: onLongPress,
    );
  }
  
  
}