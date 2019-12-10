import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import 'package:flutter/material.dart' as prefix1;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lyre/Resources/RedditHandler.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/UI/ActionItems.dart';
import 'package:lyre/UI/Animations/OnSlide.dart';
import 'package:lyre/UI/Comments/bloc/bloc.dart';
import 'package:lyre/Resources/RedditHandler.dart';
import '../../utils/redditUtils.dart';

OnSlide _commentsSliderWidget(BuildContext context, Widget child, Comment comment) {
  return OnSlide(
    backgroundColor: Colors.transparent,
    //key: PageStorageKey(comment.hashCode),
    items: <ActionItems>[
      ActionItems(
        icon: IconButton(
          icon: Icon(Icons.keyboard_arrow_up),onPressed: (){},
          color: comment.vote == VoteState.upvoted ? Colors.amber : Colors.grey,),
        onPress: (){
          changeCommentVoteState(VoteState.upvoted, comment).then((_){
          });
        }
      ),
      ActionItems(
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: comment.vote == VoteState.downvoted ? Colors.purple : Colors.grey,),
        onPress: (){
          changeCommentVoteState(VoteState.downvoted, comment).then((_){
          });
        }
      ),
      ActionItems(
        icon: Icon(
          Icons.bookmark,
          color: comment.saved ? Colors.yellow : Colors.grey,),
        onPress: (){
          changeCommentSave(comment);
          comment.refresh().then((_){
          });
        }
      ),
      ActionItems(
        icon: Icon(
          Icons.reply,
          color: Colors.grey,),
        onPress: (){
          Navigator.of(context).pushNamed('reply', arguments: {
              'redditor'        : comment,
              'content_source'  : ContentSource.Redditor
            });
        }
      ),
      ActionItems(
        icon: Icon(Icons.person, color: Colors.grey),
        onPress: (){
          Navigator.pushNamed(context, 'reply', arguments: {
            'comment'        : comment,
            'reply_text'  : ""
          });
        }
      ),
      ActionItems(
        icon: Icon(Icons.menu,color: Colors.grey,),
        onPress: (){

        }
      ),
    ],
    
    child: child
  );
}
Color getColor(int depth) {
    if (depth >= 0 && depth <= colorList.length - 1) {
      return colorList[depth];
    }
    int remain = depth % colorList.length;
    return colorList[remain];
  }

List<Color> colorList = [
    Color.fromARGB(255, 163, 255, 221),
    Color.fromARGB(255, 255, 202, 130),
    Color.fromARGB(255, 130, 255, 198),
    Color.fromARGB(255, 239, 170, 255),
    Color.fromARGB(255, 170, 182, 255),
    Color.fromARGB(255, 247, 255, 170),
    Color.fromARGB(255, 255, 140, 209),
    Color.fromARGB(255, 140, 145, 255),
  ];

