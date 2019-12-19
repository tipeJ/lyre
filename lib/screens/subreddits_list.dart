import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Bloc/bloc.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/widgets/widgets.dart';

/// Class for displaying the list of subreddits to which the current user has subscribed to. Also shows Frontpage and r/All
class SubredditsList extends State<ExpandingSheetContent> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Material(
      child: CustomScrollView(
        controller: widget.innerController,
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: widget.appBarContent,
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              InkWell(
                onTap: () {
                  widget.innerController.reset();
                  BlocProvider.of<PostsBloc>(context).add(PostsSourceChanged(source: ContentSource.Frontpage));
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      alignment: Alignment.centerLeft,
                      constraints: const BoxConstraints(minHeight: 40.0),
                      padding: const EdgeInsets.only(
                        bottom: 0.0,
                        left: 5.0,
                        top: 0.0),
                      child: const Text("Frontpage"),
                    ),
                    const Divider(indent: 10.0, endIndent: 10.0, height: 0.0,)
                  ],
                )
              ),
              InkWell(
                onTap: () {
                  _openSub('all');
                },
                child: Container(
                  alignment: Alignment.centerLeft,
                  constraints: const BoxConstraints(minHeight: 40.0),
                  padding: const EdgeInsets.only(
                    bottom: 0.0,
                    left: 5.0,
                    top: 0.0),
                  child: const Text("All"),
                ),
              )
            ]),
          ),
          SliverAppBar(
            backgroundColor: Theme.of(context).canvasColor,
            automaticallyImplyLeading: false,
            floating: true,
            snap: true,
            pinned: true,
            actions: <Widget>[Container()],
            title: new TextField(
              enabled: widget.innerController.extent.isAtMax,
              onChanged: (String s) {
                searchQuery = s;
                setState(() {
                });
                // sub_bloc.fetchSubs(s);
              },
              decoration: const InputDecoration(hintText: 'Search Subscriptions'),
              onEditingComplete: () {
                widget.innerController.reset();
                BlocProvider.of<PostsBloc>(context).add(PostsSourceChanged(source: ContentSource.Subreddit, target: searchQuery));
              },
            ),
          ),
          BlocBuilder<LyreBloc, LyreState>(
            builder: (context, state) {
              return _defaultSubredditList(state.subscriptions.where((name) {
                  final sub = name.toLowerCase();
                  return sub.contains(searchQuery.toLowerCase());
                }).toList()..sort());
            },
          )
        ],
      )
    );
  }

  /// Open a subreddit from the list
  _openSub(String s) {
    widget.innerController.reset();
    BlocProvider.of<PostsBloc>(context).add(PostsSourceChanged(source: ContentSource.Subreddit, target: s));
  }

  /// Returns the list of subscriptions
  Widget _defaultSubredditList(List<String> subreddits) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, i) {
        return InkWell(
          onTap: (){
            _openSub(subreddits[i]);
          },
          child: SubredditItem(
            last: i == subreddits.length-1,
            subreddit: subreddits[i],
          )
        );
      }, childCount: subreddits.length),
    );
  }
  
  // Widget _searchedSubredditList(AsyncSnapshot<SubredditM> snapshot) {
  //   var subs = snapshot.data.results;
  //   return SliverList(
  //     delegate: SliverChildBuilderDelegate((context, i) {
  //       return InkWell( //Subreddit entry
  //         onTap: (){
  //           _openSub(subs[i].displayName);
  //         },
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: <Widget>[
  //             Container(
  //               padding: EdgeInsets.only(
  //                 bottom: 0.0,
  //                 left: 5.0,
  //                 top: 0.0),
  //               child: Row(
  //                 children: <Widget>[
  //                   Expanded(
  //                     child: Text(subs[i].displayName)
  //                   ),
  //                   PopupMenuButton<String>(
  //                     elevation: 3.2,
  //                     onSelected: (s) {
  //                       },
  //                     itemBuilder: (context) {
  //                       return _subListOptions.map((s) {
  //                         return PopupMenuItem<String>(
  //                           value: s,
  //                           child: Column(
  //                             children: <Widget>[
  //                               Row(
  //                                 mainAxisAlignment: MainAxisAlignment.start,
  //                                 children: <Widget>[
  //                                   s == _subListOptions[0]
  //                                     ? Icon(Icons.remove_circle)
  //                                     : Icon(Icons.add_circle),
  //                                   VerticalDivider(),
  //                                   Text(s),
                                    
  //                                 ]
  //                               ,),
  //                               s != _subListOptions[_subListOptions.length-1] ? Divider() : null
  //                             ].where((w) => notNull(w)).toList(),
  //                           ),
  //                         );
  //                       }).toList();
  //                     },
  //                   )
  //                 ],
  //               ),
  //             ),
  //             i != subs.length-1 ? Divider(indent: 10.0, endIndent: 10.0, height: 0.0,) : null
  //           ].where((w) => notNull(w)).toList(),
  //         )
  //       );
  //     }, childCount: subs.length),
  //   );
  // }
}

class SubredditItem extends StatelessWidget {
  /// Whether to show the divider (Last item will not)
  final bool last;
  final String subreddit;

  const SubredditItem({@required this.last, @required this.subreddit, Key key}) : super(key: key);

  /// List of options for subRedditView
  final List<String> _subListOptions = const [
    "Unsubscribe",
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          constraints: const BoxConstraints(minHeight: 40.0),
          padding: const EdgeInsets.only(
            bottom: 0.0,
            left: 5.0,
            top: 0.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(subreddit)
              ),
              PopupMenuButton<String>(
                elevation: 3.2,
                onSelected: (s) {
                  // Unsubscribe
                  BlocProvider.of<LyreBloc>(context).add(UnSubscribe(subreddit: subreddit));
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
        last ? null : const Divider(indent: 10.0, endIndent: 10.0, height: 0.0,)
      ].where((w) => notNull(w)).toList(),
    );
  }
}