import 'package:flutter/material.dart';
import 'package:lyre/UI/Comments/comment.dart';
import '../../Blocs/comments_bloc.dart';
import '../../Models/Comment.dart';
import '../postInnerWidget.dart';
import '../interfaces/previewCallback.dart';
import '../../Models/Post.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:flutter_advanced_networkimage/transition.dart';
import 'package:flutter_advanced_networkimage/zoomable.dart';

class commentsList extends StatefulWidget {
  final Post post;

  commentsList(this.post);

  @override
  State<commentsList> createState() => new comL(post);
}

class comL extends State<commentsList>
    with SingleTickerProviderStateMixin, PreviewCallback {
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

  Post post;

  comL(this.post);

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
                  child: new Opacity(
                    opacity: 1.0,
                    child: new Container(
                      child: Image(
                          image: AdvancedNetworkImage(
                        previewUrl,
                        useDiskCache: true,
                        cacheRule: CacheRule(maxAge: const Duration(days: 7)),
                      )),
                      color: Color.fromARGB(200, 0, 0, 0),
                    ),
                  )),
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
  Widget build(BuildContext context) {
    if (bloc.currentComments == null) {
      bloc.fetchComments();
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
                          tag: 'post_hero ${post.s.id}',
                          child: new postInnerWidget(post, this),
                        ),
                      ),
                      new StreamBuilder(
                        stream: bloc.allComments,
                        builder: (context, AsyncSnapshot<CommentM> snapshot) {
                          if (snapshot.hasData) {
                            return getImprovedCommentsExpandablePage(snapshot);
                          } else if (snapshot.hasError) {
                            return Text(snapshot.error.toString());
                          }
                          return SliverToBoxAdapter(
                            child: Container(
                              child: Center(child: CircularProgressIndicator()),
                              padding: EdgeInsets.only(top: 3.5, bottom: 2.5),
                            ),
                          );
                        },
                      ),
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

  Future<bool> requestPop() {
    post.expanded = false;
    bloc.currentComments = null;
    return new Future.value(true);
  }

  Color getColor(int depth) {
    if (depth >= 0 && depth <= colorList.length - 1) {
      return colorList[depth];
    }
    int remain = depth % colorList.length;
    return colorList[remain];
  }
  Widget getCommentWidget(commentResult comment, int i) {
    if (comment is commentC) {
      return CommentWidget(comment);
    } else if (comment is moreC) {
      return new GestureDetector(
        child: Container(
          child: Container(
              child: Row(
                children: <Widget>[
                  (comment.id == bloc.loadingMoreId)
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
                    "Load more comments (${comment.count})"
                  )
                ],
              ),
              decoration: BoxDecoration(
                  border: Border(
                      left: BorderSide(
                          color: getColor(comment.depth), width: 3.5)))),
          padding: EdgeInsets.only(
            left: 4.5 + comment.depth * 3.5,
            right: 0.5,
            top: 0.5,
            bottom: 0.5,
          ),
        ),
        onTapUp: (TapUpDetails details) {
          if (comment.id != bloc.loadingMoreId) {
            setState(() {
              bloc.loadingMoreId = comment.id;
              bloc.getB(comment, i, comment.depth, post.s.id);
            });
          }
        },
      );
    }
  }

  Widget getCommentsPage(AsyncSnapshot<CommentM> snapshot) {
    var comments = snapshot.data.results;
    return new SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int i) {
        if (i == 0) {
          return new Container(
            height: 0.0,
          );
        } else {
          var comment = comments[i - 1];
          return Visibility(
            child: getCommentWidget(comment, i),
            visible: comment.visible,
          );
        }
      }, childCount: comments.length + 1),
    );
  }

  Widget getImprovedCommentsExpandablePage(AsyncSnapshot<CommentM> snapshot){
    var comments = snapshot.data.results;
    return new SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int i){
        
          return Visibility(
            child: GestureDetector(
              child: getCommentWidget(comments[i], i),
              onTap: (){
                setState(() {
                  bloc.changeVisibility(i);
                });
              },
            ),
            visible: comments[i].visible,
          );
        
      }, childCount: comments.length),
    );
  }

  List<commentTest> clist(List<commentResult> results, int index) {
    var list = List<commentTest>();
    var firstR = results[index];
    if (index == results.length - 1 ||
        results[index + 1].depth == results[index].depth) return null;
    for (int i = index + 1; true; i++) {
      if (i == results.length || results[i].depth == firstR.depth) {
        break;
      } else if (results[i].depth == firstR.depth + 1) {
        var test = new commentTest(i, results[i], clist(results, i));
        list.add(test);
      }
    }
    return list;
  }

  void close(BuildContext context) {
    Navigator.pop(context);
  }
}

class commentTest {
  int position;
  List<commentTest> children;
  commentResult result;

  commentTest(this.position, this.result,
      [this.children = const <commentTest>[]]);
}
