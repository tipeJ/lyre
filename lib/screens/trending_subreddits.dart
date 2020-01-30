import 'package:flutter/material.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/screens/screens.dart';
import 'package:lyre/widgets/widgets.dart';

class TrendingScreen extends StatelessWidget {

  static const _names = "subreddit_names";
  static const _count = "comment_count";
  static const _url = "comment_url";

  final Map<String, dynamic> data;
  const TrendingScreen({@required this.data, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const ActionSheetTitle(title: "Trending Subreddits"),
      ]..addAll(List<Widget>.generate(data[_names].length, (i) {
        final String subreddit = data[_names][i];
        return ListTile(
          title: Text(subreddit),
          onTap: () {
            Navigator.of(context).pushNamed("posts", arguments: {
              'content_source' : ContentSource.Subreddit,
              'target' : subreddit
            });
          },
          trailing: IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: "Sidebar",
            onPressed: () {
              Navigator.of(context).pop();
              Scaffold.of(context).showBottomSheet((context) => DraggableScrollableSheet(
                initialChildSize: 0.45,
                minChildSize: 0.45,
                maxChildSize: 1.0,
                expand: false,
                builder: (context, controller) {
                  return WikiScreen(
                    subreddit: subreddit,
                    pageName: WIKI_SIDEBAR_ARGUMENTS,
                    controller: controller,
                    title: "r/$subreddit"
                  );
                },
              ));
            },
          ),
        );
      })),
    );
  }
}