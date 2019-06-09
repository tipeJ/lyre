import 'package:flutter/material.dart';
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
import 'package:cached_network_image/cached_network_image.dart';
import 'postInnerWidget.dart';
import 'interfaces/previewCallback.dart';
import 'dart:math';
import '../Resources/reddit_api_provider.dart';

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

  @override
  void preview(String url) {
    if (!isPreviewing) {
      previewUrl = url;
      showOverlay();
      //previewController.forward();
    }
  }

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

  @override
  void initState() {
    super.initState();
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
    getUserInfoW();
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
                        )
                        ),
                      color: Color.fromARGB(200, 0, 0, 0),
                    ),
                  )),
              onLongPressUp: () {
                hideOverlay();
              },
            ));
  }

  String searchQuery = "";

  OverlayState state;
  OverlayEntry entry;

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


  void _showDialog(){
    showDialog(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          content: Column(
            children: <Widget>[
              DropdownButton<String>(
                items: sortTypes.map((String value){
                  return new DropdownMenuItem<String>(
                    child: Text(value),
                    value: value,
                    );
                }).toList(),
                onChanged: (value){
                  setState(() {
                   currentSortType = value; 
                  });
                },
              ),
              DropdownButton<String>(
                items: sortTimes.map((String value){
                  return new DropdownMenuItem<String>(
                    child: Text(value),
                    value: value,
                    );
                }).toList(),
                onChanged: (value){
                  setState(() {
                   currentSortTime = value; 
                  });
                },
              )
            ],
          ),
        );
      }
    );
  }

  var typeHeight = 25.0;
  bool typeVisible = true;

  _changeTypeVisibility(){
    setState(() {
      if(typeVisible){
        typeHeight = 0.0;
        typeVisible = false;
      }else{
        typeHeight = 25.0;
        typeVisible = true;
      }
    });
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
  void getUserInfoW() async {
    var b = await PostsProvider().isLoggedIn();
    if(b){
      var r = await PostsProvider().getRed();
      var u = await r.user.me();
      userInfo = u.displayName + " _ " + u.commentKarma.toString();
    }
  }
  String userInfo = "";
  

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
            padding: EdgeInsets.only(top: 200),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: new Column(
                    children: <Widget>[
                      Text("Auto-load more posts"),
                      Switch(
                        value: autoLoad,
                        onChanged: (bool newValue) {
                          autoLoad = newValue;
                        },
                      ),
                      RaisedButton(
                        child: const Text('Log in'),
                        color: Theme.of(context).accentColor,
                        onPressed: (){
                          var pp = PostsProvider();
                          pp.registerReddit();
                        },
                      ),
                      Text(userInfo),
                    ],
                  ),
                ),
                //StreamBuilder (is necessary?) of registered usernames from database
                StreamBuilder(
                  stream: bloc.registeredUsernames,
                  builder: (context, AsyncSnapshot<List<String>> snapshot){
                    if(snapshot.hasData){
                      return getRegisteredUsernamesList(snapshot);
                    }else{
                      return Container(height: 5.0,width: 5.0,color: Colors.teal,);
                    }
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
                new IgnorePointer(
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
                                  height: lerp(50.0, maxHeight) + paramsHeight,
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
                                              onTap: (){
                                                _changeParamsVisibility();
                                              },
                                              child: new Container(
                                                height: 45.0,
                                                child: new Stack(
                                                  children: <Widget>[
                                                    new AnimatedOpacity(
                                                      opacity: 1.0-lerp(0.0, 1.0),
                                                      duration:
                                                      Duration(milliseconds: 150),
                                                      curve: Curves.easeInQuad,
                                                      child: Container(
                                                        padding: EdgeInsets.all(5.0),
                                                        child: Row(
                                                          crossAxisAlignment:
                                                          CrossAxisAlignment.center,
                                                          children: <Widget>[
                                                            Column(children: <Widget>[
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
                                                            
                                                          ],
                                                        ),
                                                      ),
                                                    ),
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
                                                        ))
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
                                              height: 30.0,
                                              color: Colors.blue,
                                              child: Padding(
                                                child: Column(
                                                  children: <Widget>[
                                                    AnimatedContainer(
                                                      child: Row(
                                                        children: _createParams(true),
                                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                      ),
                                                      duration: Duration(milliseconds: 150),
                                                      height: typeHeight,
                                                      curve: Curves.ease,
                                                    ),
                                                    AnimatedContainer(
                                                      child: Row(
                                                        children: _createParams(false),
                                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                      ),
                                                      duration: Duration(milliseconds: 150),
                                                      height: 25.0-typeHeight,
                                                      curve: Curves.ease,
                                                    )
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
                              ),/*
                              new AnimatedContainer(
                                child: new Container(
                                  decoration: BoxDecoration(
                                      color: Color.fromARGB(255, 70, 64, 66),
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(25.0)),
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
                                              onVerticalDragUpdate:
                                                  (DragUpdateDetails details) {
                                                if (details.delta.direction < 1.0 &&
                                                    !isElevated) {
                                                  initV(context);
                                                  controller.forward();
                                                  subsListHeight = 350.0;
                                                  isElevated = true;
                                                } else if (details.delta.direction >
                                                    1.0 &&
                                                    isElevated) {
                                                  reverse(context);
                                                  subsListHeight = 50.0;
                                                }
                                              },
                                              onTap: (){
                                                _changeParamsVisibility();
                                              },
                                              child: new Container(
                                                height: 45.0,
                                                child: new Stack(
                                                  children: <Widget>[
                                                    new AnimatedOpacity(
                                                      opacity: !isElevated ? 1.0 : 0.0,
                                                      duration:
                                                      Duration(milliseconds: 200),
                                                      curve: Curves.easeInQuad,
                                                      child: Container(
                                                        padding: EdgeInsets.all(5.0),
                                                        child: Row(
                                                          crossAxisAlignment:
                                                          CrossAxisAlignment.center,
                                                          children: <Widget>[
                                                            Column(children: <Widget>[
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
                                                            )
                                                            /*
                                                            InkWell(
                                                              child: new Icon(
                                                                  Icons.list,
                                                                  color: Theme.of(context)
                                                                      .accentColor,
                                                                ),
                                                                onTap: (){
                                                                  _showDialog();
                                                                },
                                                            )*/
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    new AnimatedOpacity(
                                                        opacity: isElevated ? 1.0 : 0.0,
                                                        duration:
                                                        Duration(milliseconds: 200),
                                                        curve: Curves.easeInQuad,
                                                        child: new Container(
                                                          decoration: BoxDecoration(),
                                                          child: new TextField(
                                                            enabled: isElevated,
                                                            onChanged: (String s) {
                                                              searchQuery = s;
                                                              sub_bloc.fetchSubs(s);
                                                            },
                                                            onEditingComplete: () {
                                                              currentSubreddit = searchQuery;
                                                              reverse(context);
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
                                                        ))
                                                  ],
                                                ),
                                                width:
                                                MediaQuery.of(context).size.width,
                                              )),
                                          
                                          
                                          new Container(
                                            height: (height2Animation != null)
                                                ? height2Animation.value
                                                : 0.0,
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
                                              height: 30.0,
                                              color: Colors.blue,
                                              child: Padding(
                                                child: Column(
                                                  children: <Widget>[
                                                    AnimatedContainer(
                                                      child: Row(
                                                        children: _createParams(true),
                                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                      ),
                                                      duration: Duration(milliseconds: 150),
                                                      height: typeHeight,
                                                      curve: Curves.ease,
                                                    ),
                                                    AnimatedContainer(
                                                      child: Row(
                                                        children: _createParams(false),
                                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                      ),
                                                      duration: Duration(milliseconds: 150),
                                                      height: 25.0-typeHeight,
                                                      curve: Curves.ease,
                                                    )
                                                  ],
                                                ),
                                                padding: EdgeInsets.only(left: 5.0, right: 5.0),
                                                ),
                                            ),
                                            visible: !isElevated,
                                          ),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(25.0)),
                                ),
                                duration: Duration(milliseconds: 325),
                                height: subsListHeight + paramsHeight,
                                curve: Curves.fastOutSlowIn,
                                width: MediaQuery.of(context).size.width,
                              )
                              */
                            ],
                          ),
                        ),
                    );
                 
                    },
                     ),
                  
                  ignoring: !visible,
                )

              ],
            ),
            onLongPressUp: () {
              hideOverlay();
            },
          )),
        ),
        onWillPop: _willPop);
  }
  Widget getRegisteredUsernamesList(AsyncSnapshot<List<String>> snapshot){
    var list = snapshot.data;
    return new SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int i){
        return Text(list[i]);
      }),
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
                        currentPostId = posts[i].id;
                        showComments(context, posts[i]);
                      }
                    }, //TODO: Add a new fling animation for vertical scrolling
                    child: new Hero(
                      tag: 'post_hero ${posts[i].id}',
                      child: new postInnerWidget(posts[i], this),
                    ),
                  );
          }),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); //<-- and remember to dispose it
    controller?.dispose();
    previewController?.dispose();
    super.dispose();
  }

  void showComments(BuildContext context, Post inside) {
    //Navigator.push(context, SlideRightRoute(widget: commentsList(inside)));
    cPost = inside;
    inside.expanded = true;
    Navigator.of(context).pushNamed('/second');
  }
}
