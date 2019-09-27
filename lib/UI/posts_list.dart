import 'package:draw/draw.dart' as prefix0;
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix1;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:lyre/Blocs/bloc/bloc.dart';
import 'package:lyre/UI/Comments/comment.dart';
import 'package:lyre/UI/CustomExpansionTile.dart';
import 'package:lyre/utils/urlUtils.dart';
import 'dart:ui';
import '../Models/Post.dart';
import '../Models/Subreddit.dart';
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

enum PreviewType { Image, Video }

class PostsView extends StatelessWidget {
  String redditor;
  ContentSource initialSource;

  final PostsBloc _postsBloc = PostsBloc();
  PostsView(String targetRedditor, ContentSource source){
    this.redditor = targetRedditor;
    initialSource = targetRedditor.isNotEmpty
      ? ContentSource.Redditor
      : (source == null)
        ? ContentSource.Subreddit
        : source;
  }

  @override
  Widget build(BuildContext context){
    return BlocProvider(
      builder: (context) => _postsBloc,
      child: PostsList(redditor, initialSource),
    );
  }
}

class PostsList extends StatefulWidget {
  final String redditor;
  final ContentSource initialSource;

  PostsList(this.redditor, this.initialSource);
  State<PostsList> createState() => new PostsListState(redditor, initialSource);
}

