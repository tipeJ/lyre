import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:lyre/Resources/RedditHandler.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/UI/ActionItems.dart';
import 'package:lyre/UI/Animations/OnSlide.dart';
import 'package:lyre/UI/Comments/bloc/bloc.dart';
import 'package:markdown/markdown.dart' as prefix0;
import '../../utils/redditUtils.dart';


class CommentWidget extends StatelessWidget {
  final Comment comment;

  CommentWidget(this.comment);
  @override
  Widget build(BuildContext context) {
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
              Navigator.pushNamed(context, 'reply', arguments: comment);
            }
          ),
          ActionItems(
            icon: Icon(Icons.person, color: Colors.grey),
            onPress: (){
              Navigator.pushNamed(context, 'posts', arguments: {
                'redditor'        : comment.author,
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
        
        child: new Container(
            child: new CommentContent(comment),
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
  CommentContent(this.comment);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      child: Row(children: <Widget>[
        Padding(child: VerticalDivider(width: dividerWidth,), padding: EdgeInsets.only(right: 3.5),),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[-
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
                  child: Text(comment.body),
                      //new Html(data: prefix0.markdownToHtml(comment.body),)
                  padding: const EdgeInsets.only(
                      left: 16.0, right: 16.0, top: 6.0, bottom: 16.0)),
              Divider(height: dividerWidth,)
            ]),
        ),
      ],)
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

const double dividerWidth = 3.5;

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
          child: Row(
            children: <Widget>[
              Padding(
                child: VerticalDivider(width: dividerWidth,),
                padding: EdgeInsets.only(right: 3.5),
              ),
              Column(children: <Widget>[
                (bloc.loadingMoreId == moreComments.id)
                  ? new Padding(
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
              ),
              Divider(height: dividerWidth,)
              ],)
            ],
          ),
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
              bloc.add(FetchMore(moreComments: moreComments, location: index));
            });
          }
        },
      );
  }
}