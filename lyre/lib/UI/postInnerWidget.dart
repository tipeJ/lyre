import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../Models/Post.dart';
import '../Resources/globals.dart';
import '../utils/imageUtils.dart';
import '../Ui/Animations/slide_right_transition.dart';
import 'comments_list.dart';
import '../utils/utils_html.dart';
import 'interfaces/previewCallback.dart';
import 'package:url_launcher/url_launcher.dart';

class postInnerWidget extends StatelessWidget {
  bool isIntended = true;
  final Post post;
  final PreviewCallback callBack;

  postInnerWidget(this.post, this.callBack);

  Widget build(BuildContext context) {
    if (post.self) {
      return new defaultColumn(post, callBack);
    }
    var divided = post.url.split(".");
    var last = divided.last;
    if (supportedFormats.contains(last)) {
      if (isIntended) {
        return new Stack(children: <Widget>[
          new Container(
            child: new GestureDetector(
              child: new CachedNetworkImage(
                fit: BoxFit.fitWidth,
                fadeInDuration: Duration(milliseconds: 500),
                imageUrl: post.url,
              ),
              onLongPress: () {
                callBack.preview(post.url);
              },
              /*onLongPressUp: (){
                  callBack.previewEnd();
                },*/
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
                  color: Color.fromARGB(100, 0, 0, 0),
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
              child: new Text(
                post.title.toString(),
                style:
                    new TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
                textScaleFactor: 1.0,
              ),
              padding:
                  const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0)),
          const SizedBox(
            height: 3.5,
          ),(post.self && post.selftext != null)
              ? Container(
            child: ShaderMask(
              child: Container(
                child: MarkdownBody(
                  data: convertToMarkdown(post.selftext),
                ),

              ),
              shaderCallback: (Rect bounds) {
                return LinearGradient(colors: [
                  Colors.white,
                  Theme.of(context).primaryColor,
                ], stops: [
                  0.0,
                  1.0,
                ], begin: Alignment.topCenter, end: Alignment.bottomCenter)
                    .createShader(bounds);
              },
              blendMode: BlendMode.srcATop,
            ),
            padding: EdgeInsets.only(
                left: 10.0, right: 10.0, top: 12.0, bottom: 8.0),
            height: 175.0,
          )
              : Container(height: 0.0),
          new ButtonTheme.bar(
              child: new ButtonBar(children: <Widget>[
            new Padding(
                child: new Text(
                    "\u{1F44D} ${post.points}    \u{1F60F} ${post.author}",
                    textAlign: TextAlign.right,
                    textScaleFactor: 1.0,
                    style: new TextStyle(color: Colors.black.withOpacity(0.6))),
                padding:
                    const EdgeInsets.only(left: 16.0, right: 16.0, top: 0.0)),
            new FlatButton(
                child: new Text("${post.comments} comments"),
                onPressed: () {
                  currentPostId = post.id;
                  showComments(context);
                }),
            !post.self
                ? new FlatButton(
                    child: new Text("\u{1F517} Open"),
                    onPressed: () {
                      if (!post.self) launch(post.url);
                    })
                : null
          ])),
        ]);
  }

  void showComments(BuildContext context) {
    if (callback is comL) {
      return;
    }
    Navigator.push(context, SlideRightRoute(widget: commentsList(post)));
  }
}
