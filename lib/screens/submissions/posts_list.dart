import 'package:auto_size_text/auto_size_text.dart';
import 'package:draw/draw.dart' as draw;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import 'package:lyre/Bloc/bloc.dart';
import 'package:lyre/Resources/RedditHandler.dart';
import 'package:lyre/Resources/filter_manager.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/Themes/themes.dart';
import 'package:lyre/screens/screens.dart';
import 'package:lyre/screens/subreddits_list.dart';
import 'package:lyre/utils/share_utils.dart';
import 'package:lyre/utils/urlUtils.dart';
import 'package:lyre/utils/utils.dart';
import 'package:lyre/widgets/widgets.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:transparent_image/transparent_image.dart';
import 'dart:ui';
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
  ViewMode
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

  bool _autoLoad;
  PostsBloc bloc;

  ScrollController scontrol = new ScrollController();
  ValueNotifier<bool> _appBarVisibleNotifier;

  _OptionsVisibility _optionsVisibility;
  PersistentBottomSheetController _optionsController;

  PersistentBottomSheetController _submissionOptionsController;
  _SubmissionSelectionVisibility _submissionSelectionVisibility;

  TextEditingController _quickTextController;
  String get _quickText => _quickTextController != null ? _quickTextController.text : "";
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
    bloc.close();
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
    print(currentUserName);
    List<Widget> widgets = [];
    for(int i = 0; i < list.length; i++){
      widgets.add(InkWell(
          child: Container(
            child: Text(
              list[i],
              style : Theme.of(context).textTheme.title.apply(
                fontWeightDelta: ((i == 0 && currentUserName.isEmpty) || (i != 0 && currentUserName == list[i])) ? 0 : -2,
              ),
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
          },
        ));
    }
    widgets.add(_registrationButton);
    return widgets;
  }

  Widget get _registrationButton => OutlineButton(
    textColor: Theme.of(context).textTheme.body1.color,
    child: const Text('Add an Account'),
    onPressed: () async {
      var pp = PostsProvider();
      final authUrl = await pp.redditAuthUrl();
      PostsProvider().auth(authUrl.values.first).then((loggedInUserName) async {
        BlocProvider.of<LyreBloc>(context).add(UserChanged(userName: loggedInUserName));
        //TODO: FIX OPENING NEW SUBREDDIT WHEN SWITCHING ACCOUNT
        bloc.add(PostsSourceChanged(source: ContentSource.Subreddit, target: homeSubreddit));
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
                    Text('Authenticate Lyre', style: Theme.of(context).textTheme.title),
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
      
  Future<bool> _willPop() {
    if (_paramsVisibility != _ParamsVisibility.None) {
      setState(() {
        _paramsVisibility = _paramsVisibility == _ParamsVisibility.Time ? _ParamsVisibility.Type : _ParamsVisibility.None;
      });
      return Future.value(false);
    }
    return new Future.value(true);
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


  @override
  Widget build(BuildContext context) {
    _autoLoad = BlocProvider.of<LyreBloc>(context).state.autoLoadSubmissions;
    bloc = BlocProvider.of<PostsBloc>(context);
    if ((bloc.state.userContent == null || bloc.state.userContent.isEmpty) && bloc.state.state == LoadingState.Inactive) {
      bloc.add(PostsSourceChanged(source: bloc.state.contentSource, target: bloc.state.target));
    }
    return WillPopScope(
      child: BlocListener<LyreBloc, LyreState>(
        condition: (prev, curr) => prev.currentUserName != curr.currentUserName,
        listener: (context, state) {
          BlocProvider.of<PostsBloc>(context).add(PostsSourceChanged(target: homeSubreddit, source: ContentSource.Subreddit));
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          drawer: Drawer(
            child: Stack(
              children: <Widget>[
                BlocBuilder<LyreBloc, LyreState>(
                  builder: (context, LyreState state) {
                    final currentUser = state.readOnly ? "" : state.currentUserName;
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: CustomScrollView(
                        slivers: <Widget>[
                          SliverSafeArea(
                            sliver: SliverToBoxAdapter(
                              child: CustomExpansionTile(
                                title: currentUser.isNotEmpty ? currentUser : "Guest",
                                trailing: state.readOnly
                                  ? Container()
                                  : OutlineButton.icon(
                                      textColor: LyreColors.unsubscribeColor,
                                      highlightedBorderColor: LyreColors.unsubscribeColor.withOpacity(0.6),
                                      icon: const Icon(MdiIcons.logout),
                                      label: const Text("Log Out"),
                                      onPressed: () async {
                                        var deleteSettings = false;
                                        final result = await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text("Log Out"),
                                              content: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text("Delete Settings"),
                                                  StatefulBuilder(
                                                    builder: (BuildContext context, setState) {
                                                      return Checkbox(
                                                        value: deleteSettings,
                                                        onChanged: (newValue) {
                                                          setState(() {
                                                            deleteSettings = newValue;
                                                          });
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                OutlineButton(
                                                  child: const Text("Cancel"),
                                                  onPressed: () {
                                                    Navigator.of(context).pop(false);
                                                  },
                                                ),
                                                OutlineButton(
                                                  child: const Text("Log Out"),
                                                  onPressed: () {
                                                    Navigator.of(context).pop(true);
                                                  },
                                                )
                                              ],
                                            );
                                          }
                                        );
                                        if (result) {
                                          final logOutResult = await PostsProvider().logOut(state.currentUserName, deleteSettings);
                                          final snackBar = SnackBar(content: Text(logOutResult ? "Logged Out" : "Failed To Log Out"));
                                          BlocProvider.of<LyreBloc>(context).add(UserChanged(userName: "")); //Empty for Read-Only
                                          Navigator.of(context).pop();
                                          Scaffold.of(context).showSnackBar(snackBar);
                                        }
                                      },
                                    ),
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
                                  style: Theme.of(context).textTheme.display1,
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
                                  style: Theme.of(context).textTheme.display1,
                                ),
                                const Text(
                                  'Link karma',
                                  style: TextStyle(fontSize: 18.0, color: Colors.grey),
                                ),
                                const Divider(),
                                const _SelfContentTypeWidget("Comments"),
                                const _SelfContentTypeWidget("Submitted"),
                                const _SelfContentTypeWidget("Upvoted"),
                                const _SelfContentTypeWidget("Saved"),
                                const _SelfContentTypeWidget("Hidden"),
                                const _SelfContentTypeWidget("Watching"),
                                const _SelfContentTypeWidget("Friends")
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
                          color: Colors.black12,
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
                    textStyle: Theme.of(context).textTheme.body1,
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
          endDrawer: Drawer(
            child: BlocBuilder<PostsBloc, PostsState>(
              builder: (context, state) => Container(
                color: Theme.of(context).primaryColor,
                child: SidebarView(state: state)
              )
            )
          ),
          body: Builder(
            builder: (context) {
              return PersistentBottomAppbarWrapper(
                fullSizeHeight: MediaQuery.of(context).size.height,
                listener: _appBarVisibleNotifier,
                body: NotificationListener<Notification>(
                  child: _submissionList(),
                  onNotification: (notification) {
                    if (notification is SubmissionOptionsNotification) {
                      _selectedUserContent = notification.submission;
                      _submissionSelectionVisibility = _SubmissionSelectionVisibility.Default;
                      _submissionOptionsController = Scaffold.of(context).showBottomSheet(
                        (context) => Material(
                          textStyle: Theme.of(context).textTheme.body1,
                          color: Theme.of(context).primaryColor,
                          child: _submissionOptionsSheet(context)
                        )
                      );
                    } else if (notification is ScrollNotification) {
                      if ((_autoLoad ?? false) && (notification.metrics.maxScrollExtent - notification.metrics.pixels) < MediaQuery.of(context).size.height * 1.5){
                        BlocProvider.of<PostsBloc>(context).add(FetchMore());
                      }
                      if (notification.depth == 0 && notification is ScrollUpdateNotification) {
                        if (notification.scrollDelta >= 10.0 && _paramsVisibility != _ParamsVisibility.QuickText) {
                          _appBarVisibleNotifier.value = false;
                        } else if (notification.scrollDelta <= -10.0){
                          _appBarVisibleNotifier.value = true;
                        }
                      }
                    }
                    return false;
                  },
                ),
                appBarContent: _postsAppBar,
                expandingSheetContent: SubredditsList(),
              );
            },
          )
        )
      ),
      onWillPop: _willPop);
  }

  Widget get _postsAppBar => Builder(
    builder: (context) => Container(
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 56.0,
        color: Theme.of(context).primaryColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            // * Reply container
            AnimatedContainer(
              height: _paramsVisibility == _ParamsVisibility.QuickText ? kBottomNavigationBarHeight : 0.0,
              duration: appBarContentTransitionDuration,
              curve: Curves.ease,
              child: Material(
                color: Theme.of(context).primaryColor,
                child:  Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: _buildQuickTextInput(context)
                ),
              ),
            ),
            // * Default appBar contents
            AnimatedContainer(
              height: _paramsVisibility == _ParamsVisibility.None ? kBottomNavigationBarHeight : 0.0,
              duration: appBarContentTransitionDuration,
              curve: Curves.ease,
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Expanded(
                    child: Material(
                      color: Theme.of(context).primaryColor,
                      child: InkWell(
                        onLongPress: () {
                          _prepareQuickTextInput(_QuickText.QuickAction);
                        },
                        onDoubleTap: () {
                          if (homeSubreddit == FRONTPAGE_HOME_SUB) {
                            BlocProvider.of<PostsBloc>(context).add((PostsSourceChanged(source: ContentSource.Frontpage)));
                          } else {
                            BlocProvider.of<PostsBloc>(context).add((PostsSourceChanged(source: ContentSource.Subreddit, target: homeSubreddit)));
                          }
                        },
                        onTap: () {
                          if (BlocProvider.of<LyreBloc>(context).state.legacySorting) {
                            // ! Will be deprecated
                            setState(() {
                              _paramsVisibility = _ParamsVisibility.Type; 
                            });
                          } else {
                            Scaffold.of(context).showBottomSheet((builder) => ContentSort(types: sortTypes,));
                          }
                        },
                        child: BlocBuilder<PostsBloc, PostsState>(
                          builder: (context, state) {
                            return Wrap(
                              direction: Axis.vertical,
                              children: <Widget>[
                                BlocBuilder<LyreBloc, LyreState>(
                                  builder: (context, lyreState) {
                                    return Text(
                                      state.contentSource == ContentSource.Self ? lyreState.currentUserName : state.getSourceString(prefix: false),
                                      style: Theme.of(context).textTheme.title
                                    );
                                  },
                                ),
                                Text(
                                  state.getFilterString(),
                                  style: LyreTextStyles.timeParams.apply(
                                    color: Theme.of(context).textTheme.display1.color
                                  ),
                                )
                              ],
                            );
                          },
                        )
                      )
                    )
                  ),
                  Material(
                    color: Theme.of(context).primaryColor,
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          icon: const Icon(Icons.menu),
                          tooltip: "Menu",
                          onPressed: () {
                            _optionsVisibility = _OptionsVisibility.Default;
                            _optionsController = Scaffold.of(context).showBottomSheet(
                              (context) => _optionsSheet(context)
                            );
                          },
                        ),
                        BlocBuilder<PostsBloc, PostsState>(
                          builder: (context, state) {
                            return IconButton(
                              icon: const Icon(Icons.create),
                              tooltip: "Create a Submission",
                              onPressed: () {
                                setState(() {
                                  if (PostsProvider().isLoggedIn()) {
                                    Map<String, dynamic> args = Map();
                                    args['initialTargetSubreddit'] = state.contentSource == ContentSource.Subreddit ? state.target : '';
                                    Navigator.of(context).pushNamed('submit', arguments: args);
                                  } else {
                                    final snackBar = SnackBar(
                                      content: Text(
                                          'Log in to post your submission'),
                                    );
                                    Scaffold.of(context).showSnackBar(snackBar);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ],
                    )
                  )
                ],
              )
            ),
          // * Type Params
          BlocBuilder<PostsBloc, PostsState>(
            builder: (context, state) {
              return AnimatedContainer(
                height: _paramsVisibility == _ParamsVisibility.Type ? kBottomNavigationBarHeight : 0.0,
                duration: appBarContentTransitionDuration,
                curve: Curves.ease,
                child: Material(
                  color: Theme.of(context).primaryColor,
                  child: Row(children: state.contentSource == ContentSource.Self ? _sortTypeParams(sortTypesuser) : _sortTypeParams(sortTypes),),
                ),
              );
            },
          ),
          // * Time Params
          AnimatedContainer(
            height: _paramsVisibility == _ParamsVisibility.Time ? kBottomNavigationBarHeight : 0.0,
            duration: appBarContentTransitionDuration,
            curve: Curves.ease,
            child: Material(
              color: Theme.of(context).primaryColor,
              textStyle: Theme.of(context).textTheme.body1,
              child: Row(children: _sortTimeParams(),)
            ),
          ),
        ],)
      )
    ),
  );

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
                style: Theme.of(context).textTheme.body1,
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
              final sortType = parseTypeFilter(_tempType);
              final sortTime = sortTimes[index];
              BlocProvider.of<PostsBloc>(context).add(ParamsChanged(typeFilter: sortType, timeFilter: sortTime));
              _tempType = "";
            }
            _changeTypeVisibility();
            _change_ParamsVisibility();
          },
        )
      );
    });
  }
  
  List<Widget> _sortTypeParams(List<String> types) {
    return List<Widget>.generate(types.length, (int index) {
      return Expanded(
        child: InkWell(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _getTypeIcon(types[index]),
              AutoSizeText(
                types[index],
                softWrap: false,
                style: Theme.of(context).textTheme.body1,
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
              var q = types[index];
              if (q == "hot" || q == "new" || q == "rising") {
                parseTypeFilter(q);
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
  IconData _postViewIconData(PostView postView) {
    switch (postView) {
      case PostView.Compact:
        return MdiIcons.viewCompact;
      case PostView.ImagePreview:
        return MdiIcons.imageOutline;
      case PostView.IntendedPreview:
        return MdiIcons.imageArea;
      default:
        // Default to NoPreview
        return MdiIcons.imageOff;
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
              final sortType = parseTypeFilter(q);

              BlocProvider.of<PostsBloc>(context).add(ParamsChanged(typeFilter: sortType, timeFilter: ""));

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

  ///Options sheet content
  Widget _optionsSheet(BuildContext context) {
    switch (_optionsVisibility) {
      case _OptionsVisibility.Search:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ActionSheetTitle(title: "Search", actionCallBack: (){
              _switchOptionsVisibility(_OptionsVisibility.Default);
            }),
            ActionSheetInkwell(
              title: Text("Submissions", style: Theme.of(context).textTheme.body1),
              onTap: () => Navigator.of(context).popAndPushNamed("search_usercontent")
            ),
            ActionSheetInkwell(
              title: Text("Communities", style: Theme.of(context).textTheme.body1),
              onTap: () => Navigator.of(context).popAndPushNamed("search_communities")
            ),
          ],
        );
      case _OptionsVisibility.ViewMode:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ActionSheetTitle(title: "View Mode", actionCallBack: (){
              _switchOptionsVisibility(_OptionsVisibility.Default);
            }),
          ]..addAll(List<Widget>.generate(PostView.values.length, (index) =>
            BlocBuilder<PostsBloc, PostsState>(
              builder: (context, state) {
                final equals = state.viewMode == PostView.values[index];
                return ActionSheetInkwell(
                  title: Row(children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 5.0),
                      child: Icon(_postViewIconData(PostView.values[index]), color: equals ? Theme.of(context).textTheme.body1.color : Theme.of(context).iconTheme.color)
                    ),
                    Text(PostViewTitles[index], style: equals ? const TextStyle(fontWeight: FontWeight.bold) : null)
                  ]),
                  // Send a PostView Change event if the selected ViewMode is not currently active
                  onTap: !equals ? () {
                    Navigator.of(context).pop();
                    BlocProvider.of<PostsBloc>(context).add(ViewModeChanged(viewMode: PostView.values[index]));
                  } : null,
                );
              }
            ),
          )),
        );
      default:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ActionSheetTitle(
              customTitle: BlocBuilder<LyreBloc, LyreState>(
                builder: (context, state) => InkWell(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ClipOval(
                          child: Container(
                            width: 25,
                            height: 25,
                            color: Theme.of(context).accentColor,
                            child: state.currentUser != null
                              ? Image(
                                  image: AdvancedNetworkImage(
                                    state.currentUser.data["icon_img"],
                                    cacheRule: const CacheRule(maxAge: Duration(days: 31))
                                  ),
                                )
                              : const Center(child: Text('?', style: TextStyle(fontWeight: FontWeight.bold)))
                          )
                        )
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(state.currentUserName.isEmpty ? "Guest" : state.currentUserName, style: Theme.of(context).textTheme.body1),
                           state.showKarmaInMenuSheet && state.currentUser != null
                            ? Row(
                                children: <Widget>[
                                  const Icon(MdiIcons.yinYang, size: 12.0),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 3.5),
                                    child: Text((state.currentUser.commentKarma + state.currentUser.linkKarma).toString(), style: const TextStyle(fontSize: 12.0))
                                  ),
                                ],)
                            : Container()
                        ]
                      ),
                    ],
                  )
                ),
              )
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                InkWell(
                  child: Padding(
                    padding: const EdgeInsets.all(3.5),
                    child: Row(children: [
                      const Icon(Icons.search),
                      Text("Search", style: Theme.of(context).textTheme.body2),
                    ],),
                  ),
                  onTap: () => _switchOptionsVisibility(_OptionsVisibility.Search),
                ),
                InkWell(
                  child: Padding(
                    padding: const EdgeInsets.all(3.5),
                    child: Row(children: [
                      const Icon(Icons.open_in_new),
                      Text("Open", style: Theme.of(context).textTheme.body2),
                    ],),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _prepareQuickTextInput(_QuickText.QuickAction);
                  },
                ),
                BlocProvider.of<PostsBloc>(context).state.contentSource == ContentSource.Subreddit
                  // Display filters shortcut when in r/all
                  ? BlocProvider.of<PostsBloc>(context).state.target == "all"
                    // Only Display filters button if user has logged in
                    ? !BlocProvider.of<LyreBloc>(context).state.readOnly
                      ? InkWell(
                          child: Padding(
                            padding: const EdgeInsets.all(3.5),
                            child: Row(children: [
                              const Icon(Icons.filter_list),
                              Text("Filters", style: Theme.of(context).textTheme.body2),
                            ],),
                          ),
                          onTap: () => Navigator.of(context).pushNamed("filters_global"))
                      : null
                    : InkWell(
                        child: Padding(
                          padding: const EdgeInsets.all(3.5),
                          child: Row(children: [
                            const Icon(Icons.info),
                            Text("Sidebar", style: Theme.of(context).textTheme.body2),
                          ],),
                        ),
                        onTap: () => Scaffold.of(context).showBottomSheet((context) => DraggableScrollableSheet(
                          builder: (context, scrollController) => SidebarView(scrollController: scrollController, state: BlocProvider.of<PostsBloc>(context).state),
                          initialChildSize: 0.45,
                          minChildSize: 0.45,
                          maxChildSize: 1.0,
                          expand: false,
                        ))
                      )
                  : null,
                  InkWell(
                    child: Padding(
                      padding: const EdgeInsets.all(3.5),
                      child: Row(children: [
                        const Icon(MdiIcons.viewModule),
                        Text("View Mode", style: Theme.of(context).textTheme.body2),
                      ],),
                    ),
                    onTap: () => _switchOptionsVisibility(_OptionsVisibility.ViewMode),
                  ),
                  ].where((w) => notNull(w)).toList(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(children: [
                Expanded(
                  child: Text("Night Mode", style: Theme.of(context).textTheme.body1),
                ),
                Switch(
                  value: BlocProvider.of<LyreBloc>(context).state.currentTheme == defaultLyreThemes.darkTeal,
                  onChanged: (newValue) {
                    BlocProvider.of<LyreBloc>(context).add(ThemeChanged(theme: newValue ? defaultLyreThemes.darkTeal : defaultLyreThemes.lightBlue));
                  },
                )
              ],)
            )
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
            ActionSheetTitle(title: "Copy", actionCallBack: () => _switchSelectionOptions(_SubmissionSelectionVisibility.Default)),
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
          ].where((w) => notNull(w)).toList(),
        );
      case _SubmissionSelectionVisibility.Share:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ActionSheetTitle(title: "Share", actionCallBack: () => _switchSelectionOptions(_SubmissionSelectionVisibility.Default)),
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
          ].where((w) => notNull(w)).toList(),
        );
      case _SubmissionSelectionVisibility.Filter:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ActionSheetTitle(title: "Filter", actionCallBack: () => _switchSelectionOptions(_SubmissionSelectionVisibility.Default)),
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
          ].where((w) => notNull(w)).toList(),
        );
      default:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ActionSheetTitle(
              title: _selectedSubmission.title,
            ),
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
            // * Open a subreddit
            BlocBuilder<PostsBloc, PostsState>(
              builder: (context, state) {
                return ((state.contentSource != ContentSource.Subreddit && state.contentSource != ContentSource.Frontpage) || state.target.toString().toLowerCase() != _selectedSubmission.subreddit.displayName.toLowerCase())
                  ? ActionSheetInkwell(
                    title: Text('r/${_selectedSubmission.subreddit.displayName}'),
                    onTap: () {
                      Navigator.of(context).pop();
                      BlocProvider.of<PostsBloc>(context).add(PostsSourceChanged(source: ContentSource.Subreddit, target: _selectedSubmission.subreddit.displayName));
                    },
                  )
                  : Container();
                },
            ),
            // * Open a profile
            BlocBuilder<PostsBloc, PostsState>(
              builder: (context, state) {
                return (state.contentSource != ContentSource.Redditor || state.target.toString().toLowerCase() != _selectedSubmission.author.toLowerCase())
                  ? ActionSheetInkwell(
                    title: Text('u/${_selectedSubmission.author}'),
                    onTap: () {
                      Navigator.of(context).pop();
                      BlocProvider.of<PostsBloc>(context).add(PostsSourceChanged(source: ContentSource.Redditor, target: _selectedSubmission.author));
                    },
                  )
                  : Container();
                },
            ),
            ActionSheetInkwell(
              title: const Text('Launch In Browser'),
              onTap: () {
                launchURL(context, _selectedSubmission.url.toString());
              },
            ),
            ActionSheetInkwell(
              title: const Text('Report'),
              onTap: () {
                _prepareQuickTextInput(_QuickText.Report);
                Navigator.of(context).pop();
              },
            ),
            ActionSheetInkwell(
              title: const Text('Copy'),
              onTap: () {
                _switchSelectionOptions(_SubmissionSelectionVisibility.Copy);
              },
            ),
            ActionSheetInkwell(
              title: const Text('Filter'),
              onTap: () {
                _switchSelectionOptions(_SubmissionSelectionVisibility.Filter);
              },
            )
          ].where((w) => notNull(w)).toList()
        );
    }
  }

  ///Builds the Quick Text Input content Row
  Widget _buildQuickTextInput(BuildContext context) {
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
                        decoration: const InputDecoration.collapsed(hintText: 'Reply'),
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
        // Quick Action
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return Row(
              children: <Widget>[
                Expanded(
                  child: Visibility(
                    visible: _paramsVisibility == _ParamsVisibility.QuickText,
                    child: TextField(
                      enabled: _paramsVisibility == _ParamsVisibility.QuickText,
                      autofocus: true,
                      controller: _quickTextController,
                      decoration: InputDecoration.collapsed(hintText: 'Quick Action'),
                      onChanged: (s){
                        setState(() {
                        });
                      },
                      onSubmitted: (s) {
                        _paramsVisibility = _ParamsVisibility.None;
                        if (s.length > 2 && (s.startsWith("r ") || s.startsWith("u "))) {
                          // Needed to fix doctype errors
                          final target = s.substring(2).trim();
                          if (s.startsWith("r")) {
                            BlocProvider.of<PostsBloc>(context).add(PostsSourceChanged(source: ContentSource.Subreddit, target: target));
                          } else {
                            BlocProvider.of<PostsBloc>(context).add(PostsSourceChanged(source: ContentSource.Redditor, target: target));
                          }
                        } else {
                          BlocProvider.of<PostsBloc>(context).add(PostsSourceChanged(source: ContentSource.Subreddit, target: s));
                        }
                      },
                    )
                  ),
                ),
                _quickText.length > 2 && (_quickText.startsWith("r ") || _quickText.startsWith("u "))
                  ? InkWell(
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Icon(Icons.send)
                    ),
                    // Long press to open a new page
                    onLongPress: () {
                      final text = _quickText;
                      _paramsVisibility = _ParamsVisibility.None;
                      Navigator.of(context).pushNamed('posts', arguments: {
                        'target'        : text.substring(2),
                        'content_source'  : text.startsWith('r') ? ContentSource.Subreddit : ContentSource.Redditor
                      });
                    },
                    // Tap to open in current page
                    onTap: () {
                      final text = _quickText;
                      _paramsVisibility = _ParamsVisibility.None;
                      if (text.startsWith("r")) {
                        BlocProvider.of<PostsBloc>(context).add(PostsSourceChanged(source: ContentSource.Subreddit, target: text.substring(2)));
                      } else {
                        BlocProvider.of<PostsBloc>(context).add(PostsSourceChanged(source: ContentSource.Redditor, target: text.substring(2)));
                      }
                    },
                  )
                  : Row(children: <Widget>[
                      InkWell(
                        child: const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Icon(Icons.person)
                        ),
                        onTap: () {
                          _paramsVisibility = _ParamsVisibility.None;
                          BlocProvider.of<PostsBloc>(context).add(PostsSourceChanged(source: ContentSource.Redditor, target: _quickText));
                        },
                        onLongPress: () {
                          _paramsVisibility = _ParamsVisibility.None;
                          Navigator.of(context).pushNamed('posts', arguments: {
                            'target'        : _quickText,
                            'content_source'  : ContentSource.Redditor
                          });
                        },
                      ),
                      InkWell(
                        child: const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Icon(MdiIcons.tag)
                        ),
                        onTap: () {
                          _paramsVisibility = _ParamsVisibility.None;
                          BlocProvider.of<PostsBloc>(context).add(PostsSourceChanged(source: ContentSource.Subreddit, target: _quickText));
                        },
                        onLongPress: () {
                          _paramsVisibility = _ParamsVisibility.None;
                          Navigator.of(context).pushNamed('posts', arguments: {
                            'target'        : _quickText,
                            'content_source'  : ContentSource.Subreddit
                          });
                        },
                      ),
                      InkWell(
                        child: const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Icon(Icons.search)
                        ),
                        onTap: () {
                          // TODO: Implement quick search
                        },
                      )
                  ],),
              ].where((w) => notNull(w)).toList(),
            );
          },
        );
    }    
  }
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

