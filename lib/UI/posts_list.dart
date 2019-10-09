import 'package:draw/draw.dart' as prefix0;
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix1;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:lyre/Blocs/bloc/bloc.dart';
import 'package:lyre/Resources/PreferenceValues.dart';
import 'package:lyre/UI/Comments/comment.dart';
import 'package:lyre/UI/CustomExpansionTile.dart';
import 'package:lyre/UI/video_player/lyre_video_player.dart';
import 'package:lyre/utils/HtmlUtils.dart';
import 'package:lyre/utils/urlUtils.dart';
import 'dart:ui';
import '../Models/Subreddit.dart';
import '../Blocs/subreddits_bloc.dart';
import '../Resources/globals.dart';
import 'dart:async';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:flutter_advanced_networkimage/zoomable.dart';
import 'postInnerWidget.dart';
import 'interfaces/previewCallback.dart';
import 'dart:math';
import '../Resources/reddit_api_provider.dart';
import '../Resources/gfycat_provider.dart';
import 'package:video_player/video_player.dart';

enum PreviewType { Image, Video }

class PostsView extends StatelessWidget {
  PostsView(String targetRedditor, ContentSource source){
    this.redditor = targetRedditor;
    initialSource = targetRedditor.isNotEmpty
      ? ContentSource.Redditor
      : (source == null)
        ? ContentSource.Subreddit
        : source;
  }

  ContentSource initialSource;
  String redditor;

  final PostsBloc _postsBloc = PostsBloc();

  @override
  Widget build(BuildContext context){
    return BlocProvider(
      builder: (context) => _postsBloc,
      child: PostsList(redditor, initialSource),
    );
  }
}

class PostsList extends StatefulWidget {
  PostsList(this.redditor, this.initialSource);

  final ContentSource initialSource;
  final String redditor;

  State<PostsList> createState() => new PostsListState(redditor, initialSource);
}

class PostsListState extends State<PostsList> with TickerProviderStateMixin, PreviewCallback {
  PostsListState(this.redditor, this.initialSource);

  bool autoLoad;
  PostsBloc bloc;
  //Represents the topmost widget, in Subreddits it's the subreddit header; in users it's the user info header.
  Widget headerWidget;

  OverlayEntry imageEntry;
  final ContentSource initialSource;
  bool isPreviewing = false;
  final FloatingNavBarController navBarController = FloatingNavBarController(maxNavBarHeight: 400.0, typeHeight: 25.0);
  AnimationController previewController;
  PreviewType previewType;
  var previewUrl = "https://i.imgur.com/CSS40QN.jpg";

  final String redditor;

  ScrollController scontrol = new ScrollController();
  OverlayState state;
  var titletext = "Lyre for Reddit";
  OverlayEntry videoEntry;

  LyreVideoController _vController;
  VideoPlayerController _videoController;
  AnimationController _videoControlsController;
  Future<void> _videoInitialized;

  @override
  void dispose() {
    _videoController.dispose();
    _vController.dispose();
    scontrol.dispose();
    previewController?.dispose();
    bloc.dispose();
    super.dispose();
  }

