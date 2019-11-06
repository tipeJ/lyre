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
import 'package:tree_view/tree_view.dart';
import '../../Resources/globals.dart';

const selection_image = "Image";
const selection_album = "Album";

class CommentsList extends StatelessWidget{
  final Submission submission;
  CommentsBloc bloc = CommentsBloc();

  CommentsList(this.submission);

  @override
  Widget build(BuildContext context){
    return BlocProvider(
      builder: (context) => bloc,
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
                  /*
                  BlocBuilder<CommentsBloc, List<dynamic>>(
                          builder: (context, List<dynamic> state){
                            return TreeView(
                              parentList: getCommentTreeList(context, state,),
                            );
                          },
                        )*/
            )),
        onWillPop: requestPop);
  }

  List<Parent> getCommentTreeList(BuildContext context, List<dynamic> children) {
    List<Parent> returnList = [];
    children.forEach((comment) {
      if (comment is Comment) {
        if (comment.replies != null && comment.replies.toList().isNotEmpty) {
          returnList.add(Parent(
            parent: Padding(
              child: CommentContent(comment),
              padding: EdgeInsets.only(left: comment.depth * 3.5),
            ),
            childList: ChildList(children: getCommentTreeList(context, comment.replies.toList()),),));
        } else {
          returnList.add(Parent(
            parent: Padding(
              child: CommentContent(comment),
              padding: EdgeInsets.only(left: comment.depth * 3.5),
            ),
            childList: ChildList(),
          ));
        }
      } else {
        returnList.add(Parent(parent: Container(
          child: MoreCommentsWidget(comment, 1), // ! CHANGE TO CORRENT INDEX
          padding: EdgeInsets.only(
            left: 4.5 + comment.data['depth'] * 3.5,
            right: 0.5,
            top: 0.5,
            bottom: 0.5,
          ),
        ),
        childList: ChildList(),
        ));
      }
    }) ;
    return returnList;
  }

  Widget getCommentWidgets(BuildContext context, List<dynamic> list){
    return SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int i){
          return prefix0.Visibility(
            child: GestureDetector(
              child: getCommentWidget(list[i].c, i),
              onTap: (){
                setState(() {
                 BlocProvider.of<CommentsBloc>(context).collapse(i); 
                });
              },
            ),
            visible: bloc.comments[i].visible,
          );
      }, childCount: list.length),
    );
  }
  
  bool getWidgetVisibility(int index){
    var item = bloc.state[index];
    return item.visible;
    if(item is MoreComments){
      return !getWidgetVisibility(index-1);
    }
    var comment = item as Comment;
    if(!comment.isRoot && comment.collapsed){
      comment.parent().then((parent){
        return !(parent as Comment).collapsed;
      });
    }
    return true;
  }

  Future<bool> requestPop() {
    //post.expanded = false;
    return new Future.value(true);
  }

  Widget getCommentWidget(dynamic comment, int i) {
    if (comment is Comment) {
      return CommentContent(comment);
    } else {
      return MoreCommentsWidget(comment, i);
    }
    if (comment is Comment) {
      return CommentWidget(comment);
    } else if (comment is MoreComments) {
      return new MoreCommentsWidget(comment, i);
    }
  }
}