import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lyre/Bloc/bloc.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/Themes/themes.dart';
import 'package:lyre/widgets/widgets.dart';

/// Screen for showing SideBar content
class SidebarView extends StatelessWidget {

  /// Optional parameter for use with draggablescrollablebottomsheet
  final ScrollController scrollController;

  final PostsState state;

  const SidebarView({this.scrollController, @required this.state, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: CustomScrollView(
        controller: scrollController,
        slivers: _getSlivers(context, state),
      )
    );
  }

  List<Widget> _getSlivers(BuildContext context, PostsState state) {
    switch (state.contentSource) {
      case ContentSource.Frontpage:
        return _frontpageWidgets(context, state);
      case ContentSource.Redditor:
        return _redditorWidgets(context, state);
      case ContentSource.Self:
        return _selfWidgets(context, state);
      default:
        // Default to Subreddit
        return _subredditWidgets(context, state);
    }
  }

  // TODO: Implement ?
  List<Widget> _redditorWidgets(BuildContext context, PostsState state) => const [
    SliverSafeArea(
      sliver: SliverToBoxAdapter(
        child: CustomExpansionTile(
          title: "Trending Communities",
          children: <Widget>[],
        )
      )
    ),
    SliverToBoxAdapter(
      child: TextField(
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.all(5.0),
          helperText: "Search Reddit",
          helperStyle: TextStyle(fontStyle: FontStyle.italic)
        ),
      ),
    ),
  ];

  // TODO: Implement?
  List<Widget> _selfWidgets(BuildContext context, PostsState state) => const [];

  List<Widget> _frontpageWidgets(BuildContext context, PostsState state) => const [
    SliverSafeArea(
      sliver: SliverToBoxAdapter(
        child: CustomExpansionTile(
          title: "Trending Communities",
          // TODO: Add Trending Communities
          children: const [],
        )
      )
    ),
    SliverToBoxAdapter(
      child: TextField(
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.all(5.0),
          helperText: "Search Reddit",
          helperStyle: TextStyle(fontStyle: FontStyle.italic)
        ),
      ),
    ),
  ];

  List<Widget> _subredditWidgets(BuildContext context, PostsState state) => [
    SliverAppBar(
      title: const Text(
        'Sidebar',
        style: LyreTextStyles.title,
      ),
      automaticallyImplyLeading: false,
      pinned: true,
      actions: [Container()],
      backgroundColor: Theme.of(context).canvasColor,
      titleSpacing: 0.0,
    ),
    notNull(state.sideBar)
      ? SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 5.0),
              child: Text(
                "Subscribers",
                style: LyreTextStyles.bottomSheetTitle,
              )
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Text(
                state.subreddit.data["subscribers"].toString(),
              )
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 5.0),
              child: Text(
                "Online",
                style: LyreTextStyles.bottomSheetTitle,
              )
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Text(
                state.subreddit.data["accounts_active"].toString(),
              )
            )
          ]
        )
      )
      : null,
    SliverToBoxAdapter(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: OutlineButton(
              child: const Text("Submit"),
              onPressed: () {
                Navigator.of(context).pop();
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
              },
            )
          ),
          // Expanded(
          //   child: OutlineButton(
          //     child: const Text("Message the Mods"),
          //     onPressed: () {},
          //   )
          // )
        ],
      ),
    ),
    BlocBuilder<LyreBloc, LyreState>(
      builder: (BuildContext context, lyreState) {
        final bool subbed = lyreState.isSubscribed(state.target);
        return SliverToBoxAdapter(
          child: OutlineButton(
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(
                subbed ? "Unsubscribe" : "Subscribe",
                style: TextStyle(color: subbed ? LyreColors.unsubscribeColor : LyreColors.subscribeColor),
              )
            ),
            onPressed: () {
              if (subbed) {
                BlocProvider.of<LyreBloc>(context).add(UnSubscribe(subreddit: state.target));
              } else {
                BlocProvider.of<LyreBloc>(context).add(Subscribe(subreddit: state.target));
              }
            },
          )
        );
      },
    ),
    notNull(state.sideBar)
      ? SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(state.sideBar.contentHtml)
        )
      )
      : null
  ].where((w) => notNull(w)).toList();
}