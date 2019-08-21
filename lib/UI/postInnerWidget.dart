import 'package:flutter/material.dart';
import 'package:lyre/UI/posts_list.dart';
import 'dart:ui';
import 'Animations/OnSlide.dart';
import 'ActionItems.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import '../Models/Post.dart';
import '../Resources/globals.dart';
import '../utils/imageUtils.dart';
import '../utils/urlUtils.dart';
import 'package:draw/draw.dart';
import '../Ui/Animations/slide_right_transition.dart';
import 'comments_list.dart';
import 'interfaces/previewCallback.dart';
import '../Resources/MediaProvider.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import '../Resources/RedditHandler.dart';
import '../utils/redditUtils.dart';

enum PostView{
  ImagePreview,
  IntendedPreview,
  Compact,
  NoPreview
}
class postInnerWidget extends StatelessWidget {
  PostView viewSetting = PostView.IntendedPreview;
  bool isFullSize = true;
  final Post post;
  final PreviewCallback callBack;

  postInnerWidget(this.post, this.callBack);


  Widget getWidget(BuildContext context){

    if (post.s.isSelf) {
      return getSlideColumn(context);
    }
    if (post.hasPreview()) {
      switch (viewSetting) {
        case PostView.IntendedPreview:
          return new Stack(children: <Widget>[
            getExpandedImage(context),
            new Positioned(
                bottom: 0.0,
                child: new BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 0.0,
                    sigmaY: 0.0,
                  ),
                  child: new Container(
                    width: MediaQuery.of(context).size.width,
                    color: Color.fromARGB(155, 0, 0, 0),
                    child: getSlideColumn(context),
                  ),
                ))
          ]);
          break;
        case PostView.ImagePreview:
          return new Column(
            children: <Widget>[
              getExpandedImage(context),
              getSlideColumn(context)
            ],
          );
          break;
        case PostView.Compact:
          return new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                child: defaultColumn(post, callBack),
                width: MediaQuery.of(context).size.width * 0.9,
              ),
              getSquaredImage(context)
          ],);
          break;
        default:
          return new defaultColumn(post, callBack);
      }
    }
    return getSlideColumn(context);
  }
  Widget getExpandedImage(BuildContext context){
    var x = MediaQuery.of(context).size.width;
    var y = 250.0;
    if(post.preview.source.width >= x){
      y = (x / post.preview.source.width)*post.preview.source.height;
    }
    return new Container(
      child: getImageWidget(context),
      
      height: (isFullSize) ? y : 250.0,
      width: x,
    );
  }
  Widget getImageWidget(BuildContext context){
    return Stack(children: <Widget>[
        SizedBox.expand(
          child: new GestureDetector(
            child: Image(
              image: AdvancedNetworkImage(
                post.getImageUrl().toString(),
                useDiskCache: true,
                cacheRule: CacheRule(maxAge: const Duration(days: 7))
              ),
              fit: (isFullSize) ? BoxFit.contain : BoxFit.cover,
            ),
            
            onTap: () {
              handleClick(context);
            },
            onLongPress: (){
              handlePress(context);
            },
            onLongPressUp: (){
                callBack.previewEnd();
            },
          ),
        ),
        (post.linkType == LinkType.YouTube)? getCenteredIndicator(post.linkType) : Container(height: 0.0),
      ],);
  }
  Widget getSquaredImage(BuildContext context){
    return new Container(
      child: getImageWidget(context),
      //The fixed height of the post image:
      height: 40,
      width: 40,
    );
  }
  void handleClick(BuildContext context){
    if(post.linkType == LinkType.YouTube){
      //TODO: Implement YT plugin?
      _launchURL(context, post);
    }else if(post.linkType == LinkType.DirectImage || post.linkType == LinkType.Gfycat){
      callBack.preview(post.getUrl());
    }else{
      _launchURL(context, post);
    }
  }

  void handlePress(BuildContext context){
    switch (post.linkType) {
      case LinkType.YouTube:
        callBack.preview(getYoutubeThumbnailFromId(getYoutubeIdFromUrl(post.getUrl())));
        break;
      default :
        callBack.preview(post.getImageUrl().toString());
        break;
    }
  }

  Widget getCenteredIndicator(LinkType type){
    return Center(
      child: 
          Container(
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
          ),
        
      
    );
  }
  Widget getIndicator(LinkType type){
    if(type == LinkType.YouTube){
      return Center(child: Icon(Icons.play_arrow, color: Colors.white,),);
    }
  }

  Widget build(BuildContext context) {
    return Container(
      child: ClipRRect(
        child: Container(
          child: getWidget(context),
          color: Colors.black38,
        ),
        //The circular radius for post widgets. Set 0.0 for rectangular.
        borderRadius: BorderRadius.circular(10.0),
      ),
      padding: EdgeInsets.only(
        //The gap bewtween the widgets.
        bottom: 5.0
      ),
    );
  }
  Widget getSlideColumn(BuildContext context){
    return new OnSlide(
      items: <ActionItems>[
        ActionItems(
          icon: IconButton(
            icon: Icon(Icons.keyboard_arrow_up),onPressed: (){},
            color: post.s.vote == VoteState.upvoted ? Colors.amber : Colors.grey,),
          onPress: (){
            changeSubmissionVoteState(VoteState.upvoted, post.s);
          }
        ),
        ActionItems(
          icon: IconButton(
            icon: Icon(Icons.keyboard_arrow_down),onPressed: (){},
            color: post.s.vote == VoteState.downvoted ? Colors.purple : Colors.grey,),
          onPress: (){
            changeSubmissionVoteState(VoteState.downvoted, post.s);
          }
        ),
        ActionItems(
          icon: IconButton(
            icon: Icon(Icons.bookmark),onPressed: (){},
            color: post.s.saved ? Colors.yellow : Colors.grey,),
          onPress: (){
            changeSubmissionSave(post.s);
            post.s.refresh();
          }
        ),
        ActionItems(
          icon: IconButton(icon: Icon(Icons.person),onPressed: (){},color: Colors.grey,),
          onPress: (){
            Navigator.push(context, SlideRightRoute(widget: PostsView(post.s.author)));
          }
        ),
        ActionItems(
          icon: IconButton(icon: Icon(Icons.menu),onPressed: (){},color: Colors.grey,),
          onPress: (){

          }
        ),
      ],
      child: defaultColumn(post, callBack),
      backgroundColor: Colors.transparent,
    );
  }
}

