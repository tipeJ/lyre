import 'package:flutter/material.dart';
import 'package:lyre/utils/urlUtils.dart';
import 'dart:ui';
import '../Models/item_model.dart';
import '../Models/Post.dart';
import '../Models/Subreddit.dart';
import '../Blocs/posts_bloc.dart';
import '../Blocs/subreddits_bloc.dart';
import '../Resources/globals.dart';
import 'dart:async';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:flutter_advanced_networkimage/transition.dart';
import 'package:flutter_advanced_networkimage/zoomable.dart';
import 'postInnerWidget.dart';
import 'interfaces/previewCallback.dart';
import 'dart:math';
import '../Resources/reddit_api_provider.dart';
import '../Resources/gfycat_provider.dart';
import 'package:video_player/video_player.dart';
enum PreviewType{
    Image,
    Video
  }
class lyApp extends StatefulWidget {
  State<lyApp> createState() => new PostsList();
}

class PostsList extends State<lyApp>
    with TickerProviderStateMixin, PreviewCallback {
  var titletext = "Lyre for Reddit";
  var currentSub = "";

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

  var subsListHeight = 50.0;

  Tween opacityTween = new Tween<double>(begin: 0.0, end: 1.0);
  Animation<double> opacityAnimation;
  AnimationController previewController;

  bool isElevated = false;

  bool isIntended = true;

  bool isPreviewing = false;
  var previewUrl = "https://i.imgur.com/CSS40QN.jpg";

  bool paramsExpanded = false;

  var paramsHeight = 0.0;

  PreviewType previewType;

  @override
  void preview(String url) {
    var x = getLinkType(url);
    if(x == LinkType.Gfycat){
      if(!isPreviewing){
          previewType = PreviewType.Video;
          gfycatProvider().getGfyWebmUrl(getGfyid(url)).then((onValue){
          _videoController = VideoPlayerController.network(onValue);
          _initializeVideoPlayerFuture = _videoController.initialize();
          showVideoOverlay();
          _videoController.setLooping(loopVideos);
          _videoController.play();
        });
      }
      
    }else{
      if (!isPreviewing) {
        previewType = PreviewType.Image;
        previewUrl = url;
        showOverlay();
        //previewController.forward();
      }
    }
  }
  Future<void> _initializeVideoPlayerFuture;

  @override
  void view(String url) {}

  @override
  void previewEnd() {
    if (isPreviewing) {
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
  
  VideoPlayerController _videoController;
  

  void initV(BuildContext context) {

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
    opacityAnimation = opacityTween.animate(
        CurvedAnimation(parent: previewController, curve: Curves.easeInSine));

    ;
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
  double get maxHeight => 400.0; //<-- Get max height of the screen

  void refreshUser(){
    setState(() {
      
    });
    bloc.fetchAllPosts();
  }
  @override
  void initState() {
    currentUser.addListener(refreshUser);
    _controller = AnimationController( //<-- initialize a controller
      vsync: this,
      duration: Duration(milliseconds: 600), 
    );
    controller = new AnimationController(
        vsync: this, duration: const Duration(milliseconds: 325));
    previewController = new AnimationController(
        vsync: this, duration: const Duration(milliseconds: 50));

    new Future.delayed(Duration.zero, () {
      initV(context);
    });
    state = Overlay.of(context);
    imageEntry = OverlayEntry(
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
                        )
                        ),
                      color: Color.fromARGB(200, 0, 0, 0),
                    ),
                  )),
              onLongPressUp: () {
                hideOverlay();
              },
            ));
            
    videoEntry = OverlayEntry(
      builder: (context) => new GestureDetector(
        child: Container(
          color: Color.fromARGB(200, 0, 0, 0),
          child: FutureBuilder(
              future: _initializeVideoPlayerFuture,
              builder: (context, snapshot){
                if(snapshot.connectionState == ConnectionState.done){
                  return Center(
                    child: Container(
                      child: AspectRatio(
                        child: VideoPlayer(_videoController),
                        aspectRatio: _videoController.value.aspectRatio,
                      ),
                    ),
                  );
                }else{
                  return Center(child: CircularProgressIndicator());
                }
              },
            )
        ),
        onTap: (){
          hideOverlay();
        },
      )
    );
    super.initState();
  }

  String searchQuery = "";

  OverlayState state;
  OverlayEntry imageEntry;
  OverlayEntry videoEntry;

  showOverlay() {
    if (!isPreviewing) {
      state.insert(imageEntry);
      isPreviewing = true;
    }
  }
  showVideoOverlay(){
    if(!isPreviewing){
      state.insert(videoEntry);
      isPreviewing = true;
    }
  }
  

  hideOverlay() {
    if (isPreviewing) {
      if(previewType == PreviewType.Image){
        imageEntry.remove();
      }else if(previewType == PreviewType.Video){
        videoEntry.remove();
      }
      state.deactivate();
      isPreviewing = false;
    }
  }

  var typeHeight = 25.0;
  bool typeVisible = true;

  _changeTypeVisibility(){
      if(typeVisible){
        typeHeight = 0.0;
        typeVisible = false;
      }else{
        typeHeight = 25.0;
        typeVisible = true;
      }
  }
  List<Widget> _createParams(bool type){
    return (type)? new List<Widget>.generate(sortTypes.length, (int index){
      return InkWell(
        child: Text(sortTypes[index]),
        onTap: (){
            setState(() {
              var q = sortTypes[index];
              if(q == "hot" || q == "new" || q == "rising"){
                currentSortType = q;
                currentSortTime = "";
                
                bloc.fetchAllPosts();
                bloc.resetFilters();
                
                _changeParamsVisibility();
              }else{
                bloc.tempType = q;
                _changeTypeVisibility();
              }
          });
          
        },
      );
    }) : new List<Widget>.generate(sortTimes.length, (int index){
      return InkWell(
        child: Text(sortTimes[index]),
        onTap: (){
          if(bloc.tempType != ""){
            currentSortType = bloc.tempType;
            currentSortTime = sortTimes[index];    
            bloc.fetchAllPosts();
            bloc.resetFilters();
            bloc.tempType = "";
          }
          _changeTypeVisibility();
          _changeParamsVisibility();
        },
      );
    });
  }

  _changeParamsVisibility(){
    //Resets the bloc:s tempType filter in case of continuity errors.
    bloc.tempType = "";
    setState(() {
      if(paramsExpanded){
      paramsHeight = 0.0;
      paramsExpanded = false;
    }else{
      paramsExpanded = true;
      paramsHeight = 25.0;
    }
    });
  }

  AnimationController _controller;
  double lerp(double min, double max) =>
      lerpDouble(min, max, _controller.value);

  void _handleDragUpdate(DragUpdateDetails details) {
    _controller.value -= details.primaryDelta / maxHeight; //<-- Update the _controller.value by the movement done by user.
  }
  void _reverse(){
    _controller.fling(velocity: -2.0);
    isElevated = false;
  }

  void _handleDragEnd(DragEndDetails details) {
    if(_controller.status == AnimationStatus.completed){
      isElevated = true;
    }
    if (_controller.isAnimating ||
        _controller.status == AnimationStatus.completed) return;

    final double flingVelocity =
        details.velocity.pixelsPerSecond.dy / maxHeight; //<-- calculate the velocity of the gesture
    if (flingVelocity < 0.0){
      _controller.fling(velocity: max(2.0, -flingVelocity)); //<-- either continue it upwards
      isElevated = true;
    }
    else if (flingVelocity > 0.0){
        _controller.fling(velocity: min(-2.0, -flingVelocity)); //<-- or continue it downwards
      isElevated = false;
    }
      
    else
      _controller.fling(velocity: _controller.value < 0.5 ? -2.0 : 2.0); //<-- or just continue to whichever edge is closer
  }
  

  @override
  Widget build(BuildContext context) {
    if (bloc.latestModel == null) {
      bloc.fetchAllPosts();
    }
    return new WillPopScope(
        child: Scaffold(
          resizeToAvoidBottomPadding: true,
          drawer: new Drawer(
              child: new Container(
            padding: EdgeInsets.only(top: 200, left: 20.0, right: 20.0),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Text(
                    "Logged in as " + currentUser.value,
                    style: TextStyle(
                      fontSize: 24.0
                    ),
                    ),
                ),
                getRegisteredUsernamesList(bloc.usernamesList),
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Text("Auto-load more posts"),
                      Switch(
                        value: autoLoad,
                        onChanged: (bool newValue) {
                          autoLoad = newValue;
                        },
                      ),
                      RaisedButton(
                        child: const Text('Add an account'),
                        color: Theme.of(context).accentColor,
                        onPressed: (){
                          var pp = PostsProvider();
                          setState(() {
                            pp.registerReddit();
                            bloc.fetchAllPosts();
                          });
                        },
                      ),
                    ]
                  ),
                ),
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
                    getFloatingNavBar()
                  ],
                ),
            onLongPressUp: () {
              hideOverlay();
            },
          )),
        ),
        onWillPop: _willPop);
  }
  Widget getFloatingNavBar(){
    return new IgnorePointer(
      child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child){
            return new AnimatedOpacity(
              opacity: visible ? 1.0 : 0.0,
              duration: Duration(milliseconds: 250),
              curve: Curves.easeInSine,
              child: Container(
                alignment: Alignment.bottomCenter,
                padding: new EdgeInsets.only(
                  bottom: 25.0-lerp(0,25.0),
                  right: 55.0-lerp(0,55.0),
                  left: 55.0-lerp(0,55.0),
                ),
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                      new Container(
                        height: lerp(45.0, maxHeight) + paramsHeight,
                        decoration: BoxDecoration(
                            color: Color.fromARGB(255, 70, 64, 66),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(25.0),
                              topRight: Radius.circular(25.0),
                              bottomLeft: Radius.circular(25.0-lerp(0,25.0)),
                              bottomRight: Radius.circular(25.0-lerp(0,25.0)),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black,
                                offset: new Offset(0.0, 5.5),
                                blurRadius: 20.0,
                              )
                            ]),
                        child: ClipRRect(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[    
                                new GestureDetector(
                                    onVerticalDragUpdate: _handleDragUpdate,
                                    onVerticalDragEnd: _handleDragEnd,
                                    child: new Container(
                                      height: 45.0,
                                      child: new Stack(
                                        children: <Widget>[
                                          new AnimatedOpacity(
                                              opacity: lerp(0,1.0),
                                              duration:
                                              Duration(milliseconds: 200),
                                              curve: Curves.easeInQuad,
                                              child: new Container(
                                                decoration: BoxDecoration(),
                                                padding: EdgeInsets.only(
                                                  left: 15.0,
                                                  right: 15.0,
                                                ),
                                                child: new TextField(
                                                  //TODO: FIX isElevated
                                                  enabled: isElevated,
                                                  onChanged: (String s) {
                                                    searchQuery = s;
                                                    sub_bloc.fetchSubs(s);
                                                  },
                                                  onEditingComplete: () {
                                                    currentSubreddit = searchQuery;
                                                    _reverse();
                                                    bloc.fetchAllPosts();
                                                    bloc.resetFilters();
                                                    subsListHeight = 50.0;
                                                    scontrol.animateTo(0.0,
                                                        duration: Duration(
                                                            milliseconds:
                                                            400),
                                                        curve: Curves
                                                            .decelerate);
                                                  },
                                                ),
                                              )),
                                          new IgnorePointer(
                                            ignoring: isElevated,
                                            child: new AnimatedOpacity(
                                              opacity: 1.0-lerp(0.0, 1.0),
                                              duration: Duration(milliseconds: 150),
                                              curve: Curves.easeInQuad,
                                              child: Container(
                                                padding: EdgeInsets.all(5.0),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: <Widget>[
                                                    Expanded(
                                                      child: InkWell(
                                                        child: Column(children: <Widget>[
                                                          new Text(
                                                            'r/$currentSubreddit',
                                                            style: TextStyle(
                                                              color: Colors.white70,
                                                              fontSize: 22.0,
                                                            ),
                                                            textAlign: TextAlign.start,
                                                          ),
                                                          new Text(
                                                            bloc.getFilterString(),
                                                            style: TextStyle(
                                                              color: Colors.white54,
                                                              fontSize: 14.0,
                                                            ),
                                                            textAlign: TextAlign.start,
                                                          )
                                                        ],
                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        ),
                                                        onTap: (){
                                                          _changeParamsVisibility();
                                                        },
                                                      )
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.create
                                                      ),
                                                      onPressed: (){
                                                        final snackBar = SnackBar(
                                                              content: Text('Log in in order to post your submission'),
                                                            );
                                                        setState(() {
                                                         PostsProvider().isLoggedIn().then((onV) {
                                                           if(onV){
                                                             
                                                           }else{
                                                             Scaffold.of(context).showSnackBar(snackBar);
                                                           }
                                                         });
                                                        });
                                                      },
                                                    )
                                                  ],
                                                ),
                                              ),
                                        ),
                                          )
                                        ],
                                      ),
                                      width:
                                      MediaQuery.of(context).size.width,
                                    )),       
                                new Container(
                                  height: lerp(0, 350),
                                  child: new StreamBuilder(
                                    stream: sub_bloc.getSubs,
                                    builder: (context,
                                        AsyncSnapshot<SubredditM> snapshot) {
                                      if(isElevated){
                                        if (snapshot.hasData) {
                                        return buildSubsList(snapshot);
                                      } else if (snapshot.hasError) {
                                        return Text(
                                            snapshot.error.toString());
                                      }
                                      return Center(
                                          child: CircularProgressIndicator());
                                      }else{
                                        return Container(height: 0.0,);
                                      }
                                    },
                                  ),
                                ),
                                new Visibility(
                                  child: new Container(
                                    height: 25.0,
                                    color: Colors.blue,
                                    child: Padding(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          AnimatedSize(
                                            child: Container(
                                              child: Row(
                                                children: _createParams(true),
                                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                              ),
                                              height: typeHeight
                                            ),
                                            duration: Duration(milliseconds: 150),
                                            vsync: this,
                                            curve: Curves.ease,
                                          ),
                                          AnimatedSize(
                                            child: Container(
                                              child: Row(
                                                children: _createParams(false),
                                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                              ),
                                              height: 25.0-typeHeight
                                            ),
                                            duration: Duration(milliseconds: 150),
                                            vsync: this,
                                            curve: Curves.ease,
                                          ),
                                        ],
                                      ),
                                      padding: EdgeInsets.only(left: 5.0, right: 5.0),
                                      ),
                                  ),
                                  visible: !isElevated,
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(25.0),
                              topRight: Radius.circular(25.0),
                              bottomLeft: Radius.circular(25.0-lerp(0,25.0)),
                              bottomRight: Radius.circular(25.0-lerp(0,25.0)),
                            ),
                      )
                    ),
                  ],
                ),
              ),
          );
        
          },
            ),
      ignoring: !visible,
                );
  }
  Widget getRegisteredUsernamesList(List<String> list){
    return new SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int i){
        return InkWell(
          child: Container(
            child: Text(
              list[i],
              style: TextStyle(
                fontSize: 18.0,
                fontStyle: FontStyle.italic
              ),),
            margin: EdgeInsets.all(18.0),
          ),
          onTap: (){
            if(i == 0){
              PostsProvider().logInAsGuest().then((_){
                setState(() {
                  bloc.fetchAllPosts();
                });
              });
            }
            PostsProvider().logIn(list[i]);
            bloc.fetchAllPosts();
          },
        );
      }, childCount: list.length),
    );
  }

  Future<bool> _willPop() {
    if (isElevated) {
      _reverse();
      return new Future.value(false);
    }
    return new Future.value(true);
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
              title: new Text("r/" + subs[i].displayName,
                  textScaleFactor: 1.0,
                  style: DefaultTextStyle.of(context)
                      .style
                      .apply(fontSizeFactor: 1.5)),
              onTap: () {
                currentSubreddit = subs[i].displayName;
                _reverse();
                subsListHeight = 50.0;
                bloc.resetFilters();
                bloc.fetchAllPosts();
                scontrol.animateTo(0.0,
                    duration: Duration(milliseconds: 400),
                    curve: Curves.decelerate);
              });
        });
  }

  ScrollController scontrol = new ScrollController();
  bool visible = true;

  Widget buildList(AsyncSnapshot<ItemModel> snapshot) {
    var posts = snapshot.data.results;
    return new NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (autoLoad &&
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          bloc.fetchMore();
        }
        if(scrollInfo is ScrollUpdateNotification){
          var sc = scrollInfo as ScrollUpdateNotification;
          if(sc.scrollDelta >= 10.0 && visible && !isElevated){
            setState(() {
              visible = false;
            });
          }
          else if(sc.scrollDelta <= -10.0 && !visible){
            setState(() {
              visible = true;
            });
          }
        }
      },
      child: new ListView.builder(
          physics: const AlwaysScrollableScrollPhysics (),
          controller: scontrol,
          itemCount: posts.length + 1,
          itemBuilder: (BuildContext context, int i) {
            return (i == posts.length)
                ? Container(
                    color: Colors.blueGrey,
                    child: FlatButton(
                        onPressed: () {
                          setState(() {
                            bloc.fetchMore();
                          });
                        },
                        child: Text("Load more")),
                  )
                : GestureDetector(
                    onHorizontalDragUpdate: (DragUpdateDetails details) {
                      if (details.delta.direction > 1.0 &&
                          details.delta.dx < -25) {
                        currentPostId = posts[i].s.id;
                        showComments(context, posts[i]);
                      }
                    }, //TODO: Add a new fling animation for vertical scrolling
                    child: new Hero(
                      tag: 'post_hero ${posts[i].s.id}',
                      child: new postInnerWidget(posts[i], this),
                    ),
                  );
          }),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _videoController.dispose();
    controller?.dispose();
    previewController?.dispose();
  }

  void showComments(BuildContext context, Post inside) {
    //Navigator.push(context, SlideRightRoute(widget: commentsList(inside)));
    cPost = inside;
    inside.expanded = true;
    Navigator.of(context).pushNamed('/second');
  }
}
