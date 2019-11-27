import 'package:auto_size_text/auto_size_text.dart';
import 'package:draw/draw.dart' as prefix0;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import 'package:lyre/Blocs/bloc/bloc.dart';
import 'package:lyre/Resources/PreferenceValues.dart';
import 'package:lyre/Resources/RedditHandler.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/Themes/textstyles.dart';
import 'package:lyre/UI/Comments/comment.dart';
import 'package:lyre/UI/CustomExpansionTile.dart';
import 'package:lyre/UI/bottom_appbar.dart';
import 'package:lyre/utils/HtmlUtils.dart';
import 'package:lyre/utils/share_utils.dart';
import 'package:lyre/utils/urlUtils.dart';
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
import '../Resources/reddit_api_provider.dart';

class PostsList extends StatefulWidget {
  PostsList({Key key}) : super(key: key);

  State<PostsList> createState() => new PostsListState();
}

enum _ParamsVisibility {
  Type,
  Time,
  None,
  Reply,
}
enum _SubmissionSelectionVisibility {
  Default,
  Copy,
  Share
}

class PostsListState extends State<PostsList> with TickerProviderStateMixin{

  static const _titletext = "Lyre for Reddit";
  //Needed for weird bug when switching between usercontentoptionspages. (Shows inkwell animation in next page if instantly switched)
  static const _userContentOptionsTransitionDelay = Duration(milliseconds: 200);

  PostsListState();

  bool autoLoad;
  PostsBloc bloc;

  ScrollController scontrol = new ScrollController();
  ValueNotifier<bool> appBarVisibleNotifier;

  PersistentBottomSheetController _submissionOptionsController;
  _SubmissionSelectionVisibility _submissionSelectionVisibility;

  TextEditingController _replyController;
  ReplySendingState _replySendingState = ReplySendingState.Inactive;
  String _replyErrorMessage;

  prefix0.UserContent __selectedUserContent;
  prefix0.Submission get _selectedSubmission => __selectedUserContent as prefix0.Submission;
  prefix0.Comment get _selectedComment => __selectedUserContent as prefix0.Comment;

  Widget _replyTrailingAction() {
    if (_replySendingState == ReplySendingState.Inactive) { //Submit icon
      return Icon(Icons.send);
    } else if (_replySendingState == ReplySendingState.Sending) { // Loading indicator
      return CircularProgressIndicator();
    }
    //Error widget:
    return Icon(Icons.close);
  }


  @override
  void dispose() {
    scontrol.dispose();
    bloc.drain();
    appBarVisibleNotifier.dispose();
    _replyController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
     appBarVisibleNotifier = ValueNotifier(true);
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
                        final newUser = await pp.getLatestUser();
                        BlocProvider.of<LyreBloc>(context).add(UserChanged(userName: newUser.username));
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
    if (_paramsVisibility != _ParamsVisibility.None) {
      setState(() {
        _paramsVisibility = _paramsVisibility == _ParamsVisibility.Time ? _ParamsVisibility.Type : _ParamsVisibility.None;
      });
      return Future.value(false);
    }
    return new Future.value(true);
  }

