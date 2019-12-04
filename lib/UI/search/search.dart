import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/UI/search/bloc/bloc.dart';
import 'package:lyre/UI/search/bloc/search_communities_bloc.dart';
import 'package:lyre/UI/search/bloc/search_communities_event.dart';
import 'package:lyre/UI/search/bloc/search_communities_state.dart';

enum SearchType {
  User,
  Submission,
  Comment
}

class SearchView extends StatefulWidget {
  final SearchType initialSearchType;
  const SearchView({@required this.initialSearchType, Key key}) : super(key: key);

  @override
  _SearchUsersViewState createState() => _SearchUsersViewState();
}

class _SearchUsersViewState extends State<SearchView> with SingleTickerProviderStateMixin {

  TabController _tabController;

  TextEditingController _usersController;
  TextEditingController _submissionsController;
  TextEditingController _commentsController;

  @override
  void initState() { 
    super.initState();
    int initialIndex;
    if (widget.initialSearchType == SearchType.User) {
      initialIndex = 0;
    } else if (widget.initialSearchType == SearchType.Submission) {
      initialIndex = 1;
    } else {
      initialIndex = 2;
    }
    _usersController = TextEditingController();
    _submissionsController = TextEditingController();
    _commentsController = TextEditingController();
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, value) {
          return [SliverSafeArea(
            sliver: SliverAppBar(
              floating: false,
              backgroundColor: Theme.of(context).canvasColor,
              automaticallyImplyLeading: false,
              title: Padding(
                padding: EdgeInsets.only(bottom: 3.5),
                child: TabBar(
                  controller: _tabController,
                  tabs: <Widget>[
                    Text('Communities'),
                    Text('Submissions'),
                    Text('Comments'),
                  ],
                )
              ),
            ),
          )];
        },
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            _usersSearchView(context),
            Container(),
            Container()
          ],
        ),
      ),
    );
  }

  Widget _usersSearchView(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          floating: true,
          snap: true,
          title: Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _usersController,
                  )
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    BlocProvider.of<SearchCommunitiesBloc>(context).add(UserSearchQueryChanged(query: _usersController.text));
                  },
                )
              ],
            )
          ),
        ),
        BlocBuilder<SearchCommunitiesBloc, SearchCommunitiesState>(
          builder: (context, state) {
            if (!state.loading && state.users.isEmpty) {
              return SliverToBoxAdapter(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height / 2,
                  child: Center(child: Icon(Icons.search, size: 55.0,),),
                ),
              );
            } else if (state.loading) {
              return SliverToBoxAdapter(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height / 2,
                  child: Center(child: CircularProgressIndicator(),),
                ),
              );
            } else {
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final object = state.users[i];
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
                    } else {
                      return Container(width: MediaQuery.of(context).size.width, height: 50.0, color: Colors.red,);
                    }
                  },
                  childCount: state.users.length
                ),
              );
            }
          },
        )
      ],
    );
  }
}