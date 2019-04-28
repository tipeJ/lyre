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

class postInnerWidget extends StatelessWidget {
  bool isIntended = true;
  final Post post;
  final PreviewCallback callBack;

  postInnerWidget(this.post, this.callBack);

  Widget getWidget(BuildContext context){
    if (post.self) {
      return new defaultColumn(post, callBack);
    }
    if (post.linkType == LinkType.DirectImage || post.linkType == LinkType.YouTube) {
      if (isIntended) {
        return new Stack(children: <Widget>[
          new Container(
            child: SizedBox.expand(
              child: new GestureDetector(
                child: Image(
                  image: AdvancedNetworkImage(
                    
                    (post.linkType == LinkType.YouTube) ? getYoutubeThumbnailFromId(getYoutubeIdFromUrl(post.url)) : post.url,
                    useDiskCache: true,
                    cacheRule: CacheRule(maxAge: const Duration(days: 7))
                  ),
                  fit: BoxFit.cover,
                ),
                
                onTap: () {
                  callBack.preview(post.url);
                },
                onLongPress: (){
                  callBack.preview(post.url);
                },
                onLongPressUp: (){
                    callBack.previewEnd();
                },
            ),

            ),
            
            //The fixed height of the post image:
            height: 400.0,
          ),
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
      } else {
        return new defaultColumn(post, callBack);
      }
    }
    return new defaultColumn(post, callBack);
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
        mainAxisSize: MainAxisSize.max,
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
                      _launchURL(context, post.url);
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
  void _launchURL(BuildContext context, String url) async {
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
}
