import 'package:flutter/material.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Themes/themes.dart';
import 'package:lyre/screens/screens.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';


///Screen for displaying global filters for the currently logged in user. Shouldn't be available to read-only instances of the application.
class GlobalFilters extends StatefulWidget {
  const GlobalFilters({Key key}) : super(key: key);

  @override
  _GlobalFiltersState createState() => _GlobalFiltersState();
}

class _GlobalFiltersState extends State<GlobalFilters> {

  Future<dynamic> _filtersFuture;
  List<String> _filteredSubreddits;

  @override
  void initState() { 
    super.initState();
    _filtersFuture = PostsProvider().getFilteredSubreddits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Global Filters"),
      ),
      body: FutureBuilder<dynamic>(
        future: _filtersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            if (snapshot.data is String) return Center(child: Text(snapshot.data));
            if (_filteredSubreddits == null) _filteredSubreddits = snapshot.data;
            if (_filteredSubreddits.isEmpty) return Center(child: Text("Dankmemes not filtered (yet)", style: TextStyle(color: Theme.of(context).textTheme.body2.color)));
            return Builder(
              builder: (context) {
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _filtersFuture = PostsProvider().getFilteredSubreddits();
                      _filteredSubreddits = null;
                    });
                  },
                  child: ListView.builder(
                    itemCount: _filteredSubreddits.length,
                    itemBuilder: (_, i) {
                      final sub = _filteredSubreddits[i];
                      return ListTile(
                        dense: true,
                        title: Text(sub),
                        onTap: () {
                          Scaffold.of(context).showBottomSheet(
                            (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ListTile(
                                  leading: const Icon(MdiIcons.tag),
                                  title: Text("r/$sub"),
                                  onTap: () {
                                    Navigator.of(context).pushNamed("posts", arguments: {
                                      'content_source' : ContentSource.Subreddit,
                                      'target' : sub
                                    });
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.info),
                                  title: const Text("Sidebar"),
                                  onTap: () {
                                    // Pop the bottom sheet
                                    Navigator.of(context).pop();
                                    Scaffold.of(context).showBottomSheet((context) => DraggableScrollableSheet(
                                      initialChildSize: 0.45,
                                      minChildSize: 0.45,
                                      maxChildSize: 1.0,
                                      expand: false,
                                      builder: (context, controller) {
                                        return WikiScreen(
                                          subreddit: sub,
                                          pageName: WIKI_SIDEBAR_ARGUMENTS,
                                          controller: controller,
                                          title: "r/$sub"
                                        );
                                      },
                                    ));
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.delete, color: LyreColors.unsubscribeColor),
                                  title: const Text("Remove"),
                                  onTap: () async {
                                    Navigator.of(context).pop();
                                    final bool remove = await showDialog(
                                      context: context,
                                      child: _RemoveFilterDialog(subreddit: sub)
                                    ) ?? false;
                                    if (remove) {
                                      setState(() {
                                        _filteredSubreddits.removeAt(i);
                                      });
                                      await PostsProvider().removeGlobalFilter(subreddit: sub);
                                    }
                                  },
                                )
                              ],
                            )
                          );
                        },
                      );
                    })
                );
              },
              );
          } else if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final String subreddit = await showDialog(
            context: context,
            builder: (context) {
              return _AddFilterDialog();
            }
          );
          if (subreddit != null) {
            _filteredSubreddits.add(subreddit);
            setState(() {});
          }
        },
      ),
    );
  }
}
class _RemoveFilterDialog extends StatelessWidget {
  final String subreddit;

  const _RemoveFilterDialog({@required this.subreddit, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Remove r/$subreddit from filters"),
      actions: <Widget>[
        OutlineButton(
          child: const Text("Cancel"),
          onPressed: () => Navigator.of(context).pop(),
        ),
        OutlineButton(
          child: const Text("OK"),
          onPressed: () => Navigator.of(context).pop(true),
        )
      ],
      );
  }
}

class _AddFilterDialog extends StatefulWidget {
  const _AddFilterDialog({Key key}) : super(key: key);

  @override
  __AddFilterDialogState createState() => __AddFilterDialogState();
}

class __AddFilterDialogState extends State<_AddFilterDialog> {
  TextEditingController _addFilterController;

  @override
  void initState() { 
    super.initState();
    _addFilterController = TextEditingController();
  }

  @override
  void dispose() { 
    _addFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const SizedBox(width: 0.0, height: 0.0),
      titlePadding: const EdgeInsets.all(0.0),
      content: TextField(
        controller: _addFilterController,
        decoration: const InputDecoration(
          labelText: "Filter Subreddit",
          prefixText: 'r/'
        ),
        onChanged: (str) => setState((){}),
      ),
      actions: <Widget>[
        OutlineButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        OutlineButton(
          child: Text('Add Filter'),
          onPressed: _addFilterController.text.isNotEmpty ? () async {
            await PostsProvider().addGlobalFilter(subreddit: _addFilterController.text);
            Navigator.of(context).pop(_addFilterController.text);
          } : null,
        )
      ],
    );
  }
}