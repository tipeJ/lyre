import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import 'package:flutter/material.dart' as prefix0;
import 'package:flutter_html/flutter_html.dart';
import 'package:lyre/Themes/textstyles.dart';
import 'package:lyre/UI/Comments/comment.dart';
import '../Resources/RedditHandler.dart';

class replyWindow extends StatefulWidget {
  final Comment comment;
  final String initialText;
  replyWindow(this.comment, [this.initialText]);

  _replyWindowState createState() => _replyWindowState();
}

enum ReplySendingState {
  Sending,
  Inactive,
  Error
}

class _replyWindowState extends State<replyWindow> {
  
  TextEditingController _replyController;

  _replyWindowState();

  ReplySendingState _replySendingState = ReplySendingState.Inactive;
  String error = "";

  bool popReady = true;
  Future<bool> _willPop(){
    if (_replySendingState == ReplySendingState.Error) {
      setState(() {
       _replySendingState = ReplySendingState.Inactive; 
      });
      return Future.value(false);
    } else if (_replySendingState == ReplySendingState.Sending){
      return Future.value(false);
    }
    return popReady ? Future.value(true) : Future.value(false);
  }
  List<Widget> parentWidgets = [];

  final double initialHeight = 250;

  @override
  void initState() {
    _replyController = TextEditingController(text: widget.initialText ?? "");
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
                          content: Html(data: '',),
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
                  onTap: _reply,
                ),
              ),
            ]
           ),
           body: Stack(
             children: <Widget>[
               IgnorePointer(
                 ignoring: _replySendingState != ReplySendingState.Inactive,
                 child: Column(
                  children: <Widget>[
                    CommentContent(widget.comment),
                    TextField(
                      enabled: _replySendingState == ReplySendingState.Inactive,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      controller: _replyController,
                    ),
                  ]
                ),
               ),
              prefix0.Visibility (
                visible: _replySendingState != ReplySendingState.Inactive,
                child: Container (
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: Colors.black.withOpacity(0.6),
                  child: _replySendingState == ReplySendingState.Sending
                      ? Center(
                        child: CircularProgressIndicator()
                      )
                      : Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(bottom: 10.0),
                            child: Text('ERROR: ' + error, style: LyreTextStyles.errorMessage,),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                            OutlineButton(
                              child: Text('Close'),
                              onPressed:() => Navigator.of(context).maybePop(),
                            ),
                            OutlineButton(
                              child: Text('Retry'),
                              onPressed: _reply,
                            )
                          ],)
                        ],
                      )
                )
              )
             ],
           ),
         ),
       );
  }
  _reply() {
    setState(() {
      _replySendingState = ReplySendingState.Sending;
    });
    reply(widget.comment, _replyController.text).then((value) {
      if (value is String) {
        setState(() {
          error = value;
          _replySendingState = ReplySendingState.Error;
        });
      } else if (value is Comment) {
        print('poping');
        Navigator.of(context).pop(value);
      }
    });
  }
  Future<void> _addParentComment(Comment c) async {
    //Break the loop if comment is a root comment (parent is a submission, not a comment).
    if(c.isRoot)return;
    var parent = await c.parent() as Comment;
    parentWidgets.add(CommentContent(parent));
    _addParentComment(parent);
  }
}