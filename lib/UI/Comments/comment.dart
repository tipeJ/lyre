import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lyre/Models/Comment.dart';
import 'package:lyre/Resources/RedditHandler.dart';
import 'package:lyre/UI/ActionItems.dart';
import 'package:lyre/UI/Animations/OnSlide.dart';
import 'package:lyre/UI/Animations/slide_right_transition.dart';
import 'package:lyre/UI/Comments/bloc/bloc.dart';
import 'package:lyre/UI/posts_list.dart';
import 'package:lyre/UI/reply.dart';
import '../../utils/redditUtils.dart';



class CommentWidget extends StatefulWidget {
  final commentC comment;

  CommentWidget(this.comment);
  @override
  _CommentWidgetState createState() => _CommentWidgetState(comment);
}

class _CommentWidgetState extends State<CommentWidget> {
  final commentC comment;

  _CommentWidgetState(this.comment);
  @override
  Widget build(BuildContext context) {
    return new OnSlide(
        backgroundColor: Colors.transparent,
        key: PageStorageKey(comment.hashCode),
        items: <ActionItems>[
          ActionItems(
            icon: IconButton(
              icon: Icon(Icons.keyboard_arrow_up),onPressed: (){},
              color: comment.c.vote == VoteState.upvoted ? Colors.amber : Colors.grey,),
            onPress: (){
              changeCommentVoteState(VoteState.upvoted, comment.c).then((_){
                setState(() {
                  
                });
              });
            }
          ),
          ActionItems(
            icon: IconButton(
              icon: Icon(Icons.keyboard_arrow_down),onPressed: (){},
              color: comment.c.vote == VoteState.downvoted ? Colors.purple : Colors.grey,),
            onPress: (){
              changeCommentVoteState(VoteState.downvoted, comment.c).then((_){
                setState((){

                });
              });
            }
          ),
          ActionItems(
            icon: IconButton(
              icon: Icon(Icons.bookmark),onPressed: (){},
              color: comment.c.saved ? Colors.yellow : Colors.grey,),
            onPress: (){
              changeCommentSave(comment.c);
              comment.c.refresh().then((_){
                setState(() {
                  
                });
              });
            }
          ),
          ActionItems(
            icon: IconButton(
              icon: Icon(Icons.reply),onPressed: (){},
              color: Colors.grey,),
            onPress: (){
              Navigator.push(context, SlideRightRoute(widget: replyWindow(comment.c)));
            }
          ),
          ActionItems(
            icon: IconButton(icon: Icon(Icons.person),onPressed: (){},color: Colors.grey,),
            onPress: (){
              Navigator.push(context, SlideRightRoute(widget: PostsList(comment.c.fullname)));
            }
          ),
          ActionItems(
            icon: IconButton(icon: Icon(Icons.menu),onPressed: (){},color: Colors.grey,),
            onPress: (){

            }
          ),
        ],
        child: new Container(
            child: new Container(
              decoration: BoxDecoration(
                border: Border(
                    left:
                        BorderSide(color: getColor(comment.depth), width: 3.5)),
              ),
              child: Hero(
                child: new CommentContent(comment.c),
                tag: 'comment_hero ${comment.id}',
              ),
            ),
            padding: new EdgeInsets.only(
                left: 3.5 + comment.depth * 3.5,
                right: 0.5,
                top: comment.depth == 0 ? 2.0 : 0.1,
                bottom: 0.0))
      );
  }

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

class CommentContent extends StatelessWidget {
  final Comment comment;
  const CommentContent(this.comment);

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
class MoreCommentsWidget extends StatefulWidget {
  final MoreComments moreComments;
  final int index;

  MoreCommentsWidget(this.moreComments, this.index);
  @override
  _MoreCommentsWidgetState createState() => _MoreCommentsWidgetState(moreComments, index);
}

class _MoreCommentsWidgetState extends State<MoreCommentsWidget> {
  final MoreComments moreComments;
  final int index;

  _MoreCommentsWidgetState(this.moreComments, this.index);

  CommentsBloc bloc;
  
  @override
  Widget build(BuildContext context) {
    bloc = BlocProvider.of<CommentsBloc>(context);
    return new GestureDetector(
        child: Container(
          child: Container(
              child: Row(
                children: <Widget>[
                  (bloc.loadingMoreId == moreComments.id)
                      ? new Container(
                          padding: EdgeInsets.all(5.0),
                          child: SizedBox(
                            child: CircularProgressIndicator(),
                            height: 18.0,
                            width: 18.0,
                          ),
                        )
                      : Container(),
                  new Text(
                    "Load more comments (${moreComments.count})"
                  )
                ],
              ),
              decoration: BoxDecoration(
                  border: Border(
                      left: BorderSide(
                          color: getColor(moreComments.data['depth'].depth), width: 3.5)))),
          padding: EdgeInsets.only(
            left: 4.5 + moreComments.data['depth'] * 3.5,
            right: 0.5,
            top: 0.5,
            bottom: 0.5,
          ),
        ),
        onTapUp: (TapUpDetails details) {
          if (moreComments.id != bloc.loadingMoreId) {
            setState(() {
              bloc.loadingMoreId = moreComments.id;
              bloc.dispatch(FetchMore(moreComments: moreComments, location: index));
            });
          }
        },
      );
  }
}