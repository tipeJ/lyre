import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:transparent_image/transparent_image.dart';
import '../Models/item_model.dart';
import '../Models/Post.dart';
import '../Resources/globals.dart';
import '../utils/imageUtils.dart';
import '../Ui/Animations/slide_right_transition.dart';
import 'comments_list.dart';
import 'package:url_launcher/url_launcher.dart';

class postInnerWidget extends StatelessWidget {
  bool isIntended = true;
  final Post post;

  postInnerWidget(this.post);

  Widget build(BuildContext context) {
    if (post.self) {
      return new defaultColumn(post);
    }
    var divided = post.url.split(".");
    var last = divided.last;
    if (supportedFormats.contains(last)) {
      if (isIntended) {
        return new Stack(children: <Widget>[
          new FadeInImage.memoryNetwork(
            fit: BoxFit.fill,
            placeholder: kTransparentImage,
            image: post.url,
          ),
          new Positioned(
              bottom: 0.0,
              child: new BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 10.0,
                  sigmaY: 10.0,
                ),
                child: new Container(
                  width: MediaQuery.of(context).size.width,
                  color: Color.fromARGB(100, 0, 0, 0),
                  child: new defaultColumn(post),
                ),
              ))
        ]);
      } else {
        return new defaultColumn(post);
      }
    }
    return new defaultColumn(post);
  }
}
class defaultColumn extends StatelessWidget{

  final Post post;
  defaultColumn(this.post);

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
          ),
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
              ]))
        ]);
  }
  void showComments(BuildContext context) {
    Navigator.push(context, SlideRightRoute(widget: commentsList()));
  }
}