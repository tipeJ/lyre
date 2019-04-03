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

class postInnerWidget extends StatelessWidget {
  bool isIntended = true;
  final Post post;
  final PreviewCallback callBack;

  postInnerWidget(this.post, this.callBack);

  Widget build(BuildContext context) {
    if (post.self) {
      return new defaultColumn(post, callBack);
    }
    LinkType type = getLinkType(post.url);
    if (type == LinkType.DirectImage || type == LinkType.YouTube) {
      if (isIntended) {
        return new Stack(children: <Widget>[
          new Container(
            child: new GestureDetector(
              child: OverflowBox(
                child: new CachedNetworkImage(
                  fit: BoxFit.contain,
                  fadeInDuration: Duration(milliseconds: 500),
                  //TODO: make this more elegant ffs
                  imageUrl: (type == LinkType.YouTube) ? getYoutubeThumbnailFromId(getYoutubeIdFromUrl(post.url)) : post.url,
                ),
                minHeight: 0.0,
                minWidth: 0.0,
                maxWidth: double.infinity,
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
}

class defaultColumn extends StatelessWidget {
  final Post post;
  final PreviewCallback callback;

  defaultColumn(this.post, this.callback);

  @override
  Widget build(BuildContext context) {
    return new Column(
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
                  var url = post.url;
                  if(!post.self){
                    if(url.contains("youtube.com") || url.contains("youtu.be")){
                      playYouTube(url);
                    }
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
                            style: new TextStyle(color: Colors.lightBlue.withOpacity(0.6), fontSize: 9.0)),
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
                          showComments(context);
                        },
                    )
                    
                        /*
                    !post.self
                        ? new FlatButton(
                            child: new Text("\u{1F517} Open"
                              ,style: TextStyle(
                                  fontSize: 9.0
                              )
                            ),
                            onPressed: () {
                              if (!post.self) _launchURL(context,post.url);
                            })
                        : null*/
          ])),
          const SizedBox(
            height: 3.5,
          )
        ]);
  }

  void showComments(BuildContext context) {
    if (callback is comL) {
      return;
    }
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
    }catch(e){
      debugPrint(e.toString());
    }
  }
}
