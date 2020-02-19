import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Bloc/bloc.dart';
import 'package:lyre/Resources/constants_gql.dart';
import 'package:lyre/Resources/resources.dart';
import 'package:lyre/Themes/themes.dart';
import 'package:lyre/screens/screens.dart';
import 'package:lyre/widgets/widgets.dart';

class TopGrowingCommunitiesScreen extends StatelessWidget {
  const TopGrowingCommunitiesScreen({Key key}) : super(key: key);

  Widget _subredditsList(BuildContext context) => BlocBuilder<TopCommunityBloc, TopCommunityState>(builder: (_, state) {
    if (state.loadingState != LoadingState.Inactive) return const Center(child: CircularProgressIndicator());
    return ListView.builder(
      itemBuilder: (context, i) {
        final subreddit = state.communities[i];
        return ListTile(
          leading: CircleAvatar(
            child: Image(
              image: AdvancedNetworkImage(
                subreddit.thumbnailUrl
              ),
            ),
          ),
          title: Row(
            children: [
              subreddit.isNsfw ? const Padding(
                padding: EdgeInsets.only(right: 5.0),
                child: Text("NSFW", style: TextStyle(color: LyreColors.unsubscribeColor))
              ) : const SizedBox(),
              Text(subreddit.name)
            ]
          ),
          trailing: IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: "Sidebar",
            onPressed: () {
              Scaffold.of(context).showBottomSheet((context) => DraggableScrollableSheet(
                initialChildSize: 0.45,
                minChildSize: 0.45,
                maxChildSize: 1.0,
                expand: false,
                builder: (context, controller) {
                  return WikiScreen(
                    subreddit: subreddit.name,
                    pageName: WIKI_SIDEBAR_ARGUMENTS,
                    controller: controller,
                    title: "r/${subreddit.name}"
                  );
                },
              ));
            },
          ),
          onTap: () => Navigator.of(context).pushNamed("posts", arguments: {
            'content_source' : ContentSource.Subreddit,
            'target' : subreddit.name
          }),
        );
      },
      itemCount: state.communities.length,
    );
  });

  

  Widget _portraitLayout(BuildContext context) => PersistentBottomAppbarWrapper(
    body: _subredditsList(context),
    appBarContent: Material(
      color: Theme.of(context).primaryColor,
      child: Container(
        height: kBottomNavigationBarHeight,
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text("Top Growing Communities"),
            BlocBuilder<TopCommunityBloc, TopCommunityState>(builder: (_, state) => Text(state.category))
          ]
        )
      )
    ),
    listener: ValueNotifier(true),
    expandingSheetContent: _PortraitLayoutExpandingSheetContent(),
  );

  Widget _landscapeLayout(BuildContext context) => Row(
    children: <Widget>[
      Flexible(
        flex: 2,
        child: _categoriesList(context)
      ),
      Flexible(
        flex: 3,
        child: _subredditsList(context)
      )
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (BlocProvider.of<TopCommunityBloc>(context).state.communities.isEmpty) BlocProvider.of<TopCommunityBloc>(context).add((ChangeCategory(category: redditTopCommunitiesCategories.keys.elementAt(0))));
    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) => 
        constraints.maxWidth > constraints.maxHeight
          ? _landscapeLayout(context)
          : _portraitLayout(context)),
    );
  }
}

Widget _categoriesList(BuildContext context, [ScrollController controller]) => ListView.builder(
    controller: controller,
    itemCount: redditTopCommunitiesCategories.length,
    itemBuilder: (_, i) => ListTile(
      title: Text(redditTopCommunitiesCategories.keys.elementAt(i)),
      onTap: () => BlocProvider.of<TopCommunityBloc>(context).add(ChangeCategory(category: redditTopCommunitiesCategories.keys.elementAt(i))),
    ),
  );

class _PortraitLayoutExpandingSheetContent extends State<ExpandingSheetContent> {

  @override
  Widget build(BuildContext context) {
    return Material(
      child: _categoriesList(context, widget.innerController)
    );
  }
}