class _submissionList extends StatefulWidget {
  const _submissionList({
    Key key,
  }) : super(key: key);

  @override
  __submissionListState createState() => __submissionListState();
}

class __submissionListState extends State<_submissionList> {

  Completer<void> _refreshCompleter;

  @override
  void initState() { 
    super.initState();
    _refreshCompleter = Completer();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: StreamBuilder(
        stream: BlocProvider.of<PostsBloc>(context),
        builder: (BuildContext context, AsyncSnapshot<PostsState> snapshot){
          if (snapshot.hasData) {
            final state = snapshot.data;
            if(state.userContent != null && state.userContent.isNotEmpty){
              return NestedScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                headerSliverBuilder: (context, b) => [
                  LyreHeader(state: state)
                ],
                body: RefreshIndicator(
                  onRefresh: () {
                    BlocProvider.of<PostsBloc>(context).add(RefreshPosts());
                    return _refreshCompleter.future;
                  },
                  child: _buildListWithHeader(state, context)
                )
              );
            } else if (state.state == LoadingState.Error && state.userContent.isEmpty) {
              // Return error message
              return Center(child: Text(state.errorMessage, style: LyreTextStyles.errorMessage,));
            } else {
              // Return loading indicator
              return const Center(child: CircularProgressIndicator());
            }
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      )
    );
  }

