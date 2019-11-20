import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix0;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Resources/PreferenceValues.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/UI/interfaces/previewc.dart';
import 'dart:ui';
import 'Animations/OnSlide.dart';
import 'ActionItems.dart';
import '../Resources/globals.dart';
import '../utils/imageUtils.dart';
import '../utils/urlUtils.dart';
import 'package:draw/draw.dart';
import 'interfaces/previewCallback.dart';
import '../Resources/MediaProvider.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import '../Resources/RedditHandler.dart';
import '../utils/redditUtils.dart';

class postInnerWidget extends StatelessWidget {
  postInnerWidget(this.submission, this.previewSource, [this.viewSetting, this.expanded]);

  bool expanded = false;
  bool fullSizePreviews;
  LinkType linkType;
  PostView postView;
  bool showCircle;

  double blurLevel;

  bool showNsfw = false;
  bool showSpoiler = false;

  final PreviewSource previewSource;
  final Submission submission;
  final PostView viewSetting;

  Widget getWidget(BuildContext context){
    if (submission.isSelf) {
      return getDefaultSlideColumn(context);
    }
    if (submission.preview != null && submission.preview.isNotEmpty) {
      return BlocBuilder<LyreBloc, LyreState>(
        builder: (context, state){
          showCircle = state.settings.get(SUBMISSION_PREVIEW_SHOWCIRCLE) ?? false;
          fullSizePreviews = state.settings.get(IMAGE_SHOW_FULLSIZE) ?? false;
          postView = viewSetting ?? state.settings.get(SUBMISSION_VIEWMODE);
          showNsfw = state.settings.get(SHOW_NSFW_PREVIEWS) ?? false;
          showSpoiler = state.settings.get(SHOW_SPOILER_PREVIEWS) ?? false;
          blurLevel = (state.settings.get(IMAGE_BLUR_LEVEL) ?? 20).toDouble();
          return getMediaWidget(context);
        }
      );
    }
    return getDefaultSlideColumn(context);
  }

  Widget getMediaWidget(BuildContext context) {
    switch (postView) {
      case PostView.IntendedPreview:
        return intendedWidget(context);
      case PostView.ImagePreview:
        return imagePreview(context);
      case PostView.Compact:
        return compactWidget(context);
      default:
        return new defaultColumn(submission, previewSource, linkType);
    }
  }

  Widget compactWidget(BuildContext context) {
    return getSlideColumn(
      context,
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            child: defaultColumn(submission, previewSource, linkType),
            width: MediaQuery.of(context).size.width * 0.9,
          ),
          getSquaredImage(context)
        ],
      )
    );
  }

  Column imagePreview(BuildContext context) {
    return new Column(
      children: <Widget>[
        getExpandedImage(context),
        getDefaultSlideColumn(context)
      ],
    );
  }

  Stack intendedWidget(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        getExpandedImage(context),
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
                  color: Colors.black.withOpacity(0.6),
                  child: getDefaultSlideColumn(context),
                ),
              )
              : new Container(
                  width: MediaQuery.of(context).size.width,
                  color: Colors.black.withOpacity(0.6),
                  child: getDefaultSlideColumn(context),
                ),
        ),
        ((submission.over18 && !showNsfw || (submission.spoiler && !showSpoiler)) || videoLinkTypes.contains(linkType))
          ? getCenteredIndicator(linkType, showCircle)
          : null
    ].where((w) => notNull(w)).toList());
  }

  Widget getExpandedImage(BuildContext context){
    var x = MediaQuery.of(context).size.width;
    var y = 250.0; //Default preview height
    final preview = submission.preview.first;
    if(preview.source.width >= x){
      y = (x / preview.source.width) * preview.source.height;
    }
    return Container(
      child: getImageWidget(context, fullSizePreviews),
      height: (fullSizePreviews) ? y : 250.0,
      width: x,
    );
  }

  Widget getImageWidget(BuildContext context, [bool fullSizePreviews]){
    if (postView == PostView.Compact) {
      return getImageWrapper(context, BoxFit.cover);
    }
    return getImageWrapper(context, fullSizePreviews ? BoxFit.contain : BoxFit.cover);
  }

  Widget getImageWrapper(BuildContext context, BoxFit fit){
    return new GestureDetector(
      child: Image(
        color: Colors.black.withOpacity(0.22),
        colorBlendMode: BlendMode.luminosity,
        width: double.infinity,
        height: double.infinity,
        image: AdvancedNetworkImage(
          submission.preview.first.source.url.toString(),
          useDiskCache: true,
          cacheRule: const CacheRule(maxAge: const Duration(days: 7))
        ),
        fit: fit,
      ),
      
      onTap: () {
        handleClick(context);
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
      child: getImageWidget(context, false),
      //The fixed height of the post image:
      constraints: BoxConstraints.tight(Size(MediaQuery.of(context).size.width * 0.1, MediaQuery.of(context).size.width * 0.1)),
    );
  }

  void handleClick(BuildContext context){
    if(linkType == LinkType.YouTube){
      //TODO: Implement YT plugin?
      launchURL(context, submission);
    } else if(linkType == LinkType.Default){
      launchURL(context, submission);
    } else if (linkType == LinkType.RedditVideo){
      PreviewCall().callback.preview(submission.data["media"]["reddit_video"]["dash_url"]);
    } else {
      print("URL:" + submission.url.toString());
      PreviewCall().callback.preview(submission.url.toString());
    }
  }

  void _handlePress(BuildContext context){
    switch (linkType) {
      case LinkType.YouTube:
        PreviewCall().callback.preview(getYoutubeThumbnailFromId(getYoutubeIdFromUrl(submission.url.toString())));
        break;
      default :
        PreviewCall().callback.preview(submission.preview.first.source.url.toString());
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

  // Returns the slide column with the defaultcolumn as child
  Widget getDefaultSlideColumn(BuildContext context){
    return getSlideColumn(context, child: defaultColumn(submission, previewSource, linkType));
  }

  Widget getSlideColumn(BuildContext context, {Widget child}){
    return new OnSlide(
      items: <ActionItems>[
        ActionItems(
          icon: IconButton(
            icon: const Icon(Icons.keyboard_arrow_up),onPressed: (){},
            color: submission.vote == VoteState.upvoted ? Colors.amber : Colors.grey,),
          onPress: (){
            changeSubmissionVoteState(VoteState.upvoted, submission);
          }
        ),
        ActionItems(
          icon: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),onPressed: (){},
            color: submission.vote == VoteState.downvoted ? Colors.purple : Colors.grey,),
          onPress: (){
            changeSubmissionVoteState(VoteState.downvoted, submission);
          }
        ),
        ActionItems(
          icon: IconButton(
            icon: const Icon(Icons.bookmark),onPressed: (){},
            color: submission.saved ? Colors.yellow : Colors.grey,),
          onPress: (){
            changeSubmissionSave(submission);
            submission.refresh();
          }
        ),
        ActionItems(
          icon: IconButton(icon: const Icon(Icons.person),onPressed: (){},color: Colors.grey,),
          onPress: (){
            Navigator.of(context).pushNamed('posts', arguments: {
              'redditor'        : submission.author,
              'content_source'  : ContentSource.Redditor
            });
          }
        ),
        ActionItems(
          icon: IconButton(icon: Icon(Icons.menu),onPressed: (){},color: Colors.grey,),
          onPress: (){

          }
        ),
      ],
      child: child,
      backgroundColor: Colors.transparent,
    );
  }

  Widget build(BuildContext context) {
    linkType = getLinkType(submission.url.toString());
    return Padding(
      child: ClipRRect(
        child: Container(
          child: getWidget(context),
          color: Theme.of(context).primaryColor,
        ),
        //The circular radius for post widgets. Set 0.0 for rectangular.
        borderRadius: BorderRadius.circular(10.0),
      ),
      padding: const EdgeInsets.only(
        //The gap bewtween the widgets.
        bottom: 5.0
      ),
    );
  }
}

