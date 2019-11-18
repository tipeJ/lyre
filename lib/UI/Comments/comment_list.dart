import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix0;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Themes/textstyles.dart';
import 'package:lyre/UI/Comments/bloc/bloc.dart';
import 'package:lyre/UI/Comments/bloc/comments_bloc.dart';
import 'package:lyre/UI/Comments/comment.dart';
import 'package:lyre/UI/bottom_appbar.dart';
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
      builder: (context) => CommentsBloc(this.submission),
      child: CommentList(),
    );
  }
}

class CommentList extends StatefulWidget {

  CommentList();

  @override
  CommentListState createState() => CommentListState();
}


class CommentListState extends State<CommentList> with SingleTickerProviderStateMixin{

  CommentListState();

  CommentsBloc bloc;

  @override
  void dispose() { 
    bloc.drain();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bloc = BlocProvider.of<CommentsBloc>(context);
    if(bloc.state == null || bloc.state.comments.isEmpty){
      bloc.add(SortChanged(submission: bloc.initialState.submission, commentSortType: CommentSortType.best));
    }
    return  WillPopScope(
        child: Scaffold(
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
            body: PersistentBottomAppbarWrapper(
              fullSizeHeight: null,
              body: StatefulBuilder(
                  builder: (BuildContext context, setState) {
                    return BlocBuilder<CommentsBloc, CommentsState>(
                      builder: (context, state) {
                        if (notNull(state) && state.submission is Submission && state.comments.isNotEmpty) {
                          return CustomScrollView(
                            slivers: <Widget>[
                              SliverToBoxAdapter(
                                child:  Hero(
                                  tag: 'post_hero ${(state.submission as Submission).id}',
                                  child:  postInnerWidget(state.submission as Submission, PreviewSource.Comments,),
                                ),
                              ),
                              getCommentWidgets(context, state.comments),
                            ],
                          );
                        } else {
                          return Center(child: CircularProgressIndicator(),);
                        }
                      },
                    );
                    
                  },
                ),
                appBarContent: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: BlocBuilder<CommentsBloc, CommentsState> (
                    builder: (context, state) {
                      return notNull(state) && state.parentComment == null
                        ? Row(
                          children: <Widget>[
                            IconButton(icon: Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context),),
                            Text("Comments"),
                            Spacer(),
                            DropdownButton<CommentSortType>(
                              value: state.sortType,
                              items: CommentSortType.values.map((CommentSortType value) {
                                return new DropdownMenuItem<CommentSortType>(
                                  value: value,
                                  child: new Text(value.toString().split(".")[1]),
                                );
                              }).toList(),
                              onChanged: (value) {
                                BlocProvider.of<CommentsBloc>(context).add(SortChanged(submission: state.submission, commentSortType: value));
                                setState(() {
                                });
                              },
                            )
                          ],
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text("You are viewing a single comment"),
                            RaisedButton(
                              child: Text("View All Comments"),
                              onPressed: (){
                                BlocProvider.of<CommentsBloc>(context).add(SortChanged(submission: state.submission, commentSortType: CommentSortType.top));
                              },
                            )
                          ],
                        );
                    }
                  )
                ),
              )
            ),
        onWillPop: requestPop);
  }

  Widget getCommentWidgets(BuildContext context, List<dynamic> list){
    return SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int i){
          return BlocBuilder<CommentsBloc, CommentsState>(
            builder: (BuildContext context, state) {
              return prefix0.Visibility(
                child: getCommentWidget(state.comments[i].c, i,),
                visible: state.comments[i].visible,
              );
            },
          );
      }, childCount: list.length),
    );
  }

  Future<bool> requestPop() {
    //post.expanded = false;
    return  Future.value(true);
  }

  Widget getCommentWidget(dynamic comment, int i) {
    if (comment is Comment) {
      return GestureDetector(
        child: CommentWidget(comment, i),
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