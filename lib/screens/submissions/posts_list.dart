import 'package:auto_size_text/auto_size_text.dart';
import 'package:draw/draw.dart' as draw;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import 'package:lyre/UI/submissions/bloc/bloc.dart';
import 'package:lyre/Resources/PreferenceValues.dart';
import 'package:lyre/Resources/RedditHandler.dart';
import 'package:lyre/Resources/filter_manager.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/Themes/textstyles.dart';
import 'package:lyre/widgets/comment.dart';
import 'package:lyre/widgets/CustomExpansionTile.dart';
import 'package:lyre/widgets/bottom_appbar.dart';
import 'package:lyre/utils/share_utils.dart';
import 'package:lyre/utils/urlUtils.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:transparent_image/transparent_image.dart';
import 'dart:ui';
import '../../Models/Subreddit.dart';
import '../../Blocs/subreddits_bloc.dart';
import '../../Resources/globals.dart';
import 'dart:async';
import 'package:flutter_advanced_networkimage/provider.dart';
import '../../widgets/postInnerWidget.dart';
import '../interfaces/previewCallback.dart';
import '../../Resources/reddit_api_provider.dart';

class PostsList extends StatefulWidget {
  PostsList({Key key}) : super(key: key);

  State<PostsList> createState() => new PostsListState();
}

enum _ParamsVisibility {
  Type,
  Time,
  None,
  QuickText,
}
enum _SubmissionSelectionVisibility {
  Default,
  Copy,
  Share,
  Filter
}
enum _OptionsVisibility {
  Default,
  Search,
}
enum _QuickText {
  Reply,
  Report,
  QuickAction
}

class PostsListState extends State<PostsList> with TickerProviderStateMixin{
  //Needed for weird bug when switching between usercontentoptionspages. (Shows inkwell animation in next page if instantly switched)
  static const _userContentOptionsTransitionDelay = Duration(milliseconds: 200);

  PostsListState();

  bool autoLoad;
  PostsBloc bloc;

  ScrollController scontrol = new ScrollController();
  ValueNotifier<bool> _appBarVisibleNotifier;

  _OptionsVisibility _optionsVisibility;
  PersistentBottomSheetController _optionsController;

  PersistentBottomSheetController _submissionOptionsController;
  _SubmissionSelectionVisibility _submissionSelectionVisibility;

  TextEditingController _quickTextController;
  _QuickText _quickTextSelection;
  SendingState _replySendingState = SendingState.Inactive;
  String _replyErrorMessage;

  draw.UserContent _selectedUserContent;
  draw.Submission get _selectedSubmission => _selectedUserContent as draw.Submission;
  draw.Comment get _selectedComment => _selectedUserContent as draw.Comment;

  Widget _replyTrailingAction() {
    if (_replySendingState == SendingState.Inactive) { //Submit icon
      return Icon(Icons.send);
    } else if (_replySendingState == SendingState.Sending) { // Loading indicator
      return CircularProgressIndicator();
    }
    //Error widget:
    return Icon(Icons.close);
  }


