import 'dart:math';
import 'dart:math' as prefix0;
import 'dart:ui';

import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/UI/Comments/comment.dart';
import 'package:lyre/UI/bottom_appbar.dart';
import 'package:lyre/UI/interfaces/previewCallback.dart';
import 'package:lyre/UI/postInnerWidget.dart';
import 'package:lyre/UI/search/bloc/bloc.dart';
import 'package:lyre/UI/search/bloc/search_communities_bloc.dart';
import 'package:lyre/UI/search/bloc/search_communities_event.dart';
import 'package:lyre/UI/search/bloc/search_communities_state.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class SearchCommunitiesView extends StatefulWidget {
  const SearchCommunitiesView({Key key}) : super(key: key);

  @override
  _SearchCommunitiesViewState createState() => _SearchCommunitiesViewState();
}

class _SearchCommunitiesViewState extends State<SearchCommunitiesView> {
  TextEditingController _communitiesQueryController;

  @override
  void initState() { 
    super.initState();
    _communitiesQueryController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PersistentBottomAppbarWrapper(
        body: _usersSearchCommunitiesView(context),
        appBarContent: Material(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _communitiesQueryController,
                  onSubmitted: (s) {
                    BlocProvider.of<SearchCommunitiesBloc>(context).add(UserSearchQueryChanged(query: s));
                  },
                )
                ),
              IconButton(icon: Icon(Icons.search),onPressed: () {
                if (_communitiesQueryController.text.isNotEmpty) {
                  BlocProvider.of<SearchCommunitiesBloc>(context).add(UserSearchQueryChanged(query: _communitiesQueryController.text));
                } else {
                  final warningSnackBar = SnackBar(content: Text("Can't search with an empty query"),);
                  Scaffold.of(context).showSnackBar(warningSnackBar);
                }
              },)
            ],)
          ),
        ),
      ),
    );
  }

  Widget _usersSearchCommunitiesView(BuildContext context) {
    return BlocBuilder<SearchCommunitiesBloc, SearchCommunitiesState>(
      builder: (context, state) {
        if (!state.loading && state.communities.isEmpty) {
          return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 2,
            child: Center(child: Icon(Icons.search, size: 55.0,),),
          );
        } else if (state.loading && state.communities.isEmpty) {
          return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 2,
            child: Center(child: CircularProgressIndicator(),),
          );
        } else {
          return ListView.builder(
            itemBuilder: (context, i) {
                if (i == state.communities.length) {
                  return FlatButton(
                    child: state.loading && state.communities.isNotEmpty ? CircularProgressIndicator() : Text('Load More'),
                    onPressed: () {
                      BlocProvider.of<SearchCommunitiesBloc>(context).add(LoadMoreCommunities());
                    },
                  );
                }
                final object = state.communities[i];
                if (object is Redditor) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    height: 50.0,
                    child: Text(object.displayName),
                  );
                } else if (object is Subreddit) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    height: 50.0,
                    child: Text('r/' + object.displayName),
                  );
                }
              },
              itemCount: state.communities.length + 1,
          );
        }
      },
    );
  }
}

class SearchUserContentView extends StatefulWidget {
  SearchUserContentView({Key key}) : super(key: key);

  @override
  _SearchUserContentViewState createState() => _SearchUserContentViewState();
}

class _SearchUserContentViewState extends State<SearchUserContentView> with SingleTickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: <Widget>[
          _usersSearchUserContentView(context),
          Align(
            alignment: Alignment.bottomCenter,
            child: _expandingSearchParams(),
          )
        ],
      ),
    );
  }

  Widget _usersSearchUserContentView(BuildContext context) {
    return BlocBuilder<SearchUsercontentBloc, SearchUsercontentState>(
      builder: (context, state) {
        if (!state.loading && state.results.isEmpty) {
          return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 2,
            child: Center(child: Icon(Icons.search, size: 55.0,),),
          );
        } else if (state.loading && state.results.isEmpty) {
          return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 2,
            child: Center(child: CircularProgressIndicator(),),
          );
        } else {
          return ListView.builder(
            itemBuilder: (context, i) {
                if (i == state.results.length) {
                  return FlatButton(
                    child: state.loading && state.results.isNotEmpty ? CircularProgressIndicator() : Text('Load More'),
                    onPressed: () {
                      //BlocProvider.of<SearchUsercontentBloc>(context).add(LoadMoreCommunities());
                    },
                  );
                }
                final object = state.results[i];
                if (object is Comment) {
                  return CommentContent(object);
                } else if (object is Submission) {
                  return postInnerWidget(object, PreviewSource.Comments);
                }
              },
              itemCount: state.results.length + 1,
          );
        }
      },
    );
  }
}

class _expandingSearchParams extends StatefulWidget {
  _expandingSearchParams({Key key}) : super(key: key);

  @override
  _expandingSearchParamsState createState() => _expandingSearchParamsState();
}

class _expandingSearchParamsState extends State<_expandingSearchParams> with SingleTickerProviderStateMixin {

  AnimationController  _animationController;
  double _lerp(double min, double max) => lerpDouble(min, max, _animationController.value);

  TextEditingController _userContentController;


