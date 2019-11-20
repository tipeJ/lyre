import 'dart:ui' as prefix2;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:draw/draw.dart' as prefix0;
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix1;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import 'package:lyre/Blocs/bloc/bloc.dart';
import 'package:lyre/Resources/PreferenceValues.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/Themes/textstyles.dart';
import 'package:lyre/UI/Comments/comment.dart';
import 'package:lyre/UI/CustomExpansionTile.dart';
import 'package:lyre/UI/bottom_appbar.dart';
import 'package:lyre/utils/HtmlUtils.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:transparent_image/transparent_image.dart';
import 'dart:ui';
import '../Models/Subreddit.dart';
import '../Blocs/subreddits_bloc.dart';
import '../Resources/globals.dart';
import 'dart:async';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'postInnerWidget.dart';
import 'interfaces/previewCallback.dart';
import 'dart:math';
import '../Resources/reddit_api_provider.dart';

class PostsList extends StatefulWidget {
  PostsList({Key key}) : super(key: key);

  State<PostsList> createState() => new PostsListState();
}

enum ParamsVisibility {
  Type,
  Time,
  None    
}

class PostsListState extends State<PostsList> with TickerProviderStateMixin{
  PostsListState();

  bool autoLoad;
  PostsBloc bloc;
  //Represents the topmost widget, in Subreddits it's the subreddit header; in users it's the user info header.
  Widget headerWidget;

  final FloatingNavBarController navBarController = FloatingNavBarController(maxNavBarHeight: 400.0, typeHeight: 25.0);

  ScrollController scontrol = new ScrollController();
  var titletext = "Lyre for Reddit";

  @override
  void dispose() {
    scontrol.dispose();
    bloc.drain();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }


  List<Widget> _getRegisteredUsernamesList(List<String> list, String currentUserName) {
    List<Widget> widgets = [];
    for(int i = 0; i < list.length; i++){
      widgets.add(InkWell(
          child: Container(
            child: Text(
              list[i],
              style: TextStyle(fontSize: 18.0, fontWeight: ((i == 0 && currentUserName.isEmpty) || (i != 0 && currentUserName == list[i])) ? FontWeight.bold : FontWeight.w400),
            ),
            padding: EdgeInsets.symmetric(vertical: 18.0),
          ),
          onTap: () {
            if (i == 0) {
              BlocProvider.of<LyreBloc>(context).add(UserChanged(userName: "")); //Empty for Read-Only           
            } else {
              BlocProvider.of<LyreBloc>(context).add(UserChanged(userName: list[i]));
            }
            Navigator.of(context).pop();
            setState(() {
              _refreshList();
            });
          },
        ));
    }
    widgets.add(_registrationButton());
    return widgets;
  }

