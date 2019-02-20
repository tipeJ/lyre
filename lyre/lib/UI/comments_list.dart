import 'package:flutter/material.dart';
import '../Models/item_model.dart';
import '../Blocs/comments_bloc.dart';
import 'posts_list.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Resources/globals.dart';
import '../Models/Comment.dart';
import 'Animations/slide_right_transition.dart';
import '../utils/utils_html.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'postInnerWidget.dart';
import '../Models/Post.dart';

class commentsList extends StatelessWidget {
  Post post;

  commentsList(this.post);

  @override
  Widget build(BuildContext context) {
    bloc.fetchComments();
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
      ),
      body: StreamBuilder(
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
                    child: new Card(child: postInnerWidget(post)),
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