  Widget _buildList(PostsState state, BuildContext context) {
    var posts = state.userContent;
    return new NotificationListener(
      onNotification: (Notification notification) {
        if (notification is ScrollNotification) {
          if ((autoLoad ?? false) && (notification.metrics.maxScrollExtent - notification.metrics.pixels) < MediaQuery.of(context).size.height * 1.5){
          bloc.add(FetchMore());
          }
          if (notification.depth == 0 && notification is ScrollUpdateNotification) {
            if (notification.scrollDelta >= 10.0 && _paramsVisibility != _ParamsVisibility.Reply) {
              appBarVisibleNotifier.value = false;
            } else if (notification.scrollDelta <= -10.0){
              appBarVisibleNotifier.value = true;
              //navBarController.setVisibility(true);
            }
          }
        } else if (notification is SubmissionOptionsNotification) {
          setState(() {
            __selectedUserContent = notification.submission;
            _submissionSelectionVisibility = _SubmissionSelectionVisibility.Default;
            _submissionOptionsController = Scaffold.of(context).showBottomSheet(
              (context) => _submissionOptionsSheet(context)
            );
          });
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
                  maxLines: 1,
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
                if (i == posts.length) {
                  return Container(
                    color: Theme.of(context).primaryColor,
                    child: FlatButton(
                      onPressed: () {
                        setState(() {
                          bloc.add(FetchMore());
                        });
                      },
                      child: bloc.loading.value == LoadingState.loadingMore ? const CircularProgressIndicator() : const Text("Load More")),
                  );
                } else {
                  return posts[i] is prefix0.Submission
                    ? postInnerWidget(posts[i] as prefix0.Submission, PreviewSource.PostsList)
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

  void _quickReply(BuildContext context) {
    // If the reply message is empty, show a short warning snackbar
    if (_replyController?.text.isEmpty) {
      final emptyTextSnackBar = SnackBar(
        content: Text("Cannot Send an Empty Reply"),
        duration: Duration(seconds: 1),
      );
      Scaffold.of(context).showSnackBar(emptyTextSnackBar);
      return;
    }

    setState(() {
      _replySendingState = ReplySendingState.Sending;
    });

    reply(__selectedUserContent, _replyController.text).then((returnValue) {
      // Show error message if return value is a string (an error), or dismiss QuickReply window.
      if (returnValue is String) {
        // Error
        setState(() {
          _replySendingState = ReplySendingState.Error;
          _replyErrorMessage = returnValue;
        });
      } else {
        // Success
        _handleSuccessfulReply(context, returnValue);
      }
    });
  }
  _handleSuccessfulReply(BuildContext context, prefix0.Comment comment) {
    final successSnackBar = SnackBar(
      content: Text('Reply Sent'),
      action: SnackBarAction(
        label: 'Open',
        onPressed: () {
          Navigator.of(context).pushNamed('comments', arguments: comment);
        },
      ),
    );
    setState(() {
      _paramsVisibility = _ParamsVisibility.None;
      _replySendingState = ReplySendingState.Inactive;
    });
    Scaffold.of(context).showSnackBar(successSnackBar);
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
                child: Material(
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
                  )
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
                    helperStyle: TextStyle(fontStyle: FontStyle.italic)
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
          listener: appBarVisibleNotifier,
          body: StreamBuilder(
            stream: bloc,
            builder: (BuildContext context, AsyncSnapshot<PostsState> snapshot){
              if (snapshot.hasData) {
                final state = snapshot.data;
                if(state.userContent != null && state.userContent.isNotEmpty){
                  autoLoad = state.preferences?.get(SUBMISSION_AUTO_LOAD);
                  if(state.contentSource == ContentSource.Redditor){
                    return state.target.isNotEmpty
                      ? _buildList(state, context)
                      : Center(child: CircularProgressIndicator());
                  } else {
                    return _buildList(state, context);
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
              return Container(
                width: MediaQuery.of(context).size.width,
                height: 56.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    // * Reply container
                    AnimatedContainer(
                      height: _paramsVisibility == _ParamsVisibility.Reply ? 56.0 : 0.0,
                      duration: Duration(milliseconds: 250),
                      curve: Curves.ease,
                      child: Material(
                        child:  Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Visibility(
                                  visible: _paramsVisibility == _ParamsVisibility.Reply,
                                  child: _replySendingState == ReplySendingState.Error
                                    ? Text(_replyErrorMessage ?? "Error Sending Reply")
                                    : Visibility(
                                      visible: _replySendingState != ReplySendingState.Error,
                                        child: TextField(
                                          enabled: _paramsVisibility == _ParamsVisibility.Reply && _replySendingState == ReplySendingState.Inactive,
                                          autofocus: true,
                                          controller: _replyController,
                                          decoration: InputDecoration.collapsed(hintText: 'Reply'),
                                      )
                                    )
                                ),
                              ),
                              IconButton(
                                icon: _replySendingState == ReplySendingState.Error
                                  ? Icon(Icons.refresh)
                                  : Icon(Icons.fullscreen),
                                onPressed: () {
                                  if (_replySendingState == ReplySendingState.Error) {
                                    setState(() {
                                      _replySendingState = ReplySendingState.Inactive;
                                    });
                                  } else if (_replySendingState == ReplySendingState.Inactive) {
                                    // Expand quickreply to a full Reply window
                                    Navigator.pushNamed(context, 'reply', arguments: {
                                      'content'        : __selectedUserContent,
                                      'reply_text'  : _replyController?.text
                                    }).then((returnValue) {
                                      if (returnValue is prefix0.Comment) {
                                        setState(() {
                                          //Successful return
                                          _handleSuccessfulReply(context, returnValue);
                                        });
                                      } else {
                                        setState(() {
                                          _replySendingState = ReplySendingState.Inactive;
                                          _paramsVisibility = _ParamsVisibility.None;
                                        });
                                      }
                                    }); 
                                  }
                                },
                              ),
                              IconButton(
                                icon: _replyTrailingAction(),
                                onPressed: () {
                                  if (_replySendingState == ReplySendingState.Inactive) {
                                    _quickReply(context);
                                  } else if (_replySendingState == ReplySendingState.Error) {
                                    setState(() {
                                      _paramsVisibility = _ParamsVisibility.None;
                                      _replySendingState = ReplySendingState.Inactive;
                                    });
                                  }
                                },
                              )
                            ]
                          )
                        ),
                      ),
                    ),
                    // * Default appBar contents
                    AnimatedContainer(
                      height: _paramsVisibility == _ParamsVisibility.None ? 56.0 : 0.0,
                      duration: Duration(milliseconds: 250),
                      curve: Curves.ease,
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
                                    _paramsVisibility = _ParamsVisibility.Type; 
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
                    ),
                  // * Type Params
                  AnimatedContainer(
                    height: _paramsVisibility == _ParamsVisibility.Type ? 56.0 : 0.0,
                    duration: Duration(milliseconds: 250),
                    curve: Curves.ease,
                    child: Material(
                      child: Row(children: _sortTypeParams(),),
                    ),
                  ),
                  // * Time Params
                  AnimatedContainer(
                    height: _paramsVisibility == _ParamsVisibility.Time ? 56.0 : 0.0,
                    duration: Duration(milliseconds: 250),
                    curve: Curves.ease,
                    child: Material(
                      child: Row(children: _sortTimeParams(),),
                    ),
                  ),
                ],)
              );
            },
          ),
          expandingSheetContent: _subredditsList(),
        )
      ),
      onWillPop: _willPop);
  }

  List<Widget> _sortTimeParams() {
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
             _paramsVisibility = _ParamsVisibility.Type; 
            });
          },
          onTap: () {
            if (_tempType != "") {
              parseTypeFilter(_tempType);
              currentSortTime = sortTimes[index];
              BlocProvider.of<PostsBloc>(context).add(ParamsChanged());
              _tempType = "";
            }
            _changeTypeVisibility();
            _change_ParamsVisibility();
          },
        )
      );
    });
  }
  
  List<Widget> _sortTypeParams() {
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
             _paramsVisibility = _ParamsVisibility.None; 
            });
          },
          onTap: () {
            setState(() {
              var q = sortTypes[index];
              if (q == "hot" || q == "new" || q == "rising") {
                parseTypeFilter(q);
                currentSortTime = "";
                  BlocProvider.of<PostsBloc>(context).add(ParamsChanged());
                  _change_ParamsVisibility();
              } else {
                _tempType = q;
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

  List<Widget> _sortTypeParamsUser(){
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

              _change_ParamsVisibility();
            } else {
              _tempType = q;
              _changeTypeVisibility();
            }
          });
        },
      );
    });
  }
  _change_ParamsVisibility() {
    //Resets the bloc:s _tempType filter in case of continuity errors.
    _tempType = "";
    setState(() {
      if (_paramsVisibility == _ParamsVisibility.None) {
        _paramsVisibility = _ParamsVisibility.Type;
      } else {
        _paramsVisibility = _ParamsVisibility.None;
      }
    });
  }
  _changeTypeVisibility() {
    if (_paramsVisibility == _ParamsVisibility.Type) {
      _paramsVisibility = _ParamsVisibility.Time;
    } else {
      _paramsVisibility = _ParamsVisibility.Type;
    }
  }

  Widget _submissionOptionsSheet(BuildContext context) {
    switch (_submissionSelectionVisibility) {
      case _SubmissionSelectionVisibility.Copy:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _selectedSubmission.preview.isNotEmpty && notNull(_selectedSubmission.preview.last)
              ? InkWell(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    alignment: Alignment.centerLeft,
                    height: 50.0,
                    child: Text('Post Preview'),
                  ),
                  onTap: () {
                    //Copy to Clipboard, and show a snackbar response message
                    copyToClipboard(_selectedSubmission.preview.last.source.url.toString()).then((success) {
                      final snackBar = SnackBar(
                        content: Text(success ? "Copied Image to Clipboard" : clipBoardErrorMessage),
                        duration: Duration(seconds: 1),
                      );
                      Scaffold.of(context).showSnackBar(snackBar);
                      //Close the Sheet
                      Navigator.of(context).pop();
                    });
                  },
                )
              : null,
            InkWell(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                alignment: Alignment.centerLeft,
                height: 50.0,
                child: Text('Link'),
              ),
              onTap: () {
                //Copy to Clipboard, and show a snackbar response message
                copyToClipboard(_selectedSubmission.shortlink.toString()).then((success) {
                  final snackBar = SnackBar(
                    content: Text(success ? "Copied Link to Clipboard" : clipBoardErrorMessage),
                    duration: Duration(seconds: 1),
                  );
                  Scaffold.of(context).showSnackBar(snackBar);
                  //Close the Sheet
                  Navigator.of(context).pop();
                });
              },
            ),
            InkWell(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                alignment: Alignment.centerLeft,
                height: 50.0,
                child: Text('Comments'),
              ),
              onTap: () {
                //Copy to Clipboard, and show a snackbar response message
                copyToClipboard(_selectedSubmission.shortlink.toString()).then((success) {
                  final snackBar = SnackBar(
                    content: Text(success ? "Copied Comments Link to Clipboard" : clipBoardErrorMessage),
                    duration: Duration(seconds: 1),
                  );
                  Scaffold.of(context).showSnackBar(snackBar);
                  //Close the Sheet
                  Navigator.of(context).pop();
                });
              },
            ),
            _optionsBackButton
          ].where((w) => notNull(w)).toList(),
        );
      case _SubmissionSelectionVisibility.Share:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            //Only show preview sharing if a preview exists
            _selectedSubmission.preview.isNotEmpty && notNull(_selectedSubmission.preview.last)
              ? InkWell(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    alignment: Alignment.centerLeft,
                    height: 50.0,
                    child: Text('Post Preview'),
                  ),
                  onTap: () {
                    //Share the image and pop the sheet
                    Navigator.of(context).pop();
                    shareString(_selectedSubmission.preview.last.source.url.toString());
                  },
                )
              : null,
            InkWell(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                alignment: Alignment.centerLeft,
                height: 50.0,
                child: Text('Link'),
              ),
              onTap: () {
                //Share the link and pop the sheet
                Navigator.of(context).pop();
                shareString(_selectedSubmission.url.toString());
              },
            ),
            InkWell(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                alignment: Alignment.centerLeft,
                height: 50.0,
                child: Text('Comments'),
              ),
              onTap: () {
                //Share the link and pop the sheet
                Navigator.of(context).pop();
                shareString(_selectedSubmission.shortlink.toString());
              },
            ),
            _optionsBackButton
          ].where((w) => notNull(w)).toList(),
        );
      default:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            !_selectedSubmission.archived
              ? InkWell(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    alignment: Alignment.centerLeft,
                    height: 50.0,
                    child: Text('Reply'),
                  ),
                  onTap: () {
                    setState(() {
                      _replyController = TextEditingController();
                      _paramsVisibility = _ParamsVisibility.Reply;
                    });
                    Navigator.of(context).pop();
                  },
                )
              : null,
            InkWell(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                alignment: Alignment.centerLeft,
                height: 50.0,
                child: Text('Share'),
              ),
              onTap: () {
                _switchSelectionOptions(_SubmissionSelectionVisibility.Share);
              },
            ),
            currentSubreddit.toLowerCase() != _selectedSubmission.subreddit.displayName.toLowerCase()
              ? InkWell(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    alignment: Alignment.centerLeft,
                    height: 50.0,
                    child: Text('r/${_selectedSubmission.subreddit.displayName}'),
                  ),
              )
              : null,
            InkWell(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                alignment: Alignment.centerLeft,
                height: 50.0,
                child: Text('Launch In Browser'),
              ),
              onTap: () {
                launchURL(context, _selectedSubmission);
              },
            ),
            InkWell(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                alignment: Alignment.centerLeft,
                height: 50.0,
                child: Text('Report'),
              ),
            ),
            InkWell(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                alignment: Alignment.centerLeft,
                height: 50.0,
                child: Text('Copy'),
              ),
              onTap: () {
                _switchSelectionOptions(_SubmissionSelectionVisibility.Copy);
              },
            ),
            InkWell(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                alignment: Alignment.centerLeft,
                height: 50.0,
                child: Text('Filter'),
              ),
            )
          ].where((w) => notNull(w)).toList()
        );
    }
  }
  Widget get _optionsBackButton => InkWell(
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0),
      alignment: Alignment.centerLeft,
      height: 50.0,
      child: Row(children: <Widget>[
        Icon(Icons.arrow_back),
        Padding(
          padding: EdgeInsets.only(left: 10.0),
          child: Text('Back')
        )
      ],),
    ),
    onTap: () {
      _switchSelectionOptions(_SubmissionSelectionVisibility.Default);
    },
  );

  _switchSelectionOptions(_SubmissionSelectionVisibility _visibility) {
    Future.delayed(_userContentOptionsTransitionDelay).then((_){
      _submissionOptionsController.setState(() {
        _submissionSelectionVisibility = _visibility;
      });
    });
  }

}
String _tempType = "";
_ParamsVisibility _paramsVisibility = _ParamsVisibility.None;