  @override
  void dispose() {
    _userContentController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  @override
  void initState() { 
    super.initState();
    _userContentController = TextEditingController();

    _animationController = AnimationController(vsync: this);
    _animationController.addListener(() {
      setState(() {});
    });
  }
  void _handleNavDragUpdate(DragUpdateDetails details) {
    _animationController.value -= details.primaryDelta / _approximatedBottomBarHeight;
  }

  void _reverseNav() {
    _animationController.fling(velocity: -2.0);
  }
  double _approximatedBottomBarHeight = kBottomNavigationBarHeight * 3;

  void _handleNavDragEnd(DragEndDetails details) {
    if (_animationController.isAnimating ||
        _animationController.status == AnimationStatus.completed) return;
    final double flingVelocity = details.velocity.pixelsPerSecond.dy /
        _approximatedBottomBarHeight; //<-- calculate the velocity of the gesture
    if (flingVelocity < 0.0) {
      _animationController.fling(
        velocity: max(2.0, -flingVelocity)); //<-- either continue it upwards
    } else if (flingVelocity > 0.0) {
      _animationController.fling(
        velocity: min(-2.0, -flingVelocity)); //<-- or continue it downwards
    } else
      _animationController.fling(
        velocity: _animationController.value < 0.5
          ? -2.0
          : 2.0); //<-- or just continue to whichever edge is closer
  }

  bool _submissions = false;
  bool _comments = false;
  bool _statistics = false;

  ///Currently selected size option (From [_sizeOptions])
  int _size = 1;
  ///List of available size options
  List<int> _sizeOptions = [
    10,
    25,
    50,
    100,
    250,
    500
  ];

  PushShiftSort _sort = PushShiftSort.Descending;
  PushShiftSortType _sortType = PushShiftSortType.Created_UTC;

  void _dispatchNewParameters(BuildContext context) {
    BlocProvider.of<SearchUsercontentBloc>(context).add(UserContentQueryChanged(parameters: CommentSearchParameters(
      query: _userContentController.text,
      size: _sizeOptions[_size],
      sort: _sort
    )));
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(15.0),
        topRight: Radius.circular(15.0),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width,
        color: Theme.of(context).canvasColor,
        child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            GestureDetector(
              onVerticalDragUpdate: _handleNavDragUpdate,
              onVerticalDragEnd: _handleNavDragEnd,
              child: Material(
                child: Container(
                  height: kBottomNavigationBarHeight,
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration.collapsed(
                            hintText: 'Search Reddit',
                          ),
                          controller: _userContentController,
                          onSubmitted: (s) {
                            _dispatchNewParameters(context);
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.search), 
                          onPressed: () {
                            if (_userContentController.text.isNotEmpty) {
                              _dispatchNewParameters(context);
                            } else {
                              final warningSnackBar = SnackBar(content: Text("Can't search with an empty query"),);
                              Scaffold.of(context).showSnackBar(warningSnackBar);
                            }
                          }
                      ),
                      IconButton(
                        icon: AnimatedIcon(
                          icon: AnimatedIcons.menu_close, progress: _animationController,), 
                          onPressed: () {
                            _animationController.value >= 0.9
                              ? _animationController.animateTo(0.0, duration: Duration(milliseconds: 250))
                              : _animationController.animateTo(1.0, curve: Curves.ease, duration: Duration(milliseconds: (_animationController.value > 0.3 ? 250 / _animationController.value : 250).round()));
                          }
                      )
                    ],
                  ),
                )
              )
            ),
            SizeTransition(
              axis: Axis.vertical,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 7.5),
                      child: ToggleButtons(
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3.5),
                            child: Text('Submissions')
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3.5),
                            child: Text('Comments')
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3.5),
                            child: Text('Statistics'),
                          ),
                        ],
                        isSelected: [
                          _submissions,
                          _comments,
                          _statistics
                        ],
                        onPressed: (i) {
                          switch (i) {
                            case 0:
                              setState(() {
                                _submissions = !_submissions;
                              });
                              break;
                            case 1:
                              setState(() {
                                _comments = !_comments;
                              });
                              break;
                            
                            default:
                              setState(() {
                                _statistics = !_statistics;
                              });
                              break;
                          }
                        },
                      )
                    ),
                    Divider(),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        children: <Widget>[
                          Text('Size'),
                          Expanded(
                            child: Slider(
                              value: _size.toDouble(),
                              min: 0.0,
                              max: (_sizeOptions.length - 1).toDouble(),
                              divisions: _sizeOptions.length - 1,
                              onChanged: (value) {
                                setState(() {
                                  _size = value.round();
                                });
                              },
                            )
                          ),
                          Text(_sizeOptions[_size].toString())
                        ],
                      )
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text('Sort'),
                          DropdownButton<PushShiftSort>(
                            value: _sort,
                            underline: null,
                            onChanged: (newSort) {
                              setState(() {
                                _sort = newSort;
                              });
                            },
                            items: PushShiftSort.values.map((i) => DropdownMenuItem(
                                value: i,
                                child: Row(children: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.only(right: 3.5),
                                    child: Icon(i == PushShiftSort.Asending ? MdiIcons.sortAscending : MdiIcons.sortDescending)
                                  ),
                                  Text(i.toString().split('.').last)
                                ],)
                              ),
                            ).toList()
                          )
                        ],
                      )
                    )
                  ],
                ),
                sizeFactor: _animationController,
            )
          ],
        ),
      ),
      ),
    );
  }
}