  @override
  void initState() {
   
    currentUser.addListener((){
      setState(() {
        
      });
    });
    _videoControlsController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200)
    );
    
    previewController = new AnimationController(
        vsync: this, duration: const Duration(milliseconds: 50));

    state = Overlay.of(context);
    imageEntry = OverlayEntry(
        builder: (context) => new Container(
          width: 400.0,
          height: 500.0,
          child: new Container(
            child: ZoomableWidget(
              onTap: (){
                hideOverlay();
              },
              enableRotate: false,
              multiFingersPan: false,
              minScale: 1.0,
              maxScale: 5.0,
              panLimit: 0.8,
              child: Image(
                image: AdvancedNetworkImage(
                  previewUrl,
                  useDiskCache: true,
                  cacheRule: CacheRule(maxAge: const Duration(days: 7)),
              )),
            ),
            color: Color.fromARGB(200, 0, 0, 0),
          )
        ),
    );

    videoEntry = OverlayEntry(
      builder: (context) => Container(
        color: const Color.fromARGB(200, 0, 0, 0),
        child: StatefulBuilder(
          builder: (context, setState){
            return FutureBuilder(
              future: _videoInitialized,
              builder: (context, snapshot){
                if (snapshot.connectionState == ConnectionState.done){
                  return LyreVideo(
                    controller: _vController,
                  );
                } else {
                  return const Center(child: CircularProgressIndicator(),);
                }
              },
            );
          },
          ),
        ),
      );
    super.initState();
  }

  @override
  void preview(String url) {
    var linkType = getLinkType(url);
    if (videoLinkTypes.contains(linkType)){
      if (!isPreviewing) {
        previewType = PreviewType.Video;
        if (linkType == LinkType.Gfycat){
          gfycatProvider().getGfyWebmUrl(getGfyid(url)).then((videoUrl) {
            _videoInitialized = _initializeVideo(videoUrl);
          });
        } else {
          _initializeVideo(url, VideoFormat.dash);
        }
      }
    } else if (!isPreviewing){
      previewType = PreviewType.Image;
      previewUrl = url.toString();
      showOverlay();
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
  void view(String url) {}

  Future<void> _initializeVideo(String videoUrl, [VideoFormat format]) async {
    
    _videoController = VideoPlayerController.network(videoUrl, formatHint: format);
    await _videoController.initialize();
    _vController = LyreVideoController(
      showControls: true,
      aspectRatio: _videoController.value.aspectRatio,
      autoPlay: true,
      videoPlayerController: _videoController,
      looping: bloc.currentState.preferences.get(VIDEO_LOOP) ?? true,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
    showVideoOverlay();
  }

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
        _videoController.pause();
        videoEntry.remove();
      }
      state.deactivate();
      isPreviewing = false;
    }
  }

  List<Widget> getRegisteredUsernamesList(List<String> list) {
    List<Widget> widgets = [];
    for(int i = 0; i < list.length; i++){
      widgets.add(InkWell(
          child: Container(
            child: Text(
              list[i],
              style: const TextStyle(fontSize: 18.0, fontStyle: FontStyle.italic),
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
    if (navBarController.isElevated) {
      navBarController.toggleElevation();
      return new Future.value(false);
    } else if(isPreviewing){
      if (_vController != null && _vController.isFullScreen){
        _vController.exitFullScreen();
      } else {
        previewUrl = "";
        hideOverlay();
      }
      return new Future.value(false);
    }
    return new Future.value(true);
  }

  Widget buildList(AsyncSnapshot<PostsState> snapshot) {
    var state = snapshot.data;
    var posts = state.userContent;
    return new NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.depth != 0) return true;
        if ((autoLoad ?? false) && (scrollInfo.metrics.maxScrollExtent - scrollInfo.metrics.pixels) < MediaQuery.of(context).size.height * 1.5){
          setState(() {
            bloc.dispatch(FetchMore());
          });
        }
        if (scrollInfo is ScrollUpdateNotification) {
          if (scrollInfo.scrollDelta >= 10.0) {
            navBarController.setVisibility(false);
          } else if (scrollInfo.scrollDelta <= -10.0){
            navBarController.setVisibility(true);
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
                      setState(() {
                        bloc.dispatch(FetchMore());
                      });
                    },
                    child: const Text("Load More")),
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
                            child: const CircularProgressIndicator(),
                            height: 25.0,
                            width: 25.0
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10.0)
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
                      child: new postInnerWidget(posts[index] as prefix0.Submission, this)
                    )
                    : new CommentContent(posts[index] as prefix0.Comment);
            }
          }),
    );
  }

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
                cacheRule: const CacheRule(maxAge: const Duration(days: 7))
              ),
            ),
          ),
          width: 120,
          height: 120,
        ),
        const Divider(),
        Text(
          'u/${redditor.fullname}',
          style: TextStyle(
            fontSize: 25.0,
          ),
          ),
        const Divider(),
        Padding(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Text('Post karma: ${redditor.linkKarma}',),
              Text('Comment karma: ${redditor.commentKarma}',)
            ],
          ),
        padding: const EdgeInsets.only(bottom: 10.0),)
      ],
    );
  }

  void showComments(BuildContext context, prefix0.Submission inside) {
    Navigator.of(context).pushNamed('comments', arguments: inside);
  }

  void refreshList(){
    bloc.dispatch(PostsSourceChanged());
  }

  @override
  Widget build(BuildContext context) {
    bloc = BlocProvider.of<PostsBloc>(context);
    if (bloc.currentState.userContent == null || bloc.currentState.userContent.isEmpty) {
      bloc.dispatch(PostsSourceChanged(redditor: this.redditor, source: this.initialSource));
    }
    bloc.state.listen((PostsState state){
      if(state.userContent.isNotEmpty && !state.updated) scontrol.animateTo(0.0, duration: Duration(milliseconds: 800), curve: Curves.easeInOut);
    });
    return new WillPopScope(
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          drawer: new Drawer(
              child: new Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                                    return const Text('Error loading user data');
                                  }
                                  return CustomExpansionTile(
                                    title: "Profile",
                                    initiallyExpanded: true,
                                    fontSize: 32.0,
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Column(children: <Widget>[
                                            Text(
                                              snapshot.data.commentKarma.toString(),
                                              style: const TextStyle(fontSize: 28.0),
                                            ),
                                            const Text(
                                              'Comment karma',
                                              style: const TextStyle(fontSize: 22.0),
                                            )
                                          ],),
                                          const Spacer(),
                                          const VerticalDivider(),
                                          const Spacer(),
                                          Column(children: <Widget>[
                                            Text(
                                              snapshot.data.linkKarma.toString(),
                                              style: const  TextStyle(fontSize: 28.0),
                                            ),
                                            const Text(
                                              'Link karma',
                                              style: TextStyle(fontSize: 22.0),
                                            )
                                          ],)
                                        ],
                                      ),
                                      const Divider(),
                                      const SelfContentTypeWidget("Comments"),
                                      const SelfContentTypeWidget("Submitted"),
                                      const SelfContentTypeWidget("Upvoted"),
                                      const SelfContentTypeWidget("Saved"),
                                      const SelfContentTypeWidget("Hidden"),
                                      const SelfContentTypeWidget("Watching"),
                                      const SelfContentTypeWidget("Friends")
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
                SliverAppBar(
                  expandedHeight: 125.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: Theme.of(context).canvasColor.withOpacity(0.8),
                  actions: <Widget>[Container()],
                  leading: Container(),
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: false,
                    title: Text(
                      'r/' + currentSubreddit,
                      style: prefix1.TextStyle(fontSize: 32.0),
                      ),
                    background: BlocBuilder<PostsBloc, PostsState>(
                      builder: (context, state){
                        return state.styleSheetImages.isNotEmpty
                          ? prefix1.Image(
                            image: AdvancedNetworkImage(
                              state.styleSheetImages[0].url.toString(),
                              useDiskCache: true,
                              cacheRule: CacheRule(maxAge: const Duration(days: 28)),
                            ),
                            fit: BoxFit.fitHeight
                          )
                          : Container(); // TODO: Placeholder image
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.all(5.0),
                      helperText: "Search r/$currentSubreddit",
                      helperStyle: prefix1.TextStyle(fontStyle: FontStyle.italic)
                    ),
                  ),
                ),
                BlocBuilder<PostsBloc, PostsState>(
                  builder: (context, state){
                    return notNull(state.sideBar)
                      ? SliverToBoxAdapter(
                        child: Html(
                          data: parseShittyFlutterHtml(state.sideBar.contentHtml),
                          padding: EdgeInsets.symmetric(horizontal: 5.0),
                        )
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
                          autoLoad = state.preferences?.get(SUBMISSION_AUTO_LOAD);
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
                    new FloatingNavigationBar(controller: navBarController,)
                  ].where(notNull).toList(),
                ),
            onTapUp: (TapUpDetails details) {
              hideOverlay();
            },
          )),
        ),
        onWillPop: _willPop);
  }
}

