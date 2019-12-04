import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/UI/bottom_appbar.dart';
import 'package:lyre/UI/bottom_appbar_expanding.dart' as prefix0;
import 'package:lyre/UI/search/bloc/bloc.dart';
import 'package:lyre/UI/search/bloc/search_communities_bloc.dart';
import 'package:lyre/UI/search/bloc/search_communities_event.dart';
import 'package:lyre/UI/search/bloc/search_communities_state.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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

  TextEditingController _usersController;

  @override
  void initState() { 
    super.initState();
    _usersController = TextEditingController();
  }

  @override
  void dispose() {
    _usersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PersistentBottomAppbarWrapper(
        fullSizeHeight: 450.0,
        body: _usersSearchView(context),
        expandingSheetContent: _paramsBar(),
      )
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
            if (!state.loading && state.communities.isEmpty) {
              return SliverToBoxAdapter(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height / 2,
                  child: Center(child: Icon(Icons.search, size: 55.0,),),
                ),
              );
            } else if (state.loading && state.communities.isEmpty) {
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
                    } else {
                      return Container(width: MediaQuery.of(context).size.width, height: 50.0, color: Colors.red,);
                    }
                  },
                  childCount: state.communities.length+1
                ),
              );
            }
          },
        )
      ],
    );
  }
}

class _paramsBar extends State<ExpandingSheetContent> with SingleTickerProviderStateMixin {
  AnimationController _iconController;

  @override
  void initState() { 
    super.initState();
    _iconController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
  }

  @override
  void dispose() { 
    _iconController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return NotificationListener<prefix0.DraggableScrollableNotification>(
      child: CustomScrollView(
      scrollDirection: Axis.vertical,
      controller: widget.innerController,
      physics: AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Material(
            child: Container(
              height: 56.0,
              width: MediaQuery.of(context).size.width,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(),
                  ),
                  IconButton(icon: AnimatedIcon(icon: AnimatedIcons.arrow_menu, progress: _iconController,), onPressed: () {},)
                ],
              )
            )
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([Checkbox(value: false, onChanged: (bool newValue) {},),
        Divider(),
        Text('Setting stuff')]),
        )
      ],
    ),
    onNotification: (not) {
      //print('received');
      if (!widget.innerController.extent.isAtMax) {
        setState(() {
          _iconController.value = (widget.innerController.extent.currentExtent / widget.innerController.extent.maxExtent);
        });
      }
      return true;
    },
    );
  }
}