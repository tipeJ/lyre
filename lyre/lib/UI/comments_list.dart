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

  @override
  State<commentsList> createState() => new comL(post);
}
class comL extends State<commentsList> with SingleTickerProviderStateMixin, PreviewCallback{

  @override
  void previewEnd() {
    if(isPreviewing){
      previewUrl = "";
      // previewController.reverse();
      hideOverlay();
    }
  }

  @override
  void view(String s) {

  }

  @override
  void preview(String url) {
    if(!isPreviewing){
      previewUrl = url;
      showOverlay();
      //previewController.forward();
    }
  }

  Post post;

  comL(this.post);

  bool isPreviewing = false;
  var previewUrl = "";

  OverlayState state;
  OverlayEntry entry;
  @override
  void initState(){
    super.initState();
    state = Overlay.of(context);
    entry = OverlayEntry(
        builder: (context) => new GestureDetector(
          child: new Container(
              width: 400.0,
              height: 500.0,
              child: new Opacity(
                opacity: 1.0,
                child: new Container(
                  child: new CachedNetworkImage(
                      imageUrl: previewUrl
                  ),
                  color: Color.fromARGB(200, 0, 0, 0),
                ),
              )
          ),
          onLongPressUp: (){
            hideOverlay();
          },
        )
    );
  }
  showOverlay(){
    if(!isPreviewing){
      state.insert(entry);
      isPreviewing = true;
    }

  }
  hideOverlay(){
    if(isPreviewing){
      entry.remove();
      state.deactivate();
      isPreviewing = false;
    }

  }
  @override
  Widget build(BuildContext context) {
    bloc.fetchComments();
    return Scaffold(
        appBar: AppBar(
          title: Text('Comments'),
        ),
        body: new Container(
          child: new GestureDetector(
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
              ],
            ),
            onTapUp: hideOverlay(),
            onHorizontalDragUpdate: (DragUpdateDetails details) {
              if (details.delta.direction < 1.0 && details.delta.dx > 30) {
                Navigator.pop(context);
              }
            }
          )
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
              /*onHorizontalDragUpdate: (DragUpdateDetails details) {
                if (details.delta.direction < 1.0 && details.delta.dx > 30) {
                  Navigator.pop(context);
                }
              },*/
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