bool notNull(Object o) => o != null;

class defaultColumn extends StatelessWidget {
  final Post post;
  final PreviewCallback callback;

  defaultColumn(this.post, this.callback);

  @override
  Widget build(BuildContext context) {
    return new InkWell(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Padding(
              child: GestureDetector(
                child: Text(
                    post.s.title,
                    style:
                    new TextStyle(
                      fontWeight: FontWeight.normal, 
                      fontSize: 12.0,
                      color: (post.s.stickied)
                        ? Color.fromARGB(255, 0, 200, 53)
                        : Colors.white
                      ),
                    textScaleFactor: 1.0,
                  ),
                onTap: (){
                  switch (post.linkType) {
                    case LinkType.YouTube:
                      playYouTube(post.getUrl());
                      break;
                    case LinkType.Default:
                      _launchURL(context, post);
                      break;
                    default:
                      break;
                  }
                },
              ),
              padding:
                  const EdgeInsets.only(left: 6.0, right: 16.0, top: 6.0, bottom: 0.0)),
          (post.s.isSelf && post.s.selftext != null && post.s.selftext.isNotEmpty)
              ? Container(
            child: Container(
              child: Text(
                post.s.selftext,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11.0,
                  fontFamily: "Roboto"
                ),
                overflow: TextOverflow.fade,
                maxLines: post.expanded ? null : 5,
              ),
            ),
            padding: EdgeInsets.only(
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
                    new Padding(
                        child: new Text(
                            "${post.s.score}",
                            textAlign: TextAlign.left,
                            textScaleFactor: 1.0,
                            style: new TextStyle(
                              color: getScoreColor(post.s, context),
                              fontSize: 9.0)),
                        padding:
                            const EdgeInsets.only(left: 6.0, right: 4.0, top: 0.0)),
                    new Padding(
                        child: new Text(
                            "u/${post.s.author}",
                            textAlign: TextAlign.left,
                            textScaleFactor: 1.0,
                            style: new TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 9.0)),
                        padding:
                            const EdgeInsets.only(left: 0.0, right: 4.0, top: 0.0)),
                    new Padding(
                        child: new Text(
                            "r/${post.s.subreddit.displayName}",
                            textAlign: TextAlign.left,
                            textScaleFactor: 1.0,
                            style: new TextStyle(color: Color.fromARGB(255, 109, 250, 255), fontSize: 9.0)),
                        padding:
                            const EdgeInsets.only(left: 0.0, right: 4.0, top: 0.0)),
                    new GestureDetector(
                      child: new Text(
                            "${post.s.numComments} comments",
                            style: TextStyle(
                              fontSize: 10.0,
                              color: Colors.white.withOpacity(0.9)
                            ),
                        ),
                        onTap: (){
                          //showComments(context);
                        },
                    ),
                    new Padding(
                      child: new Text(
                        getSubmissionAge(post.s.createdUtc).inHours.toString() + ' hours ago',
                        style: TextStyle(
                              fontSize: 10.0,
                              color: Colors.white.withOpacity(0.9)
                        ),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                    ),
                    post.s.isSelf ? null :
                    new Padding(
                        child: new Text(
                            post.s.domain,
                            textAlign: TextAlign.left,
                            textScaleFactor: 1.0,
                            style: new TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9.0)),
                        padding:
                            const EdgeInsets.only(left: 4.0)),

                    post.s.gold != null && post.s.gold >= 1 ?
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

                    post.s.silver != null && post.s.silver >= 1 ?
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


                    post.s.platinum != null && post.s.platinum >= 1 ?
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
          currentPostId = post.s.id;
          showComments(context);
        },
    );
  }

  void showComments(BuildContext context) {
    if (callback is comL) {
      return;
    }
    post.hasBeenViewed = true;
    post.expanded = true;
    Navigator.of(context).push(SlideRightRoute(widget: commentsList(post)));
  }
  
}
void _launchURL(BuildContext context, Post post) async {
    String url = post.getUrl();
    try{
      await launch(
          url,
          option: new CustomTabsOption(
            toolbarColor: Theme.of(context).primaryColor,
            enableDefaultShare: true,
            enableUrlBarHiding: true,
            showPageTitle: true,
            animation: new CustomTabsAnimation(
              startEnter: 'slide_up',
              startExit: 'android:anim/fade_out',
              endEnter: 'android:anim/fade_in',
              endExit: 'slide_down',
            ),
            extraCustomTabs: <String>[
              // ref. https://play.google.com/store/apps/details?id=org.mozilla.firefox
              'org.mozilla.firefox',
              // ref. https://play.google.com/store/apps/details?id=com.microsoft.emmx
              'com.microsoft.emmx',
            ]
          )
      );
      post.hasBeenViewed = true;
    }catch(e){
      debugPrint(e.toString());
    }
  }