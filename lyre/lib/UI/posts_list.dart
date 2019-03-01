import 'package:flutter/material.dart';
import 'dart:ui';
import '../Models/item_model.dart';
import '../Models/Post.dart';
import '../Models/Subreddit.dart';
import '../Blocs/posts_bloc.dart';
import '../Blocs/subreddits_bloc.dart';
import '../Resources/globals.dart';
import 'dart:async';
import '../Ui/Animations/slide_right_transition.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'postInnerWidget.dart';
import 'interfaces/previewCallback.dart';
import 'comments_list.dart';

class lyApp extends StatefulWidget{
  State<lyApp> createState() => new PostsList();
}

class PostsList extends State<lyApp> with TickerProviderStateMixin, PreviewCallback {
  var titletext = "Lyre for Reddit";
  var currentSub = "";


  Tween heightTween = new Tween<double>(begin: 0.0, end: 0.0);
  Tween height2Tween = new Tween<double>(begin: 0.0, end: 350.0);
  Tween padTween = new Tween<double>(begin: 25.0, end: 0.0);
  Tween roundTween = new Tween<double>(begin: 30.0, end: 0.0);
  Tween edgeTween = new Tween<double>(begin: 55.0, end: 0.0);
  AnimationController controller;
  Animation<double> heightAnimation;
  Animation<double> height2Animation;
  Animation<double> padAnimation;
  Animation<double> roundAnimation;
  Animation<double> edgeAnimation;

  Tween opacityTween = new Tween<double>(begin: 0.0,end: 1.0);
  Animation<double> opacityAnimation;
  AnimationController previewController;

  bool isElevated = false;

  bool isIntended = true;

  bool isPreviewing = false;
  var previewUrl = "https://i.imgur.com/CSS40QN.jpg";


  @override
  void preview(String url) {
    if(!isPreviewing){
      previewUrl = url;
      showOverlay();
      //previewController.forward();
    }
  }

  @override
  void view(String url) {

  }

  @override
  void previewEnd(){
    if(isPreviewing){
      previewUrl = "";
     // previewController.reverse();
      hideOverlay();
    }
  }

  void reverse(BuildContext context) {
    controller.reset();
    controller.reverse();
    isElevated = false;
  }