class CommentWidget extends StatefulWidget {
  final Comment comment;
  final int location;
  CommentWidget(this.comment, this.location);

  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {

  TextEditingController _replyController;
  bool _replyVisible = false;
  ReplySendingState _replySendingState;

  @override void dispose(){
    _replyController?.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return widget.comment.isRoot
      ? _commentContent(context)
      : dividersWrapper(depth: widget.comment.depth, child: _commentContent(context));
  }

  Column _commentContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      
      children: <Widget>[
        OnSlide(
          backgroundColor: Colors.transparent,
          //key: PageStorageKey(comment.hashCode),
          items: <ActionItems>[
            ActionItems(
              icon: IconButton(
                icon: const Icon(Icons.keyboard_arrow_up),onPressed: (){},
                color: widget.comment.vote == VoteState.upvoted ? Colors.amber : Colors.grey,),
              onPress: (){
                changeCommentVoteState(VoteState.upvoted, widget.comment).then((_){
                });
              }
            ),
            ActionItems(
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: widget.comment.vote == VoteState.downvoted ? Colors.purple : Colors.grey,),
              onPress: (){
                changeCommentVoteState(VoteState.downvoted, widget.comment).then((_){
                });
              }
            ),
            ActionItems(
              icon: Icon(
                Icons.bookmark,
                color: widget.comment.saved ? Colors.yellow : Colors.grey,),
              onPress: (){
                changeCommentSave(widget.comment);
                widget.comment.refresh().then((_){
                });
              }
            ),
            ActionItems(
              icon: Icon(
                _replyVisible ? Icons.close : Icons.reply,
                color: Colors.grey,),
              onPress: (){
                _handleReplyButtonToggle();
              },
            ),
            ActionItems(
              icon: Icon(Icons.person, color: Colors.grey),
              onPress: () {
                Navigator.pushNamed(context, 'posts', arguments: {
                  'redditor'        : widget.comment.author,
                  'content_source'  : ContentSource.Redditor
                });
              }
            ),
            ActionItems(
              icon: Icon(Icons.menu,color: Colors.grey,),
              onPress: (){

              }
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _commentContentChildren(context, widget.comment)),
            ),
              
              StatefulBuilder(
                builder: (BuildContext context, setState) {
                  return prefix1.Visibility(
                    child: _replyWidget(),
                    visible: _replyVisible);
                  },
              ),
              Container(height: _dividerWidth, color: _dividerColor,)
            ]);
  }

  Widget _replyWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(15.0)
      ),
      margin: const EdgeInsets.all(15.0),
      child: Column(
        children: <Widget>[
          Padding(
            child: TextField(
                keyboardType: TextInputType.multiline,
                maxLines: null,
                controller: _replyController ?? null,
                autofocus: true,
                decoration: InputDecoration(hintText: 'Reply'),
                onSubmitted: (s){
                  _send();
                },
            ),
            padding: const EdgeInsets.all(10.0),
          ),
          //Divider(),
          Row(children: <Widget>[
            IconButton(icon: const Icon(Icons.close), onPressed: (){ _handleReplyButtonToggle();},),
            const Spacer(),
            IconButton(icon: const Icon(Icons.fullscreen), onPressed: (){
              Navigator.pushNamed(context, 'reply', arguments: {
                'content'        : widget.comment,
                'reply_text'  : _replyController?.text
              }).then((returnValue) {
                if (returnValue is Comment) {
                  setState(() {
                    _handleReplyButtonToggle();
                    BlocProvider.of<CommentsBloc>(context).add(AddComment(location: widget.location, comment: returnValue));
                  });
                }
              }); 
            },),
            _replySendingState == ReplySendingState.Inactive
              ? IconButton(icon: Icon(Icons.send), onPressed: _send,)
              : Padding(
                padding: EdgeInsets.only(right: 10),
                child: CircularProgressIndicator()
              )
          ],),
        ],
      ),
    );
  }

  void _handleReplyButtonToggle() {
    if (PostsProvider().isLoggedIn()) {
        if (_replyVisible) {
          setState(() {
            _replyVisible = false;
            _replySendingState = null;
          });
              
        } else {
          _replyController = TextEditingController();
          setState(() {
            _replySendingState = ReplySendingState.Inactive;
            _replyVisible = !_replyVisible;
          });
          
        }
    } else {
      final logInSnackBar = SnackBar(content: Text("Log in to reply"),);
      Scaffold.of(context).showSnackBar(logInSnackBar);
    }
  }

  void _send() {
    //If the reply value is empty, show error snackbar.
    if (_replyController.text.isEmpty) {
      final textSnackBar = SnackBar(content: Text("Cannot reply with an empty message"),);
      Scaffold.of(context).showSnackBar(textSnackBar);
      return;
    }
    setState(() {
      _replySendingState = ReplySendingState.Sending;
    });
    reply(widget.comment, _replyController.text).then((value) {
      //Show Error
      if (value is String) {
        final textSnackBar = SnackBar(content: Text("Error sending comment: $value"),);
        Scaffold.of(context).showSnackBar(textSnackBar);
        setState(() {
         _replySendingState = ReplySendingState.Inactive; 
        });
      } else {
        setState(() {
          _handleReplyButtonToggle();
          BlocProvider.of<CommentsBloc>(context).add(AddComment(location: widget.location, comment: value));
        });
      }
    });
  }
}
List<Widget> _commentContentChildren(BuildContext context, Comment comment) {
  return [ new Padding(
      child: Row(
        children: <Widget>[
          Material(
            child: Text("${comment.score} ",
              textAlign: TextAlign.left,
              textScaleFactor: 0.65,
              style: new TextStyle(
                  fontWeight: FontWeight.bold,
                  color: getScoreColor(comment, context))),
          ),
          Material(
            child: Text(
            "● u/${comment.author}",
            textScaleFactor: 0.7,
            ),
          ),
          Spacer(),
          Text(
            getSubmissionAge(comment.createdUtc),
            textScaleFactor: 0.7,
            ),
        ],
      ),
      padding: const EdgeInsets.only(
          left: _contentEdgePadding, right: 16.0, top: 6.0)),
    new Padding(
      child: MarkdownBody(data: comment.body,),
      padding: const EdgeInsets.only(
          left: _contentEdgePadding, right: 16.0, top: 6.0, bottom: 12.0))];
}
class CommentContent extends StatelessWidget {
  final Comment comment;
  const CommentContent(this.comment, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _commentContentChildren(context, comment),
    );
  }
}
const _contentEdgePadding = 16.0;
const double _dividerSpacer = 10.5;
const double _dividerWidth = 0.75;
final Color _dividerColor = Colors.grey.withOpacity(0.2);

List<Widget> _getDividers(int depth) {
  List<Widget> returnList = [];
  for (var i = 1; i < depth+1; i++) {
    returnList.add(Container(
      margin: EdgeInsets.only(left: _dividerSpacer),
      color: _dividerColor,
      width: _dividerWidth,
    ));
  }
  return returnList;
}

Widget dividersWrapper({int depth, Widget child}) {
  return IntrinsicHeight(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _getDividers(depth)..add(Flexible(child: child,)),)
  );
}
class MoreCommentsWidget extends StatefulWidget {
  final MoreComments moreComments;
  final int index;

  MoreCommentsWidget(this.moreComments, this.index);
  @override
  _MoreCommentsWidgetState createState() => _MoreCommentsWidgetState();
}

class _MoreCommentsWidgetState extends State<MoreCommentsWidget> {

  _MoreCommentsWidgetState();

  @override
  Widget build(BuildContext context) {
    return Container(
      child: dividersWrapper(
        depth: widget.moreComments.data["depth"],
        child: InkWell(
          onTap: () {
              if (widget.moreComments.id != BlocProvider.of<CommentsBloc>(context).loadingMoreId) {
                setState(() {
                  BlocProvider.of<CommentsBloc>(context).loadingMoreId = widget.moreComments.id;
                  BlocProvider.of<CommentsBloc>(context).add(FetchMore(moreComments: widget.moreComments, location: widget.index));
                });
              }
            },
          child: Container(
            padding: EdgeInsets.only(left: _contentEdgePadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                (BlocProvider.of<CommentsBloc>(context).loadingMoreId == widget.moreComments.id)
                  ? new Padding(
                      padding: EdgeInsets.all(5.0),
                      child: SizedBox(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                        height: 18.0,
                        width: 18.0,
                      ),
                    )
                  : Container(),
                new Text(
                  "Load more comments (${widget.moreComments.count})"
                ),
                Container(height: _dividerWidth, color: _dividerColor,)
              ]
            ,)
          )
        ),
      )
    );
  }
}