  @override
  void dispose() {
    scontrol.dispose();
    bloc.drain();
    _appBarVisibleNotifier.dispose();
    _quickTextController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
     _appBarVisibleNotifier = ValueNotifier(true);
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
    child: const Text('Add an Account'),
      color: Theme.of(context).primaryColor,
      onPressed: () async {
        var pp = PostsProvider();
        final authUrl = await pp.redditAuthUrl();
        PostsProvider().auth(authUrl.values.first).then((loggedInUserName) async {
          BlocProvider.of<LyreBloc>(context).add(UserChanged(userName: loggedInUserName));
          bloc.add(PostsSourceChanged(source: ContentSource.Subreddit, target: currentSubreddit));
        });
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
                      IconButton(icon: Icon(Icons.close),onPressed: () async {
                        await pp.closeAuthServer();
                        Navigator.pop(context);
                      },)
                    ],
                  ),
                ),
                Expanded(
                  child: InAppWebView(
                    onLoadStop: (controller, s) async {
                      if (s.contains('localhost:8080')) {
                        //Exit on successful authorization;
                        Navigator.pop(context);
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
  bool _subscribed = false;

  Widget _buildList(PostsState state, BuildContext context) {
    var posts = state.userContent;
    return new NotificationListener(
      onNotification: (Notification notification) {
        if (notification is ScrollNotification) {
          if ((autoLoad ?? false) && (notification.metrics.maxScrollExtent - notification.metrics.pixels) < MediaQuery.of(context).size.height * 1.5){
          bloc.add(FetchMore());
          }
          if (notification.depth == 0 && notification is ScrollUpdateNotification) {
            if (notification.scrollDelta >= 10.0 && _paramsVisibility != _ParamsVisibility.QuickText) {
              _appBarVisibleNotifier.value = false;
            } else if (notification.scrollDelta <= -10.0){
              _appBarVisibleNotifier.value = true;
              //navBarController.setVisibility(true);
            }
          }
        } else if (notification is SubmissionOptionsNotification) {
          setState(() {
            _selectedUserContent = notification.submission;
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
              actions: <Widget>[
                StatefulBuilder(
                  builder: (BuildContext context, setState) {
                    return Container(
                      color: Colors.black54,
                      margin: EdgeInsets.all(10.0),
                      child: ToggleButtons(
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text(
                              _subscribed ? "Unsubscribe" : "Subscribe",
                            )
                          )
                        ],
                        disabledColor: Colors.white70,
                        isSelected: [_subscribed],
                        onPressed: (i){
                          setState(() {
                            _subscribed = !_subscribed;
                          });
                        },
                      ),
                    );
                  },
                ),
              ],
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: EdgeInsets.only(
                  left: 10.0,
                  bottom: 5.0
                  ),
                title: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width / 1.5),
                  child: Text(
                    // TODO: Fix this shit (can't add / without causing a new line automatically)
                    state.getSourceString(prefix: false),
                    softWrap: true,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                ),
                collapseMode: CollapseMode.parallax,
                background: state.subreddit != null && state.subreddit.mobileHeaderImage != null
                  ? 
                  FadeInImage(
                    placeholder: MemoryImage(kTransparentImage),
                    image: AdvancedNetworkImage(
                      state.subreddit.mobileHeaderImage.toString(),
                      useDiskCache: true,
                      cacheRule: const CacheRule(maxAge: Duration(days: 3)),
                    ),
                    fit: BoxFit.cover
                  )
                  // Container()
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
                  return posts[i] is draw.Submission
                    ? postInnerWidget(posts[i] as draw.Submission, PreviewSource.PostsList)
                    : new CommentContent(posts[i] as draw.Comment, PreviewSource.PostsList);
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
    if (_quickTextController?.text.isEmpty) {
      final emptyTextSnackBar = const SnackBar(
        content: Text("Cannot Send an Empty Reply"),
        duration: Duration(seconds: 1),
      );
      Scaffold.of(context).showSnackBar(emptyTextSnackBar);
      return;
    }

    setState(() {
      _replySendingState = SendingState.Sending;
    });

    reply(_selectedUserContent, _quickTextController.text).then((returnValue) {
      // Show error message if return value is a string (an error), or dismiss QuickReply window.
      if (returnValue is String) {
        // Error
        setState(() {
          _replySendingState = SendingState.Error;
          _replyErrorMessage = returnValue;
        });
      } else {
        // Success
        _handleSuccessfulReply(context, returnValue);
      }
    });
  }
  _handleSuccessfulReply(BuildContext context, draw.Comment comment) {
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
      _replySendingState = SendingState.Inactive;
    });
    Scaffold.of(context).showSnackBar(successSnackBar);
  }

  Widget _getSpaciousUserColumn(draw.Redditor redditor){
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
          style: const TextStyle(
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

  void _showComments(BuildContext context, draw.Submission inside) {
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
          child: BlocBuilder<PostsBloc, PostsState>(
                builder: (context, state){
                  return CustomScrollView(
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
                      notNull(state.sideBar)
                        ? SliverToBoxAdapter(
                          child: Text("Sidebar Coming Soon")//MarkdownBody(data: state.sideBar.contentMarkdown,)
                        )
                        : null
                    ].where((w) => notNull(w)).toList(),
                  );
                },
              )
          
        ),
        body: PersistentBottomAppbarWrapper(
          fullSizeHeight: MediaQuery.of(context).size.height,
          listener: _appBarVisibleNotifier,
          body: StreamBuilder(
            stream: bloc,
            builder: (BuildContext context, AsyncSnapshot<PostsState> snapshot){
              if (snapshot.hasData) {
                final state = snapshot.data;
                if(state.userContent != null && state.userContent.isNotEmpty && bloc.loading.value != LoadingState.refreshing){
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
                      height: _paramsVisibility == _ParamsVisibility.QuickText ? 56.0 : 0.0,
                      duration: Duration(milliseconds: 250),
                      curve: Curves.ease,
                      child: Material(
                        child:  Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: _buildQuickTextInput(context)
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
                                onLongPress: () {
                                  _optionsVisibility = _OptionsVisibility.Default;
                                  _optionsController = Scaffold.of(context).showBottomSheet(
                                    (context) => _optionsSheet(context)
                                  );
                                },
                                onDoubleTap: () {
                                  currentSubreddit = homeSubreddit;
                                  BlocProvider.of<PostsBloc>(context).add((PostsSourceChanged(source: ContentSource.Subreddit, target: homeSubreddit)));
                                },
                                onTap: () {
                                  setState(() {
                                    _paramsVisibility = _ParamsVisibility.Type; 
                                  });
                                },
                                child: Wrap(
                                  direction: Axis.vertical,
                                  children: <Widget>[
                                    Text(
                                      state.getSourceString(prefix: false),
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

  //Options sheet content
  Widget _optionsSheet(BuildContext context) {
    switch (_optionsVisibility) {
      case _OptionsVisibility.Search:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            InkWell(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                alignment: Alignment.centerLeft,
                height: 50.0,
                child: Text('Submissions'),
              ),
              onTap: () {
                Navigator.of(context).popAndPushNamed("search_usercontent");
              },
            ),
            InkWell(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                alignment: Alignment.centerLeft,
                height: 50.0,
                child: Text('Communities'),
              ),
              onTap: () {
                Navigator.of(context).popAndPushNamed('search_communities');
              },
            ),
            _optionsBackButton
          ],
        );
      default:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            InkWell(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                alignment: Alignment.centerLeft,
                height: 50.0,
                child: Text('Search'),
              ),
              onTap: () {
                _switchOptionsVisibility(_OptionsVisibility.Search);
              },
            ),
            InkWell(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                alignment: Alignment.centerLeft,
                height: 50.0,
                child: Text('Open'),
              ),
              onTap: () {
                // TODO: Implement Open
              },
            ),
          ],
        );
    }
  }

  ///Returns the Submission options sheet.
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
            _submissionOptionsBackButton
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
            _submissionOptionsBackButton
          ].where((w) => notNull(w)).toList(),
        );
      case _SubmissionSelectionVisibility.Filter:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            //Only show domain filtering if post is a link submission
            !_selectedSubmission.isSelf
              ? InkWell(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    alignment: Alignment.centerLeft,
                    height: 50.0,
                    child: Text(_selectedSubmission.url.authority),
                  ),
                  onTap: () {
                    //Filter the domain and pop the sheet
                    Navigator.of(context).pop();
                    FilterManager().filter(_selectedSubmission.url.authority, FilterType.Domain);
                  },
                )
              : null,
            InkWell(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                alignment: Alignment.centerLeft,
                height: 50.0,
                child: Text('u/${_selectedSubmission.author}'),
              ),
              onTap: () {
                //Filter the User and pop the sheet
                Navigator.of(context).pop();
                FilterManager().filter(_selectedSubmission.author, FilterType.Redditor);
              },
            ),
            InkWell(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                alignment: Alignment.centerLeft,
                height: 50.0,
                child: Text('r/${_selectedSubmission.subreddit.displayName}'),
              ),
              onTap: () {
                //Filter the Subreddit and pop the sheet
                Navigator.of(context).pop();
                FilterManager().filter(_selectedSubmission.subreddit.displayName, FilterType.Subreddit);
              },
            ),
            _submissionOptionsBackButton
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
                    _prepareQuickTextInput(_QuickText.Reply);
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
                if (_selectedSubmission.isSelf) {
                  //If Selected submission is a self-post, There is no need for extra options as the link redirects to the comments
                  Navigator.of(context).pop();
                  shareString(_selectedSubmission.url.toString());
                } else {
                  //Show Sharing options (Link, Image, Comments)
                  _switchSelectionOptions(_SubmissionSelectionVisibility.Share);
                }
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
              onTap: () {
                _prepareQuickTextInput(_QuickText.Report);
                Navigator.of(context).pop();
              },
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
              onTap: () {
                _switchSelectionOptions(_SubmissionSelectionVisibility.Filter);
              },
            )
          ].where((w) => notNull(w)).toList()
        );
    }
  }

  ///Builds the Quick Text Input content Row
  Row _buildQuickTextInput(BuildContext context) {
    switch (_quickTextSelection) {
      case _QuickText.Reply:
        return Row(
          children: <Widget>[
            Expanded(
              child: Visibility(
                visible: _paramsVisibility == _ParamsVisibility.QuickText,
                child: _replySendingState == SendingState.Error
                  ? Text(_replyErrorMessage ?? "Error Sending Reply")
                  : Visibility(
                    visible: _replySendingState != SendingState.Error,
                      child: TextField(
                        enabled: _paramsVisibility == _ParamsVisibility.QuickText && _replySendingState == SendingState.Inactive,
                        autofocus: true,
                        controller: _quickTextController,
                        decoration: InputDecoration.collapsed(hintText: 'Reply'),
                    )
                  )
              ),
            ),
            IconButton(
              icon: _replySendingState == SendingState.Error
                ? Icon(Icons.refresh)
                : Icon(Icons.fullscreen),
              onPressed: () {
                if (_replySendingState == SendingState.Error) {
                  setState(() {
                    _replySendingState = SendingState.Inactive;
                  });
                } else if (_replySendingState == SendingState.Inactive) {
                  // Expand quickreply to a full Reply window
                  Navigator.pushNamed(context, 'reply', arguments: {
                    'content'        : _selectedUserContent,
                    'reply_text'  : _quickTextController?.text
                  }).then((returnValue) {
                    if (returnValue is draw.Comment) {
                      setState(() {
                        //Successful return
                        _handleSuccessfulReply(context, returnValue);
                      });
                    } else {
                      setState(() {
                        _replySendingState = SendingState.Inactive;
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
                if (_replySendingState == SendingState.Inactive) {
                  _quickReply(context);
                } else if (_replySendingState == SendingState.Error) {
                  setState(() {
                    _paramsVisibility = _ParamsVisibility.None;
                    _replySendingState = SendingState.Inactive;
                  });
                }
              },
            )
          ]
        );
      case _QuickText.Report:
        return Row(
          children: <Widget>[
            Expanded(
              child: Visibility(
                visible: _paramsVisibility == _ParamsVisibility.QuickText,
                child: TextField(
                  enabled: _paramsVisibility == _ParamsVisibility.QuickText,
                  autofocus: true,
                  controller: _quickTextController,
                  decoration: InputDecoration.collapsed(hintText: 'Report'),
                )
              ),
            ),
            IconButton(
              icon: Icon(Icons.flag),
              onPressed: () async {
                final res = await report(_selectedUserContent, _quickTextController.text);
                final snackBar = SnackBar(content: Text(res is String ? "Error Sending Report: $res" : "Report Sent"),);
                setState(() {
                  _paramsVisibility = _ParamsVisibility.None;
                });
                Scaffold.of(context).showSnackBar(snackBar);
              },
            )
          ],
        );
      default:
        return Row(children: <Widget>[],);
    }    
  }
  ///Returns the back button used in some options (Share, Copy) 
  Widget get _submissionOptionsBackButton => InkWell(
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
  ///Returns the back button used in some options (Share, Copy) 
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
      _switchOptionsVisibility(_OptionsVisibility.Default);
    },
  );

  _switchSelectionOptions(_SubmissionSelectionVisibility _visibility) {
    Future.delayed(_userContentOptionsTransitionDelay).then((_){
      _submissionOptionsController.setState(() {
        _submissionSelectionVisibility = _visibility;
      });
    });
  }

  _switchOptionsVisibility(_OptionsVisibility _visibility) {
    Future.delayed(_userContentOptionsTransitionDelay).then((_){
      _optionsController.setState(() {
        _optionsVisibility = _visibility;
      });
    });
  }

  _prepareQuickTextInput(_QuickText selection) {
    setState(() {
      _appBarVisibleNotifier.value = true;
      _quickTextController = TextEditingController();
      _quickTextSelection = selection;
      _paramsVisibility = _ParamsVisibility.QuickText;
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
                  widget.innerController.reset();
                  BlocProvider.of<PostsBloc>(context).add(PostsSourceChanged(source: ContentSource.Subreddit, target: searchQuery));
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
    widget.innerController.reset();
    BlocProvider.of<PostsBloc>(context).add(PostsSourceChanged(source: ContentSource.Subreddit, target: s));
  }

  /// List of options for subRedditView
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