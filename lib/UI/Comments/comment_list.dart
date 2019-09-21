import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix0;
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Models/Post.dart';
import 'package:lyre/UI/Animations/slide_right_transition.dart';
import 'package:lyre/UI/Comments/bloc/bloc.dart';
import 'package:lyre/UI/Comments/bloc/comments_bloc.dart';
import 'package:lyre/UI/Comments/comment.dart';
import 'package:lyre/UI/interfaces/previewCallback.dart';
import 'package:lyre/UI/postInnerWidget.dart';
import '../../Resources/globals.dart';

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
  _CommentListState createState() => _CommentListState(this.submission);
}


class _CommentListState extends State<CommentList> with SingleTickerProviderStateMixin, PreviewCallback{
  final Submission submission;

  _CommentListState(this.submission);

  bool isPreviewing = false;
  var previewUrl = "";

  OverlayState state;
  OverlayEntry entry;

  @override
  void initState() {
    super.initState();
    state = Overlay.of(context);
    entry = OverlayEntry(
        builder: (context) => new GestureDetector(
              child: new Container(
                  width: 400.0,
                  height: 500.0,
                  child: new Container(
                      child: Image(
                          image: AdvancedNetworkImage(
                        previewUrl,
                        useDiskCache: true,
                        cacheRule: CacheRule(maxAge: const Duration(days: 7)),
                      )),
                      color: Color.fromARGB(200, 0, 0, 0),
                  ),),
              onLongPressUp: () {
                hideOverlay();
              },
            ));
  }

  showOverlay() {
    if (!isPreviewing) {
      state.insert(entry);
      isPreviewing = true;
    }
  }

  hideOverlay() {
    if (isPreviewing) {
      entry.remove();
      state.deactivate();
      isPreviewing = false;
    }
  }

  @override
  void previewEnd() {
    if (isPreviewing) {
      previewUrl = "";
      // previewController.reverse();
      hideOverlay();
    }
  }

  @override
  void view(String s) {}

  @override
  void preview(String url) {
    if (!isPreviewing) {
      previewUrl = url;
      showOverlay();
      //previewController.forward();
    }
  }

  CommentsBloc bloc;

  @override
  Widget build(BuildContext context) {
    bloc = BlocProvider.of<CommentsBloc>(context);
    if(bloc.currentState == null || bloc.currentState.isEmpty){
      bloc.dispatch(SortChanged(submission, CommentSortType.best));
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
                      : postInnerWidget(Post.fromApi(recentlyViewed[i-1]), this, PostView.Compact,);
                  },
                ),
              ),
            ),
            body: new Container(
              child: new GestureDetector(
                  child: new CustomScrollView(
                    slivers: <Widget>[
                      new SliverToBoxAdapter(
                        child: new Hero(
                          tag: 'post_hero ${submission.id}',
                          child: new postInnerWidget(Post.fromApi(submission), this),
                        ),
                      ),
                      
                      new StreamBuilder(
                        stream: bloc.state,
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
                  onTapUp: hideOverlay(),
                  onHorizontalDragUpdate: (DragUpdateDetails details) {
                    if (details.delta.direction < 1.0 &&
                        details.delta.dx > 30) {
                      Navigator.of(context).maybePop();
                    }
                  }),
            )),
        onWillPop: requestPop);
  }

  Widget getCommentWidgets(BuildContext context, List<dynamic> list){
    return SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int i){
          return prefix0.Visibility(
            child: GestureDetector(
              child: getCommentWidget(list[i], i),
            ),
            visible: true,
          );
        
      }, childCount: list.length),
    );
  }
  
  bool getWidgetVisibility(int index){
    var item = bloc.currentState[index];
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
      return Text(comment.body);
      return CommentWidget(comment);
    } else if (comment is MoreComments) {
      return Text("morecomments object");
      return new MoreCommentsWidget(comment, i);
    }
  }
  
}