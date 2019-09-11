import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix0;
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Models/Post.dart';
import 'package:lyre/UI/Comments/bloc/bloc.dart';
import 'package:lyre/UI/Comments/bloc/comments_bloc.dart';
import 'package:lyre/UI/interfaces/previewCallback.dart';
import 'package:lyre/UI/postInnerWidget.dart';

class CommentsList extends StatelessWidget{
  final Submission submission;
  CommentsBloc bloc;

  CommentsList(this.submission);

  @override
  Widget build(BuildContext context){
    return BlocProvider(
      builder: (context) => bloc,
      child: CommentList(submission),
    )
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
    if(bloc.currentState.forest == null || bloc.currentState.submission == null){
      bloc.dispatch(SourceChanged(submission, CommentSortType.best));
    }
    return WillPopScope(
        child: Scaffold(
            appBar: AppBar(
              title: Text('Comments'),
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
                      new BlocBuilder<CommentsBloc, CommentsState>(
                        bloc: bloc,
                        builder: (context, commentsState){
                          return 
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

  Widget getCommentWidgets(BuildContext context, CommentsState commentsState){
    return SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int i){
          return prefix0.Visibility(
            child: GestureDetector(
              child: getCommentWidget(comments[i], i),
              onTap: (){
                setState(() {
                  bloc.changeVisibility(i);
                });
              },
            ),
            visible: commentsState.forest.,
          );
        
      }, childCount: comments.length),
    );
    )
  }

  bool getWidgetVisibility(dynamic comment){
    if(comment is Comment){
      return comment.coll
    }
  }

  Future<bool> requestPop() {
    //post.expanded = false;
    return new Future.value(true);
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

  
}