  Widget _registrationButton() {
   return OutlineButton(
    child: const Text('Add an account'),
      color: Theme.of(context).primaryColor,
      onPressed: () async {
        var pp = PostsProvider();
        /*setState(() {
          pp.registerReddit();
          _refreshList();
        });*/
        final authUrl = await pp.redditAuthUrl();
        pp.auth(authUrl.values.first);
        showDialog(
          context: context,
          builder: (BuildContext context) => Material(
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
              backgroundColor: Theme.of(context).primaryColor,
              child: Column(children: <Widget>[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 15.0),
                  height: 50.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('Authenticate Lyre', style: LyreTextStyles.dialogTitle),
                      IconButton(icon: Icon(Icons.close),onPressed: (){
                        Navigator.pop(context);
                        pp.closeAuthServer();
                      },)
                    ],
                  ),
                ),
                Expanded(
                  child: InAppWebView(
                    onLoadStop: (controller, s) async {
                      if (s.contains('localhost:8080')) {
                        Navigator.pop(context);
                        pp.closeAuthServer();
                      }
                    },
                    initialOptions: {
                      'clearCache' : false,
                      'clearSessionCache' : true
                    },
                    initialUrl: authUrl.keys.first
                  )
                )
              ],),
            )
          )
        );
      },
    );
  }

  Future<bool> _willPop() {
    if (navBarController.isElevated) {
      navBarController.toggleElevation();
      return new Future.value(false);
    }
    return new Future.value(true);
  }

  Widget _buildList(PostsState state) {
    var posts = state.userContent;
    return new NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if ((autoLoad ?? false) && (scrollInfo.metrics.maxScrollExtent - scrollInfo.metrics.pixels) < MediaQuery.of(context).size.height * 1.5){
          bloc.add(FetchMore());
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
      child: CustomScrollView(
        controller: scontrol,
        slivers: <Widget>[
          SliverPadding(
            padding: EdgeInsets.only(bottom: 5.0),
            sliver: SliverAppBar(
              expandedHeight: 125.0,
              floating: false,
              pinned: false,
              backgroundColor: Theme.of(context).canvasColor,
              actions: <Widget>[Container()],
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: EdgeInsets.only(
                  left: 10.0,
                  bottom: 5.0
                  ),
                title: Text(
                  state.getSourceString(),
                  overflow: TextOverflow.fade,
                  style: LyreTextStyles.title,
                ),
                collapseMode: CollapseMode.parallax,
                background: state.subreddit != null && state.subreddit.mobileHeaderImage != null
                  ? FadeInImage(
                    placeholder: MemoryImage(kTransparentImage),
                    image: AdvancedNetworkImage(
                      state.subreddit.mobileHeaderImage.toString(),
                      useDiskCache: true,
                      cacheRule: CacheRule(maxAge: const Duration(days: 3)),
                    ),
                    fit: BoxFit.cover
                  )
                  : Container() // TODO: Placeholder image
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                if(i == posts.length){
                  return Container(
                    color: Theme.of(context).primaryColor,
                    child: FlatButton(
                        onPressed: () {
                          setState(() {
                            bloc.add(FetchMore());
                          });
                        },
                        child: bloc.loading.value == LoadingState.loadingMore ? CircularProgressIndicator() : Text("Load More")),
                  );
                } else {
                  return posts[i] is prefix0.Submission
                        ? new Hero(
                          tag: 'post_hero ${(posts[i] as prefix0.Submission).id}',
                          child: new postInnerWidget(posts[i] as prefix0.Submission, PreviewSource.PostsList)
                        )
                        : new CommentContent(posts[i] as prefix0.Comment);
                }
              },
              childCount: posts.length+1,
            )
          )
        ],
      )
    );
  }

  Widget _getSpaciousUserColumn(prefix0.Redditor redditor){
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

  void _showComments(BuildContext context, prefix0.Submission inside) {
    Navigator.of(context).pushNamed('comments', arguments: inside);
  }

  void _refreshList(){
    bloc.add(PostsSourceChanged());
  }

  @override
  Widget build(BuildContext context) {
    bloc = BlocProvider.of<PostsBloc>(context);
    if (bloc.state.userContent == null || bloc.state.userContent.isEmpty) {
      bloc.add(PostsSourceChanged(source: bloc.state.contentSource, target: bloc.state.target));
    }
    bloc.loading.addListener((){
      if (bloc.loading.value == LoadingState.refreshing) scontrol.animateTo(0.0, duration: Duration(milliseconds: 800), curve: Curves.easeInOut);
      setState(() {
        
      });
    });
    return new WillPopScope(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        drawer: new Drawer(
          child: Stack(
            children: <Widget>[
              BlocBuilder<LyreBloc, LyreState>(
                builder: (context, LyreState state) {
                  final currentUser = state.readOnly ? "" : state.currentUser.displayName;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: CustomScrollView(
                      slivers: <Widget>[
                        SliverSafeArea(
                          sliver: SliverToBoxAdapter(
                            child: CustomExpansionTile(
                              title: currentUser.isNotEmpty ? currentUser : "Guest",
                              showDivider: true,
                              initiallyExpanded: true,
                              children: _getRegisteredUsernamesList(state.userNames, currentUser),
                            ),
                          )
                        ),
                        state.currentUser != null ? SliverToBoxAdapter(
                          child: CustomExpansionTile(
                            title: "Profile",
                            initiallyExpanded: true,
                            showDivider: true,
                            children: <Widget>[
                              Text(
                                state.currentUser.commentKarma.toString(),
                                style: LyreTextStyles.title,
                                textScaleFactor: 0.8,
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 5.0),
                                child: const Text(
                                  'Comment karma',
                                  style: const TextStyle(fontSize: 18.0, color: Colors.grey),
                                ),
                              ),
                              Text(
                                state.currentUser.linkKarma.toString(),
                                style: const  TextStyle(fontSize: 28.0),
                              ),
                              const Text(
                                  'Link karma',
                                  style: TextStyle(fontSize: 18.0, color: Colors.grey),
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
                          )
                        ) : null,
                      ].where(notNull).toList(),
                    )
                  );
                },
              ),
              
              Positioned(
                bottom: 0.0,
                child: Container(
                  height: 50.0,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Theme.of(context).canvasColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 25.0,
                        spreadRadius: 20.0,
                        offset: Offset(0.0, -5)
                      )
                    ]
                  ),
                ),
              ),
              Positioned(
                bottom: 0.0,
                right: 0.0,
                child: Row(
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
              )
            ],
          )
        ),
        endDrawer: new Drawer(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                expandedHeight: 125.0,
                floating: false,
                pinned: true,
                backgroundColor: Theme.of(context).canvasColor.withOpacity(0.8),
                automaticallyImplyLeading: false,
                actions: <Widget>[Container()],
                leading: Container(),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: EdgeInsets.only(left: 10.0),
                  title: Text(
                    'Sidebar',
                    style: LyreTextStyles.title,
                    ),
                  background: BlocBuilder<PostsBloc, PostsState>(
                    builder: (context, state){
                      return state.subreddit != null && state.subreddit.mobileHeaderImage != null
                        ? FadeInImage(
                          placeholder: MemoryImage(kTransparentImage),
                          image: AdvancedNetworkImage(
                            state.subreddit.mobileHeaderImage.toString(),
                            useDiskCache: true,
                            cacheRule: CacheRule(maxAge: const Duration(days: 3)),
                          ),
                          fit: BoxFit.cover
                        )
                        : Container(); // TODO: Placeholder image
                    }
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
        body: PersistentBottomAppbarWrapper(
          fullSizeHeight: MediaQuery.of(context).size.height,
          body: StreamBuilder(
            stream: bloc,
            builder: (BuildContext context, AsyncSnapshot<PostsState> snapshot){
              if (snapshot.hasData) {
                final state = snapshot.data;
                if(state.userContent != null && state.userContent.isNotEmpty){
                  autoLoad = state.preferences?.get(SUBMISSION_AUTO_LOAD);
                  if(state.contentSource == ContentSource.Redditor){
                    return state.target.isNotEmpty
                      ? _buildList(state)
                      : Center(child: CircularProgressIndicator());
                  } else {
                    return _buildList(state);
                  }
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          appBarContent: BlocBuilder<PostsBloc, PostsState>(
            builder: (context, state) {
              return _paramsVisibility == ParamsVisibility.None
                ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Expanded(
                        child: Material(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _paramsVisibility = ParamsVisibility.Type; 
                              });
                            },
                            child: Wrap(
                              direction: Axis.vertical,
                              children: <Widget>[
                                Text(
                                  state.getSourceString(),
                                  style: LyreTextStyles.typeParams
                                ),
                                Text(
                                  state.getFilterString(),
                                  style: LyreTextStyles.timeParams.apply(
                                    color: Theme.of(context).textTheme.body1.color.withOpacity(0.75)
                                  ),
                                )
                              ],
                            )
                          )
                        )
                      ),
                      Material(
                        child: IconButton(
                          icon: Icon(Icons.create),
                          onPressed: () {
                            setState(() {
                              if (PostsProvider().isLoggedIn()) {
                                Navigator.of(context).pushNamed('submit');
                              } else {
                                final snackBar = SnackBar(
                                  content: Text(
                                      'Log in to post your submission'),
                                );
                                Scaffold.of(context).showSnackBar(snackBar);
                              }
                            });
                          },
                        )
                      )
                    ],
                  )
                )
              : Material(
                child: AnimatedCrossFade(
                    firstChild: Row(children: sortTypeParams(),),
                    secondChild: Row(children: sortTimeParams(),),
                    crossFadeState: _paramsVisibility == ParamsVisibility.Type ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    duration: Duration(milliseconds: 300),
                  )
              );
            },
          ),
          expandingSheetContent: _subredditsList(),
        )
      ),
      onWillPop: _willPop);
  }

  List<Widget> sortTimeParams() {
    return new List<Widget>.generate(sortTimes.length, (int index) {
      return Expanded(
        child: InkWell(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _getTypeIcon(sortTimes[index]),
              AutoSizeText(
                sortTimes[index],
                softWrap: false,
                maxFontSize: 12.0,
                minFontSize: 8.0,
                ),
            ],
          ),
          onLongPress: () {
            setState(() {
             _paramsVisibility = ParamsVisibility.Type; 
            });
          },
          onTap: () {
            if (tempType != "") {
              parseTypeFilter(tempType);
              currentSortTime = sortTimes[index];
              BlocProvider.of<PostsBloc>(context).add(ParamsChanged());
              tempType = "";
            }
            _changeTypeVisibility();
            _changeParamsVisibility();
          },
        )
      );
    });
  }
  
  List<Widget> sortTypeParams() {
    return new List<Widget>.generate(sortTypes.length, (int index) {
      return Expanded(
        child: InkWell(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _getTypeIcon(sortTypes[index]),
              AutoSizeText(
                sortTypes[index],
                softWrap: false,
                maxFontSize: 12.0,
                minFontSize: 8.0,
                ),
            ],
          ),
          onLongPress: () {
            setState(() {
             _paramsVisibility = ParamsVisibility.None; 
            });
          },
          onTap: () {
            setState(() {
              var q = sortTypes[index];
              if (q == "hot" || q == "new" || q == "rising") {
                parseTypeFilter(q);
                currentSortTime = "";
                  BlocProvider.of<PostsBloc>(context).add(ParamsChanged());
                  _changeParamsVisibility();
              } else {
                tempType = q;
                _changeTypeVisibility();
              }
            });
          },
        )
      );
    });
  }
  Widget _getTypeIcon(String type) {
    switch (type) {
      // * Type sort icons:
      case 'new':
        return Icon(MdiIcons.newBox);
      case 'rising':
        return Icon(MdiIcons.trendingUp);
      case 'top':
        return Icon(MdiIcons.trophy);
      case 'controversial':
        return Icon(MdiIcons.swordCross);
      // * Age sort icons:
      case 'hour':
        return Icon(MdiIcons.clock);
      case '24h':
        return Text('24', style: LyreTextStyles.iconText);
      case 'week':
        return Icon(MdiIcons.calendarWeek);
      case 'month':
        return Icon(MdiIcons.calendarMonth);
      case 'year':
        return Text('365', style: LyreTextStyles.iconText);
      case 'all time':
        return Icon(MdiIcons.infinity);
      default:
        //Defaults to hot
        return Icon(MdiIcons.fire);
    }
  }

  List<Widget> sortTypeParamsUser(){
    return new List<Widget>.generate(sortTypesuser.length, (int index) {
      return InkWell(
        child: Text(sortTypesuser[index]),
        onTap: () {
          setState(() {
            var q = sortTypesuser[index];
            if (q == "hot" || q == "new" || q == "rising") {
              parseTypeFilter(q);
              currentSortTime = "";

              BlocProvider.of<PostsBloc>(context).add(ParamsChanged());

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
  String tempType = "";
  ParamsVisibility _paramsVisibility = ParamsVisibility.None;
  _changeParamsVisibility() {
    //Resets the bloc:s tempType filter in case of continuity errors.
    tempType = "";
    setState(() {
      if (_paramsVisibility == ParamsVisibility.None) {
        _paramsVisibility = ParamsVisibility.Type;
      } else {
        _paramsVisibility = ParamsVisibility.None;
      }
    });
  }
  _changeTypeVisibility() {
    if (_paramsVisibility == ParamsVisibility.Type) {
      _paramsVisibility = ParamsVisibility.Time;
    } else {
      _paramsVisibility = ParamsVisibility.Type;
    }
  }
}
class _subredditsList extends State<ExpandingSheetContent> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: widget.innerController,
      physics: widget.scrollEnabled ? BouncingScrollPhysics() : NeverScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverSafeArea(
          sliver: SliverToBoxAdapter(
            child: new TextField(
              enabled: widget.appbarController.expanded(),
              onChanged: (String s) {
                searchQuery = s;
                sub_bloc.fetchSubs(s);
              },
              onEditingComplete: () {
                currentSubreddit = searchQuery;
                widget.appbarController.expansionController.animateTo(0.0);
                BlocProvider.of<PostsBloc>(context).add(PostsSourceChanged(source: ContentSource.Subreddit));
              },
            ),
          ),
        ),
        StreamBuilder(
          stream: sub_bloc.getSubs,
          builder: (context,
          AsyncSnapshot<SubredditM> snapshot) {
            if (snapshot.hasData) {
              return _searchedSubredditList(snapshot);
            } else if (snapshot.hasError) {
              return SliverToBoxAdapter(
                child: Center(child: Text(snapshot.error.toString(), style: LyreTextStyles.errorMessage,),),
              );
            } else {
              return _defaultSubredditList();
            }
          },
        ),
      ],
    );
  }

  _openSub(String s) {
    currentSubreddit = s;
    widget.appbarController.expansionController.animateTo(0.0);
    BlocProvider.of<PostsBloc>(context).add(PostsSourceChanged(source: ContentSource.Subreddit));
  }

  List<String> subListOptions = [
    "Remove",
    "Subscribe"
  ];

  Widget _defaultSubredditList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, i) {
        return InkWell(
          onTap: (){
            _openSub(subreddits[i]);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(
                  bottom: 0.0,
                  left: 5.0,
                  top: 0.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(subreddits[i])
                    ),
                    PopupMenuButton<String>(
                      elevation: 3.2,
                      onSelected: (s) {
                        },
                      itemBuilder: (context) {
                        return subListOptions.map((s) {
                          return PopupMenuItem<String>(
                            value: s,
                            child: Column(
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    s == subListOptions[0]
                                      ? Icon(Icons.remove_circle)
                                      : Icon(Icons.add_circle),
                                    VerticalDivider(),
                                    Text(s),
                                    
                                  ]
                                ,),
                                s != subListOptions[subListOptions.length-1] ? Divider() : null
                              ].where((w) => notNull(w)).toList(),
                            ),
                          );
                        }).toList();
                      },
                    )
                  ],
                ),
              ),
              i != subreddits.length-1 ? Divider(indent: 10.0, endIndent: 10.0, height: 0.0,) : null
            ].where((w) => notNull(w)).toList(),
          )
        );
      }, childCount: subreddits.length),
    );
  }
  Widget _searchedSubredditList(AsyncSnapshot<SubredditM> snapshot) {
    var subs = snapshot.data.results;
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, i) {
        return InkWell( //Subreddit entry
          onTap: (){
            _openSub(subs[i].displayName);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(
                  bottom: 0.0,
                  left: 5.0,
                  top: 0.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(subs[i].displayName)
                    ),
                    PopupMenuButton<String>(
                      elevation: 3.2,
                      onSelected: (s) {
                        },
                      itemBuilder: (context) {
                        return subListOptions.map((s) {
                          return PopupMenuItem<String>(
                            value: s,
                            child: Column(
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    s == subListOptions[0]
                                      ? Icon(Icons.remove_circle)
                                      : Icon(Icons.add_circle),
                                    VerticalDivider(),
                                    Text(s),
                                    
                                  ]
                                ,),
                                s != subListOptions[subListOptions.length-1] ? Divider() : null
                              ].where((w) => notNull(w)).toList(),
                            ),
                          );
                        }).toList();
                      },
                    )
                  ],
                ),
              ),
              i != subs.length-1 ? Divider(indent: 10.0, endIndent: 10.0, height: 0.0,) : null
            ].where((w) => notNull(w)).toList(),
          )
        );
      }, childCount: subs.length),
    );
    return ListView.builder(
      physics: widget.scrollEnabled ? BouncingScrollPhysics() : NeverScrollableScrollPhysics(),
      itemCount: subs.length+1,
      itemBuilder: (context, i) {
        
      },
    );
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
  double maxNavBarHeight = 400.0; //<-- Get max height of the screen
  var subsListHeight = 50.0;
  String tempType = "";

  AnimationController _navBarController;

  bool isElevated;
  get() => _navBarController.value > 0.9;

  @override void dispose(){

    _navBarController.dispose();

    super.dispose();

  }

  @override
  void initState(){
    super.initState();
    maxNavBarHeight = 400.0;
    _navBarController = AnimationController(
      //<-- initialize a controller
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    // ! ENABLE IS PROFILE/RELEASE maxNavBarHeight = MediaQuery.of(context).size.height / 2.5;
    widget.controller.addListener((){
      if(widget.controller.isElevated != isElevated) _reverseNav();
      setState(() {
      });
    });
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
    switch (BlocProvider.of<PostsBloc>(context).state.contentSource) {
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
            BlocProvider.of<PostsBloc>(context).add(ParamsChanged());
            tempType = "";
          }
          _changeTypeVisibility();
          _changeParamsVisibility();
        },
      );
    });
  }

  List<Widget> sortTypeParamsUser(){
    return new List<Widget>.generate(sortTypesuser.length, (int index) {
      return InkWell(
        child: Text(sortTypesuser[index]),
        onTap: () {
          setState(() {
            var q = sortTypesuser[index];
            if (q == "hot" || q == "new" || q == "rising") {
              parseTypeFilter(q);
              currentSortTime = "";

              BlocProvider.of<PostsBloc>(context).add(ParamsChanged());
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

              BlocProvider.of<PostsBloc>(context).add(ParamsChanged());
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
    widget.controller.isElevated = false;
  }

  Widget _buildSubsList(AsyncSnapshot<SubredditM> snapshot) {
    var subs = snapshot.data.results;
    return ListView.builder(
      itemCount: subs.length+1,
      itemBuilder: (context, i) {
        return InkWell( //Subreddit entry
          onTap: (){
            _openSub(subs[i].displayName);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(
                  bottom: 0.0,
                  left: 5.0,
                  top: 0.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(subs[i].displayName)
                    ),
                    PopupMenuButton<String>(
                      elevation: 3.2,
                      onSelected: (s) {
                        },
                      itemBuilder: (context) {
                        return subListOptions.map((s) {
                          return PopupMenuItem<String>(
                            value: s,
                            child: Column(
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    s == subListOptions[0]
                                      ? Icon(Icons.remove_circle)
                                      : Icon(Icons.add_circle),
                                    VerticalDivider(),
                                    Text(s),
                                    
                                  ]
                                ,),
                                s != subListOptions[subListOptions.length-1] ? Divider() : null
                              ].where((w) => notNull(w)).toList(),
                            ),
                          );
                        }).toList();
                      },
                    )
                  ],
                ),
              ),
              i != subs.length-1 ? Divider(indent: 10.0, endIndent: 10.0, height: 0.0,) : null
            ].where((w) => notNull(w)).toList(),
          )
        );
      },
    );
  }
  _openSub(String s) {
    currentSubreddit = s;
    _reverseNav();
    subsListHeight = 50.0;
    _refreshList();
  }

  void _refreshList(){
    BlocProvider.of<PostsBloc>(context).add(PostsSourceChanged(source: ContentSource.Subreddit));
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
                                      new Opacity(
                                          opacity: navBarLerp(0, 1.0),
                                          child: new Container(
                                            decoration: BoxDecoration(),
                                            padding: EdgeInsets.only(
                                              left: 15.0,
                                              right: 15.0,
                                            ),
                                            child: new TextField(
                                              enabled: widget.controller.isElevated,
                                              onChanged: (String s) {
                                                widget.controller.searchQuery = s;
                                                sub_bloc.fetchSubs(s);
                                              },
                                              onEditingComplete: () {
                                                currentSubreddit = widget.controller.searchQuery;
                                                _reverseNav();
                                                _refreshList();
                                                subsListHeight = 50.0;
                                              },
                                            ),
                                          )),
                                      new IgnorePointer(
                                        ignoring: widget.controller.isElevated,
                                        child: new Opacity(
                                          opacity: 1.0 - navBarLerp(0.0, 1.0),
                                          child: Container(
                                            padding: EdgeInsets.all(5.0),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: <Widget>[
                                                Expanded(
                                                  child: InkWell(
                                                    child: StreamBuilder(
                                                      stream: BlocProvider.of<PostsBloc>(context),
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
                                                (BlocProvider.of<PostsBloc>(context).state != null && BlocProvider.of<PostsBloc>(context).state.contentSource == ContentSource.Subreddit)
                                                  ? IconButton(
                                                    icon: Icon(Icons.create),
                                                    onPressed: () {
                                                      final snackBar = SnackBar(
                                                        content: Text(
                                                            'Log in to post your submission'),
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
                                              ].where((w) => notNull(w)).toList(),
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
                                      return _buildSubsList(snapshot);
                                    } else if (snapshot.hasError) {
                                      return Text(snapshot.error.toString(), style: LyreTextStyles.errorMessage,);
                                    } else {
                                      return ListView.builder(
                                        itemCount: subreddits.length,
                                        itemBuilder: (context, i) {
                                          return InkWell(
                                            onTap: (){
                                              _openSub(subreddits[i]);
                                            },
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Container(
                                                  padding: EdgeInsets.only(
                                                    bottom: 0.0,
                                                    left: 5.0,
                                                    top: 0.0),
                                                  child: Row(
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: Text(subreddits[i])
                                                      ),
                                                      PopupMenuButton<String>(
                                                        elevation: 3.2,
                                                        onSelected: (s) {
                                                          },
                                                        itemBuilder: (context) {
                                                          return subListOptions.map((s) {
                                                            return PopupMenuItem<String>(
                                                              value: s,
                                                              child: Column(
                                                                children: <Widget>[
                                                                  Row(
                                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                                    children: <Widget>[
                                                                      s == subListOptions[0]
                                                                        ? Icon(Icons.remove_circle)
                                                                        : Icon(Icons.add_circle),
                                                                      VerticalDivider(),
                                                                      Text(s),
                                                                      
                                                                    ]
                                                                  ,),
                                                                  s != subListOptions[subListOptions.length-1] ? Divider() : null
                                                                ].where((w) => notNull(w)).toList(),
                                                              ),
                                                            );
                                                          }).toList();
                                                        },
                                                      )
                                                    ],
                                                  ),
                                                ),
                                                i != subreddits.length-1 ? Divider(indent: 10.0, endIndent: 10.0, height: 0.0,) : null
                                              ].where((w) => notNull(w)).toList(),
                                            )
                                          );
                                        },
                                      );
                                    }
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
  
  List<String> subListOptions = [
    "Remove",
    "Subscribe"
  ];

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
            bloc.add(PostsSourceChanged(
              source: ContentSource.Self,
              target: SelfContentType.Comments
            ));
            break;
          case "Submitted":
            bloc.add(PostsSourceChanged(
              source: ContentSource.Self,
              target: SelfContentType.Submitted
            ));
            break;
          case "Upvoted":
            bloc.add(PostsSourceChanged(
              source: ContentSource.Self,
              target: SelfContentType.Upvoted
            ));
            break;
          case "Saved":
            bloc.add(PostsSourceChanged(
              source: ContentSource.Self,
              target: SelfContentType.Saved
            ));
            break;
          case "Hidden":
            bloc.add(PostsSourceChanged(
              source: ContentSource.Self,
              target: SelfContentType.Hidden
            ));
            break;
          case "Watching":
            bloc.add(PostsSourceChanged(
              source: ContentSource.Self,
              target: SelfContentType.Watching
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
