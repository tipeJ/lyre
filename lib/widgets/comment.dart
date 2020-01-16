import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import 'package:flutter/material.dart' as prefix1;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Resources/RedditHandler.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/widgets/ActionItems.dart';
import 'package:lyre/screens/Animations/OnSlide.dart';
import 'package:lyre/Bloc/bloc.dart';
import 'package:lyre/Resources/RedditHandler.dart';
import 'package:lyre/screens/interfaces/previewCallback.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../utils/redditUtils.dart';

class CommentOptionsNotification extends Notification {
  final Comment comment;

  const CommentOptionsNotification({@required this.comment});
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
  final PreviewSource previewSource;
  CommentWidget(this.comment, this.location, this.previewSource);

  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {

  TextEditingController _replyController;
  bool _replyVisible = false;
  SendingState _replySendingState;
  bool _saved;

  @override
  void initState() { 
    super.initState();
    _saved = widget.comment.saved;
  }

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
              icon: Icon(
                MdiIcons.arrowUpBold,
                color: widget.comment.vote == VoteState.upvoted ? Colors.amber : Colors.grey,),
              onPress: () async {
                await changeCommentVoteState(VoteState.upvoted, widget.comment);
                setState((){});
              }
            ),
            ActionItems(
              icon: Icon(
                MdiIcons.arrowDownBold,
                color: widget.comment.vote == VoteState.downvoted ? Colors.purple : Colors.grey,),
              onPress: () async {
                await changeCommentVoteState(VoteState.downvoted, widget.comment);
                setState((){});
              }
            ),
            ActionItems(
              icon: Icon(
                Icons.bookmark,
                color: _saved ? Colors.yellow : Colors.grey,),
              onPress: () async {
                setState((){
                  _saved = !_saved;
                });
                await changeCommentSave(widget.comment);
              }
            ),
            ActionItems(
              icon: Icon(
                _replyVisible ? Icons.close : Icons.reply,),
              onPress: (){
                _handleReplyButtonToggle();
              },
            ),
            ActionItems(
              icon: const Icon(Icons.person),
              onPress: () {
                Navigator.of(context).pushNamed('posts', arguments: {
                  'target'        : widget.comment.author,
                  'content_source'  : ContentSource.Redditor
                });
              }
            ),
            ActionItems(
              icon: const Icon(Icons.menu),
              onPress: (){
                CommentOptionsNotification(comment: widget.comment)..dispatch(context);
              }
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [ 
              new Padding(
                child: Row(
                  children: <Widget>[
                    Text("${widget.comment.score} ",
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.body1.apply(color: getScoreColor(widget.comment, context), fontSizeFactor: 0.9)),
                    Text(
                      "● u/${widget.comment.author}",
                      style: Theme.of(context).textTheme.body2,
                    ),
                    widget.previewSource != PreviewSource.Comments
                      ? Padding(
                          padding: EdgeInsets.only(left: 3.5),
                          child: Text.rich(
                            TextSpan(
                              style: Theme.of(context).textTheme.body2,
                              children: [
                                TextSpan(text: "in "),
                                TextSpan(text: "${widget.comment.subreddit.displayName}", style: TextStyle(color: Theme.of(context).accentColor))
                              ]
                            ),
                            textScaleFactor: 0.7,
                          )
                      )
                      : null,
                    Spacer(),
                    Text(
                      getSubmissionAge(widget.comment.createdUtc),
                      style: Theme.of(context).textTheme.body2,
                    ),
                  ].where((w) => notNull(w)).toList(),
                ),
                padding: const EdgeInsets.only(
                    left: _contentEdgePadding, right: 16.0, top: 6.0)),
              new Padding(
                child: Text(widget.comment.body, style: Theme.of(context).textTheme.body1),
                padding: const EdgeInsets.only(
                    left: _contentEdgePadding, right: 16.0, top: 6.0, bottom: 12.0)),
                    
              ],
            )),
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
            _replySendingState == SendingState.Inactive
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
            _replySendingState = SendingState.Inactive;
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
      _replySendingState = SendingState.Sending;
    });
    reply(widget.comment, _replyController.text).then((value) {
      //Show Error
      if (value is String) {
        final textSnackBar = SnackBar(content: Text("Error sending comment: $value"),);
        Scaffold.of(context).showSnackBar(textSnackBar);
        setState(() {
         _replySendingState = SendingState.Inactive; 
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
List<Widget> _commentContentChildren(BuildContext context, Comment comment, PreviewSource previewSource) {
  return [ 
    new Padding(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text("${comment.score} ",
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.body2.apply(color: getScoreColor(comment, context)),
          ),
          Text(
            "● u/${comment.author}",
            style: Theme.of(context).textTheme.body2,
          ),
          previewSource != PreviewSource.Comments
            ? Padding(
                padding: const EdgeInsets.only(left: 3.5),
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: "in "),
                      TextSpan(text: "${comment.subreddit.displayName}", style: Theme.of(context).textTheme.body2.apply(color: Theme.of(context).accentColor))
                    ]
                  ),
                  style: Theme.of(context).textTheme.body2,
                )
            )
            : null,
          const Spacer(),
          Text(
            getSubmissionAge(comment.createdUtc),
            style: Theme.of(context).textTheme.body2,
          ),
        ].where((w) => notNull(w)).toList(),
      ),
      padding: const EdgeInsets.only(
          left: _contentEdgePadding, right: 16.0, top: 6.0)),
    new Padding(
      child: Text(
        comment.body,
        style: Theme.of(context).textTheme.body1
      ),
      padding: const EdgeInsets.only(
          left: _contentEdgePadding, right: 16.0, top: 6.0, bottom: 12.0))];
}
class CommentContent extends StatelessWidget {
  final Comment comment;
  final PreviewSource previewSource;
  const CommentContent(this.comment, this.previewSource, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _commentContentChildren(context, comment, previewSource),
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
    return dividersWrapper(
      depth: widget.moreComments.data["depth"],
      child: InkWell(
        onTap: () {
            if (widget.moreComments.id != BlocProvider.of<CommentsBloc>(context).loadingMoreId) {
              setState(() {
                BlocProvider.of<CommentsBloc>(context).loadingMoreId = widget.moreComments.id;
                BlocProvider.of<CommentsBloc>(context).add(FetchMoreComments(moreComments: widget.moreComments, location: widget.index));
              });
            }
          },
        child: Container(
          padding: EdgeInsets.only(left: _contentEdgePadding),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  (BlocProvider.of<CommentsBloc>(context).loadingMoreId == widget.moreComments.id)
                    ? Container(
                        padding: const EdgeInsets.all(5.0),
                        child: const CircularProgressIndicator(),
                        constraints: const BoxConstraints.tightFor(width: 20.0, height: 20.0),
                      )
                    : Container(),
                  Text(
                    "Load more comments (${widget.moreComments.count})",
                      style: Theme.of(context).textTheme.body2,
                  ),
                ]
              ,),
              Container(height: _dividerWidth, color: _dividerColor,)
            ],
          )
        )
      ),
    );
  }
}