class _subredditsList extends State<ExpandingSheetContent> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Container(
      child: CustomScrollView(
        controller: widget.innerController,
        physics: _paramsVisibility == _ParamsVisibility.None ? AlwaysScrollableScrollPhysics() : NeverScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: widget.appBarContent,
          ),
          SliverSafeArea(
            top: true,
            sliver: SliverAppBar(
              backgroundColor: Theme.of(context).canvasColor,
              automaticallyImplyLeading: false,
              floating: true,
              pinned: true,
              actions: <Widget>[Container()],
              title: new TextField(
                enabled: widget.innerController.extent.isAtMax,
                onChanged: (String s) {
                  searchQuery = s;
                  sub_bloc.fetchSubs(s);
                },
                decoration: InputDecoration(hintText: 'Search'),
                onEditingComplete: () {
                  currentSubreddit = searchQuery;
                  widget.innerController.voia();
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
      )
    );
  }

  _openSub(String s) {
    currentSubreddit = s;
    widget.innerController.voia();
    BlocProvider.of<PostsBloc>(context).add(PostsSourceChanged(source: ContentSource.Subreddit));
  }

  // List of options for subRedditView
  List<String> _subListOptions = [
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
                        return _subListOptions.map((s) {
                          return PopupMenuItem<String>(
                            value: s,
                            child: Column(
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    s == _subListOptions[0]
                                      ? Icon(Icons.remove_circle)
                                      : Icon(Icons.add_circle),
                                    VerticalDivider(),
                                    Text(s),
                                    
                                  ]
                                ,),
                                s != _subListOptions[_subListOptions.length-1] ? Divider() : null
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
                        return _subListOptions.map((s) {
                          return PopupMenuItem<String>(
                            value: s,
                            child: Column(
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    s == _subListOptions[0]
                                      ? Icon(Icons.remove_circle)
                                      : Icon(Icons.add_circle),
                                    VerticalDivider(),
                                    Text(s),
                                    
                                  ]
                                ,),
                                s != _subListOptions[_subListOptions.length-1] ? Divider() : null
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
      itemCount: subs.length+1,
      itemBuilder: (context, i) {
        
      },
    );
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
        child: Text(contentType, style: TextStyle(
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
