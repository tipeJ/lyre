import 'dart:ui';
import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix0;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/utils/urlUtils.dart';
import 'package:lyre/widgets/comment.dart';
import 'package:lyre/widgets/bottom_appbar.dart';
import 'package:lyre/screens/interfaces/previewCallback.dart';
import 'package:lyre/widgets/postInnerWidget.dart';
import 'package:lyre/Bloc/bloc.dart';
import 'package:lyre/widgets/widgets.dart';
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
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
            child: const Center(child: Icon(Icons.search, size: 55.0,),),
          );
        } else if (state.loading && state.communities.isEmpty) {
          return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 2,
            child: const Center(child: CircularProgressIndicator(),),
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
            child: const Center(child: const Icon(Icons.search, size: 55.0,),),
          );
        } else if (state.loading && state.results.isEmpty) {
          return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 2,
            child: const Center(child: const CircularProgressIndicator(),),
          );
        } else {
          return BlocBuilder<LyreBloc, LyreState>(
            builder: (context, lyreState) {
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
                      return InkWell(
                        onTap: () => Navigator.of(context).pushNamed('comments', arguments: object),
                        child: CommentContent(object, PreviewSource.PostsList)
                      );
                    } else if (object is Submission) {
                      return postInnerWidget(
                        submission: object,
                        previewSource: PreviewSource.PostsList,
                        linkType: getLinkType(object.url.toString()),
                        fullSizePreviews: lyreState.fullSizePreviews,
                        showCircle: lyreState.showPreviewCircle,
                        blurLevel: lyreState.blurLevel.toDouble(),
                        showNsfw: lyreState.showNSFWPreviews,
                        showSpoiler: lyreState.showSpoilerPreviews,
                        onOptionsClick: () {},
                      );
                    }
                  },
                  itemCount: state.results.length + 1,
              );
            },
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

class _expandingSearchParamsState extends State<_expandingSearchParams> with TickerProviderStateMixin {

  TextEditingController _userContentController;
  FocusNode _node;
  FocusNode _removeFocus;


  @override
  void dispose() {
    _userContentController.dispose();
    _authorController.dispose();
    _authorExpansionController.dispose();
    _subredditExpansionController.dispose();
    _subredditController.dispose();
    super.dispose();
  }
  @override
  void initState() { 
    super.initState();
    _userContentController = TextEditingController();
    _node = FocusNode();
    _node.addListener(() {
      setState((){});
    });
    _removeFocus = FocusNode();
    _authorController = TextEditingController();
    _subredditController = TextEditingController();

    _authorExpansionController = AnimationController(vsync: this);
    _subredditExpansionController = AnimationController(vsync: this);
  }

  bool _submissions = true;
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

  bool _authorEnabled = false;
  AnimationController _authorExpansionController;
  TextEditingController _authorController;

  bool _subredditEnabled = false;
  AnimationController _subredditExpansionController;
  TextEditingController _subredditController;

  PersistentBottomSheetController _sheetController;

  ///Send a new Query Changed event to the [SearchUsercontentBloc] of the given context
  void _dispatchNewParameters(BuildContext context) {
    // TODO: Implement Submissions (and statistics?) search.
    BlocProvider.of<SearchUsercontentBloc>(context).add(UserContentQueryChanged(parameters: CommentSearchParameters(
      query: _userContentController.text,
      size: _sizeOptions[_size],
      sort: _sort,
      sortType: _sortType,
      author: _authorEnabled ? _authorController.text : null,
      subreddit: _subredditEnabled ? _subredditController.text : null
    )));
  }

