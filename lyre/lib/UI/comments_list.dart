import 'package:flutter/material.dart';
import '../Models/item_model.dart';
import '../Blocs/comments_bloc.dart';
import 'posts_list.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Resources/globals.dart';
import '../Models/Comment.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/utils_html.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'postInnerWidget.dart';
import 'interfaces/previewCallback.dart';
import '../Models/Post.dart';
class commentsList extends StatefulWidget{
  final Post post;

  commentsList(this.post);

  comL createState() => new comL(post);
}
class comL extends State<lyApp> with SingleTickerProviderStateMixin, PreviewCallback{
  Post post;

  comL(this.post);

  bool isPreviewing = false;
  var previewUrl = "";

  void initV(BuildContext context) {
    opacityAnimation = opacityTween.animate(CurvedAnimation(
        parent: previewController,
        curve: Curves.easeInSine));
    previewController.reset();
  }

  @override
  void initState() {
    super.initState();
    previewController = new AnimationController(
        vsync: this, duration: new Duration(milliseconds: 50));

    new Future.delayed(Duration.zero, () {
      initV(context);
    });
  }

  @override
  void preview(String url) {
    if(!isPreviewing){
      previewUrl = url;
      isPreviewing = true;
      previewController.forward();
    }
  }

  @override
  void view(String url) {

  }

  @override
  void previewEnd(){
    if(isPreviewing){
      previewUrl = "";
      isPreviewing = false;
      previewController.reverse();
    }
  }
  Tween opacityTween = new Tween<double>(begin: 0.0,end: 1.0);
  Animation<double> opacityAnimation;
  AnimationController previewController;

  @override
  Widget build(BuildContext context) {
    bloc.fetchComments();
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
      ),
      body: new Container(
        child: new Stack(
          children: <Widget>[
            new StreamBuilder(
              stream: bloc.allComments,
              builder: (context, AsyncSnapshot<CommentM> snapshot) {
                if (snapshot.hasData) {
                  return getCommentsPage(snapshot);
                } else if (snapshot.hasError) {
                  return Text(snapshot.error.toString());
                }
                return Center(child: CircularProgressIndicator());
              },
            ),
            new Opacity(
              opacity: opacityAnimation.value,
              child: new Container(
                child: new CachedNetworkImage(
                    imageUrl: previewUrl
                ),
                color: Color.fromARGB(200, 0, 0, 0),
              ),
            )
          ],
        ),
      )
    );
  }

  Widget getCommentsPage(AsyncSnapshot<CommentM> snapshot) {
    var comments = snapshot.data.results;
    return new ListView.builder(
        itemCount: comments.length + 1,
        itemBuilder: (BuildContext context, int i) {
          if (i == 0) {
            return new Hero(
                tag: 'post_hero',
                child: new Container(
                    child: new Card(child: postInnerWidget(post, this)),
                    padding: const EdgeInsets.only(
                        left: 0.0, right: 0.0, top: 8.0, bottom: 0.0)));
          } else {
            var comment = comments[i-1];
            return new GestureDetector(
              onHorizontalDragUpdate: (DragUpdateDetails details) {
                if (details.delta.direction < 1.0 && details.delta.dx > 30) {
                  Navigator.pop(context);
                }
              },
              child: new Container(
                  child: new Card(
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.circular(0.5),
                      ),
                      child: new Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            new Padding(
                                child: new Text(
                                    "\u{1F44D} ${comment.points}    \u{1F60F} ${comment.author}",
                                    textAlign: TextAlign.right,
                                    textScaleFactor: 1.0,
                                    style: new TextStyle(
                                        color: Colors.black.withOpacity(0.6))),
                                padding: const EdgeInsets.only(
                                    left: 16.0, right: 16.0, top: 16.0)),
                            new Padding(
                                child: new Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new MarkdownBody(
                                      data: convertToMarkdown(comment.text),
                                    )
                                  ],
                                ),
                                padding: const EdgeInsets.only(
                                    left: 16.0,
                                    right: 16.0,
                                    top: 16.0,
                                    bottom: 16.0))
                          ])),
                  padding: new EdgeInsets.only(
                      left: 0.0 + comment.depth * 8,
                      right: 0.5,
                      top: comment.depth == 0 ? 2.0 : 0.1,
                      bottom: 0.0)),
            );
          }
        });
  }
}