class PostsListState extends State<PostsList>
    with TickerProviderStateMixin, PreviewCallback {
  var titletext = "Lyre for Reddit";
  var currentSub = "";
  final String redditor;
  final ContentSource initialSource;

  PostsBloc bloc;

  PostsListState(this.redditor, this.initialSource);

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
    if (x == LinkType.Gfycat) {
      if (!isPreviewing) {
        previewType = PreviewType.Video;
        gfycatProvider().getGfyWebmUrl(getGfyid(url)).then((onValue) {
          _videoController = VideoPlayerController.network(onValue);
          _initializeVideoPlayerFuture = _videoController.initialize();
          showVideoOverlay();
          _videoController.setLooping(loopVideos);
          _videoController.play();
        });
      }
    } else {
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
    maxHeight = MediaQuery.of(context).size.height / 2.5;
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

  double maxHeight = 400.0; //<-- Get max height of the screen

  /*void refreshUser() {
    setState(() {});
    bloc.fetchAllPosts();
  }
  */


  @override
  void initState() {
    maxHeight = 400.0;
    currentUser.addListener((){
      setState(() {
        
      });
    });
    _controller = AnimationController(
      //<-- initialize a controller
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
                  child: new Container(
                    child: Image(
                        image: AdvancedNetworkImage(
                      previewUrl,
                      useDiskCache: true,
                      cacheRule: CacheRule(maxAge: const Duration(days: 7)),
                    )),
                    color: Color.fromARGB(200, 0, 0, 0),
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
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return Center(
                          child: Container(
                            child: AspectRatio(
                              child: VideoPlayer(_videoController),
                              aspectRatio: _videoController.value.aspectRatio,
                            ),
                          ),
                        );
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    },
                  )),
              onTap: () {
                hideOverlay();
              },
            ));
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

  showVideoOverlay() {
    if (!isPreviewing) {
      state.insert(videoEntry);
      isPreviewing = true;
    }
  }

  hideOverlay() {
    if (isPreviewing) {
      if (previewType == PreviewType.Image) {
        imageEntry.remove();
      } else if (previewType == PreviewType.Video) {
        videoEntry.remove();
      }
      state.deactivate();
      isPreviewing = false;
    }
  }

  var typeHeight = 25.0;
  bool typeVisible = true;

  _changeTypeVisibility() {
    if (typeVisible) {
      typeHeight = 0.0;
      typeVisible = false;
    } else {
      typeHeight = 25.0;
      typeVisible = true;
    }
  }

  String tempType = "";

  List<Widget> _createParams(bool type) {
    return (type)
        ? new List<Widget>.generate(sortTypes.length, (int index) {
            return InkWell(
              child: Text(sortTypes[index]),
              onTap: () {
                setState(() {
                  var q = sortTypes[index];
                  if (q == "hot" || q == "new" || q == "rising") {
                    parseTypeFilter(q);
                    currentSortTime = "";

                    refreshList();
                    //bloc.resetFilters();

                    _changeParamsVisibility();
                  } else {
                    tempType = q;
                    _changeTypeVisibility();
                  }
                });
              },
            );
          })
        : new List<Widget>.generate(sortTimes.length, (int index) {
            return InkWell(
              child: Text(sortTimes[index]),
              onTap: () {
                if (tempType != "") {
                  parseTypeFilter(tempType);
                  currentSortTime = sortTimes[index];
                  refreshList();
                  tempType = "";
                }
                _changeTypeVisibility();
                _changeParamsVisibility();
              },
            );
          });
  }

  _changeParamsVisibility() {
    //Resets the bloc:s tempType filter in case of continuity errors.
    tempType = "";
    setState(() {
      if (paramsExpanded) {
        paramsHeight = 0.0;
        paramsExpanded = false;
      } else {
        paramsExpanded = true;
        paramsHeight = 25.0;
      }
    });
  }

  AnimationController _controller;

  double lerp(double min, double max) =>
      lerpDouble(min, max, _controller.value);

  void _handleDragUpdate(DragUpdateDetails details) {
    _controller.value -= details.primaryDelta /
        maxHeight; //<-- Update the _controller.value by the movement done by user.
  }

  void _reverse() {
    _controller.fling(velocity: -2.0);
    isElevated = false;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_controller.status == AnimationStatus.completed) {
      isElevated = true;
    }
    if (_controller.isAnimating ||
        _controller.status == AnimationStatus.completed) return;

    final double flingVelocity = details.velocity.pixelsPerSecond.dy /
        maxHeight; //<-- calculate the velocity of the gesture
    if (flingVelocity < 0.0) {
      _controller.fling(
          velocity: max(2.0, -flingVelocity)); //<-- either continue it upwards
      isElevated = true;
    } else if (flingVelocity > 0.0) {
      _controller.fling(
          velocity: min(-2.0, -flingVelocity)); //<-- or continue it downwards
      isElevated = false;
    } else
      _controller.fling(
          velocity: _controller.value < 0.5
              ? -2.0
              : 2.0); //<-- or just continue to whichever edge is closer
  }
  

  @override
  Widget build(BuildContext context) {
    bloc = BlocProvider.of<PostsBloc>(context);
    if (bloc.currentState.userContent == null || bloc.currentState.userContent.isEmpty) {
      bloc.dispatch(PostsSourceChanged(redditor: this.redditor, source: this.initialSource));
    }
    return new WillPopScope(
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          drawer: new Drawer(
              child: new Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Stack(
                  children: <Widget>[
                    CustomScrollView(
                      slivers: <Widget>[
                        SliverToBoxAdapter(
                          child: Container(height: 150,),
                        ),
                        SliverToBoxAdapter(
                          child: BlocBuilder<PostsBloc, PostsState>(
                            builder: (context, PostsState state){
                              return CustomExpansionTile(
                                fontSize: 32.0,
                                title: currentUser.value,
                                children: getRegisteredUsernamesList(state.usernamesList),
                              );
                            },
                          )
                        ),
                        PostsProvider().isLoggedIn() ? SliverToBoxAdapter(
                          child: FutureBuilder(
                            future: PostsProvider().getLoggedInUser(),
                            builder: (BuildContext context, AsyncSnapshot<prefix0.Redditor> snapshot){
                              switch (snapshot.connectionState) {
                                case ConnectionState.done:
                                  if(snapshot.hasError){
                                    return Text('Error loading user data');
                                  }
                                  return CustomExpansionTile(
                                    title: "Profile",
                                    fontSize: 32.0,
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Column(children: <Widget>[
                                            Text(
                                              snapshot.data.commentKarma.toString(),
                                              style: TextStyle(fontSize: 28.0),
                                            ),
                                            Text(
                                              'Comment karma',
                                              style: TextStyle(fontSize: 22.0),
                                            )
                                          ],),
                                          Spacer(),
                                          VerticalDivider(),
                                          Spacer(),
                                          Column(children: <Widget>[
                                            Text(
                                              snapshot.data.linkKarma.toString(),
                                              style: TextStyle(fontSize: 28.0),
                                            ),
                                            Text(
                                              'Link karma',
                                              style: TextStyle(fontSize: 22.0),
                                            )
                                          ],)
                                        ],
                                      ),
                                      Divider(),
                                      SelfContentTypeWidget("Comments", scontrol),
                                      SelfContentTypeWidget("Submitted", scontrol),
                                      SelfContentTypeWidget("Upvoted", scontrol),
                                      SelfContentTypeWidget("Saved", scontrol),
                                      SelfContentTypeWidget("Hidden", scontrol),
                                      SelfContentTypeWidget("Watching", scontrol),
                                      SelfContentTypeWidget("Friends", scontrol)
                                    ],
                                  );
                                default:
                                  return Container();
                              }
                          },
                        ),
                        ) : null,
                        SliverToBoxAdapter(
                          child: RaisedButton(
                              child: const Text('Add an account'),
                              color: Theme.of(context).primaryColor,
                              onPressed: () {
                                var pp = PostsProvider();
                                setState(() {
                                  pp.registerReddit();
                                  refreshList();
                                });
                              },
                            ),
                        )
                      ].where(notNull).toList(),
                    ),
                    Positioned(
                      bottom: 0.0,
                      right: 0.0,
                      child: Container(
                        height: 50.0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Text(appName + ' v.' + appVersion),
                            IconButton(
                              icon: Icon(Icons.settings),
                              onPressed: (){
                                Navigator.of(context).pushNamed('settings');
                              },
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                )
          )),
          endDrawer: new Drawer(
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.all(5.0),
                      helperText: "Search"
                    ),
                  ),
                ),
                BlocBuilder<PostsBloc, PostsState>(
                  builder: (context, state){
                    return notNull(state.sideBar)
                      ? SliverToBoxAdapter(
                        child: Html(data: state.sideBar.contentHtml),
                      )
                      : null;
                  },
                )
              ].where((w) => notNull(w)).toList(),
            )
          ),
          body: new Container(
              child: new GestureDetector(
                child: new Stack(
                  children: <Widget>[
                    StreamBuilder(
                      stream: bloc.state.takeWhile((PostsState s){
                        return s.userContent != null;
                      }),
                      builder: (context, AsyncSnapshot<PostsState> snapshot){
                        if(snapshot.hasData && snapshot.data.userContent != null && snapshot.data.userContent.isNotEmpty){
                          final state = snapshot.data;
                          if(state.contentSource == ContentSource.Redditor){
                            return snapshot.data.targetRedditor.isNotEmpty
                              ? buildList(snapshot)
                              : Center(child: CircularProgressIndicator());
                          } else {
                            return buildList(snapshot);
                          }
                        }else if (snapshot.hasError) {
                          return Text(snapshot.error.toString());
                        }else{
                          return Center(child: CircularProgressIndicator());
                        }
                      },
                    ),
                    getFloatingNavBar()
                  ].where(notNull).toList(),
                ),
            onTapUp: (TapUpDetails details) {
              hideOverlay();
            },
          )),
        ),
        onWillPop: _willPop);
  }

  Widget getFloatingNavBar() {
    return new IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return new AnimatedOpacity(
            opacity: visible ? 1.0 : 0.0,
            duration: Duration(milliseconds: 250),
            curve: Curves.easeInSine,
            child: Container(
              alignment: Alignment.bottomCenter,
              padding: new EdgeInsets.only(
                bottom: 25.0 - lerp(0, 25.0),
                right: 55.0 - lerp(0, 55.0),
                left: 55.0 - lerp(0, 55.0),
              ),
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  new Container(
                      height: lerp(45.0, maxHeight) + paramsHeight,
                      decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25.0),
                            topRight: Radius.circular(25.0),
                            bottomLeft: Radius.circular(25.0 - lerp(0, 25.0)),
                            bottomRight: Radius.circular(25.0 - lerp(0, 25.0)),
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
                                          opacity: lerp(0, 1.0),
                                          duration: Duration(milliseconds: 200),
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
                                                refreshList();
                                                subsListHeight = 50.0;
                                                scontrol.animateTo(0.0,
                                                    duration: Duration(
                                                        milliseconds: 400),
                                                    curve: Curves.decelerate);
                                              },
                                            ),
                                          )),
                                      new IgnorePointer(
                                        ignoring: isElevated,
                                        child: new AnimatedOpacity(
                                          opacity: 1.0 - lerp(0.0, 1.0),
                                          duration: Duration(milliseconds: 150),
                                          curve: Curves.easeInQuad,
                                          child: Container(
                                            padding: EdgeInsets.all(5.0),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: <Widget>[
                                                Expanded(
                                                    child: InkWell(
                                                      child: StreamBuilder(
                                                        stream: bloc.state,
                                                        builder: (context, AsyncSnapshot<PostsState> snapshot){
                                                          return snapshot.hasData && snapshot.data.userContent.isNotEmpty
                                                          ? Column(
                                                              children: <Widget>[
                                                                new Text(
                                                                  snapshot.data.getSourceString(),
                                                                  style: TextStyle(
                                                                    fontSize: 22.0,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign.start,
                                                                ),
                                                                new Text(
                                                                  snapshot.data.getFilterString(),
                                                                  style: TextStyle(
                                                                    fontSize: 14.0,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign.start,
                                                                )
                                                              ],
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment.start,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                            )
                                                          : Container();
                                                        },
                                                      ),
                                                  onTap: () {
                                                    _changeParamsVisibility();
                                                  },
                                                )),
                                                (bloc.currentState != null && bloc.currentState.contentSource == ContentSource.Subreddit && currentSubreddit != "all")
                                                  ? IconButton(
                                                    icon: Icon(Icons.create),
                                                    onPressed: () {
                                                      final snackBar = SnackBar(
                                                        content: Text(
                                                            'Log in in order to post your submission'),
                                                      );
                                                      setState(() {
                                                        if(PostsProvider().isLoggedIn()){
                                                          showSubmit(context);
                                                        }else{
                                                          Scaffold.of(context).showSnackBar(snackBar);
                                                        }
                                                      });
                                                    },
                                                  )
                                                  : null,
                                              ].where(notNull).toList(),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  width: MediaQuery.of(context).size.width,
                                )),
                            new Container(
                              //Height for the expanding bottom nav bar
                              height: lerp(0, maxHeight-50.0),
                              child: new StreamBuilder(
                                stream: sub_bloc.getSubs,
                                builder: (context,
                                    AsyncSnapshot<SubredditM> snapshot) {
                                  if (isElevated) {
                                    if (snapshot.hasData) {
                                      return buildSubsList(snapshot);
                                    } else if (snapshot.hasError) {
                                      return Text(snapshot.error.toString());
                                    }
                                    return Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: <Widget>[
                                            Icon(
                                              Icons.search,
                                              size: max(50.0, MediaQuery.of(context).size.width/7),
                                              ),
                                            Text('Search for subreddits')
                                          ],
                                        ));
                                  } else {
                                    return Container(
                                      height: 0.0,
                                    );
                                  }
                                },
                              ),
                            ),
                            new Visibility(
                              child: new Container(
                                height: 25.0,
                                color: Theme.of(context).primaryColorDark,
                                child: Padding(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      AnimatedSize(
                                        child: Container(
                                            child: Row(
                                              children: _createParams(true),
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                            ),
                                            height: typeHeight),
                                        duration: Duration(milliseconds: 150),
                                        vsync: this,
                                        curve: Curves.ease,
                                      ),
                                      AnimatedSize(
                                        child: Container(
                                            child: Row(
                                              children: _createParams(false),
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                            ),
                                            height: 25.0 - typeHeight),
                                        duration: Duration(milliseconds: 150),
                                        vsync: this,
                                        curve: Curves.ease,
                                      ),
                                    ],
                                  ),
                                  padding:
                                      EdgeInsets.only(left: 5.0, right: 5.0),
                                ),
                              ),
                              visible: !isElevated,
                            ),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(25.0),
                          topRight: Radius.circular(25.0),
                          bottomLeft: Radius.circular(25.0 - lerp(0, 25.0)),
                          bottomRight: Radius.circular(25.0 - lerp(0, 25.0)),
                        ),
                      )),
                ],
              ),
            ),
          );
        },
      ),
      ignoring: !visible,
    );
  }

  List<Widget> getRegisteredUsernamesList(List<String> list) {
    List<Widget> widgets = [];
    for(int i = 0; i < list.length; i++){
      widgets.add(InkWell(
          child: Container(
            child: Text(
              list[i],
              style: TextStyle(fontSize: 18.0, fontStyle: FontStyle.italic),
            ),
            margin: EdgeInsets.all(18.0),
          ),
          onTap: () {
            if (i == 0) {
              PostsProvider().logInAsGuest().then((_) {
                setState(() {
                  refreshList();
                });
              });
            }
            PostsProvider().logIn(list[i]).then((success){
              if(success) refreshList();
            });
          },
        ));
    }
    return widgets;
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
                refreshList();
                scontrol.animateTo(0.0,
                    duration: Duration(milliseconds: 400),
                    curve: Curves.decelerate);
              });
        });
  }

  ScrollController scontrol = new ScrollController();
  bool visible = true;

  Widget buildList(AsyncSnapshot<PostsState> snapshot) {
    var state = snapshot.data;
    var posts = state.userContent;
    return new NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (autoLoad &&
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          // ! bloc.fetchMore();
        }
        if (scrollInfo is ScrollUpdateNotification) {
          var sc = scrollInfo;
          if (sc.scrollDelta >= 10.0 && visible && !isElevated) {
            setState(() {
              visible = false;
            });
          } else if (sc.scrollDelta <= -10.0 && !visible) {
            setState(() {
              visible = true;
            });
          }
        }
        return true;
      },
      child: new ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: scontrol,
          itemCount: state.contentSource == ContentSource.Redditor ? posts.length + 2 : posts.length + 1,
          itemBuilder: (BuildContext context, int i) {
            var finalIndex = state.contentSource == ContentSource.Redditor ? posts.length + 1 : posts.length;
            if(i == finalIndex){
              return Container(
                color: Theme.of(context).primaryColor,
                child: FlatButton(
                    onPressed: () {
                      bloc.dispatch(FetchMore());
                      setState(() {
                        // ! bloc.fetchMore();
                      });
                    },
                    child: Text("Load more")),
              );
            } else if(state.contentSource == ContentSource.Redditor && i == 0){
              if(headerWidget == null){
                headerWidget = FutureBuilder(
                  future: PostsProvider().getRedditor(state.targetRedditor),
                  builder: (BuildContext context, AsyncSnapshot<prefix0.Redditor> snapshot){
                    if(snapshot.connectionState == ConnectionState.done){
                      return getSpaciousUserColumn(snapshot.data);
                    }else{
                      return Padding(
                        child: Center(
                          child: Container(
                            child: CircularProgressIndicator(),
                            height: 25.0,
                            width: 25.0
                          ),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10.0)
                      );
                    }
                  },
                );
              }
              return headerWidget;
            } else {
              int index = state.contentSource == ContentSource.Redditor ? i-1 : i;
              return posts[index] is prefix0.Submission
                    ? new Hero(
                      tag: 'post_hero ${(posts[index] as prefix0.Submission).id}',
                      child: new postInnerWidget(Post.fromApi((posts[index] as prefix0.Submission)), this, PostView.IntendedPreview)
                    )
                    : new CommentContent(posts[index] as prefix0.Comment);
            }
          }),
    );
  }
  //Represents the topmost widget, in Subreddits it's the subreddit header; in users it's the user info header.
  Widget headerWidget;

  Widget getSpaciousUserColumn(prefix0.Redditor redditor){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(
          child: ClipOval(
            child: Image(
              image: AdvancedNetworkImage(
                redditor.data['icon_img'],
                useDiskCache: true,
                cacheRule: CacheRule(maxAge: const Duration(days: 7))
              ),
            ),
          ),
          width: 120,
          height: 120,
        ),
        Divider(),
        Text(
          'u/${redditor.fullname}',
          style: TextStyle(
            fontSize: 25.0,
          ),
          ),
        Divider(),
        Padding(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Text('Post karma: ${redditor.linkKarma}',),
              Text('Comment karma: ${redditor.commentKarma}',)
            ],
          ),
        padding: EdgeInsets.only(bottom: 10.0),)
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _videoController.dispose();
    controller?.dispose();
    scontrol.dispose();
    previewController?.dispose();
    bloc.dispose();
  }

  void showComments(BuildContext context, prefix0.Submission inside) {
    Navigator.of(context).pushNamed('comments', arguments: inside);
  }

  void showSubmit(BuildContext context) {
    Navigator.of(context).pushNamed('submit');
  }

  void refreshList(){
    bloc.dispatch(PostsSourceChanged());
    scontrol.animateTo(0.0, duration: Duration(milliseconds: 800), curve: Curves.easeInOut);
  }
}