  Widget _buildListWithHeader(PostsState state, BuildContext context) {
    final posts = state.userContent;
    if (state.state != LoadingState.Refreshing) {
      _refreshCompleter?.complete();
      _refreshCompleter = Completer();
      return _buildList(context, state, posts);
    }
    return _buildList(context, state, posts);
  }
  Widget _buildList(BuildContext context, PostsState postsState, List<draw.UserContent> posts) {
    return BlocBuilder<LyreBloc, LyreState>(
      builder: (context, state) {
        return ListView.builder(
          padding: const EdgeInsets.only(top: 5.0),
          itemCount: posts.length+1,
          itemBuilder: (context, i) {
            if (i == posts.length) {
              return Card(
                child: InkWell(
                  onTap: () {
                    BlocProvider.of<PostsBloc>(context).add(FetchMore());
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Builder(
                      builder: (context) {
                        if (postsState.state == LoadingState.LoadingMore) {
                          return Center(child: const CircularProgressIndicator());
                        } else if (postsState.state == LoadingState.Error) {
                          return Center(child: const Text(noConnectionErrorMessage, style: LyreTextStyles.errorMessage));
                        }
                        return Center(child: Text("Load More", style: Theme.of(context).textTheme.body1));
                      },
                    )
                  )
              ));
            } else if (posts[i] is draw.Submission) {
              final submission = posts[i] as draw.Submission;
              final linkType = getLinkType(submission.url.toString());
              return postInnerWidget(
                submission: posts[i] as draw.Submission,
                previewSource: PreviewSource.PostsList,
                linkType: linkType,
                fullSizePreviews: state.fullSizePreviews,
                postView: postsState.viewMode,
                showCircle: state.showPreviewCircle,
                blurLevel: state.blurLevel.toDouble(),
                showNsfw: state.showNSFWPreviews,
                showSpoiler: state.showSpoilerPreviews,
                onOptionsClick: () {
                  SubmissionOptionsNotification(submission: submission)..dispatch(context);
                },
              );
            } else {
              return Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed('comments', arguments: posts[i]);
                  },
                  child: CommentContent(posts[i], PreviewSource.PostsList),
                )
              );
            }
          },
        );
      },
    );
  }
}

String _tempType = "";
_ParamsVisibility _paramsVisibility = _ParamsVisibility.None;

class _SelfContentTypeWidget extends StatelessWidget {
  const _SelfContentTypeWidget(this.contentType);

  final String contentType;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        margin: EdgeInsets.all(5.0),
        width: MediaQuery.of(context).size.width,
        child: Text(contentType, style: Theme.of(context).textTheme.title)
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
        // Close the drawer
        Navigator.of(context).pop();
      },
    );
  }
}
