import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lyre/Resources/filter_manager.dart';

class FiltersView extends StatefulWidget {
  FiltersView({Key key}) : super(key: key);

  @override
  _FiltersViewState createState() => _FiltersViewState();
}

class _FiltersViewState extends State<FiltersView> with SingleTickerProviderStateMixin{

  TabController _tabController;
  TextEditingController _addFilterController;

  Box _subredditsBox;
  Box _usersBox;
  Box _domainsBox;

  @override
  void initState() { 
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _addFilterController = TextEditingController();
  }
  @override
  void dispose() { 
    _tabController.dispose();
    _addFilterController.dispose();
    super.dispose();
  }
  Future<dynamic> _openFiltersDatabase() async {
    _subredditsBox = await Hive.openBox(FILTER_SUBREDDITS_BOX);
    _usersBox = await Hive.openBox(FILTER_USERS_BOX);
    _domainsBox = await Hive.openBox(FILTER_DOMAINS_BOX);
    return 0;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(_getAddFilterDialogTitle()),
                content: TextField(
                  controller: _addFilterController,
                  decoration: InputDecoration(
                    helperText: _getAddFilterDialogTitle()
                  ),
                ),
                actions: <Widget>[
                  OutlineButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      _addFilterController.clear();
                      Navigator.of(context).pop();
                    },
                  ),
                  OutlineButton(
                    child: Text('Add Filter'),
                    onPressed: () async {
                      await _addFilter();
                      setState(() {
                      });
                      _addFilterController.clear();
                      Navigator.of(context).pop();
                    },
                  )
                ],
              );
            }
          );
        },
      ),
      body: Container(
        padding: EdgeInsets.all(10.0),
        child: FutureBuilder(
          future: _openFiltersDatabase(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return NestedScrollView(
                headerSliverBuilder: (context, value) {
                  return [
                    SliverSafeArea(
                      sliver: SliverAppBar(
                        floating: true,
                        automaticallyImplyLeading: false,
                        title: TabBar(
                          controller: _tabController,
                          tabs: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(bottom: 3.5),
                              child: Text('Subreddits'),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 3.5),
                              child: Text('Users'),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 3.5),
                              child: Text('Domains'),
                            ),
                          ],
                        ),
                      ),
                    )
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    _subredditsList(),
                    _usersList(),
                    _domainsList()
                  ],
                ),
              );
            } else {
              return Container();
            }
          },
        )
      ),
    );
  }

  String _getAddFilterDialogTitle() {
    switch (_tabController.index) {
      case 0:
        return 'Filter Subreddit';        
      case 1:
        return 'Filter User';
      default:
        return 'Filter Domain';
    }
  }

  Future<int> _addFilter() {
    if (_tabController.index == 0) {
      return _subredditsBox.add(_addFilterController.text.toLowerCase());
    } else if (_tabController.index == 1) {
      return _usersBox.add(_addFilterController.text.toLowerCase());
    } else  {
      return _domainsBox.add(_addFilterController.text.toLowerCase());
    }
  }

  Widget _subredditsList() {
    return ListView.separated(
      itemCount: _subredditsBox.length,
      separatorBuilder: (context, i) => Divider(),
      itemBuilder: (context, i) {
        return Container(
          height: 50.0,
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text(_subredditsBox.getAt(i)),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () async {
                  await _subredditsBox.deleteAt(i);
                  setState(() {
                  });
                },
              )
            ],
          ),
        );
      },
    );
  }
  Widget _usersList() {
    return ListView.separated(
      itemCount: _usersBox.length,
      separatorBuilder: (context, i) => Divider(),
      itemBuilder: (context, i) {
        return Container(
          height: 50.0,
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text(_usersBox.getAt(i)),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () async {
                  await _usersBox.deleteAt(i);
                  setState(() {
                  });
                },
              )
            ],
          ),
        );
      },
    );
  }
  Widget _domainsList() {
    return ListView.separated(
      itemCount: _domainsBox.length,
      separatorBuilder: (context, i) => Divider(),
      itemBuilder: (context, i) {
        return Container(
          height: 50.0,
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text(_domainsBox.getAt(i)),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () async {
                  await _domainsBox.deleteAt(i);
                  setState(() {
                  });
                },
              )
            ],
          ),
        );
      },
    );
  }
}