  void initV(BuildContext context) {
    heightTween.begin = 50.0;
    heightTween.end = 350.0;

    heightAnimation = heightTween
        .animate(CurvedAnimation(parent: controller, curve: Curves.ease));
    padAnimation = padTween.animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut));
    roundAnimation = roundTween.animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut));
    edgeAnimation = edgeTween.animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut));
    height2Animation = height2Tween.animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut));
    opacityAnimation = opacityTween.animate(CurvedAnimation(parent: previewController, curve: Curves.easeInSine));
    heightAnimation.addListener(() {
      setState(() {});
    });
    height2Animation.addListener(() {
      setState(() {});
    });
    padAnimation.addListener(() {
      setState(() {});
    });
    edgeAnimation.addListener(() {
      setState(() {});
    });
    roundAnimation.addListener(() {
      setState(() {});
    });
    controller.reset();
    previewController.reset();
  }

  @override
  void initState() {
    super.initState();
    controller = new AnimationController(
        vsync: this, duration: const Duration(milliseconds: 325));
    previewController = new AnimationController(
        vsync: this, duration: const Duration(milliseconds: 50));

    new Future.delayed(Duration.zero, () {
      initV(context);
    });
    state = Overlay.of(context);
    entry = OverlayEntry(
        builder: (context) => new GestureDetector(
          child: new Container(
              width: 400.0,
              height: 500.0,
              child: new Opacity(
                opacity: 1.0,
                child: new Container(
                  child: new CachedNetworkImage(
                      imageUrl: previewUrl
                  ),
                  color: Color.fromARGB(200, 0, 0, 0),
                ),
              )
          ),
          onLongPressUp: (){
            hideOverlay();
          },
        )
    );
  }

  String searchQuery = "";

  OverlayState state;
  OverlayEntry entry;
  showOverlay(){
    if(!isPreviewing){
      state.insert(entry);
      isPreviewing = true;
    }

  }
  hideOverlay(){
    if(isPreviewing){
      entry.remove();
      state.deactivate();
      isPreviewing = false;
    }

  }

  @override
  Widget build(BuildContext context) {
    if(bloc.latestModel == null){
      bloc.fetchAllPosts();
    }
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        drawer: new Drawer(
            child: new Container(
              padding: EdgeInsets.only(
                top: 200
              ),
              child: new Column(
                children: <Widget>[
                  Text(
                      "Auto-load more posts"
                  ),
                  Switch(
                    value: autoLoad,
                    onChanged: (bool newValue){
                      autoLoad = newValue;
                    },
                  )
                ],
              ),
            )),
        body: new Container(
          child: new GestureDetector(
            child: new Stack(
              children: <Widget>[
                new StreamBuilder(
                  stream: bloc.allPosts,
                  builder: (context, AsyncSnapshot<ItemModel> snapshot) {
                    if (snapshot.hasData) {
                      return buildList(snapshot);
                    } else if (snapshot.hasError) {
                      return Text(snapshot.error.toString());
                    }
                    return Center(child: CircularProgressIndicator());
                  },
                ),
                new Container(
                  alignment: Alignment.bottomCenter,
                  padding: new EdgeInsets.only(
                      bottom: (padAnimation.value != null) ? padAnimation.value : 0.0,
                      right: (edgeAnimation.value != null) ? edgeAnimation.value : 0.0,
                      left: (edgeAnimation.value != null) ? edgeAnimation.value : 0.0,),
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      new AnimatedContainer(
                        child: new Card(
                          color: Color.fromARGB(255, 70, 64, 66),
                          elevation: 4.0,
                          shape: BeveledRectangleBorder(
                              borderRadius:
                              BorderRadius.all(Radius.circular(10.0))),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              new GestureDetector(
                                  onVerticalDragUpdate:
                                      (DragUpdateDetails details) {
                                    if (details.delta.direction < 1.0 &&
                                        !isElevated) {
                                      initV(context);
                                      controller.forward();
                                      isElevated = true;
                                    } else if (details.delta.direction > 1.0 &&
                                        isElevated) {
                                      reverse(context);
                                    }
                                  },
                                  child: new Container(
                                    child: new Stack(
                                      children: <Widget>[
                                        new AnimatedOpacity(
                                          opacity: !isElevated ? 1.0 : 0.0,
                                          duration: Duration(milliseconds: 200),
                                          curve: Curves.easeInQuad,
                                          child: new Text(
                                            currentSubreddit,
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 35.0,
                                            ),
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                        new AnimatedOpacity(
                                            opacity: isElevated ? 1.0 : 0.0,
                                            duration: Duration(milliseconds: 200),
                                            curve: Curves.easeInQuad,
                                            child: new Container(
                                              child: new TextField(
                                                enabled: isElevated,
                                                onChanged: (String s) {
                                                  searchQuery = s;
                                                  sub_bloc.fetchSubs(s);
                                                },
                                                onEditingComplete: () {
                                                  currentSubreddit =
                                                  "/r/${searchQuery}";
                                                  reverse(context);
                                                  bloc.fetchAllPosts();
                                                  scontrol.animateTo(0.0,
                                                      duration: Duration(
                                                          milliseconds: 400),
                                                      curve: Curves.decelerate);
                                                },
                                              ),
                                              color: Colors.black54,
                                            ))
                                      ],
                                    ),
                                    width: MediaQuery.of(context).size.width,
                                  )),
                              new Container(
                                height: height2Animation.value,
                                child: new StreamBuilder(
                                  stream: sub_bloc.getSubs,
                                  builder: (context,
                                      AsyncSnapshot<SubredditM> snapshot) {
                                    if (snapshot.hasData) {
                                      return buildSubsList(snapshot);
                                    } else if (snapshot.hasError) {
                                      return Text(snapshot.error.toString());
                                    }
                                    return Center(
                                        child: CircularProgressIndicator());
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        duration: Duration(milliseconds: 325),
                        height: heightAnimation.value,
                        curve: Curves.fastOutSlowIn,
                        width: MediaQuery.of(context).size.width,
                      )
                    ],
                  ),
                ),
              ],
            ),
            onLongPressUp: (){
              hideOverlay();
            },
          )
        ));
  }

  Widget buildSubsList(AsyncSnapshot<SubredditM> snapshot) {
    var subs = snapshot.data.results;
    return new ListView.builder(
        padding: new EdgeInsets.all(16.0),
        itemCount: subs.length,
        itemExtent: 50.0,
        itemBuilder: (BuildContext context, int i) {
          return new ListTile(
              leading: const Icon(Icons.arrow_right),
              title: new Text(subs[i].url,
                  textScaleFactor: 1.0,
                  style: DefaultTextStyle.of(context)
                      .style
                      .apply(fontSizeFactor: 1.5)),
              onTap: () {
                currentSubreddit = subs[i].url;
                reverse(context);
                bloc.fetchAllPosts();
                scontrol.animateTo(0.0,
                    duration: Duration(milliseconds: 400),
                    curve: Curves.decelerate);
              });
        });
  }

  ScrollController scontrol = new ScrollController();

  Widget buildList(AsyncSnapshot<ItemModel> snapshot) {
    var posts = snapshot.data.results;
    return new NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo){
        if(autoLoad && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent){
          bloc.fetchMore();
        }
      },
      child: new ListView.builder(
          controller: scontrol,
          itemCount: posts.length + 1,
          itemBuilder: (BuildContext context, int i) {
            return (i == posts.length) ?
            Container(
              color: Colors.blueGrey,
              child: FlatButton(
                  onPressed: (){
                    setState(() {
                      bloc.fetchMore();
                    });
                  },
                  child: Text("Load more")
              ),
            )
                : GestureDetector(
              onHorizontalDragUpdate: (DragUpdateDetails details) {
                if (details.delta.direction > 1.0 && details.delta.dx < -25) {
                  currentPostId = posts[i].id;
                  showComments(context, posts[i]);
                }
              }, //TODO: Add a new fling animation for vertical scrolling
              child: new Hero(
                tag: 'post_hero',
                child: new Container(
                    child: new Card(
                        child: postInnerWidget(posts[i],this)),
                    padding: const EdgeInsets.only(
                        left: 0.0, right: 0.0, top: 8.0, bottom: 0.0))
                ,
              ),
            );
          }),
    );
  }
  @override
  void dispose(){
    controller?.dispose();
    previewController?.dispose();
    super.dispose();
  }

  void showComments(BuildContext context, Post inside) {
    //Navigator.push(context, SlideRightRoute(widget: commentsList(inside)));
    cPost = inside;
    Navigator.pushNamed(context, '/second');
  }

}