class SelfContentTypeWidget extends StatelessWidget {
  final String contentType;
  final ScrollController scontrol;
  const SelfContentTypeWidget(this.contentType, this.scontrol);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        margin: EdgeInsets.all(5.0),
        width: MediaQuery.of(context).size.width,
        child: Text(contentType, style: prefix1.TextStyle(
          fontSize: 22.0
        ),)
      ),
      onTap: (){
        final bloc = BlocProvider.of<PostsBloc>(context);
        switch (contentType) {
          case "Comments":
            bloc.dispatch(PostsSourceChanged(
              source: ContentSource.Self,
              selfContentType: SelfContentType.Comments
            ));
            break;
          case "Submitted":
            bloc.dispatch(PostsSourceChanged(
              source: ContentSource.Self,
              selfContentType: SelfContentType.Submitted
            ));
            break;
          case "Upvoted":
            bloc.dispatch(PostsSourceChanged(
              source: ContentSource.Self,
              selfContentType: SelfContentType.Upvoted
            ));
            break;
          case "Saved":
            bloc.dispatch(PostsSourceChanged(
              source: ContentSource.Self,
              selfContentType: SelfContentType.Saved
            ));
            break;
          case "Hidden":
            bloc.dispatch(PostsSourceChanged(
              source: ContentSource.Self,
              selfContentType: SelfContentType.Hidden
            ));
            break;
          case "Watching":
            bloc.dispatch(PostsSourceChanged(
              source: ContentSource.Self,
              selfContentType: SelfContentType.Watching
            ));
            break;
          //Non-Posts sources:
          case "Friends":
            // TODO: Implement
            break;
          default:
        }
        scontrol.animateTo(0.0, duration: Duration(milliseconds: 800), curve: Curves.easeInOut);
      },
    );
  }
}
