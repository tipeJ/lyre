import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix0;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Themes/textstyles.dart';
import 'package:lyre/UI/Comments/bloc/bloc.dart';
import 'package:lyre/UI/Comments/bloc/comments_bloc.dart';
import 'package:lyre/UI/Comments/comment.dart';
import 'package:lyre/UI/interfaces/previewCallback.dart';
import 'package:lyre/UI/postInnerWidget.dart';
import '../../Resources/globals.dart';

const selection_image = "Image";
const selection_album = "Album";

class CommentsList extends StatelessWidget{
  final Submission submission;

  CommentsList(this.submission);

  @override
  Widget build(BuildContext context){
    return BlocProvider(
      builder: (context) => CommentsBloc(),
      child: CommentList(submission),
    );
  }
}

class CommentList extends StatefulWidget {
  final Submission submission;

  CommentList(this.submission);

  @override
  CommentListState createState() => CommentListState(this.submission);
}


class CommentListState extends State<CommentList> with SingleTickerProviderStateMixin{
  final Submission submission;

  CommentListState(this.submission);

  CommentsBloc bloc;

  @override
  void dispose() { 
    bloc.drain();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bloc = BlocProvider.of<CommentsBloc>(context);
    if(bloc.state == null || bloc.state.isEmpty){
      bloc.add(SortChanged(submission, CommentSortType.best));
    }
    return new WillPopScope(
        child: Scaffold(
            appBar: AppBar(
              title: Text('Comments'),
            ),
            endDrawer: Drawer(
              child: Container(
                padding: EdgeInsets.all(10.0),
                child: ListView.builder(
                  itemCount: recentlyViewed.length+1,
                  itemBuilder: (context, i){
                    return i == 0
                      ? Text(
                        "Recently Viewed",
                        style: TextStyle(
                          fontSize: 26.0,
                        ),
                      )
                      : postInnerWidget(recentlyViewed[i-1], PreviewSource.Comments, PostView.Compact,);
                  },
                ),
              ),
            ),
            body: new Container(
              child: new CustomScrollView(
                slivers: <Widget>[
                  new SliverToBoxAdapter(
                    child: new Hero(
                      tag: 'post_hero ${submission.id}',
                      child: new postInnerWidget(submission, PreviewSource.Comments,),
                    ),
                  ),
                  new StreamBuilder(
                    stream: bloc,
                    builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot){
                      if (snapshot.hasData) {
                        return getCommentWidgets(context, snapshot.data);
                      } else {
                        return SliverToBoxAdapter(
                          child: Container(
                            child: Center(child: CircularProgressIndicator()),
                            padding: EdgeInsets.only(top: 3.5, bottom: 2.5),
                          ),
                        );
                      }
                    },
                  )
                ],
              ),
            )),
        onWillPop: requestPop);
  }

  Widget getCommentWidgets(BuildContext context, List<dynamic> list){
    return SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int i){
          return StatefulBuilder(
            builder: (BuildContext context, setState) {
              return prefix0.Visibility(
                child: getCommentWidget(list[i].c, i),
                visible: list[i].visible,
              );
            },
          );
      }, childCount: list.length),
    );
  }

  Future<bool> requestPop() {
    //post.expanded = false;
    return new Future.value(true);
  }

  Widget getCommentWidget(dynamic comment, int i) {
    if (comment is Comment) {
      return GestureDetector(
        child: CommentContent(comment),
        onTap: (){
          setState(() {
           BlocProvider.of<CommentsBloc>(context).add(Collapse(location: i)); 
          });
        },
      );
    } else {
      return MoreCommentsWidget(comment, i);
    }
  }
}