class FloatingNavigationBar extends StatefulWidget {
  FloatingNavigationBar({
    Key key,
    @required this.controller,
  }) : super(key: key);

  final FloatingNavBarController controller;

  @override
  _FloatingNavigationBarState createState() => _FloatingNavigationBarState();
}

class _FloatingNavigationBarState extends State<FloatingNavigationBar> with TickerProviderStateMixin{
  AnimationController controller;
  Animation<double> edgeAnimation;
  Tween edgeTween = new Tween<double>(begin: 55.0, end: 0.0);
  Animation<double> height2Animation;
  Tween height2Tween = new Tween<double>(begin: 0.0, end: 350.0);
  Animation<double> heightAnimation;
  double maxNavBarHeight = 400.0; //<-- Get max height of the screen
  Animation<double> opacityAnimation;
  Tween opacityTween = new Tween<double>(begin: 0.0, end: 1.0);
  Animation<double> padAnimation;
  Tween padTween = new Tween<double>(begin: 25.0, end: 0.0);
  Animation<double> roundAnimation;
  Tween roundTween = new Tween<double>(begin: 30.0, end: 0.0);
  var subsListHeight = 50.0;
  String tempType = "";

  AnimationController _navBarController;

  @override void dispose(){
    controller?.dispose();

  @override
  void initState(){
    maxNavBarHeight = 400.0;
    _navBarController = AnimationController(
      //<-- initialize a controller
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    controller = new AnimationController(
        vsync: this, duration: const Duration(milliseconds: 325));
        void initV(BuildContext context) {
    maxNavBarHeight = MediaQuery.of(context).size.height / 2.5;
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
    widget.controller.addListener((){
      setState(() {
      });
    });
  }
    super.initState();
  }

    _navBarController.dispose();

    super.dispose();

  }

  @override
  void initState(){
    maxNavBarHeight = 400.0;
    _navBarController = AnimationController(
      //<-- initialize a controller
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    controller = new AnimationController(
        vsync: this, duration: const Duration(milliseconds: 325));
        void initV(BuildContext context) {
    maxNavBarHeight = MediaQuery.of(context).size.height / 2.5;
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
    widget.controller.addListener((){
      setState(() {
      });
    });
  }
    super.initState();
  }

  double navBarLerp(double min, double max) => lerpDouble(min, max, _navBarController.value);

  _changeTypeVisibility() {
    if (widget.controller.typeVisible) {
      widget.controller.typeVisible = false;
    } else {
      widget.controller.typeVisible = true;
    }
  }

  List<Widget> _createParams([bool type]) {
    switch (BlocProvider.of<PostsBloc>(context).currentState.contentSource) {
      case ContentSource.Subreddit:
        return (type)
          ? sortTypeParams()
          : sortTimeParams();
      default: //Defaults to [ContentSource.Redditor]
        return (type)
          ? sortTypeParamsUser()
          : sortTimeParams();
    }
  }

  List<Widget> sortTimeParams() {
    return new List<Widget>.generate(sortTimes.length, (int index) {
      return InkWell(
        child: Text(sortTimes[index]),
        onTap: () {
          if (tempType != "") {
            parseTypeFilter(tempType);
            currentSortTime = sortTimes[index];
            BlocProvider.of<PostsBloc>(context).dispatch(ParamsChanged());
            tempType = "";
          }
          _changeTypeVisibility();
          _changeParamsVisibility();
        },
      );
    });
  }

  List<Widget> sortTypeParamsUser(){
    return new List<Widget>.generate(sortTypes.length, (int index) {
      return InkWell(
        child: Text(sortTypesuser[index]),
        onTap: () {
          setState(() {
            var q = sortTypes[index];
            if (q == "hot" || q == "new" || q == "rising") {
              parseTypeFilter(q);
              currentSortTime = "";

              BlocProvider.of<PostsBloc>(context).dispatch(ParamsChanged());
              //bloc.resetFilters();

              _changeParamsVisibility();
            } else {
              tempType = q;
              _changeTypeVisibility();
            }
          });
        },
      );
    });
  }

  List<Widget> sortTypeParams() {
    return new List<Widget>.generate(sortTypes.length, (int index) {
          return InkWell(
            child: Text(sortTypes[index]),
            onTap: () {
              setState(() {
                var q = sortTypes[index];
                if (q == "hot" || q == "new" || q == "rising") {
                  parseTypeFilter(q);
                  currentSortTime = "";

                  BlocProvider.of<PostsBloc>(context).dispatch(ParamsChanged());
                  //bloc.resetFilters();

                  _changeParamsVisibility();
                } else {
                  tempType = q;
                  _changeTypeVisibility();
                }
              });
            },
          );
        });
  }

  _changeParamsVisibility() {
    //Resets the bloc:s tempType filter in case of continuity errors.
    tempType = "";
    setState(() {
      if (widget.controller.paramsExpanded) {
        widget.controller.typeVisible = true; //Reset params visibility so that type pops up on next click
        widget.controller.paramsHeight = 0.0;
        widget.controller.paramsExpanded = false;
      } else {
        widget.controller.paramsExpanded = true;
        widget.controller.paramsHeight = 25.0;
      }
    });
  }

  void _handleNavDragUpdate(DragUpdateDetails details) {
    _navBarController.value -= details.primaryDelta /
        maxNavBarHeight; //<-- Update the _navBarController.value by the movement done by user.
  }

  void _reverseNav() {
    _navBarController.fling(velocity: -2.0);
    widget.controller.isElevated = false;
  }

  void _handleNavDragEnd(DragEndDetails details) {
    if (_navBarController.status == AnimationStatus.completed) {
      widget.controller.isElevated = true;
    }
    if (_navBarController.isAnimating ||
        _navBarController.status == AnimationStatus.completed) return;

    final double flingVelocity = details.velocity.pixelsPerSecond.dy /
        maxNavBarHeight; //<-- calculate the velocity of the gesture
    if (flingVelocity < 0.0) {
      _navBarController.fling(
          velocity: max(2.0, -flingVelocity)); //<-- either continue it upwards
      widget.controller.isElevated = true;
    } else if (flingVelocity > 0.0) {
      _navBarController.fling(
          velocity: min(-2.0, -flingVelocity)); //<-- or continue it downwards
      widget.controller.isElevated = false;
    } else
      _navBarController.fling(
          velocity: _navBarController.value < 0.5
              ? -2.0
              : 2.0); //<-- or just continue to whichever edge is closer
  }

  void reverse(BuildContext context) {
    controller.reset();
    controller.reverse();
    widget.controller.isElevated = false;
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
                _reverseNav();
                subsListHeight = 50.0;
                refreshList();
              });
        });
  }

  void refreshList(){
    BlocProvider.of<PostsBloc>(context).dispatch(PostsSourceChanged());
  }

  @override
  Widget build(BuildContext context) {
      widget.controller.addListener((){
        setState(() {
        });
      });
      return new IgnorePointer(
        child: AnimatedBuilder(
          animation: _navBarController,
          builder: (context, child) {
            return new AnimatedOpacity(
              opacity: widget.controller.visible ? 1.0 : 0.0,
              duration: Duration(milliseconds: 250),
              curve: Curves.easeInSine,
              child: Container(
                alignment: Alignment.bottomCenter,
                padding: new EdgeInsets.only(
                  bottom: 25.0 - navBarLerp(0, 25.0),
                  right: 55.0 - navBarLerp(0, 55.0),
                  left: 55.0 - navBarLerp(0, 55.0),
                ),
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    new Container(
                      height: navBarLerp(45.0, widget.controller.maxNavBarHeight) + widget.controller.paramsHeight,
                      decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25.0),
                            topRight: Radius.circular(25.0),
                            bottomLeft: Radius.circular(25.0 - navBarLerp(0, 25.0)),
                            bottomRight: Radius.circular(25.0 - navBarLerp(0, 25.0)),
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
                                onVerticalDragUpdate: _handleNavDragUpdate,
                                onVerticalDragEnd: _handleNavDragEnd,
                                child: new Container(
                                  height: 45.0,
                                  child: new Stack(
                                    children: <Widget>[
                                      new AnimatedOpacity(
                                          opacity: navBarLerp(0, 1.0),
                                          duration: const Duration(milliseconds: 200),
                                          curve: Curves.easeInQuad,
                                          child: new Container(
                                            decoration: BoxDecoration(),
                                            padding: EdgeInsets.only(
                                              left: 15.0,
                                              right: 15.0,
                                            ),
                                            child: new TextField(
                                              //TODO: FIX isElevated
                                              enabled: widget.controller.isElevated,
                                              onChanged: (String s) {
                                                widget.controller.searchQuery = s;
                                                sub_bloc.fetchSubs(s);
                                              },
                                              onEditingComplete: () {
                                                currentSubreddit = widget.controller.searchQuery;
                                                _reverseNav();
                                                refreshList();
                                                subsListHeight = 50.0;
                                              },
                                            ),
                                          )),
                                      new IgnorePointer(
                                        ignoring: widget.controller.isElevated,
                                        child: new AnimatedOpacity(
                                          opacity: 1.0 - navBarLerp(0.0, 1.0),
                                          duration: const Duration(milliseconds: 150),
                                          curve: Curves.easeInQuad,
                                          child: Container(
                                            padding: EdgeInsets.all(5.0),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: <Widget>[
                                                Expanded(
                                                  child: InkWell(
                                                    child: StreamBuilder(
                                                      stream: BlocProvider.of<PostsBloc>(context).state,
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
                                                            mainAxisAlignment: MainAxisAlignment.start,
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                          )
                                                        : Container();
                                                      },
                                                    ),
                                                  onTap: () {
                                                    _changeParamsVisibility();
                                                  },
                                                )),
                                                (BlocProvider.of<PostsBloc>(context).currentState != null && BlocProvider.of<PostsBloc>(context).currentState.contentSource == ContentSource.Subreddit)
                                                  ? IconButton(
                                                    icon: Icon(Icons.create),
                                                    onPressed: () {
                                                      final snackBar = SnackBar(
                                                        content: Text(
                                                            'Log in in order to post your submission'),
                                                      );
                                                      setState(() {
                                                        if(PostsProvider().isLoggedIn()){
                                                          Navigator.of(context).pushNamed('submit');
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
                              height: navBarLerp(0, widget.controller.maxNavBarHeight-25.0),
                              child: new StreamBuilder(
                                stream: sub_bloc.getSubs,
                                builder: (context,
                                    AsyncSnapshot<SubredditM> snapshot) {
                                  if (widget.controller.isElevated) {
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
                                          Text('Search For Subreddits')
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
                                            height: widget.controller.typeVisible ? 25.0 : 0.0),
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
                                            height: widget.controller.typeVisible ? 0.0 : 25.0),
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
                              visible: !widget.controller.isElevated,
                            ),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(25.0),
                          topRight: Radius.circular(25.0),
                          bottomLeft: Radius.circular(25.0 - navBarLerp(0, 25.0)),
                          bottomRight: Radius.circular(25.0 - navBarLerp(0, 25.0)),
                        ),
                      )
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        ignoring: !widget.controller.visible,
      );
  }
}

class FloatingNavBarController extends ChangeNotifier{
  FloatingNavBarController({
    @required this.maxNavBarHeight,
    @required this.typeHeight
  });

  bool isElevated = false;
  final double typeHeight;
  final double maxNavBarHeight;
  bool paramsExpanded = false;
  double paramsHeight = 0.0;
  String searchQuery = "";
  bool typeVisible = true;
  bool visible = true;

  void toggleElevation(){
    isElevated = !isElevated;
    notifyListeners();
  }

  void setVisibility(bool visibility){
    if(visible != visibility){
      this.visible = visibility;
      notifyListeners();
    }
  }

  void toggleVisibility(){
    this.visible = !visible;
    notifyListeners();
  }
}

class SelfContentTypeWidget extends StatelessWidget {
  const SelfContentTypeWidget(this.contentType);

  final String contentType;

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
      },
    );
  }
}