  Future<bool> _willPop() async {
    if (_node.hasFocus) {
      _node.unfocus();
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _willPop,
      child: ClipRRect(
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15.0),
          topRight: Radius.circular(15.0),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Material(
                color: Theme.of(context).primaryColor,
                child: Container(
                  height: kBottomNavigationBarHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(right: _node.hasFocus ? 0.0 : 5.0),
                        child: prefix0.Visibility(
                          visible: !_node.hasFocus,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () {
                              Navigator.of(context).maybePop();
                            },
                          )
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          focusNode: _node,
                          enabled: _sheetController == null,
                          decoration: InputDecoration(
                            hintText: 'Search Reddit',
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none
                          ),
                          controller: _userContentController,
                          onSubmitted: (s) {
                            _dispatchNewParameters(context);
                          },
                        ),
                      ),
                      OutlineButton(
                        child: Text("Filters"), 
                        onPressed: () async {
                          _sheetController = Scaffold.of(context).showBottomSheet((context) => _filtersContent());
                          await _sheetController.closed;
                          setState(() {
                            _sheetController = null;
                          });
                        }
                      )
                    ],
                  ),
                )
              ),
            ],
          ),
        ),
      )
    );
  }

  Padding _filtersContent() {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ActionSheetTitle(
            title: "Search Filters",
          ),
          Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(vertical: 7.5),
            child: ToggleButtons(
              renderBorder: false,
              selectedColor: Theme.of(context).accentColor,
              fillColor: Theme.of(context).primaryColor.withOpacity(0.4),
              children: const <Widget>[
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
                    if (!_submissions) {
                      _sheetController.setState(() {
                        _comments = false;
                        _statistics = false;
                        _submissions = true;
                      });
                    }
                    break;
                  case 1:
                    if (!_comments) {
                      _sheetController.setState(() {
                        _comments = true;
                        _statistics = false;
                        _submissions = false;
                      });
                    }
                    break;
                  
                  default:
                    if (!_statistics) {
                      _sheetController.setState(() {
                        _comments = false;
                        _statistics = true;
                        _submissions = false;
                      });
                    }
                    break;
                }
              },
            )
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: <Widget>[
                const Text('Size'),
                Expanded(
                  child: Slider(
                    value: _size.toDouble(),
                    min: 0.0,
                    max: (_sizeOptions.length - 1).toDouble(),
                    divisions: _sizeOptions.length - 1,
                    onChanged: (value) {
                      _sheetController.setState(() {
                        _size = value.round();
                      });
                    },
                  )
                ),
                SizedBox(
                  width: 25.0,
                  child: Text(_sizeOptions[_size].toString())
                )
              ],
            )
          ),
          _parametersWidget(
            'Sort', 
            _sort == PushShiftSort.Asending
              ? OutlineButton.icon(
                  icon: Icon(MdiIcons.sortAscending),
                  label: const Text("Ascending"),
                  onPressed: () {
                    _sheetController.setState(() {
                      _sort = PushShiftSort.Descending;
                    });
                  },
                )
              : OutlineButton.icon(
                  icon: Icon(MdiIcons.sortDescending),
                  label: const Text("Descending"),
                  onPressed: () {
                    _sheetController.setState(() {
                      _sort = PushShiftSort.Asending;
                    });
                  },
                )
          ),
          _parametersWidget(
            'Sort Type',
            DropdownButton<PushShiftSortType>(
              value: _sortType,
              onChanged: (newSort) {
                _sheetController.setState(() {
                  _sortType = newSort;
                });
              },
              items: PushShiftSortType.values.map((i) {
                String _typeString;
                IconData _headingIconData;
                if (i == PushShiftSortType.Created_UTC) {
                  _typeString = "Date";
                  _headingIconData = MdiIcons.clock;
                } else if (i == PushShiftSortType.Num_Comments) {
                  _typeString = "Number of Comments";
                  _headingIconData = MdiIcons.commentMultiple;
                } else {
                  _typeString = "Karma";
                  _headingIconData = MdiIcons.yinYang;
                }
                return DropdownMenuItem(
                  value: i,
                  child: Row(children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 3.5),
                      child: Icon(_headingIconData)
                    ),
                    Text(_typeString)
                  ],)
                );
              },
              ).toList())
            ),
            _parametersWidget(
              'Limit to Author', 
              Checkbox(
                value: _authorEnabled,
                onChanged: (enabled) {
                  _sheetController.setState(() {
                    _authorEnabled = enabled;
                    _authorExpansionController.animateTo(_authorEnabled ? 1.0 : 0.0, duration: Duration(milliseconds: 200), curve: Curves.ease);
                  });
                },
              )
          ),
          SizeTransition(
            sizeFactor: _authorExpansionController,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: TextField(
                enabled: _authorEnabled,
                autofocus: false,
                controller: _authorController,
                decoration: InputDecoration(
                  labelText: 'Author Username'
                ),
              )
            ),
          ),
            _parametersWidget(
              'Limit to Subreddit', 
              Checkbox(
                value: _subredditEnabled,
                onChanged: (enabled) {
                  _sheetController.setState(() {
                    _subredditEnabled = enabled;
                    _subredditExpansionController.animateTo(_subredditEnabled ? 1.0 : 0.0, duration: Duration(milliseconds: 200), curve: Curves.ease);
                  });
                },
              )
          ),
          SizeTransition(
            sizeFactor: _subredditExpansionController,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: TextField(
                enabled: _subredditEnabled,
                autofocus: false,
                controller: _subredditController,
                decoration: InputDecoration(
                  labelText: 'Subreddit'
                ),
              )
            ),
          ),
        ],
      )
    );
  }
  ///Helper Widget Wrapper for reducing repeating code. Title Text Widget will be displayed first, and the child last, with a SpaceBetween row alignment.
  Widget _parametersWidget(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(title),
          child
        ],
      )
    );
  }
}