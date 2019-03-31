import 'package:flutter/material.dart';
import '../Models/item_model.dart';
import '../Blocs/comments_bloc.dart';
import 'CustomExpansionTile.dart';
import '../Resources/globals.dart';
import '../Models/Comment.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/utils_html.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'postInnerWidget.dart';
import 'interfaces/previewCallback.dart';
import '../Models/Post.dart';

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
                      child: new CachedNetworkImage(imageUrl: previewUrl),
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
    }else{
      print("WTW:" + bloc.currentComments.results.length.toString());
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
                            tag: 'post_hero ${post.id}',
                            child: new Container(
                                child: new Card(
                                    child: postInnerWidget(post, this)),
                                padding: const EdgeInsets.only(
                                    left: 0.0,
                                    right: 0.0,
                                    top: 8.0,
                                    bottom: 0.0))),
                      ),
                      new StreamBuilder(
                        stream: bloc.allComments,
                        builder: (context, AsyncSnapshot<CommentM> snapshot) {
                          if (snapshot.hasData) {
                            return getCommentsExpandablePage(snapshot);
                          } else if (snapshot.hasError) {
                            return Text(snapshot.error.toString());
                          }
                          return SliverToBoxAdapter(
                            child: Container(
                              child: Center(child: CircularProgressIndicator()),
                              padding: EdgeInsets.only(
                                top: 3.5,
                                bottom: 2.5
                              ),
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
      return new GestureDetector(
        child: new Container(
            child: new Container(
              decoration: BoxDecoration(
                border: Border(
                    left:
                        BorderSide(color: getColor(comment.depth), width: 3.5)),
              ),
              child: new Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Padding(
                        child: new Text(
                            "\u{1F44D} ${comment.points}    \u{1F60F} ${comment.author}",
                            textAlign: TextAlign.right,
                            textScaleFactor: 1.0,
                            style: new TextStyle(
                                color: Colors.white.withOpacity(0.6))),
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16.0, top: 16.0)),
                    new Padding(
                        child: new Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            new MarkdownBody(
                              data: convertToMarkdown(comment.text),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16.0, top: 16.0, bottom: 16.0))
                  ]),
            ),
            padding: new EdgeInsets.only(
                left: 3.5 + comment.depth * 3.5,
                right: 0.5,
                top: comment.depth == 0 ? 2.0 : 0.1,
                bottom: 0.0)),

      );
    } else if (comment is moreC) {
      return new GestureDetector(
        child: Container(
          child: new Text(
            "Load more comments (${comment.count})",
            style: TextStyle(color: colorList[0]),
          ),
          padding: EdgeInsets.only(
            left: 4.5 + comment.depth * 3.5,
            right: 0.5,
            top: 2.5,
            bottom: 2.5,
          ),
        ),
        onTapUp: (TapUpDetails details) {
          setState(() {
            print("ID: : " + (comment as moreC).id);
            //bloc.getComments(comment.id,i-1,comment.depth);
            bloc.getB(comment, i - 1, comment.depth);
          });
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
      },childCount: comments.length+1),
      /*
        itemCount: comments.length + 1,
        itemBuilder: (BuildContext context, int i) {
          if (i == 0) {
            return new Container(height: 0.0,);
          } else {
            var comment = comments[i-1];
            return Visibility(
                child: getCommentWidget(comment, i),
                visible: comment.visible,
            );
          }
        }*/
    );
  }
  Widget getCommentsExpandableSingle(commentTest parent){
    if(parent.children == null || parent.children.isEmpty){
      return new ListTile(
        title: getCommentWidget(parent.result, parent.position),
      );
    }
    var post_children = new List<Widget>();
    parent.children.forEach((child) => {
        post_children.add(getCommentsExpandableSingle(child))
    });
    return new CustomExpansionTile(
      title: getCommentWidget(parent.result, parent.position),
      children: post_children,
      initiallyExpanded: !preCollapsed,
      key: new PageStorageKey(parent.position),
      trailing: Container(width: 0.0,height: 0.0,),
    );
  }
  Widget getCommentsExpandablePage(AsyncSnapshot<CommentM> snapshot){
    var comments = snapshot.data.results;
    var xList = List<commentTest>();
    for(int i = 0; i < comments.length; i++){
      if(comments[i].depth == 0){
        var test = new commentTest(i,comments[i],clist(comments,i));
        xList.add(test);
      }
    }
    return new SliverList(
        delegate: SliverChildBuilderDelegate((BuildContext context, int i){
          if (i == 0) {
            return new Container(
              height: 0.0,
            );
          } else {
            return getCommentsExpandableSingle(xList[i-1]);
          }

        }, childCount: xList.length)
    );
  }
  List<commentTest> clist(List<commentResult> results, int index){
    var list = List<commentTest>();
    var firstR = results[index];
    if(index == results.length-1 || results[index+1].depth == results[index].depth) return null;
    for(int i = index + 1; true; i++){
      if(i == results.length || results[i].depth == firstR.depth){
        break;
      }else if(results[i].depth == firstR.depth+1){
        var test = new commentTest(i,results[i],clist(results,i));
        list.add(test);
      }
    }
    return list;
  }

  void close(BuildContext context) {
    Navigator.pop(context);
  }
}
class commentTest{
  int position;
  List<commentTest> children;
  commentResult result;

  commentTest(this.position, this.result, [this.children = const <commentTest>[]]);

}
