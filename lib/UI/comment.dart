import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../utils/redditUtils.dart';

class CommentWidget extends StatelessWidget {
  final Comment comment;
  const CommentWidget(this.comment);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: new Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Padding(
              child: Row(
                children: <Widget>[
                  Material(
                    child: Text("${comment.score} ",
                      textAlign: TextAlign.left,
                      textScaleFactor: 0.65,
                      style: new TextStyle(
                          fontWeight: FontWeight.bold,
                          color: getScoreColor(comment, context))),
                  )
                  ,
                  Material(
                    child: Text(
                    "● u/${comment.author}",
                    textScaleFactor: 0.7,
                  ),
                  ),
                  
                  
                ],
              ),
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16.0, top: 6.0)),
          new Padding(
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new MarkdownBody(
                    data: comment.body,
                  )
                ],
              ),
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16.0, top: 6.0, bottom: 16.0))
        ]),
    );
  }
}