class defaultColumn extends StatelessWidget {
  defaultColumn(this.submission, this.previewSource, this.linkType);

  final PreviewSource previewSource;
  final LinkType linkType;
  final Submission submission;

  void showComments(BuildContext context) {
    Navigator.of(context).pushNamed('comments', arguments: submission);
  }

  @override
  Widget build(BuildContext context) {
    return new InkWell(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Padding(
              child: GestureDetector(
                child: Text(
                    submission.title,
                    style:
                    new TextStyle(
                      fontWeight: FontWeight.normal, 
                      fontSize: 12.0,
                      color: (submission.stickied)
                        ? Color.fromARGB(255, 0, 200, 53)
                        : Colors.white
                      ),
                    textScaleFactor: 1.0,
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
              child: Container(
                child: Text(
                  submission.selftext,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11.0,
                    fontFamily: "Roboto"
                  ),
                  overflow: TextOverflow.fade,
                  maxLines: previewSource == PreviewSource.Comments ? null : 5,
                ),
              ),
              padding: const EdgeInsets.only(
                left: 8.0,
                right: 8.0,
                top: 8.0,
                bottom: 8.0
              ),
            )
          : Container(height: 3.5),
          new ButtonTheme.bar(
              child: new Row(
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
                            textScaleFactor: 1.0,
                            style: new TextStyle(
                              color: getScoreColor(submission, context),
                              fontSize: 9.0)),
                        padding:
                            const EdgeInsets.only(left: 4.0, right: 4.0, top: 0.0)),
                    new Padding(
                        child: new Text(
                            "u/${submission.author}",
                            textAlign: TextAlign.left,
                            textScaleFactor: 1.0,
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 9.0)),
                        padding:
                            const EdgeInsets.only(left: 0.0, right: 4.0, top: 0.0)),
                    new Padding(
                        child: new Text(
                            "r/${submission.subreddit.displayName}",
                            textAlign: TextAlign.left,
                            textScaleFactor: 1.0,
                            style: const TextStyle(color: Color.fromARGB(255, 109, 250, 255), fontSize: 9.0)),
                        padding:
                            const EdgeInsets.only(left: 0.0, right: 4.0, top: 0.0)),
                    new Text(
                          "${submission.numComments} comments",
                          style: TextStyle(
                            fontSize: 10.0,
                            color: Colors.white.withOpacity(0.9)
                          ),
                      ),
                    new Padding(
                      child: new Text(
                        getSubmissionAge(submission.createdUtc),
                        style: TextStyle(
                              fontSize: 10.0,
                              color: Colors.white.withOpacity(0.9)
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    ),
                    submission.isSelf ? null :
                    new Padding(
                        child: new Text(
                            submission.domain,
                            textAlign: TextAlign.left,
                            textScaleFactor: 1.0,
                            style: new TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9.0)),
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
          )),
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
    );
  }
}