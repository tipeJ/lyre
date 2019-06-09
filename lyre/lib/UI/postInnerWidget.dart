import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import '../Models/Post.dart';
import '../Resources/globals.dart';
import '../utils/imageUtils.dart';
import '../utils/urlUtils.dart';
import '../Ui/Animations/slide_right_transition.dart';
import 'comments_list.dart';
import 'interfaces/previewCallback.dart';
import '../Resources/MediaProvider.dart';
import 'package:flutter_advanced_networkimage/provider.dart';

enum PostView{
  ImagePreview,
  IntendedPreview,
  Compact,
  NoPreview
}

class postInnerWidget extends StatelessWidget {
  PostView viewSetting = PostView.ImagePreview;
  bool isFullSize = true;
  final Post post;
  final PreviewCallback callBack;

  postInnerWidget(this.post, this.callBack);

  Widget getWidget(BuildContext context){

    if (post.self) {
      return new defaultColumn(post, callBack);
    }
    if (post.linkType == LinkType.DirectImage || post.linkType == LinkType.YouTube) {
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
                    child: new defaultColumn(post, callBack),
                  ),
                ))
          ]);
          break;
        case PostView.ImagePreview:
          return new Column(
            children: <Widget>[
              getExpandedImage(context),
              defaultColumn(post, callBack)
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
    return new defaultColumn(post, callBack);
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
                (post.linkType == LinkType.YouTube) ? getYoutubeThumbnailFromId(getYoutubeIdFromUrl(post.url)) : post.url,
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
      _launchURL(context, post);
    }else if(post.linkType == LinkType.DirectImage){
      callBack.preview(post.url);
    }
  }

  void handlePress(BuildContext context){
    switch (post.linkType) {
      case LinkType.YouTube:
        callBack.preview(getYoutubeThumbnailFromId(getYoutubeIdFromUrl(post.url)));
        break;
      default :
          callBack.preview(post.url);
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
}

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
                child: new Text(
                  post.title.toString(),
                  style:
                  new TextStyle(fontWeight: FontWeight.normal, fontSize: 12.0),
                  textScaleFactor: 1.0,
                ),
                onTap: (){
                  switch (post.linkType) {
                    case LinkType.YouTube:
                      playYouTube(post.url);
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
          (post.self && post.selftext != null && post.selftext.isNotEmpty)
              ? Container(
            child: Container(
              child: Text(
                post.selftext,
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
                            "${post.points}",
                            textAlign: TextAlign.left,
                            textScaleFactor: 1.0,
                            style: new TextStyle(color: Colors.amberAccent, fontSize: 9.0)),
                        padding:
                            const EdgeInsets.only(left: 6.0, right: 4.0, top: 0.0)),
                    new Padding(
                        child: new Text(
                            "u/${post.author}",
                            textAlign: TextAlign.left,
                            textScaleFactor: 1.0,
                            style: new TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 9.0)),
                        padding:
                            const EdgeInsets.only(left: 0.0, right: 4.0, top: 0.0)),
                    new Padding(
                        child: new Text(
                            "r/${post.subreddit}",
                            textAlign: TextAlign.left,
                            textScaleFactor: 1.0,
                            style: new TextStyle(color: Color.fromARGB(255, 109, 250, 255), fontSize: 9.0)),
                        padding:
                            const EdgeInsets.only(left: 0.0, right: 4.0, top: 0.0)),
                    new GestureDetector(
                      child: new Text("${post.comments} comments"
                            ,style: TextStyle(
                            fontSize: 9.0,
                            color: Colors.white.withOpacity(0.9)
                          ),
                        ),
                        onTap: (){
                          //showComments(context);
                        },
                    )
          ])),
          const SizedBox(
            height: 3.5,
          )
        ]),
        onTap: (){
          currentPostId = post.id;
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
    String url = post.url;
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