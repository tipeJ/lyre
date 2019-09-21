import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lyre/UI/Comments/comment.dart';

class replyWindow extends StatefulWidget {
  final Comment c;

  replyWindow(this.c);

  _replyWindowState createState() => _replyWindowState(c);
}

class _replyWindowState extends State<replyWindow> {
  final Comment comment;

  _replyWindowState(this.comment);

  bool popReady = true;
  Future<bool> _willPop(){
    return popReady ? Future.value(true) : Future.value(false);
  }
  List<Widget> parentWidgets = [];

  final double initialHeight = 250;

  @override
  void initState() {
    parentWidgets.add(
      Container(
        child: Hero(
          child: CommentContent(comment),
          tag: 'comment_hero ${comment.id}',
        ),
        color: Colors.black26,
      )
    );
    addParentComment(comment).then((_){
      setState(() {
        
      });
    });
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
         onWillPop: _willPop,
         child: Scaffold(
           appBar: AppBar(
             title: Text("Reply"),
             actions: <Widget>[
              InkWell(
                  child: Icon(Icons.remove_red_eye),
                  onTap: (){
                    showDialog(
                      context: context,
                      builder: (BuildContext context){
                        return AlertDialog(
                          content: MarkdownBody(
                                data: 'comment data',
                              ),
                          actions: <Widget>[
                            FlatButton(
                              child: Text('Close'),
                              onPressed: (){
                                Navigator.of(context).pop();
                              },
                            )
                          ],
                        );
                      }
                    );
                  },
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15.0),
                child: InkWell(
                  child: Icon(Icons.send),
                  onTap: (){
                    
                  },
                ),
              ),
            ]
           ),
           body: Stack(
               children: <Widget>[
                 Container(
                   padding: EdgeInsets.only(
                    top: initialHeight,
                    left: 15.0,
                    right: 15.0
                  ),
                  child: Column(
                    children: <Widget>[
                      TextField()
                    ],
                  ),
                 ),
                Container(
                  height: initialHeight,
                  child: ListView.builder(
                    itemCount: parentWidgets.length,
                    itemBuilder: (BuildContext context, int i){
                      return parentWidgets[i];
                    },
                  ),
                )
               ],
             ),
         ),
       );
  }
  Future<void> addParentComment(Comment c) async {
    //Break the loop if comment is a root comment (parent is a submission, not a comment).
    if(c.isRoot)return;
    var parent = await c.parent() as Comment;
    parentWidgets.add(CommentContent(parent));
    addParentComment(parent);
  }
}