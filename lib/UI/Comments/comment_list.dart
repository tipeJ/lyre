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
    if(bloc.state == null || bloc.state.comments.isEmpty){
      bloc.add(SortChanged(submission: this.submission, commentSortType: CommentSortType.best));
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
            body: Stack(
              children:  <Widget>[
                StatefulBuilder(
                  builder: (BuildContext context, setState) {
                    return CustomScrollView(
                      slivers: <Widget>[
                        SliverToBoxAdapter(
                          child:  Hero(
                            tag: 'post_hero ${submission.id}',
                            child:  postInnerWidget(submission, PreviewSource.Comments,),
                          ),
                        ),
                        StreamBuilder(
                          stream: bloc,
                          builder: (BuildContext context, AsyncSnapshot<CommentsState> snapshot){
                            if (snapshot.hasData) {
                              return getCommentWidgets(context, snapshot.data.comments);
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
                    );
                  },
                ),
                Positioned(
                  bottom: 0.0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    width: MediaQuery.of(context).size.width,
                    height: 50.0,
                    color: Theme.of(context).primaryColor,
                    child: Row(
                      children: <Widget>[
                        IconButton(icon: Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context),),
                        Text("Comments"),
                        Spacer(),
                        BlocBuilder<CommentsBloc, CommentsState> (
                          builder: (context, state) {
                            return DropdownButton<CommentSortType>(
                              value: state.sortType,
                              items: CommentSortType.values.map((CommentSortType value) {
                                return new DropdownMenuItem<CommentSortType>(
                                  value: value,
                                  child: new Text(value.toString().split(".")[1]),
                                );
                              }).toList(),
                              onChanged: (value) {
                                BlocProvider.of<CommentsBloc>(context).add(SortChanged(submission: this.submission, commentSortType: value));
                                setState(() {
                                });
                              },
                            );
                          }
                        )
                      ],
                    ),
                  ),
                )
              ],
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
    return  Future.value(true);
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